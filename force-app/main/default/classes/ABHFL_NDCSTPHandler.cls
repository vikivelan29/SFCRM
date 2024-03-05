/*********************************************************
*Class        :  ABHFL_NDCSTPHandler
*Author       :  Siddarth Jaitly
*Created Date :  12/12/2023
*Last Modified:  12/12/2023
*Description  :  Class for NDC STP
*********************************************************/
public with sharing class ABHFL_NDCSTPHandler implements ASF_IntegrationInvocable {
    List<String> sourceList = new List<String>{'Welcome BOT', 'Voice Bot', 'WhatsApp', 'Chatbot', 'CustomerPortal', 'Email'};
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
                           FROM Case WHERE Id =: caseRec.Id];
        
        //Check for mandatory API conditions
        result.status = ABHFL_Constants.ERROR;
        result.response = Custom_Messages__mdt.getInstance('NDC_STP_EvaluationFailed').Message__c;   
        if(String.isNotBlank(caseRecord.Asset.LAN__c) && caseRecord.ABHFL_Case_Detail__r.STP_Request_Type__c == ABHFL_Constants.EMAIL){
            if(caseRecord.Asset.Account_Status__c == ABHFL_Constants.ACCOUNT_STATUS_CLOSED){
            	result.status = ABHFL_Constants.SUCCESS;
                result.response = Custom_Messages__mdt.getInstance('NDC_STP_EvaluationSuccess').Message__c;
            } else {
                if(String.isNotBlank(caseRecord.Asset.Branch__r.Branch_Queue_Id__c) && caseRecord.Source__c == ABHFL_Constants.BRANCH){
                    caseRecord.OwnerId = caseRecord.Asset.Branch__r.Branch_Queue_Id__c;
                    if(Schema.sObjectType.Case.isUpdateable()){
                        update caseRecord;
                    }
                    result.response = Custom_Messages__mdt.getInstance('NDC_STP_EvaluationFailedBranchAssignment').Message__c;                                                                                                                               

                } else if(sourceList.contains(caseRecord.Source__c)) {
                    List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id,Rejected_Case_Email_Template__c,Rejected_Case_SMS_Metadata__c,Additional_Email_Templates__c,Additional_SMS_Metadata__c
                                                                    FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c =:ABHFL_Constants.NDC_CCC_EXTERNALID];
                    if(cccRecord.size() > 0){
                        Map<String, String> emailTemplateMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_Email_Templates__c);
                        Map<String, String> smsMetadataMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_SMS_Metadata__c);
                
                        Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord,
                                                                                emailTemplateMap.get('Rejected'), smsMetadataMap.get('Rejected'), false);
                    }
                    //check with Ashish this is not working as expected.
                    caseRecord.MoveToNext__c = true;
                    if(!test.isRunningTest())
                        update caseRecord;
                    result.response = Custom_Messages__mdt.getInstance('NDC_STP_EvaluationFailedCaseClosed').Message__c;  
                } else {
                    result.response = Custom_Messages__mdt.getInstance('NDC_STP_EvaluationFailed').Message__c; 
                }
            }
        }
        
        return result;
    }
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        
        List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id,Rejected_Case_Email_Template__c,Rejected_Case_SMS_Metadata__c,Additional_Email_Templates__c,Additional_SMS_Metadata__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c =:ABHFL_Constants.NDC_CCC_EXTERNALID];
        
        // Case caseRecord = [SELECT Id,Source__c,AccountId,CCC_External_Id__c,ContactId,Asset.LAN__c,Asset.Account_Status__c,
        //                    Asset.Branch__r.Branch_Queue_Id__c,ABHFL_Case_Detail__r.STP_Request_Type__c,No_Auto_Communication__c
        //                    FROM Case WHERE Id =: caseRec.Id];
        List<Case> caseRecords = new List<Case>();
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }

        List<Case> casesForCreatePELogAndinvokeCommPEevent = new List<Case>();
        Map<Id, String> emailTemplateMap = new Map<Id, String>();
        Map<Id, String> smsMetadataMap = new Map<Id, String>();
        Map<Id, Boolean> isTransferredMap = new Map<Id, Boolean>();
        for(Case caseRecord : caseRecords){
            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            //Check for mandatory API conditions
            result.status = ABHFL_Constants.ERROR;
            result.response = Custom_Messages__mdt.getInstance('NDC_STP_EvaluationFailed').Message__c;   
            if(String.isNotBlank(caseRecord.Asset.LAN__c) && caseRecord.ABHFL_Case_Detail__r.STP_Request_Type__c == ABHFL_Constants.EMAIL){
                if(caseRecord.Asset.Account_Status__c == ABHFL_Constants.ACCOUNT_STATUS_CLOSED){
                    result.status = ABHFL_Constants.SUCCESS;
                    result.response = Custom_Messages__mdt.getInstance('NDC_STP_EvaluationSuccess').Message__c;
                } else {
                    if(String.isNotBlank(caseRecord.Asset.Branch__r.Branch_Queue_Id__c) && caseRecord.Source__c == ABHFL_Constants.BRANCH){
                        Case updatedCase = new Case(Id=caseRecord.Id);
                        updatedCase.OwnerId = caseRecord.Asset.Branch__r.Branch_Queue_Id__c;
                        result.updatedCase = updatedCase;
                        result.response = Custom_Messages__mdt.getInstance('NDC_STP_EvaluationFailedBranchAssignment').Message__c;
                    } else if(sourceList.contains(caseRecord.Source__c)) {
                        
                        if(cccRecord.size() > 0){
                            Map<String, String> stpemailTemplateMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_Email_Templates__c);
                            Map<String, String> stpsmsMetadataMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_SMS_Metadata__c);

                            emailTemplateMap.put(caseRecord.Id, stpemailTemplateMap.get('Rejected'));
                            smsMetadataMap.put(caseRecord.Id, stpsmsMetadataMap.get('Rejected'));
                            isTransferredMap.put(caseRecord.Id, false);
                            casesForCreatePELogAndinvokeCommPEevent.add(caseRecord);
                        }
                        //check with Ashish this is not working as expected.
                        Case updatedCase = new Case(Id=caseRecord.Id);
                        updatedCase.Stage__c = 'Resolved';
                        result.updatedCase = updatedCase;
                        result.response = Custom_Messages__mdt.getInstance('NDC_STP_EvaluationFailedCaseClosed').Message__c;  
                    } else {
                        result.response = Custom_Messages__mdt.getInstance('NDC_STP_EvaluationFailed').Message__c; 
                    }
                }
            }
            resultMap.put(caseRecord.Id, result);
        }

        if(!casesForCreatePELogAndinvokeCommPEevent.isEmpty()){
            ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(casesForCreatePELogAndinvokeCommPEevent, emailTemplateMap, smsMetadataMap, isTransferredMap);
        }
        
        return resultMap;
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
                                                               AND Integration_Ext_Id__c =:intSpec.External_Id__c ];
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

    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();

        Set<String> intIds = new Set<String>();
        for(Case caseRec : caseRecs){
            for(ASF_Integration__c integ : integs.get(caseRec.Id)){
                if(integ.Processing_Class__c == 'ABHFL_NDCSTPHandler'){
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

        //Case caseRecord = [SELECT Id, Asset.LAN__c,CaseNumber,Business_Unit__c  FROM Case where Id =: caseRec.Id];
        List<Case> caseRecords = new List<Case>();
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }
        List<ASF_Case_Integration__c> newCaseIntegrations = new List<ASF_Case_Integration__c>();
        Map<Integer, Case_Integration_Outbound__e> peMap = new Map<Integer, Case_Integration_Outbound__e>();
        Integer index = 0;
        Map<Integer, Id> indexToCaseId = new Map<Integer, Id>();
        for(Case caseRecord : caseRecords){
            string requestBody = JSON.serialize(new NDCRequestWrapper(caseRecord.CaseNumber,caseRecord.Asset.Lan__c));
            for(ASF_Integration__c intSpec : integs.get(caseRecord.Id))
            {
                if(intSpec.Processing_Class__c == 'ABHFL_NDCSTPHandler'){
                    ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
                    caseInteg.Integration_Ext_Id__c = intSpec.External_Id__c;
                    caseInteg.Case__c = caseRecord.Id;
                    caseInteg.Status__c= ABHFL_Constants.PENDING;
                    caseInteg.Request__c = requestBody;
                    newCaseIntegrations.add(caseInteg);

                    Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
                    caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
                    //caseIntOut.Case_Integration_ID__c = caseInt.Name;
                    caseIntOut.Integration_Name__c  = intSpec.Display_Name__c;
                    caseIntOut.Request_Payload__c  =  requestBody;
                    caseIntOut.ServiceName__c = ABHFL_Constants.REPORTING_SERVICE;
                    peMap.put(index, caseIntOut);
                    indexToCaseId.put(index, caseRecord.Id);
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
                List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id,Resolved_Case_Email_Template__c,Resolved_Case_SMS_Metadata__c,Additional_Email_Templates__c,Additional_SMS_Metadata__c
                                                                FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c =:ABHFL_Constants.NDC_CCC_EXTERNALID];
                if(cccRecord.size() > 0){
                    Map<String, String> emailTemplateMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_Email_Templates__c);
                    Map<String, String> smsMetadataMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_SMS_Metadata__c);
            
                    Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord,
                                                                            emailTemplateMap.get('Resolved'), smsMetadataMap.get('Resolved'), isTransferred);          
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
            if(String.isNotBlank(caseRecord.Asset.Branch__r.Branch_Queue_Id__c) && caseRecord.OwnerId != caseRecord.Asset.Branch__r.Branch_Queue_Id__c){
                caseRecord.OwnerId = caseRecord.Asset.Branch__r.Branch_Queue_Id__c;
                update caseRecord;
                ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRecord,ABHFL_Constants.NDC_STP_NAME,null);
            }
        } else {
            Group csQueue = [SELECT Id FROM Group WHERE Type =: ABHFL_Constants.QUEUE AND DeveloperName =: ABHFL_Constants.ABHFL_CUSTOMER_SERVICE_TEAM  Limit 1];
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