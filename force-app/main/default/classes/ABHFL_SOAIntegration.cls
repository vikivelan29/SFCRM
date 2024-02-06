/*********************************************************
*@Class        :  ABHFL_SOAIntegration
*@Author       :  Anjali Sharma
*@Created Date :  12/12/2023
*@Last Modified:  
*@description  :  Class for SOA Integration
*********************************************************/
public with sharing class ABHFL_SOAIntegration implements ASF_IntegrationInvocable { 


    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - evaluate
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the ASF_IntegrationsController class, this method evaluates whether Statment Of Account integration should be fired or not.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = ABHFL_Constants.ERROR;
        //Error Message when evaluation is failed.
        result.response = Custom_Messages__mdt.getInstance('SOA_EVALUATION_FAILED_DATE_ERROR').Message__c;

        Case caseRecord = [
            SELECT Id, Asset.LAN__c, ABHFL_Case_Detail__r.From_Date__c, ABHFL_Case_Detail__r.To_Date__c
            FROM Case
            WHERE Id =: caseRec.Id WITH SECURITY_ENFORCED
        ];

         //Checking for mandatory API conditions
        if(String.isNotBlank(caseRecord.Asset.LAN__c) && caseRecord.ABHFL_Case_Detail__r.From_Date__c != null && caseRecord.ABHFL_Case_Detail__r.To_Date__c != null){
            result.status = ABHFL_Constants.SUCCESS;
            result.response = Custom_Messages__mdt.getInstance('SOA_EVALUATION_SUCCESS_RESPONSE').Message__c;
         }
         return  result;
    }

    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - run
    * @param integ - ASF_Integration record.
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the ASF_IntegrationsController class, this method runs the Statment Of Account integration and creates Case Integration record.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integ, Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
		List<ASF_Case_Integration__c> existingCaseIntRecords = [SELECT Id, Status__c FROM ASF_Case_Integration__c
                                                               WHERE Case__c =:caseRec.Id 
                                                               AND Integration_Ext_Id__c =:integ.External_Id__c WITH SECURITY_ENFORCED];
        if(existingCaseIntRecords.size()>0){
        	for(ASF_Case_Integration__c cInt : existingCaseIntRecords){
                cInt.Status__c = ABHFL_Constants.CANCELED;
            }
            if(Schema.sObjectType.ASF_Case_Integration__c.isUpdateable()){
                update existingCaseIntRecords;     
            }       
        }

        Case caseRecord = [SELECT Id, caseNumber, Business_Unit__c, Asset.LAN__c, ABHFL_Case_Detail__r.To_Date__c, ABHFL_Case_Detail__r.From_Date__c  FROM Case where Id =: caseRec.Id WITH SECURITY_ENFORCED];
        

        String toDate = DateTime.newInstance((caseRecord.ABHFL_Case_Detail__r.To_Date__c).year(),(caseRecord.ABHFL_Case_Detail__r.To_Date__c).month(),(caseRecord.ABHFL_Case_Detail__r.To_Date__c).day()).format('dd-MM-YYYY');
        String fromDate = DateTime.newInstance((caseRecord.ABHFL_Case_Detail__r.From_Date__c).year(),(caseRecord.ABHFL_Case_Detail__r.From_Date__c).month(),(caseRecord.ABHFL_Case_Detail__r.From_Date__c).day()).format('dd-MM-YYYY');

        
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Case__c  = caseRec.Id;
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Status__c = ABHFL_Constants.PENDING;
        caseInt.Request__c  =  JSON.serialize(new SOARequestWrapper(caseRecord.Asset.Lan__c, toDate, fromDate, caseRecord.caseNumber));
        caseInt.Response__c = ABHFL_Constants.WAITING_API_RESPONSE;
        if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
            insert caseInt;
        }

        ASF_Case_Integration__c caseInt1 = [Select id, name from ASF_Case_Integration__c where id =: caseInt.Id ];
       
        Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
        caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
        caseIntOut.Case_Integration_ID__c = caseInt1.Name;
        caseIntOut.Integration_Name__c  = ABHFL_Constants.SOA_INTEGRATION_NAME;
        caseIntOut.ServiceName__c = ABHFL_Constants.REPORTING_SERVICE;
        caseIntOut.Request_Payload__c  =  JSON.serialize(new SOARequestWrapper(caseRecord.Asset.Lan__c, toDate, fromDate, caseRecord.caseNumber));
        Database.SaveResult publishResult = EventBus.publish(caseIntOut);
        if(publishResult.isSuccess()){
            result.status = ABHFL_Constants.SUCCESS;
            result.response = Custom_Messages__mdt.getInstance('SOA_RUN_SUCCESS').Message__c;
        }else{
            result.status = ABHFL_Constants.ERROR;
        }
        return result;
    }



    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - processResponse
    * @param caseInteg - ASF_Case_Integration record.
    * @description - Invoked from the Case Integration trigger, this method processes the response of the integration received.
    *****************************************************************************************************************/
    public void processResponse(ASF_Case_Integration__c caseInteg){
        Boolean isTransferred = False;

        if(caseInteg.Status__c == ABHFL_Constants.SUCCESS){
            isTransferred = ABCL_IntegrationCommonUtility.transferAttachments(caseInteg);
        }

        Case caseRec =[SELECT Id, No_Auto_Communication__c, CreatedById, Source__c, OwnerId, status,  AccountId,ContactId,CCC_External_Id__c, MoveToNext__c,Attachment_Status__c, ABHFL_Case_Detail__r.STP_Failure__c   
                           FROM Case WHERE Id=:caseInteg.Case__c WITH SECURITY_ENFORCED];

        if(caseInteg.Status__c == ABHFL_Constants.SUCCESS && caseRec != null && isTransferred ){  
            handleSuccessfullTransfer(caseRec);
        }else if(caseInteg.Status__c != ABHFL_Constants.CANCELED && caseInteg.Status__c != ABHFL_Constants.PENDING) {
            handleUnsuccessfullTransfer(caseRec);
        }
        if(isTransferred == caseRec.ABHFL_Case_Detail__r.STP_Failure__c){
            ABHFL_Case_Detail__c caseDetails = new ABHFL_Case_Detail__c();
            caseDetails.STP_Failure__c = !isTransferred;
            caseDetails.Id = caseRec.ABHFL_Case_Detail__c;

            if(Schema.sObjectType.ABHFL_Case_Detail__c.isUpdateable()){
                update caseDetails;   
            }            
        }

        ABCL_IntegrationCommonUtility.updateErrorMessage(caseInteg);
    }



    private void handleSuccessfullTransfer(Case caserec){
        List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id, CCC_External_Id__c, Resolved_Case_Email_Template__c, 
        Resolved_Case_SMS_Metadata__c FROM ASF_Case_Category_Config__c
        WHERE CCC_External_Id__c =:caseRec.CCC_External_Id__c WITH SECURITY_ENFORCED];
        ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRec, cccRecord[0].Resolved_Case_Email_Template__c, 
                cccRecord[0].Resolved_Case_SMS_Metadata__c, true);
        caseRec.MoveToNext__c = true;
        caseRec.Attachment_Status__c = ABHFL_Constants.COMPLETED;
        caseRec.Stage__c = ABHFL_Constants.RESOLVED;
        if(Schema.sObjectType.Case.isUpdateable()){
            update caseRec;  
        }
    }


    private void handleUnsuccessfullTransfer(Case caseRec){
        if(caseRec.Source__c ==  ABHFL_Constants.BRANCH){
            if(caseRec.OwnerId != caseRec.CreatedById && Schema.sObjectType.Case.isUpdateable()){
                caseRec.OwnerId = caseRec.CreatedById;
                update caseRec;
                ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRec,'SOA',null);
            }
        } else {
            Group csQueue = [SELECT Id FROM Group WHERE Type =:ABHFL_Constants.QUEUE AND DeveloperName =:ABHFL_Constants.ABHFL_CUSTOMER_SERVICE_TEAM WITH SECURITY_ENFORCED Limit 1];
            caseRec.OwnerId = csQueue.Id;
            if(Schema.sObjectType.Case.isUpdateable()){
                update caseRec;
            }                
        }  
    }


/****************************************************************************************************************
    *@description - Wrapper class to get all the request parameters
*****************************************************************************************************************/

    public class SOARequestWrapper{

        public string lan;
        public String toDate;
        public String fromDate;
        public String caseId;
        public String souce = ABHFL_Constants.SOA_SOURCE;
        public String requestType = ABHFL_Constants.SOA_REQUEST_TYPE;
        public String reportName = ABHFL_Constants.SOA_REPORT_NAME;
        public String documentType = ABHFL_Constants.SOA_DOCUMENT_TYPE;
        
        SOARequestWrapper(string lanNo, String toDate, String fromDate, String caseId){
            this.lan = lanNo;
            this.toDate = toDate;
            this.fromDate = fromDate;
            this.caseId = caseId;
        }
    }
}