/*********************************************************
*@Class        :  ABHFL_AmortizationIntegration
*@Author       :  Dhinesh Kumar T
*@Created Date :  12/13/2023
*@Last Modified:  12/14/2023
*@description  :  Class for Amortization STP integration. 
*********************************************************/
public with sharing  class ABHFL_AmortizationIntegration implements ASF_IntegrationInvocable {
  /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - evaluate
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the ASF_IntegrationsController class, this method evaluates whether Amortization integration should be fired or not.
    *****************************************************************************************************************/
    
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = ABHFL_Constants.ERROR;
        result.response = Custom_Messages__mdt.getInstance('AMORT_EvaluateFailure').Message__c;
        
        Case caseRecord = [
            SELECT Id, Asset.Loan_Disbursement_Status__c,Asset.LAN__c,ABHFL_Case_Detail__r.STP_Request_Type__c,CCC_External_Id__c,AccountId,ContactId, Attachment_Status__c,Source__c,No_Auto_Communication__c
            FROM Case
            WHERE Id =: caseRec.Id WITH SECURITY_ENFORCED
        ];
        //Check for mandatory API conditions & Check for Loan Disbursement Status
        if(String.isNotBlank(caseRecord.Asset.LAN__c) && caseRecord.Asset.Loan_Disbursement_Status__c != null && caseRecord.Asset.Loan_Disbursement_Status__c == 'Partially') {
        
        
          List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id, CCC_External_Id__c, Additional_SMS_Metadata__c, Additional_Email_Templates__c FROM ASF_Case_Category_Config__c
                                                               WHERE CCC_External_Id__c = :caseRecord.CCC_External_Id__c WITH SECURITY_ENFORCED];
          if(!cccRecord.isEmpty()) {
              Map<String, String> emailTemplateMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_Email_Templates__c);
                Map<String, String> smsMetadataMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_SMS_Metadata__c);

                Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(cccRecord,  emailTemplateMap.get('Rejected'), smsMetadataMap.get('Rejected'), false);

      		// Set wrapper response and status if evaluation is failure
            result.status = ABHFL_Constants.ERROR;
            result.response = Custom_Messages__mdt.getInstance('AMORT_Evaluate_Disbursed_Partially').Message__c;
            caseRecord.MoveToNext__c = true;
            
            if(Schema.sObjectType.Case.isUpdateable() && caseRecord.Source__c == 'API'){
                update caseRecord;
            } 
            
          }
      } else if(String.isNotBlank(caseRecord.Asset.LAN__c) && caseRecord.ABHFL_Case_Detail__r.STP_Request_Type__c == 'Email') {
        result.status = ABHFL_Constants.SUCCESS;
        result.response = Custom_Messages__mdt.getInstance('AMORT_EvaluateSuccess').Message__c;
      }
  return result;
    }
     /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - run
    * @param intSpec - Integration record from the framework.
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the ASF_IntegrationsController class, this method runs the Amortization integration and creates Case Integration record.
    *****************************************************************************************************************/
     public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c intSpec, Case caseRec){
         List<ASF_Case_Integration__c> existingCaseIntRecords = [SELECT Id, Status__c FROM ASF_Case_Integration__c
                                                               WHERE Case__c =:caseRec.Id 
                                                               AND Integration_Ext_Id__c =:intSpec.External_Id__c WITH SECURITY_ENFORCED];
        if(existingCaseIntRecords.size()>0){
          for(ASF_Case_Integration__c caseInt : existingCaseIntRecords){
                if(caseInt.Status__c == ABHFL_Constants.PENDING){
                   caseInt.Status__c = ABHFL_Constants.CANCELED;  
                }
            }
            
            if(Schema.sObjectType.ASF_Case_Integration__c.isUpdateable()){
                update existingCaseIntRecords; 
            }
                       
        }
		Case caseRecord = [SELECT Id, Asset.LAN__c,CaseNumber,Business_Unit__c  FROM Case where Id =: caseRec.Id WITH SECURITY_ENFORCED];
        ASF_IntegrationsController.IntegrationWrapper response = new ASF_IntegrationsController.IntegrationWrapper();
        response.status = ABHFL_Constants.SUCCESS;
        ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
        caseInteg.Integration_Ext_Id__c = intSpec.External_Id__c;
        caseInteg.Case__c = caseRec.Id;
        caseInteg.Request__c = JSON.serialize(new AmmortRequestWrapper(caseRecord.Asset.Lan__c,caseRecord)); 
        caseInteg.Status__c = ABHFL_Constants.PENDING;
        
        if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
            insert caseInteg; 
        }
        
        ASF_Case_Integration__c caseInt = [Select Name from ASF_Case_Integration__c where id =: caseInteg.Id WITH SECURITY_ENFORCED];
        
        
        Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
        caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
        caseIntOut.Case_Integration_ID__c = caseInt.Name;
        caseIntOut.Integration_Name__c  = intSpec.Display_Name__c;
        caseIntOut.ServiceName__c = ABHFL_Constants.REPORTING_SERVICE;
        caseIntOut.Request_Payload__c  =  JSON.serialize(new AmmortRequestWrapper(caseRecord.Asset.Lan__c,caseRecord));
        Database.SaveResult publishResult = EventBus.publish(caseIntOut);
        
        if(publishResult.isSuccess()){
            response.status = ABHFL_Constants.SUCCESS;
        }else{
            response.status = ABHFL_Constants.ERROR;
        }
        return response;
    }      
    
     /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - processResponse
    * @param caseInteg - ASF_Case_Integration record.
    * @description - Invoked from the Case Integration trigger, this method processes the response of the integration received.
    *****************************************************************************************************************/
    public void processResponse(ASF_Case_Integration__c caseInteg){
        //processing of case, move to next
        Boolean integrationFailure = true;
        Case caseRec = [
                SELECT Id,AccountId,ContactId,CCC_External_Id__c, MoveToNext__c,Attachment_Status__c,OwnerId,Source__c,CreatedById,ABHFL_Case_Detail__r.STP_Failure__c,No_Auto_Communication__c
              FROM Case
              WHERE Id =: caseInteg.Case__c WITH SECURITY_ENFORCED
           ]; 
        if(caseInteg.Status__c == ABHFL_Constants.SUCCESS && caseRec!=null){
          Boolean isTransferred = ABCL_IntegrationCommonUtility.transferAttachments(caseInteg);
      if(isTransferred){
                 integrationFailure = false;
                 List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id, CCC_External_Id__c, Resolved_Case_Email_Template__c, 
                                                                      Resolved_Case_SMS_Metadata__c, Additional_SMS_Metadata__c, Additional_Email_Templates__c FROM ASF_Case_Category_Config__c
                                                                      WHERE CCC_External_Id__c =:caseRec.CCC_External_Id__c WITH SECURITY_ENFORCED];
                
                 Map<String, String> emailTemplateMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_Email_Templates__c);
                Map<String, String> smsMetadataMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_SMS_Metadata__c);
                                                      

                 ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRec,  emailTemplateMap.get('Resolved'), smsMetadataMap.get('Resolved'), isTransferred);
                 caseRec.MoveToNext__c = true;
                 update caseRec;        
            }else if(caseRec.Source__c != ABHFL_Constants.BRANCH){
                        ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRec, ABHFL_Constants.AMORTIZATION, ABHFL_Constants.STP_DOC_RETRIEVAL_FAILURE);
                      Group csQueue = [SELECT Id FROM Group WHERE Type =: ABHFL_Constants.QUEUE AND DeveloperName =: ABHFL_Constants.ABHFL_CUSTOMER_SERVICE_TEAM  WITH SECURITY_ENFORCED Limit 1];
                        caseRec.OwnerId = csQueue.Id;
                        
                        if(Schema.sObjectType.Case.isUpdateable()){
                             update caseRec;
                        } 
                    }
        }
        if(integrationFailure != caseRec.ABHFL_Case_Detail__r.STP_Failure__c){
              caseRec.ABHFL_Case_Detail__r.STP_Failure__c = integrationFailure;
              if(caseRec.Source__c != ABHFL_Constants.BRANCH){
                 Group csQueue = [SELECT Id FROM Group WHERE Type =: ABHFL_Constants.QUEUE AND DeveloperName =: ABHFL_Constants.ABHFL_CUSTOMER_SERVICE_TEAM  WITH SECURITY_ENFORCED Limit 1];
                        caseRec.OwnerId = csQueue.Id;
                        
                        if(Schema.sObjectType.Case.isUpdateable()){
                             update caseRec;
                        } 
                        
                   ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRec, ABHFL_Constants.AMORTIZATION, ABHFL_Constants.STP_DOC_RETRIEVAL_FAILURE);
             }else if(caseRec.Source__c == ABHFL_Constants.BRANCH){
                   ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRec, ABHFL_Constants.AMORTIZATION, ABHFL_Constants.STP_DOC_RETRIEVAL_FAILURE);
           }
        }
        ABCL_IntegrationCommonUtility.updateErrorMessage(caseInteg);
    }
    
    /****************************************************************************************************************
    *@description - AmmortRequestWrapper
    *****************************************************************************************************************/
      public class AmmortRequestWrapper{
        public string lan;
        public string caseId;
        public string souce;
        public string requestType;
        public string reportName;
        public string documentType;
        
        AmmortRequestWrapper(string lanNo,Case caseRec){
            this.lan = lanNo;
            this.souce = ABHFL_Constants.CRM;
            this.requestType = ABHFL_Constants.EMAIL;
            this.lan = lanNo;
            this.reportName = 'RepaymentSchedule';
            this.documentType = ABHFL_Constants.BINARY_DATA;
            this.caseId = caseRec.caseNumber;
        }
    }

}