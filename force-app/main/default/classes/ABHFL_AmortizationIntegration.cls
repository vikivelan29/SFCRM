/*********************************************************
*@Class        :  ABHFL_AmortizationIntegration
*@Author       :  Dhinesh Kumar T
*@Created Date :  12/13/2023
*@Last Modified:  12/14/2023
*@description  :  Class for Amortization STP integration. 
*********************************************************/
public without sharing  class ABHFL_AmortizationIntegration implements ASF_IntegrationInvocable {
  /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - evaluate
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the ASF_IntegrationsController class, this method evaluates whether Amortization integration should be fired or not.
    *****************************************************************************************************************/
    
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = 'Error';
        result.response = 'Evaluation Failed, cannot retrieve Amortization Letter';
        
        Case caseRecord = [
            SELECT Id, Asset.Loan_Disbursement_Status__c,Asset.LAN__c,ABHFL_Case_Detail__r.STP_Request_Type__c,CCC_External_Id__c,AccountId,ContactId, Attachment_Status__c
            FROM Case
            WHERE Id =: caseRec.Id WITH SECURITY_ENFORCED
        ];
        //Check for mandatory API conditions & Check for Loan Disbursement Status
        if(String.isNotBlank(caseRecord.Asset.LAN__c) && caseRecord.Asset.Loan_Disbursement_Status__c != null && caseRecord.Asset.Loan_Disbursement_Status__c == 'Partially') {
        
        
          List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id, CCC_External_Id__c, Rejected_Case_Email_Template__c, 
                                                               Rejected_Case_SMS_Metadata__c FROM ASF_Case_Category_Config__c
                                                               WHERE CCC_External_Id__c = :caseRecord.CCC_External_Id__c WITH SECURITY_ENFORCED];
          if(!cccRecord.isEmpty()) {
              Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(
                    caseRecord,
                    cccRecord[0].Rejected_Case_Email_Template__c,
                    cccRecord[0].Rejected_Case_SMS_Metadata__c,
                    false
              );
      // Set wrapper response and status if evaluation is failure
            result.status = 'Error';
            result.response = 'Loan is Disbursed Partially, cannot fetch Amortization Letter. Closing the Case.';
            caseRecord.MoveToNext__c = true;
            
            if(Schema.sObjectType.Case.isUpdateable()){
                update caseRecord;
            } 
            
          }
      } else {
        result.status = 'Success';
        result.response = 'Evaluation Success, Submit to get the Amortization Letter.';
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
                if(caseInt.Status__c == 'Pending'){
                   caseInt.Status__c = 'Canceled';  
                }
            }
            
            if(Schema.sObjectType.ASF_Case_Integration__c.isUpdateable()){
                update existingCaseIntRecords; 
            }
                       
        }

        ASF_IntegrationsController.IntegrationWrapper response = new ASF_IntegrationsController.IntegrationWrapper();
        response.status = 'Success';
        ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
        caseInteg.Integration_Ext_Id__c = intSpec.External_Id__c;
        caseInteg.Case__c = caseRec.Id;
        caseInteg.Status__c='Pending';
        
        if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
            insert caseInteg; 
        }
        
        ASF_Case_Integration__c caseInt = [Select Name from ASF_Case_Integration__c where id =: caseInteg.Id WITH SECURITY_ENFORCED];
        Case caseRecord = [SELECT Id, Asset.LAN__c,CaseNumber,Business_Unit__c  FROM Case where Id =: caseRec.Id WITH SECURITY_ENFORCED];
        
        Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
        caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
        caseIntOut.Case_Integration_ID__c = caseInt.Name;
        caseIntOut.Integration_Name__c  = intSpec.Display_Name__c;
        caseIntOut.Request_Payload__c  =  JSON.serialize(new AmmortRequestWrapper(caseRecord.Asset.Lan__c));
        Database.SaveResult publishResult = EventBus.publish(caseIntOut);
        
        if(publishResult.isSuccess()){
            response.status = 'Success';
        }else{
            response.status = 'Error';
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
                SELECT Id,AccountId,ContactId,CCC_External_Id__c, MoveToNext__c,Attachment_Status__c,OwnerId,Source__c,CreatedById,ABHFL_Case_Detail__r.STP_Failure__c
              FROM Case
              WHERE Id =: caseInteg.Case__c WITH SECURITY_ENFORCED
           ]; 
        if(caseInteg.Status__c=='Success' && caseRec!=null){
          Boolean isTransferred = ABCL_IntegrationCommonUtility.transferAttachments(caseInteg);
      if(isTransferred){
                 integrationFailure = false;
                 List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id, CCC_External_Id__c, Resolved_Case_Email_Template__c, 
                                                                      Resolved_Case_SMS_Metadata__c FROM ASF_Case_Category_Config__c
                                                                      WHERE CCC_External_Id__c =:caseRec.CCC_External_Id__c WITH SECURITY_ENFORCED];
                
                 ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRec, cccRecord[0].Resolved_Case_Email_Template__c, 
                                                                cccRecord[0].Resolved_Case_SMS_Metadata__c, isTransferred);
                 caseRec.MoveToNext__c = true;
                 update caseRec;        
            }else if(caseRec.Source__c != 'Branch'){
                        ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRec, 'Amortization Letter', 'STP Document Retrieval Failure');
                      Group csQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Customer_Service_Team'  WITH SECURITY_ENFORCED Limit 1];
                        caseRec.OwnerId = csQueue.Id;
                        
                        if(Schema.sObjectType.Case.isUpdateable()){
                             update caseRec;
                        } 
                    }
        }
        if(integrationFailure != caseRec.ABHFL_Case_Detail__r.STP_Failure__c){
              caseRec.ABHFL_Case_Detail__r.STP_Failure__c = integrationFailure;
              if(caseRec.Source__c != 'Branch'){
                 Group csQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Customer_Service_Team'  WITH SECURITY_ENFORCED Limit 1];
                        caseRec.OwnerId = csQueue.Id;
                        
                        if(Schema.sObjectType.Case.isUpdateable()){
                             update caseRec;
                        } 
                        
                   ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRec, 'Amortization Letter', 'STP Document Retrieval Failure');
             }else if(caseRec.Source__c == 'Branch'){
                   ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRec, 'Amortization Letter', 'STP Document Retrieval Failure');
           }
        }
    }
    
    /****************************************************************************************************************
    *@description - AmmortRequestWrapper
    *****************************************************************************************************************/
      public class AmmortRequestWrapper{
        public string lan;
        
        AmmortRequestWrapper(string lanNo){
            this.lan = lanNo;
        }
    }

}