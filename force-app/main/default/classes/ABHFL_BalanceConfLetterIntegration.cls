/*********************************************************
*@Class        :  ABHFL_BalanceConfLetterIntegration 
*@Author       :  Vishal Gangwar
*@Created Date :  12/12/2023
*@Last Modified:  
*@description  :  Class for Balance Confirmation Letter Integration
*********************************************************/

public with Sharing class ABHFL_BalanceConfLetterIntegration implements ASF_IntegrationInvocable {
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - evaluate
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the ASF_IntegrationsController class, this method evaluates whether Balance Confirmation Letter integration should be fired or not.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        
        Case caseRecord = [
            SELECT Id, CCC_External_Id__c,MoveToNext__c, Asset.LAN__c, Channel__c, Source__c,
                   ABHFL_Case_Detail__r.As_On_Date__c,ABHFL_Case_Detail__r.STP_Request_Type__c 
            FROM Case
            WHERE Id =: caseRec.Id WITH SECURITY_ENFORCED
        ];
        
        
        //Checking for mandatory API conditions
        if(String.isNotBlank(caseRecord.Asset.LAN__c) && caseRecord.ABHFL_Case_Detail__r.STP_Request_Type__c == ABHFL_Constants.EMAIL){
            if(caseRecord.ABHFL_Case_Detail__r.As_On_Date__c != null){
                result.status = ABHFL_Constants.SUCCESS;
                result.response = Custom_Messages__mdt.getInstance('BCL_Evaluation_Success_Response').Message__c;
            }else{
                 result.status = ABHFL_Constants.ERROR;
                 result.response = Custom_Messages__mdt.getInstance('BCL_Evaluation_Failed_As_On_Date_Error').Message__c; 
            }
        }else{
            result.status = ABHFL_Constants.ERROR;
            result.response = Custom_Messages__mdt.getInstance('BCL_Evaluation_Faield_LAN_Email_Error').Message__c;
        }
        
        return result;
    }
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - run
    * @param integ - ASF_Integration record.
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the ASF_IntegrationsController class, this method runs the Balance Confirmation Letter integration and creates Case Integration record.
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
                UPDATE existingCaseIntRecords;  
            }           
        }
            
        Case caseRecord = [SELECT Id, Asset.LAN__c,CaseNumber,Business_Unit__c  FROM Case where Id =: caseRec.Id WITH SECURITY_ENFORCED];    
                
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Case__c  = caseRec.Id;
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Status__c = ABHFL_Constants.PENDING;
        caseInt.Response__c = ABHFL_Constants.WAITING_API_RESPONSE;
        caseInt.Request__c = JSON.serialize(new BCLRequestWrapper(caseRecord.CaseNumber,caseRecord.Asset.Lan__c));
        
        if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
            INSERT caseInt; 
        }
        
        ASF_Case_Integration__c caseInte = [SELECT Name FROM ASF_Case_Integration__c WHERE Id =: caseInt.Id WITH SECURITY_ENFORCED];
        
        
        Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
        caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
        caseIntOut.Case_Integration_ID__c = caseInte.Name;
        caseIntOut.Integration_Name__c  = integ.Display_Name__c;
        caseIntOut.Request_Payload__c  =  JSON.serialize(new BCLRequestWrapper(caseRecord.CaseNumber,caseRecord.Asset.Lan__c));
        Database.SaveResult publishResult = EventBus.publish(caseIntOut);
        
        if(publishResult.isSuccess()){
            wrap.status = ABHFL_Constants.SUCCESS;
            wrap.response = Custom_Messages__mdt.getInstance('BCL_Run_Success').Message__c;
        }else{
            wrap.status = ABHFL_Constants.ERROR;
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
        Boolean isTransferred = False;
        
        if(caseInteg.Status__c == ABHFL_Constants.SUCCESS){
            isTransferred = ABCL_IntegrationCommonUtility.transferAttachments(caseInteg);
        }
        
        Case caseRec = [SELECT Id,AccountId,ContactId,CCC_External_Id__c, MoveToNext__c,Attachment_Status__c,Source__c,  
                                 CreatedById,ownerId,caseNumber,ABHFL_Case_Detail__c,ABHFL_Case_Detail__r.STP_Failure__c
                          FROM Case WHERE Id =: caseInteg.Case__c WITH SECURITY_ENFORCED];
        
        if(caseRec != null && isTransferred && caseInteg.Status__c == ABHFL_Constants.SUCCESS){
            handleSuccessfullTransfer(caseRec);
        }else if(caseInteg.Status__c != ABHFL_Constants.CANCELED && caseInteg.Status__c != ABHFL_Constants.PENDING){
            handleUnsuccessfullTransfer(caseRec,caseInteg);
        }
        
        if(isTransferred == caseRec.ABHFL_Case_Detail__r.STP_Failure__c){
            ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
            caseDetail.STP_Failure__c = !isTransferred;
            caseDetail.Id = caseRec.ABHFL_Case_Detail__c;
            
            if(Schema.sObjectType.ABHFL_Case_Detail__c.isUpdateable()){
                UPDATE caseDetail; 
            }            
        }     
    }
    
     private void handleSuccessfullTransfer(Case caseRec){
         List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id, CCC_External_Id__c, Resolved_Case_Email_Template__c, 
                                                                      Resolved_Case_SMS_Metadata__c FROM ASF_Case_Category_Config__c
                                                                      WHERE CCC_External_Id__c =: caseRec.CCC_External_Id__c WITH SECURITY_ENFORCED];
                
           ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRec, cccRecord[0].Resolved_Case_Email_Template__c, 
                                                            cccRecord[0].Resolved_Case_SMS_Metadata__c,true);
            
          caseRec.Attachment_Status__c = ABHFL_Constants.COMPLETED;
          caseRec.Stage__c = ABHFL_Constants.RESOLVED;
          
          if(Schema.sObjectType.Case.isUpdateable()){
            UPDATE caseRec;
          } 
     }
     
     private void handleUnsuccessfullTransfer(Case caseRec,ASF_Case_Integration__c caseInteg){
         if(caseRec.Source__c != ABHFL_Constants.BRANCH){
            Group csQueue = [SELECT Id FROM Group WHERE Type =: ABHFL_Constants.QUEUE AND DeveloperName =: ABHFL_Constants.ABHFL_CUSTOMER_SERVICE_TEAM WITH SECURITY_ENFORCED LIMIT 1];
            caseRec.OwnerId = csQueue.Id;
            
            if(Schema.sObjectType.Case.isUpdateable()){
                UPDATE caseRec;
            }  
        }else if(caseRec.Source__c == ABHFL_Constants.BRANCH ){
            
            if(Schema.sObjectType.Case.isUpdateable() && caseRec.OwnerId != caseRec.CreatedById){
                caseRec.OwnerId = caseRec.CreatedById;
                UPDATE caseRec;
            }
            
            ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRec, ABHFL_Constants.BALANCE_CONFIRMATION_LETTER, ABHFL_Constants.STP_DOC_RETRIEVAL_FAILURE + caseInteg.Name);
        }
     }
    
    
    /****************************************************************************************************************
    *@description - 
    *****************************************************************************************************************/
    public class BCLRequestWrapper{
        public string caseId;
        public string souce;
        public string requestType;
        public string lan;
        public string reportName;
        public string documentType;
        
        BCLRequestWrapper(string caseNumber,string lanNo){
            this.caseId = caseNumber;
            this.souce = ABHFL_Constants.CRM;
            this.requestType = ABHFL_Constants.EMAIL;
            this.lan = lanNo;
            this.reportName = ABHFL_Constants.BKL;
            this.documentType = ABHFL_Constants.BINARY_DATA;
        }
    }
}