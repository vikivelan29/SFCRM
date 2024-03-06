/*********************************************************
*@Class        :  ABHFL_SanctionLetterIntegration
*@Author       :  Vishal Gangwar
*@Created Date :  18/12/2023
*@Last Modified:  
*@description  :  Class for Sanction Letter Integration
*********************************************************/
public with sharing class ABHFL_SanctionLetterIntegration implements ASF_IntegrationInvocable {
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - evaluate
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the ASF_IntegrationsController class, this method evaluates whether Sanction Letter integration should be fired or not.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        
        Case caseRecord = [
            SELECT Id, CCC_External_Id__c,MoveToNext__c, Asset.LAN__c, Channel__c, Source__c,
                   ABHFL_Case_Detail__r.As_On_Date__c,ABHFL_Case_Detail__r.STP_Request_Type__c 
            FROM Case
            WHERE Id =: caseRec.Id 
        ];
        
        
        //Checking for mandatory API conditions
        if(String.isNotBlank(caseRecord.Asset.LAN__c)){
            result.status = ABHFL_Constants.SUCCESS;
            result.response = Custom_Messages__mdt.getInstance('SL_Evaluation_Success_Response').Message__c;
        }else{
            result.status = ABHFL_Constants.ERROR;
            result.response = Custom_Messages__mdt.getInstance('SL_Evaluation_Failed_LAN_Error').Message__c;
        }
        
        return result;
    }
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        
        // Case caseRecord = [
        //     SELECT Id, CCC_External_Id__c,MoveToNext__c, Asset.LAN__c, Channel__c, Source__c,
        //            ABHFL_Case_Detail__r.As_On_Date__c,ABHFL_Case_Detail__r.STP_Request_Type__c 
        //     FROM Case
        //     WHERE Id =: caseRec.Id 
        // ];
        
        List<Case> caseRecords = new List<Case>();
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }
        
        for(Case caseRecord : caseRecords){
            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            //Checking for mandatory API conditions
            if(String.isNotBlank(caseRecord.Asset.LAN__c)){
                result.status = ABHFL_Constants.SUCCESS;
                result.response = Custom_Messages__mdt.getInstance('SL_Evaluation_Success_Response').Message__c;
            }else{
                result.status = ABHFL_Constants.ERROR;
                result.response = Custom_Messages__mdt.getInstance('SL_Evaluation_Failed_LAN_Error').Message__c;
            }
            resultMap.put(caseRecord.Id, result);
        }
        
        return resultMap;
    }
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - run
    * @param integ - ASF_Integration record.
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the ASF_IntegrationsController class, this method runs the Sanction Letter integration and creates Case Integration record.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integ, Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
        List<ASF_Case_Integration__c> existingCaseIntRecords = [SELECT Id, Status__c FROM ASF_Case_Integration__c
                                                               WHERE Case__c =:caseRec.Id 
                                                               AND Integration_Ext_Id__c =:integ.External_Id__c ];
        if(existingCaseIntRecords.size()>0){
            for(ASF_Case_Integration__c cInt : existingCaseIntRecords){
                cInt.Status__c = ABHFL_Constants.CANCELED;
            }
            
            if(Schema.sObjectType.ASF_Case_Integration__c.isUpdateable()){
                UPDATE existingCaseIntRecords;  
            }
        }
        
        Case caseRecord = [SELECT Id, Asset.LAN__c,CaseNumber,Business_Unit__c FROM Case where Id =: caseRec.Id ];
               
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Case__c  = caseRec.Id;
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Status__c = ABHFL_Constants.PENDING;
        caseInt.Response__c = ABHFL_Constants.WAITING_API_RESPONSE;
        caseInt.Request__c = JSON.serialize(new SLRequestWrapper(caseRecord.Asset.Lan__c));
        
        if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
            INSERT caseInt; 
        }
        
        ASF_Case_Integration__c caseInte = [SELECT Name FROM ASF_Case_Integration__c WHERE Id =: caseInt.Id ];
        
        
        Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
        caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
        caseIntOut.Case_Integration_ID__c = caseInte.Name;
        caseIntOut.Integration_Name__c  = integ.Display_Name__c;
        caseIntOut.Request_Payload__c  =  JSON.serialize(new SLRequestWrapper(caseRecord.Asset.Lan__c));
        caseIntOut.ServiceName__c = ABHFL_Constants.REPORTING_SERVICE;
        Database.SaveResult publishResult = EventBus.publish(caseIntOut);
        
        if(publishResult.isSuccess()){
            wrap.status = ABHFL_Constants.SUCCESS;
            wrap.response = Custom_Messages__mdt.getInstance('SL_Run_Success').Message__c;
        }else{
            wrap.status = ABHFL_Constants.ERROR;
        }
        return wrap;
    }
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();

        Set<String> intIds = new Set<String>();
        for(Case caseRec : caseRecs){
            for(ASF_Integration__c integ : integs.get(caseRec.Id)){
                if(integ.Processing_Class__c == 'ABHFL_SanctionLetterIntegration'){
                    intIds.add(integ.External_Id__c);
                }
            }
        }

        List<ASF_Case_Integration__c> existingCaseIntegrations = new List<ASF_Case_Integration__c>();
        for(ASF_Case_Integration__c caseInt : [SELECT Id, Status__c, Case__c, Integration_Ext_Id__c FROM ASF_Case_Integration__c
                                                WHERE Case__c IN :caseRecs 
                                                AND Integration_Ext_Id__c IN :intIds])
        {
            if(integs.containsKey(caseInt.Case__c)){
                for(ASF_Integration__c integ : integs.get(caseInt.Case__c))
                {
                    if(integ.External_Id__c == caseInt.Integration_Ext_Id__c){
                        caseInt.Status__c = ABHFL_Constants.CANCELED;
                        existingCaseIntegrations.add(caseInt);
                    }
                }
            }
        }

        ASF_TriggerSkipperUtility.markTriggerRun('ASF_Case_Integration__c');
        update existingCaseIntegrations;
        ASF_TriggerSkipperUtility.resetTriggerRun('ASF_Case_Integration__c');
        
        List<Case> caseRecords = new List<Case>();
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }       
        List<ASF_Case_Integration__c> newCaseIntegrations = new List<ASF_Case_Integration__c>();
        Map<Integer, Case_Integration_Outbound__e> peMap = new Map<Integer, Case_Integration_Outbound__e>();
        Integer index = 0;
        Map<Integer, Id> indexToCaseId = new Map<Integer, Id>();
        for(Case caseRec : caseRecords){
            for(ASF_Integration__c integ : integs.get(caseRec.Id))
            {
                if(integ.Processing_Class__c == 'ABHFL_SanctionLetterIntegration'){
                    ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
                    caseInt.Case__c  = caseRec.Id;
                    caseInt.Integration_Ext_Id__c = integ.External_Id__c;
                    caseInt.Status__c = ABHFL_Constants.PENDING;
                    caseInt.Response__c = ABHFL_Constants.WAITING_API_RESPONSE;
                    caseInt.Request__c = JSON.serialize(new SLRequestWrapper(caseRec.Asset.Lan__c));
                    newCaseIntegrations.add(caseInt);

                    Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
                    caseIntOut.Business_Unit__c  = caseRec.Business_Unit__c;
                    //caseIntOut.Case_Integration_ID__c = caseInte.Name;
                    caseIntOut.Integration_Name__c  = integ.Display_Name__c;
                    caseIntOut.Request_Payload__c  =  JSON.serialize(new SLRequestWrapper(caseRec.Asset.Lan__c));
                    caseIntOut.ServiceName__c = ABHFL_Constants.REPORTING_SERVICE;
                    peMap.put(index, caseIntOut);
                    indexToCaseId.put(index, caseRec.Id);
                    index++;
                }
            }
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
                wrap.response = Custom_Messages__mdt.getInstance('SL_Run_Success').Message__c;
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
        Boolean isTransferred = False;
        
        if(caseInteg.Status__c == ABHFL_Constants.SUCCESS){
            isTransferred = ABCL_IntegrationCommonUtility.transferAttachments(caseInteg);
        }  
        
        Case caseRec = [SELECT Id,AccountId,ContactId,CCC_External_Id__c, MoveToNext__c,Attachment_Status__c,Source__c,  
                                 CreatedById,ownerId,caseNumber,ABHFL_Case_Detail__c,ABHFL_Case_Detail__r.STP_Failure__c,No_Auto_Communication__c
                          FROM Case WHERE Id =: caseInteg.Case__c ];
        
        if(caseRec != null && isTransferred && caseInteg.Status__c == ABHFL_Constants.SUCCESS){
            handleSuccessfullTransfer(caseRec);
        }else if(caseInteg.Status__c != ABHFL_Constants.CANCELED && caseInteg.Status__c != ABHFL_Constants.PENDING){
            handleUnsuccessfullTransfer(caseRec);
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
         List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id, CCC_External_Id__c, Resolved_Case_Email_Template__c,Additional_Email_Templates__c,
                                                                      Additional_SMS_Metadata__c,Resolved_Case_SMS_Metadata__c FROM ASF_Case_Category_Config__c
                                                                      WHERE CCC_External_Id__c =: caseRec.CCC_External_Id__c ];
           
           Map<String, String> emailTemplateMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_Email_Templates__c);
           Map<String, String> smsMetadataMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_SMS_Metadata__c);
           
           Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRec,
                                                                emailTemplateMap.get('Resolved'), smsMetadataMap.get('Resolved'), true);
                
           //ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRec, cccRecord[0].Resolved_Case_Email_Template__c, 
                                                           // cccRecord[0].Resolved_Case_SMS_Metadata__c,true);
            
          caseRec.Attachment_Status__c = ABHFL_Constants.COMPLETED;
          //caseRec.Stage__c = ABHFL_Constants.RESOLVED;
          caseRec.MoveToNext__c = true;
          
        if(Schema.sObjectType.Case.isUpdateable()){
            UPDATE caseRec;
        }
           
     }
     
     private void handleUnsuccessfullTransfer(Case caseRec){
         if(caseRec.Source__c != ABHFL_Constants.BRANCH){
            Group csQueue = [SELECT Id FROM Group WHERE Type =: ABHFL_Constants.QUEUE AND DeveloperName =: ABHFL_Constants.ABHFL_CUSTOMER_SERVICE_TEAM  Limit 1];
            caseRec.OwnerId = csQueue.Id;
            
            if(Schema.sObjectType.Case.isUpdateable()){
                UPDATE caseRec;
            }  
        }else if(caseRec.Source__c == ABHFL_Constants.BRANCH ){
            if(Schema.sObjectType.Case.isUpdateable() && caseRec.OwnerId != caseRec.CreatedById){
                caseRec.OwnerId = caseRec.CreatedById;
                UPDATE caseRec;
            }
            
            ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRec, ABHFL_Constants.SANCTION_LETTER, ABHFL_Constants.STP_DOC_RETRIEVAL_FAILURE);
        }
     }
    
    
    /****************************************************************************************************************
    *@description - 
    *****************************************************************************************************************/
    public class SLRequestWrapper{
        public string LAN;
        public string DocumentType;
        
        SLRequestWrapper(string lanNo){
            this.LAN = lanNo;
            this.DocumentType = ABHFL_Constants.SANCTION_FILE;
        }
    }
}