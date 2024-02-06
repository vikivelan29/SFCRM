/*********************************************************
*Class        :  ABHFL_NDCSTPHandler
*Author       :  Siddarth Jaitly
*Created Date :  12/12/2023
*Last Modified:  12/12/2023
*Description  :  Class for NDC STP
*********************************************************/
public with sharing class ABHFL_NDCSTPHandler implements ASF_IntegrationInvocable {
    List<String> sourceList = new List<String>{'Welcome BOT', 'Voice Bot', 'WhatsApp', 'Chatbot', 'Customer Portal', 'Email'};
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - evaluate
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @Description - Invoked from the ASF_IntegrationsController class, this method evaluates whether NDC integration should be fired or not.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        Case caseRecord = [SELECT Id,Source__c,AccountId,CCC_External_Id__c,ContactId,Asset.LAN__c,Asset.Account_Status__c,
                           Asset.Branch__r.Branch_Queue_Id__c,ABHFL_Case_Detail__r.STP_Request_Type__c,No_Auto_Communication__c
                           FROM Case WHERE Id =: caseRec.Id WITH SECURITY_ENFORCED];
        
        //Check for mandatory API conditions
        result.status = ABHFL_Constants.ERROR;
        result.response = Custom_Messages__mdt.getInstance('NDC_STP_EvaluationFailed').Message__c;   
        if(String.isNotBlank(caseRecord.Asset.LAN__c) && caseRecord.ABHFL_Case_Detail__r.STP_Request_Type__c == ABHFL_Constants.EMAIL){
            if(caseRecord.Asset.Account_Status__c == ABHFL_Constants.ACCOUNT_STATUS_CLOSED){
            	result.status = ABHFL_Constants.SUCCESS;
                result.response = Custom_Messages__mdt.getInstance('NDC_STP_EvaluationSuccess').Message__c;
            } else {
                if(caseRecord.Source__c == ABHFL_Constants.BRANCH){
                    caseRecord.OwnerId = caseRecord.Asset.Branch__r.Branch_Queue_Id__c;
                    if(Schema.sObjectType.Case.isUpdateable()){
                        update caseRecord;
                    }
                    result.response = Custom_Messages__mdt.getInstance('NDC_STP_EvaluationFailedBranchAssignment').Message__c;                                                                                                                               

                } else if(sourceList.contains(caseRecord.Source__c)) {
                    List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id,Rejected_Case_Email_Template__c,Rejected_Case_SMS_Metadata__c FROM ASF_Case_Category_Config__c 
                                                                   WHERE CCC_External_Id__c =:ABHFL_Constants.NDC_CCC_EXTERNALID WITH SECURITY_ENFORCED];
                    if(cccRecord.size() > 0){
                    	Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord, 
                                                                                                                            cccRecord[0].Rejected_Case_Email_Template__c, 
                                                                                                                            cccRecord[0].Rejected_Case_SMS_Metadata__c,
                                                                                                                            false);
                    }
                    //check with Ashish this is not working as expected.
                    caseRecord.MoveToNext__c = true;
                    update caseRecord;
                    result.response = Custom_Messages__mdt.getInstance('NDC_STP_EvaluationFailedCaseClosed').Message__c;  
                } else {
                    result.response = Custom_Messages__mdt.getInstance('NDC_STP_EvaluationFailed').Message__c; 
                }
            }
        }
        
        return result;
    }

     /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - run
    * @param integ - ASF_Integration record.
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @Description - Invoked from the ASF_IntegrationsController class, this method runs the NDC integration and creates Case Integration record.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c intSpec, Case caseRec){
        List<ASF_Case_Integration__c> existingCaseIntRecords = [SELECT Id, Status__c FROM ASF_Case_Integration__c
                                                               WHERE Case__c =:caseRec.Id 
                                                               AND Integration_Ext_Id__c =:intSpec.External_Id__c WITH SECURITY_ENFORCED];
        if(existingCaseIntRecords.size()>0){
        	for(ASF_Case_Integration__c caseInt : existingCaseIntRecords){
                caseInt.Status__c = ABHFL_Constants.CANCELED;
            }
            if(Schema.sObjectType.ASF_Case_Integration__c.isUpdateable()){
                update existingCaseIntRecords;        
            }    
        }

        Case caseRecord = [SELECT Id, Asset.LAN__c,CaseNumber,Business_Unit__c  FROM Case where Id =: caseRec.Id];

        string requestBody = JSON.serialize(new NDCRequestWrapper(caseRecord.CaseNumber,caseRecord.Asset.Lan__c));

        ASF_IntegrationsController.IntegrationWrapper response = new ASF_IntegrationsController.IntegrationWrapper();
        ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
        caseInteg.Integration_Ext_Id__c = intSpec.External_Id__c;
        caseInteg.Case__c = caseRec.Id;
        caseInteg.Status__c= ABHFL_Constants.PENDING;
        caseInteg.Request__c = requestBody;
        if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
            insert caseInteg;
        }

        ASF_Case_Integration__c caseInt = [Select Name from ASF_Case_Integration__c where id =: caseInteg.Id];
        
        Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
        caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
        caseIntOut.Case_Integration_ID__c = caseInt.Name;
        caseIntOut.Integration_Name__c  = intSpec.Display_Name__c;
        caseIntOut.Request_Payload__c  =  requestBody;
        caseIntOut.ServiceName__c = ABHFL_Constants.REPORTING_SERVICE;
        Database.SaveResult publishResult = EventBus.publish(caseIntOut);
        response.status = ABHFL_Constants.SUCCESS;
        return response;
    }    

    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - processResponse
    * @param caseInteg - ASF_Case_Integration record.
    * @return - void.
    * @Description - Invoked from the Case Integration trigger, this method processes the response of the integration received.
    *****************************************************************************************************************/
    public void processResponse(ASF_Case_Integration__c caseInt){
        Boolean integrationFailure = true;
        Boolean previousStatus;
        Case caseRecord = [SELECT Id,Source__c,AccountId,CCC_External_Id__c,ContactId,OwnerId,CreatedById,Asset.LAN__c,Asset.Account_Status__c,
                           Asset.Branch__r.Branch_Queue_Id__c,ABHFL_Case_Detail__r.STP_Request_Type__c,ABHFL_Case_Detail__r.STP_Failure__c,No_Auto_Communication__c
                           FROM Case WHERE Id =: caseInt.Case__c];
        Boolean isTransferred = false;
        if(caseInt.Status__c==ABHFL_Constants.SUCCESS){
            isTransferred = ABCL_IntegrationCommonUtility.transferAttachments(caseInt);
        }
        if(caseRecord!=null){
            if(isTransferred){
                integrationFailure = false;
                List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id,Resolved_Case_Email_Template__c,Resolved_Case_SMS_Metadata__c FROM ASF_Case_Category_Config__c 
                                                                WHERE CCC_External_Id__c =:ABHFL_Constants.NDC_CCC_EXTERNALID WITH SECURITY_ENFORCED];
                if(cccRecord.size() > 0){
                	Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord, 
                                                                                                                        cccRecord[0].Resolved_Case_Email_Template__c, 
                                                                                                                        cccRecord[0].Resolved_Case_SMS_Metadata__c, 
                                                                                                                        isTransferred);           
                }
                caseRecord.MoveToNext__c = true;
                update caseRecord;        
            } else {
                handleFailure(caseRecord);
            }
        }
        if(integrationFailure != caseRecord.ABHFL_Case_Detail__r.STP_Failure__c){
            ABHFL_Case_Detail__c caseDetails = new ABHFL_Case_Detail__c();
            caseDetails.STP_Failure__c = integrationFailure;
            caseDetails.Id = caseRecord.ABHFL_Case_Detail__c;
            if(Schema.sObjectType.ABHFL_Case_Detail__c.isUpdateable()){
                update caseDetails;  
            }            
        }
        ABCL_IntegrationCommonUtility.updateErrorMessage(caseInt);
    } 

    private static void handleFailure(Case caseRecord){
        if(caseRecord.Source__c == ABHFL_Constants.BRANCH){
            if(caseRecord.OwnerId != caseRecord.Asset.Branch__r.Branch_Queue_Id__c){
                caseRecord.OwnerId = caseRecord.Asset.Branch__r.Branch_Queue_Id__c;
                update caseRecord;
                ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRecord,ABHFL_Constants.NDC_STP_NAME,null);
            }
        } else {
            Group csQueue = [SELECT Id FROM Group WHERE Type =: ABHFL_Constants.QUEUE AND DeveloperName =: ABHFL_Constants.ABHFL_CUSTOMER_SERVICE_TEAM WITH SECURITY_ENFORCED Limit 1];
            caseRecord.OwnerId = csQueue.Id;
            update caseRecord;                
        }  
    }
    
    public class NDCRequestWrapper{
        public string caseId;
        public string souce;
        public string requestType;
        public string lan;
        public string reportName;
        public string documentType;
        
        public NDCRequestWrapper(string caseNumber,string lanNo){
            this.caseId = caseNumber;
            this.souce = ABHFL_Constants.CRM;
            this.requestType = ABHFL_Constants.EMAIL;
            this.lan = lanNo;
            this.reportName = ABHFL_Constants.NDC_REPORT;
            this.documentType = ABHFL_Constants.BINARY_DATA;
        }
        
    }
}