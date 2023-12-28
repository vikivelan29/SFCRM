/*********************************************************
*Class        :  ABHFL_WelcomeKitIntegration
*Author       :  Aditya Mehrotra
*Created Date :  12/04/2023
*Last Modified:  12/05/2023
*@description  :  Class for Welcome Kit Integration
*********************************************************/
public with sharing class ABHFL_WelcomeKitIntegration implements ASF_IntegrationInvocable {
    
    public final List<String> digitalSources = new List<String>{'Welcome BOT', 'Voice Bot', 'WhatsApp', 'Chatbot', 'Customer Portal', 'Email'};
    public final List<String> offlineSources = new List<String>{'Branch', 'Call Centre', 'Internal Usage', 'Social Media'};
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - evaluate
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the ASF_IntegrationsController class, this method evaluates whether Welcome Kit integration should be fired or not.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = ABHFL_Constants.ERROR;
        result.response = ABHFL_Constants.WK_EVALUATION_FAILED_ERROR;

        Case caseRecord = [
            SELECT Id, CCC_External_Id__c,MoveToNext__c, Asset.LAN__c, Asset.Last_Disbursement_Date__c, Channel__c, Source__c,
            	Branch_Master__r.Queue_Id__c, ABHFL_Case_Detail__r.STP_Request_Type__c, AccountId, ContactId, Attachment_Status__c
            FROM Case
            WHERE Id =: caseRec.Id WITH SECURITY_ENFORCED
        ];
        
        //Checking for mandatory API conditions
        if(String.isNotBlank(caseRecord.Asset.LAN__c) && caseRecord.ABHFL_Case_Detail__r.STP_Request_Type__c == 'Email'){
            Date today = Date.today();
            Date sixMonthsAgo = today.addMonths(-6);
            Date disbursalDate = caseRecord.Asset.Last_Disbursement_Date__c;
            if(disbursalDate >= sixMonthsAgo)
            {
                result.status = ABHFL_Constants.SUCCESS;
                result.response = ABHFL_Constants.WK_EVALUATION_SUCCESS_RESPONSE;
            }
            else
            {
                result = handleDisbursalBeforeSixMonths(caseRecord);
          	}    
        }
        
        return result;
    }
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - handleDisbursalAfterSixMonths
    * @param caseRecord - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the evaluate method, this method handles disbursal before 6 months
    *****************************************************************************************************************/
    private ASF_IntegrationsController.IntegrationWrapper handleDisbursalBeforeSixMonths(Case caseRecord){
        
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id, CCC_External_Id__c, Rejected_Case_Email_Template__c, 
                                                                  Rejected_Case_SMS_Metadata__c FROM ASF_Case_Category_Config__c
                                                                  WHERE CCC_External_Id__c =:caseRecord.CCC_External_Id__c WITH SECURITY_ENFORCED];
        if(String.isNotBlank(caseRecord.Source__c) && digitalSources.contains(caseRecord.Source__c))
       	{
           	//Send standard email template and close the case
            Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord, cccRecord[0].Rejected_Case_Email_Template__c, 
                                                                    cccRecord[0].Rejected_Case_SMS_Metadata__c, false);
            caseRecord.MoveToNext__c = true;
            if(!Test.IsRunningTest() && platformEventResult.IsSuccess() && Schema.sObjectType.Case.isUpdateable())
            {
               	update caseRecord;
            }
            result.response = ABHFL_Constants.WK_EVALUATION_FAILED_DIGITAL_ERROR;
       	}
        else
       	{
           	result.response = ABHFL_Constants.WK_EVALUATION_FAILED_OFFLINE_ERROR;
        }
        return result;
        
    }
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - run
    * @param integ - ASF_Integration record.
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the ASF_IntegrationsController class, this method runs the Welcome Kit integration and creates Case Integration record.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integ, Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
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
                
        ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
        caseInteg.Case__c  = caseRec.Id;
        caseInteg.Integration_Ext_Id__c = integ.External_Id__c;
        caseInteg.Status__c = ABHFL_Constants.PENDING;
        caseInteg.Response__c = ABHFL_Constants.WAITING_API_RESPONSE;
        if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
        	insert caseInteg;    
        }
        
        ASF_Case_Integration__c caseInt = [Select Name from ASF_Case_Integration__c where id =: caseInteg.Id WITH SECURITY_ENFORCED];
        Case caseRecord = [SELECT Id, Asset.LAN__c,CaseNumber,Business_Unit__c, MoveToNext__c  FROM Case where Id =: caseRec.Id WITH SECURITY_ENFORCED];
        
        Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
        caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
        caseIntOut.Case_Integration_ID__c = caseInt.Name;
        caseIntOut.Integration_Name__c  = integ.Display_Name__c;
        caseIntOut.Request_Payload__c  =  JSON.serialize(new WelcomeKitRequestWrapper(caseRecord.CaseNumber,caseRecord.Asset.Lan__c));
        Database.SaveResult publishResult = EventBus.publish(caseIntOut);
        
        if(publishResult.IsSuccess()){
        	wrap.status = ABHFL_Constants.SUCCESS;    
        }
        return wrap;
    }
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - processResponse
    * @param caseInteg - ASF_Case_Integration record.
    * @description - Invoked from the Case Integration trigger, this method processes the response of the integration received.
    *****************************************************************************************************************/
    public void processResponse(ASF_Case_Integration__c caseInteg){
        Boolean integrationFailure = true;
        Case caseRec =[SELECT Id,Source__c,CreatedById,AccountId,OwnerId,ContactId,CCC_External_Id__c,Asset.Branch__r.Branch_Queue_Id__c,
                           MoveToNext__c,Attachment_Status__c,ABHFL_Case_Detail__r.STP_Failure__c 
                           FROM Case WHERE Id=:caseInteg.Case__c WITH SECURITY_ENFORCED];
        if(caseInteg.Status__c==ABHFL_Constants.SUCCESS){
            Boolean isTransferred = ABCL_IntegrationCommonUtility.transferAttachments(caseInteg);
            if(isTransferred)
            {
               	integrationFailure = false;
                handleTransferSuccess(caseRec);
           	}
            else if(caseRec.Source__c != ABHFL_Constants.BRANCH)
            {	
               	handleTransferFailure(caseRec);
           	}   
        }    
        if(integrationFailure != caseRec.ABHFL_Case_Detail__r.STP_Failure__c){
            ABHFL_Case_Detail__c caseDetails = new ABHFL_Case_Detail__c();
            caseDetails.STP_Failure__c = integrationFailure;
            caseDetails.Id = caseRec.ABHFL_Case_Detail__c;
            if(Schema.sObjectType.ABHFL_Case_Detail__c.isUpdateable()){
            	update caseDetails;    
            }
            if(caseRec.Source__c != ABHFL_Constants.BRANCH){
                assignCaseToCSteam(caseRec);
            }
            ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRec, 'Welcome Kit', 'STP Document Retrieval Failure');
        }
    }
    
    private void handleTransferSuccess(Case caseRec){
        List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id, CCC_External_Id__c, Resolved_Case_Email_Template__c, 
                                                                   Resolved_Case_SMS_Metadata__c FROM ASF_Case_Category_Config__c
                                                                   WHERE CCC_External_Id__c =:caseRec.CCC_External_Id__c WITH SECURITY_ENFORCED];
                    
      	Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRec, cccRecord[0].Resolved_Case_Email_Template__c, 
                    											cccRecord[0].Resolved_Case_SMS_Metadata__c, true);
        caseRec.MoveToNext__c = true;
        if(!Test.IsRunningTest() && platformEventResult.IsSuccess() && Schema.sObjectType.Case.isUpdateable())
        {
           	update caseRec;            
        }
    }
    
    private void handleTransferFailure(Case caseRec){
        assignCaseToCSteam(caseRec);
        ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRec, 'Welcome Kit', 'STP Document Retrieval Failure');
    }
    
    private void assignCaseToCSteam(Case caseRec){
        Group csQueue = [SELECT Id FROM Group WHERE Type =:ABHFL_Constants.QUEUE AND DeveloperName =:ABHFL_Constants.ABHFL_CUSTOMER_SERVICE_TEAM WITH SECURITY_ENFORCED Limit 1];
        caseRec.OwnerId = csQueue.Id;
        if(Schema.sObjectType.Case.isUpdateable())
        {
          	update caseRec;    
        }
    }
    
    /*********************************************************
    *@description :  Wrapper Class for Welcome Kit Integration
    *********************************************************/
    public class WelcomeKitRequestWrapper{
        public string caseId;
        public string source;
        public string requestType;
        public string lan;
        public string reportName;
        public string documentType;

        public WelcomeKitRequestWrapper(string caseNumber,string lanNo){
            this.caseId = caseNumber;
            this.source = ABHFL_Constants.CRM;
            this.requestType = ABHFL_Constants.EMAIL;
            this.lan = lanNo;
            this.reportName = ABHFL_Constants.WELCOME_KIT;
            this.documentType = ABHFL_Constants.BINARY_DATA;
        }
    }
}