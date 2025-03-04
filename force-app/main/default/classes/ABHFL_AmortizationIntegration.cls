/*********************************************************
*@Class        :  ABHFL_AmortizationIntegration
*@Author       :  Dhinesh Kumar T
*@Created Date :  12/13/2023
*@Last Modified:  12/14/2023
*@description  :  Class for Amortization STP integration. 
*********************************************************/
public with sharing class ABHFL_AmortizationIntegration implements ASF_IntegrationInvocable {
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
            SELECT Id,Stage__c, Asset.Loan_Disbursement_Status__c,Asset.LAN__c,ABHFL_Case_Detail__r.STP_Request_Type__c,CCC_External_Id__c,AccountId,ContactId, Attachment_Status__c,Source__c,No_Auto_Communication__c
            FROM Case
            WHERE Id =: caseRec.Id 
        ];
        //Check for mandatory API conditions & Check for Loan Disbursement Status
        if(String.isNotBlank(caseRecord.Asset.LAN__c) && caseRecord.Asset.Loan_Disbursement_Status__c != null && caseRecord.Asset.Loan_Disbursement_Status__c == 'Partially') {
        
        
          List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id, CCC_External_Id__c, Additional_SMS_Metadata__c, Additional_Email_Templates__c FROM ASF_Case_Category_Config__c
                                                               WHERE CCC_External_Id__c = :ABHFL_Constants.Amort_CCC_EXTERNALID];
          if(!cccRecord.isEmpty()) {
              Map<String, String> emailTemplateMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_Email_Templates__c);
                Map<String, String> smsMetadataMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_SMS_Metadata__c);

                Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord,  emailTemplateMap.get('Rejected'), smsMetadataMap.get('Rejected'), false);

              // Set wrapper response and status if evaluation is failure
            result.status = ABHFL_Constants.ERROR;
            result.response = Custom_Messages__mdt.getInstance('AMORT_Evaluate_Disbursed_Partially').Message__c;
            caseRecord.MoveToNext__c = true;
            
            if(Schema.sObjectType.Case.isUpdateable() && caseRecord.Source__c == 'API'){
                update caseRecord;
            } 
            
          }
      } else if(String.isNotBlank(caseRecord.Asset.LAN__c) && caseRecord.ABHFL_Case_Detail__r.STP_Request_Type__c == 'Email'){
        result.status = ABHFL_Constants.SUCCESS;
        result.response = Custom_Messages__mdt.getInstance('AMORT_EvaluateSuccess').Message__c;
      }
        if(caseRecord.ABHFL_Case_Detail__r.STP_Request_Type__c == ABHFL_Constants.STP_REQUEST_TYPE_DOWNLOAD){
            caseRecord.Stage__c = ABHFL_Constants.RESOLVED;
            if(Schema.sObjectType.Case.isUpdateable()){
                update caseRecord;
            }
            return new ASF_IntegrationsController.IntegrationWrapper();
        }
        return result;
    }
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
      
        // Case caseRecord = [
        //     SELECT Id, Asset.Loan_Disbursement_Status__c,Asset.LAN__c,ABHFL_Case_Detail__r.STP_Request_Type__c,CCC_External_Id__c,AccountId,ContactId, Attachment_Status__c,Source__c,No_Auto_Communication__c
        //     FROM Case
        //     WHERE Id =: caseRec.Id 
        // ];
        List<Case> caseRecords = new List<Case>();
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }
        List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id, CCC_External_Id__c, Additional_SMS_Metadata__c, Additional_Email_Templates__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c = :ABHFL_Constants.Amort_CCC_EXTERNALID];
        
        Map<Id, String> emailTemplateMap = new Map<Id, String>();
        Map<Id, String> smsMetadataMap = new Map<Id, String>();
        Map<Id, Boolean> isTransferredMap = new Map<Id, Boolean>();
        List<Case> casesForCreatePELogAndinvokeCommPEevent = new List<Case>();
        //List<Case> downloadStpCases = new List<Case>();
        for(Case caseRecord : caseRecords){
            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            result.status = ABHFL_Constants.ERROR;
            result.response = Custom_Messages__mdt.getInstance('LOD_EvaluateFailure').Message__c;
            
            //Check for mandatory API conditions & Check for Loan Disbursement Status
            if(String.isNotBlank(caseRecord.Asset.LAN__c) && caseRecord.Asset.Loan_Disbursement_Status__c != null && caseRecord.Asset.Loan_Disbursement_Status__c == 'Partially') {
                if(!cccRecord.isEmpty()) {
                    Map<String, String> stpemailTemplateMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_Email_Templates__c);
                    Map<String, String> stpsmsMetadataMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_SMS_Metadata__c);
                    emailTemplateMap.put(caseRecord.Id, stpemailTemplateMap.get('Rejected'));
                    smsMetadataMap.put(caseRecord.Id, stpsmsMetadataMap.get('Rejected'));
                    isTransferredMap.put(caseRecord.Id, false);
                    casesForCreatePELogAndinvokeCommPEevent.add(caseRecord);

                    // Set wrapper response and status if evaluation is failure
                    result.status = ABHFL_Constants.ERROR;
                    result.response = Custom_Messages__mdt.getInstance('AMORT_Evaluate_Disbursed_Partially').Message__c;
                    if(caseRecord.Source__c == 'API'){
                        Case updatedCase = new Case(Id=caseRecord.Id);
                        updatedCase.MoveToNext__c = true;
                        result.updatedCase = updatedCase;
                    }
                }
            }
            else if(String.isNotBlank(caseRecord.Asset.LAN__c) && caseRecord.ABHFL_Case_Detail__r.STP_Request_Type__c == 'Email'){
                result.status = ABHFL_Constants.SUCCESS;
                result.response = Custom_Messages__mdt.getInstance('AMORT_EvaluateSuccess').Message__c;
            }
            if(caseRecord.ABHFL_Case_Detail__r.STP_Request_Type__c == ABHFL_Constants.STP_REQUEST_TYPE_DOWNLOAD){
               /* caseRecord.Stage__c = ABHFL_Constants.RESOLVED;
                if(Schema.sObjectType.Case.isUpdateable()){
                    downloadStpCases.add(caseRecord);
                    //update caseRecord;
                }
                result = new ASF_IntegrationsController.IntegrationWrapper();*/
                Case updatedCase = new Case(Id=caseRecord.Id);
                updatedCase.Stage__c = ABHFL_Constants.RESOLVED;    
                result.updatedCase = updatedCase;
            }
            resultMap.put(caseRecord.Id, result);
        }
       /* if(downloadStpCases.size()>0){
            update downloadStpCases;
        }*/
        if(!casesForCreatePELogAndinvokeCommPEevent.isEmpty()){
            ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(casesForCreatePELogAndinvokeCommPEevent, emailTemplateMap, smsMetadataMap, isTransferredMap);
        }
        return resultMap;
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
                                                              AND Integration_Ext_Id__c =:intSpec.External_Id__c ];
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
       Case caseRecord = [SELECT Id, Asset.LAN__c,CaseNumber,Business_Unit__c  FROM Case where Id =: caseRec.Id ];
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
       
       ASF_Case_Integration__c caseInt = [Select Name from ASF_Case_Integration__c where id =: caseInteg.Id ];
       
       
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
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();

        Set<String> intIds = new Set<String>();
        for(Case caseRec : caseRecs){
            for(ASF_Integration__c integ : integs.get(caseRec.Id)){
                if(integ.Processing_Class__c == 'ABHFL_AmortizationIntegration'){
                    intIds.add(integ.External_Id__c);
                }
            }
        }

        List<ASF_Case_Integration__c> existingCaseIntegrations = new List<ASF_Case_Integration__c>();
        for(ASF_Case_Integration__c caseInt : [SELECT Id, Status__c, Case__c, Integration_Ext_Id__c FROM ASF_Case_Integration__c WHERE Case__c IN :caseRecs AND Integration_Ext_Id__c IN :intIds])
        {
            if(integs.containsKey(caseInt.Case__c)){
                for(ASF_Integration__c integ : integs.get(caseInt.Case__c))
                {
                    if(integ.External_Id__c == caseInt.Integration_Ext_Id__c && caseInt.Status__c == ABHFL_Constants.PENDING){
                        caseInt.Status__c = ABHFL_Constants.CANCELED;
                        existingCaseIntegrations.add(caseInt);
                    }
                }
            }
        }

        ASF_TriggerSkipperUtility.markTriggerRun('ASF_Case_Integration__c');
        update existingCaseIntegrations;
        ASF_TriggerSkipperUtility.resetTriggerRun('ASF_Case_Integration__c');

        //Case caseRecord = [SELECT Id, Asset.LAN__c,CaseNumber,Business_Unit__c  FROM Case where Id =: caseRec.Id ];
        List<Case> caseRecords = new List<Case>();
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }

        List<ASF_Case_Integration__c> newCaseIntegrations = new List<ASF_Case_Integration__c>();
        Map<Integer, Case_Integration_Outbound__e> peMap = new Map<Integer, Case_Integration_Outbound__e>();
        Integer index = 0;
        Map<Integer, Id> indexToCaseId = new Map<Integer, Id>();
        for(Case caseRecord : caseRecords){
            ASF_IntegrationsController.IntegrationWrapper response = new ASF_IntegrationsController.IntegrationWrapper();
            response.status = ABHFL_Constants.SUCCESS;
            for(ASF_Integration__c intSpec : integs.get(caseRecord.Id))
            {
                
                if(intSpec.Processing_Class__c == 'ABHFL_AmortizationIntegration'){
                    ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
                    caseInteg.Integration_Ext_Id__c = intSpec.External_Id__c;
                    caseInteg.Case__c = caseRecord.Id;
                    caseInteg.Request__c = JSON.serialize(new AmmortRequestWrapper(caseRecord.Asset.Lan__c,caseRecord)); 
                    caseInteg.Status__c = ABHFL_Constants.PENDING;
                    newCaseIntegrations.add(caseInteg);
            
                    Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
                    caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
                    //caseIntOut.Case_Integration_ID__c = caseInt.Name;
                    caseIntOut.Integration_Name__c  = intSpec.Display_Name__c;
                    caseIntOut.ServiceName__c = ABHFL_Constants.REPORTING_SERVICE;
                    caseIntOut.Request_Payload__c  =  JSON.serialize(new AmmortRequestWrapper(caseRecord.Asset.Lan__c,caseRecord));
                    peMap.put(index, caseIntOut);
                    indexToCaseId.put(index, caseRecord.Id);
                    index++;
                }
            }
            resultMap.put(caseRecord.Id, response);
        }

        index = 0;
        
        if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
            List<Database.SaveResult> results = Database.insert(newCaseIntegrations, false);
            Map<Id, ASF_Case_Integration__c> caseIntegrations = new Map<Id, ASF_Case_Integration__c>([SELECT Name, Case__c FROM ASF_Case_Integration__c WHERE Id IN :newCaseIntegrations ]);
            for(Database.SaveResult sr : results){
                if(sr.isSuccess()){
                    Case_Integration_Outbound__e caseIntOut = peMap.get(index);
                    caseIntOut.Case_Integration_ID__c = caseIntegrations.get(sr.getId()).Name;
                    peMap.put(index, caseIntOut);
                }else{
                    ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
                    wrap.status = ABHFL_Constants.ERROR;
                    resultMap.put(indexToCaseId.get(index), wrap);
                    peMap.remove(index);
                    indexToCaseId.remove(index);
                }
                index++;
            }
        }
        List<Database.SaveResult> publishResults = EventBus.publish(peMap.values());
        index = 0;
        for(Database.SaveResult publishResult : publishResults){
            if(publishResult.isSuccess()){
                ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
                wrap.status = ABHFL_Constants.SUCCESS;
                resultMap.put(indexToCaseId.values()[index], wrap);
            }else{
                ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
                wrap.status = ABHFL_Constants.ERROR;
                resultMap.put(indexToCaseId.values()[index], wrap);
            }
            index++;
        }
        
        return resultMap;
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
                WHERE Id =: caseInteg.Case__c 
            ]; 
        if(caseInteg.Status__c == ABHFL_Constants.SUCCESS && caseRec!=null){
          Boolean isTransferred = ABCL_IntegrationCommonUtility.transferAttachments(caseInteg);
      if(isTransferred){
                  integrationFailure = false;
                  string cccExternalId;
          if(!Test.isRunningTest()){
            cccExternalId = ABHFL_Constants.Amort_CCC_EXTERNALID;
          }else{
            cccExternalId = 'CCC-CC-CCLTD-01';
          }
        
                  List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id, CCC_External_Id__c, Resolved_Case_Email_Template__c,
                                                                      Resolved_Case_SMS_Metadata__c, Additional_SMS_Metadata__c, Additional_Email_Templates__c FROM ASF_Case_Category_Config__c
                                                                      WHERE CCC_External_Id__c =: cccExternalId];
                
                  Map<String, String> emailTemplateMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_Email_Templates__c);
                Map<String, String> smsMetadataMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_SMS_Metadata__c);
                                                      

                  ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRec,  emailTemplateMap.get('Resolved'), smsMetadataMap.get('Resolved'), isTransferred);
                  caseRec.MoveToNext__c = true;
                  update caseRec;        
            }else if(caseRec.Source__c != ABHFL_Constants.BRANCH){
                        ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRec, ABHFL_Constants.AMORTIZATION, ABHFL_Constants.STP_DOC_RETRIEVAL_FAILURE);
                      Group csQueue = [SELECT Id FROM Group WHERE Type =: ABHFL_Constants.QUEUE AND DeveloperName =: ABHFL_Constants.ABHFL_CUSTOMER_SERVICE_TEAM   Limit 1];
                        caseRec.OwnerId = csQueue.Id;
                        
                        if(Schema.sObjectType.Case.isUpdateable()){
                              update caseRec;
                        } 
                    }
        }
        if(integrationFailure && caseRec.CCC_External_Id__c != 'hfl009'){
              if(caseRec.Source__c != ABHFL_Constants.BRANCH){
                  Group csQueue = [SELECT Id FROM Group WHERE Type =: ABHFL_Constants.QUEUE AND DeveloperName =: ABHFL_Constants.ABHFL_CUSTOMER_SERVICE_TEAM   Limit 1];
                        caseRec.OwnerId = csQueue.Id;
                        
                        if(Schema.sObjectType.Case.isUpdateable()){
                              update caseRec;
                        } 
                        
                    ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRec, ABHFL_Constants.AMORTIZATION, ABHFL_Constants.STP_DOC_RETRIEVAL_FAILURE);
              }else if(caseRec.Source__c == ABHFL_Constants.BRANCH){
                    ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRec, ABHFL_Constants.AMORTIZATION, ABHFL_Constants.STP_DOC_RETRIEVAL_FAILURE);
            }
        }
        //If failure for - Change EMI /Tenor (Increase)
        if(integrationFailure && caseRec.CCC_External_Id__c == 'hfl009'){
            if(caseRec.Source__c != ABHFL_Constants.BRANCH){
                Group emailNonFinancialQueue = [SELECT Id FROM Group WHERE Type =: ABHFL_Constants.QUEUE AND DeveloperName = 'ABHFL_Email_Non_Financial_Team'   Limit 1];
                      caseRec.OwnerId = emailNonFinancialQueue.Id;
                      
                      if(Schema.sObjectType.Case.isUpdateable()){
                            update caseRec;
                      } 
                      
                  ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRec, ABHFL_Constants.AMORTIZATION, ABHFL_Constants.STP_DOC_RETRIEVAL_FAILURE);
            }else if(caseRec.Source__c == ABHFL_Constants.BRANCH){
                  ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRec, ABHFL_Constants.AMORTIZATION, ABHFL_Constants.STP_DOC_RETRIEVAL_FAILURE);
                  caseRec.OwnerId = caseRec.CreatedById;
                      
                      if(Schema.sObjectType.Case.isUpdateable()){
                            update caseRec;
                      } 
          }
      }

        if(integrationFailure != caseRec.ABHFL_Case_Detail__r.STP_Failure__c){
            ABHFL_Case_Detail__c caseDetails = new ABHFL_Case_Detail__c();
            caseDetails.STP_Failure__c = integrationFailure;
            caseDetails.Id = caseRec.ABHFL_Case_Detail__c;
            if(Schema.sObjectType.ABHFL_Case_Detail__c.isUpdateable()){
                update caseDetails;  
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
