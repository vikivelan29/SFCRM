/*********************************************************
*Class        :  ABHFL_WelcomeKitIntegration
*Author       :  Aditya Mehrotra
*Created Date :  12/04/2023
*Last Modified:  12/05/2023
*@description :  Class for Welcome Kit Integration
*********************************************************/
public with sharing class ABHFL_WelcomeKitIntegration implements ASF_IntegrationInvocable {
    
    public final List<String> digitalSources = new List<String>{'Welcome BOT', 'Voice Bot', 'WhatsApp', 'Chatbot', 'Customer Portal', 'Email'};
    public final List<String> offlineSources = new List<String>{'Branch', 'Call Center', 'Internal Usage', 'Social Media'};
    
    Map<Id, String> emailTemplateMap = new Map<Id, String>();
    Map<Id, String> smsMetadataMap = new Map<Id, String>();
    Map<Id, Boolean> isTransferredMap = new Map<Id, Boolean>();
    List<Case> casesForCreatePELogAndinvokeCommPEevent = new List<Case>();
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
        result.response = Custom_Messages__mdt.getInstance('WK_Evaluation_Failure').Message__c;

        Case caseRecord = [
            SELECT Id, CCC_External_Id__c,MoveToNext__c, Asset.LAN__c, Asset.Last_Disbursement_Date__c, Channel__c, Source__c,
            	ABHFL_Case_Detail__r.STP_Request_Type__c, AccountId, ContactId, Attachment_Status__c, No_Auto_Communication__c
            FROM Case
            WHERE Id =: caseRec.Id 
        ];
        
        //Checking for mandatory API conditions
        if(String.isNotBlank(caseRecord.Asset.LAN__c) && caseRecord.ABHFL_Case_Detail__r.STP_Request_Type__c == 'Email'){
            Date today = Date.today();
            Date sixMonthsAgo = today.addMonths(-6);
            Date disbursalDate = caseRecord.Asset.Last_Disbursement_Date__c;
            if(disbursalDate >= sixMonthsAgo)
            {
                result.status = ABHFL_Constants.SUCCESS;
                result.response = Custom_Messages__mdt.getInstance('WK_Evaluation_Success').Message__c;
            }
            else
            {
                result = handleDisbursalBeforeSixMonths(caseRecord);
          	}    
        }
        
        return result;
    }
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        
        // Case caseRecord = [
        //     SELECT Id, CCC_External_Id__c,MoveToNext__c, Asset.LAN__c, Asset.Last_Disbursement_Date__c, Channel__c, Source__c,
        //     	ABHFL_Case_Detail__r.STP_Request_Type__c, AccountId, ContactId, Attachment_Status__c, No_Auto_Communication__c
        //     FROM Case
        //     WHERE Id =: caseRec.Id 
        // ];
        List<Case> caseRecords = new List<Case>();
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }

        List<Case> casesForDisbursalBeforeSixMonths = new List<Case>();
        for(Case caseRecord : caseRecords){
            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            result.status = ABHFL_Constants.ERROR;
            result.response = Custom_Messages__mdt.getInstance('WK_Evaluation_Failure').Message__c;
            //Checking for mandatory API conditions
            if(String.isNotBlank(caseRecord.Asset.LAN__c) && caseRecord.ABHFL_Case_Detail__r.STP_Request_Type__c == 'Email'){
                Date today = Date.today();
                Date sixMonthsAgo = today.addMonths(-6);
                Date disbursalDate = caseRecord.Asset.Last_Disbursement_Date__c;
                if(disbursalDate >= sixMonthsAgo)
                {
                    result.status = ABHFL_Constants.SUCCESS;
                    result.response = Custom_Messages__mdt.getInstance('WK_Evaluation_Success').Message__c;
                }
                else
                {
                    casesForDisbursalBeforeSixMonths.add(caseRecord);
                }    
            }
            resultMap.put(caseRecord.Id, result);
        }
        if(!casesForDisbursalBeforeSixMonths.isEmpty()){
            resultMap.putAll(handleDisbursalBeforeSixMonths(casesForDisbursalBeforeSixMonths));
            if(!casesForCreatePELogAndinvokeCommPEevent.isEmpty()){
                ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(casesForCreatePELogAndinvokeCommPEevent,emailTemplateMap, smsMetadataMap, isTransferredMap);
            }
        }
        return resultMap;
    }
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - handleDisbursalAfterSixMonths
    * @param caseRecord - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the evaluate method, this method handles disbursal before 6 months
    *****************************************************************************************************************/
    private Map<Id, ASF_IntegrationsController.IntegrationWrapper> handleDisbursalBeforeSixMonths(List<Case> caseRecords){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        Set<String> cccIds = new Set<String>();
        for(Case caseRec : caseRecords){
            cccIds.add(caseRec.CCC_External_Id__c);
        }
        Map<String, ASF_Case_Category_Config__c> configIdToConfigMap = new Map<String,ASF_Case_Category_Config__c>();
        for(ASF_Case_Category_Config__c cccRecord : [SELECT Id, CCC_External_Id__c, Rejected_Case_Email_Template__c, Rejected_Case_SMS_Metadata__c, Additional_Email_Templates__c,Additional_SMS_Metadata__c FROM ASF_Case_Category_Config__c
        WHERE CCC_External_Id__c IN :cccIds ])
        {
            configIdToConfigMap.put(cccRecord.CCC_External_Id__c, cccRecord);
        }

        for(Case caseRecord : caseRecords){
            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            if(String.isNotBlank(caseRecord.Source__c) && digitalSources.contains(caseRecord.Source__c))
            {
                Map<String, String> stpemailTemplateMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(configIdToConfigMap.get(caseRecord.CCC_External_Id__c).Additional_Email_Templates__c);
                Map<String, String> stpsmsMetadataMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(configIdToConfigMap.get(caseRecord.CCC_External_Id__c).Additional_SMS_Metadata__c);
                
                //Send standard email template and close the case
                this.emailTemplateMap.put(caseRecord.Id, stpemailTemplateMap.get('Rejected'));
                this.smsMetadataMap.put(caseRecord.Id, stpsmsMetadataMap.get('Rejected'));
                this.isTransferredMap.put(caseRecord.Id, false);
                this.casesForCreatePELogAndinvokeCommPEevent.add(caseRecord);
                
                //Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord, 
                //                                                        emailTemplateMap.get('Rejected'), smsMetadataMap.get('Rejected'), false);
                
                // if(!Test.IsRunningTest() && platformEventResult.IsSuccess() && Schema.sObjectType.Case.isUpdateable())
                // {
                //     update caseRecord;
                // }
                Case updatedCase = new Case(Id=caseRecord.Id);
                updatedCase.Stage__c = 'Resolved';
                result.updatedCase = updatedCase;
                result.status = ABHFL_Constants.ERROR;
                result.response = Custom_Messages__mdt.getInstance('WK_Evaluation_Failed_Digital').Message__c;
            }
            else
            {	
                result.status = ABHFL_Constants.ERROR;
                result.response = Custom_Messages__mdt.getInstance('WK_Evaluation_Failed_Offline').Message__c;
            }
            resultMap.put(caseRecord.Id, result);
        }
        return resultMap;
    }
    
    private ASF_IntegrationsController.IntegrationWrapper handleDisbursalBeforeSixMonths(Case caseRecord){
        
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id, CCC_External_Id__c, Rejected_Case_Email_Template__c, 
                                                                  Rejected_Case_SMS_Metadata__c, Additional_Email_Templates__c,
                                                       			  Additional_SMS_Metadata__c FROM ASF_Case_Category_Config__c
                                                                  WHERE CCC_External_Id__c =:caseRecord.CCC_External_Id__c ];
        
        if(String.isNotBlank(caseRecord.Source__c) && digitalSources.contains(caseRecord.Source__c))
       	{
            Map<String, String> emailTemplateMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_Email_Templates__c);
            Map<String, String> smsMetadataMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_SMS_Metadata__c);
            
           	//Send standard email template and close the case
            Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord, 
                                                                    emailTemplateMap.get('Rejected'), smsMetadataMap.get('Rejected'), false);
            caseRecord.MoveToNext__c = true;
            if(!Test.IsRunningTest() && platformEventResult.IsSuccess() && Schema.sObjectType.Case.isUpdateable())
            {
               	update caseRecord;
            }
            result.status = ABHFL_Constants.ERROR;
            result.response = Custom_Messages__mdt.getInstance('WK_Evaluation_Failed_Digital').Message__c;
       	}
        else
       	{	
            result.status = ABHFL_Constants.ERROR;
           	result.response = Custom_Messages__mdt.getInstance('WK_Evaluation_Failed_Offline').Message__c;
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
                                                               AND Integration_Ext_Id__c =:integ.External_Id__c ];
        if(existingCaseIntRecords.size()>0){
        	for(ASF_Case_Integration__c cInt : existingCaseIntRecords){
                cInt.Status__c = ABHFL_Constants.CANCELED;
            }
            if(Schema.sObjectType.ASF_Case_Integration__c.isUpdateable()){
            	update existingCaseIntRecords;                
            }
        }
        
        Case caseRecord = [SELECT Id, Asset.LAN__c,CaseNumber,Business_Unit__c, MoveToNext__c  FROM Case where Id =: caseRec.Id ];
                
        ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
        caseInteg.Case__c  = caseRec.Id;
        caseInteg.Integration_Ext_Id__c = integ.External_Id__c;
        caseInteg.Status__c = ABHFL_Constants.PENDING;
        caseInteg.Response__c = ABHFL_Constants.WAITING_API_RESPONSE;
        caseInteg.Request__c = JSON.serialize(new WelcomeKitRequestWrapper(caseRecord.CaseNumber,caseRecord.Asset.Lan__c));
        if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
        	insert caseInteg;    
        }
        
        ASF_Case_Integration__c caseInt = [Select Name from ASF_Case_Integration__c where id =: caseInteg.Id ];
                
        Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
        caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
        caseIntOut.Case_Integration_ID__c = caseInt.Name;
        caseIntOut.Integration_Name__c  = integ.Display_Name__c;
        caseIntOut.ServiceName__c = ABHFL_Constants.REPORTING_SERVICE;
        caseIntOut.Request_Payload__c  =  JSON.serialize(new WelcomeKitRequestWrapper(caseRecord.CaseNumber,caseRecord.Asset.Lan__c));
        Database.SaveResult publishResult = EventBus.publish(caseIntOut);
        
        if(publishResult.IsSuccess()){
        	wrap.status = ABHFL_Constants.SUCCESS;    
        }
        return wrap;
    }
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();

		Set<String> intIds = new Set<String>();
        for(Case caseRec : caseRecs){
            for(ASF_Integration__c integ : integs.get(caseRec.Id)){
                intIds.add(integ.External_Id__c);
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

        //Case caseRecord = [SELECT Id, Asset.LAN__c,CaseNumber,Business_Unit__c, MoveToNext__c  FROM Case where Id =: caseRec.Id ];
        List<Case> caseRecords = new List<Case>();
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }
                
        List<ASF_Case_Integration__c> newCaseIntegrations = new List<ASF_Case_Integration__c>();
        Map<Integer, Case_Integration_Outbound__e> peMap = new Map<Integer, Case_Integration_Outbound__e>();
        Integer index = 0;
        Map<Integer, Id> indexToCaseId = new Map<Integer, Id>();
        for(Case caseRecord : caseRecords){
            for(ASF_Integration__c integ : integs.get(caseRecord.Id))
            {
                ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
                caseInteg.Case__c  = caseRecord.Id;
                caseInteg.Integration_Ext_Id__c = integ.External_Id__c;
                caseInteg.Status__c = ABHFL_Constants.PENDING;
                caseInteg.Response__c = ABHFL_Constants.WAITING_API_RESPONSE;
                caseInteg.Request__c = JSON.serialize(new WelcomeKitRequestWrapper(caseRecord.CaseNumber,caseRecord.Asset.Lan__c));
                newCaseIntegrations.add(caseInteg);

                Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
                caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
                //caseIntOut.Case_Integration_ID__c = caseInt.Name;
                caseIntOut.Integration_Name__c  = integ.Display_Name__c;
                caseIntOut.ServiceName__c = ABHFL_Constants.REPORTING_SERVICE;
                caseIntOut.Request_Payload__c  =  JSON.serialize(new WelcomeKitRequestWrapper(caseRecord.CaseNumber,caseRecord.Asset.Lan__c));
                peMap.put(index, caseIntOut);
                indexToCaseId.put(index, caseRecord.Id);
                index++;
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
                    //wrap.status = ABHFL_Constants.ERROR;
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
                //wrap.status = ABHFL_Constants.ERROR;
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
        Boolean integrationFailure = true;
        Case caseRec =[SELECT Id,Source__c,CreatedById,AccountId,OwnerId,ContactId,CCC_External_Id__c,Asset.Branch__r.Branch_Queue_Id__c,
                           MoveToNext__c,Attachment_Status__c,ABHFL_Case_Detail__r.STP_Failure__c ,No_Auto_Communication__c
                           FROM Case WHERE Id=:caseInteg.Case__c ];
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
        ABCL_IntegrationCommonUtility.updateErrorMessage(caseInteg);
    }
    
    private void handleTransferSuccess(Case caseRec){
        List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id, CCC_External_Id__c, Resolved_Case_Email_Template__c,Additional_Email_Templates__c,
                                                       			   Additional_SMS_Metadata__c, Resolved_Case_SMS_Metadata__c FROM ASF_Case_Category_Config__c
                                                                   WHERE CCC_External_Id__c =:caseRec.CCC_External_Id__c ];
        
        Map<String, String> emailTemplateMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_Email_Templates__c);
        Map<String, String> smsMetadataMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_SMS_Metadata__c);

      	Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRec,
                                                                emailTemplateMap.get('Resolved'), smsMetadataMap.get('Resolved'), true);
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
        Group csQueue = [SELECT Id FROM Group WHERE Type =:ABHFL_Constants.QUEUE AND DeveloperName =:ABHFL_Constants.ABHFL_CUSTOMER_SERVICE_TEAM  Limit 1];
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
        public string souce;
        public string requestType;
        public string lan;
        public string reportName;
        public string documentType;

        public WelcomeKitRequestWrapper(string caseNumber,string lanNo){
            this.caseId = caseNumber;
            this.souce = ABHFL_Constants.CRM;
            this.requestType = ABHFL_Constants.EMAIL;
            this.lan = lanNo;
            this.reportName = ABHFL_Constants.WELCOME_KIT;
            this.documentType = ABHFL_Constants.BINARY_DATA;
        }
    }
}