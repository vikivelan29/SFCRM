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
                           Asset.Branch__r.Branch_Queue_Id__c,ABHFL_Case_Detail__r.STP_Request_Type__c FROM Case WHERE Id =: caseRec.Id WITH SECURITY_ENFORCED];
        
        //Check for mandatory API conditions
        result.status = 'Error';
        result.response = 'Evaluation Failed, cannot retrieve the NDC.';   
        if(String.isNotBlank(caseRecord.Asset.LAN__c) && caseRecord.ABHFL_Case_Detail__r.STP_Request_Type__c == 'Email'){
            if(caseRecord.Asset.Account_Status__c == 'Closed'){
            	result.status = 'Success';
                result.response = 'Evaluation Successful, Please click on Submit to retrieve NDC.';
            } else {
                if(caseRecord.Source__c == 'Branch'){
                    caseRecord.OwnerId = caseRecord.Asset.Branch__r.Branch_Queue_Id__c;
                    if(Schema.sObjectType.Case.isUpdateable()){
                        update caseRecord;
                    }
                    result.response ='NDC cannot be retrieved until the Loan is Closed. Assigning the case to Branch';                                                                                                                               

                } else if(sourceList.contains(caseRecord.Source__c)) {
                    List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id,Rejected_Case_Email_Template__c FROM ASF_Case_Category_Config__c 
                                                                   WHERE CCC_External_Id__c =:caseRecord.CCC_External_Id__c WITH SECURITY_ENFORCED];
                    Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord, 
                                                                                                                            cccRecord[0].Rejected_Case_Email_Template__c, 
                                                                                                                            null,
                                                                                                                            false);
                    //check with Ashish this is not working as expected.
                    caseRecord.MoveToNext__c = true;
                    update caseRecord;
                    result.response = 'NDC cannot be retrieved until the Loan is Closed. Case will be closed';
                } else {
                    result.response = 'Evaluation Failed, You cannot retrieve the NDC.'; 
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
                caseInt.Status__c = 'Canceled';
            }
            if(Schema.sObjectType.ASF_Case_Integration__c.isUpdateable()){
                update existingCaseIntRecords;        
            }    
        }

        ASF_IntegrationsController.IntegrationWrapper response = new ASF_IntegrationsController.IntegrationWrapper();
        ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
        caseInteg.Integration_Ext_Id__c = intSpec.External_Id__c;
        caseInteg.Case__c = caseRec.Id;
        caseInteg.Status__c='Pending';
        if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
            insert caseInteg;
        }

        ASF_Case_Integration__c caseInt = [Select Name from ASF_Case_Integration__c where id =: caseInteg.Id];
        Case caseRecord = [SELECT Id, Asset.LAN__c,CaseNumber,Business_Unit__c  FROM Case where Id =: caseRec.Id];
        
        Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
        caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
        caseIntOut.Case_Integration_ID__c = caseInt.Name;
        caseIntOut.Integration_Name__c  = intSpec.Display_Name__c;
        caseIntOut.Request_Payload__c  =  JSON.serialize(new NDCRequestWrapper(caseRecord.CaseNumber,caseRecord.Asset.Lan__c));
        Database.SaveResult publishResult = EventBus.publish(caseIntOut);
        response.status = 'Success';
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
        system.debug('Inside process response welcome kit');
        Boolean integrationFailure = true;
        Boolean previousStatus;
        Case caseRecord = [SELECT Id,Source__c,AccountId,CCC_External_Id__c,ContactId,OwnerId,CreatedById,Asset.LAN__c,Asset.Account_Status__c,
                           Asset.Branch__r.Branch_Queue_Id__c,ABHFL_Case_Detail__r.STP_Request_Type__c,ABHFL_Case_Detail__r.STP_Failure__c
                           FROM Case WHERE Id =: caseInt.Case__c];
        if(caseInt.Status__c=='Success'){
            Boolean isTransferred = ABCL_IntegrationCommonUtility.transferAttachments(caseInt);
            if(caseRecord!=null){
                if(isTransferred){
                    integrationFailure = false;
                    List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id,Resolved_Case_Email_Template__c FROM ASF_Case_Category_Config__c 
                                                                   WHERE CCC_External_Id__c =:caseRecord.CCC_External_Id__c WITH SECURITY_ENFORCED];
                    Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord, 
                                                                                                                            cccRecord[0].Resolved_Case_Email_Template__c, 
                                                                                                                            null, 
                                                                                                                            isTransferred);
                    caseRecord.MoveToNext__c = true;
                    update caseRecord;        
                } else {
                    handleFailure(caseRecord);
                }
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
    } 

    private static void handleFailure(Case caseRecord){
        if(caseRecord.Source__c == 'Branch'){
            if(caseRecord.OwnerId != caseRecord.Asset.Branch__r.Branch_Queue_Id__c){
                caseRecord.OwnerId = caseRecord.Asset.Branch__r.Branch_Queue_Id__c;
                update caseRecord;
                ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRecord,'NDC',null);
            }
        } else {
            Group csQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Customer_Service_Team' WITH SECURITY_ENFORCED Limit 1];
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
            this.souce = 'CRM';
            this.requestType = 'Email';
            this.lan = lanNo;
            this.reportName = 'NDCReport';
            this.documentType = 'BinaryData';
        }
        
    }
}