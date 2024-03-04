/*********************************************************
*Class        :  ABHFL_ICAndPIC_Integration
*Author       :  Anirudh Raturi
*Created Date :  11/12/2023
*Last Modified:  14/12/2023
*@description  :  Class for Interest Certificate And Provisional Interest Certificate Integration
*********************************************************/

public with sharing class ABHFL_ICAndPIC_Integration extends ABHFL_ICAndPIC_IntegrationHelper implements ASF_IntegrationInvocable {
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - evaluate
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the ASF_IntegrationsController class, this method evaluates whether Interest Certificate Or Provisional Interest Certificate Integration should be fired or not.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        
        String financialYr = '';
        String integrationName = '';

        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = 'Error';
        result.response = Custom_Messages__mdt.getInstance('IC_EVALUATION_FAILED').Message__c;

        Case caseRecord = [
            SELECT Id, ABHFL_Case_Detail__r.Financial_Year__c, Technical_Source__c, Asset.LAN__c, Sub_Type_Text__c, ABHFL_Case_Detail__r.STP_Request_Type__c 
            FROM Case
            WHERE Id =: caseRec.Id 
        ];
		
        integrationName = getIntegrationName(caseRecord.Sub_Type_Text__c);
        financialYr = getFinancialYr(caseRecord);
        String lan   = caseRecord.Asset.LAN__c;

        String stpRequestType = String.isNotBlank(caseRecord.ABHFL_Case_Detail__r.STP_Request_Type__c) ? caseRecord.ABHFL_Case_Detail__r.STP_Request_Type__c  : '';
        if(integrationName == 'Interest Certificate') {
            if(String.isNotBlank(financialYr) && String.isNotBlank(lan) && stpRequestType == ABHFL_Constants.EMAIL) {
                result.status = 'Success';
                result.response = Custom_Messages__mdt.getInstance('IC_EVALUATION_SUCCESS_RESPONSE').Message__c;
            }
            else if(String.isBlank(financialYr) && String.isBlank(lan)) {
                result.status = 'Error';
                result.response = Custom_Messages__mdt.getInstance('IC_EVALUATE_FAILED_FINAN_YEAR_AND_LAN').Message__c;
            }
            else if(String.isBlank(financialYr)){
                result.status = 'Error';
                result.response = Custom_Messages__mdt.getInstance('IC_EVALUATE_FAILED_FILL_FINAN_YEAR').Message__c;
            }
            else if(String.isBlank(lan)){
                result.status = 'Error';
                result.response = Custom_Messages__mdt.getInstance('IC_EVALUATE_FAILED_FILL_LAN').Message__c;
            }
        }
        else if(integrationName == 'Provisional Interest Certificate') {
            if(String.isNotBlank(lan) && stpRequestType == ABHFL_Constants.EMAIL) {
                result.status = 'Success';
                result.response = Custom_Messages__mdt.getInstance('PIC_EVALUATION_SUCCESS_RESPONSE').Message__c;
            }
            else if(String.isBlank(lan)){
                result.status = 'Error';
                result.response = Custom_Messages__mdt.getInstance('PIC_EVALUATION_FAILED').Message__c;
            }
        }
        return result;
    }
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        
        // Case caseRecord = [
        //     SELECT Id, ABHFL_Case_Detail__r.Financial_Year__c, Technical_Source__c, Asset.LAN__c, Sub_Type_Text__c, ABHFL_Case_Detail__r.STP_Request_Type__c 
        //     FROM Case
        //     WHERE Id =: caseRec.Id 
        // ];
        List<Case> caseRecords = new List<Case>();
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }
		for(Case caseRecord : caseRecords){
            String financialYr = '';
            String integrationName = '';

            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            result.status = 'Error';
            result.response = Custom_Messages__mdt.getInstance('IC_EVALUATION_FAILED').Message__c;
            integrationName = getIntegrationName(caseRecord.Sub_Type_Text__c);
            financialYr = getFinancialYr(caseRecord);
            String lan   = caseRecord.Asset.LAN__c;

            String stpRequestType = String.isNotBlank(caseRecord.ABHFL_Case_Detail__r.STP_Request_Type__c) ? caseRecord.ABHFL_Case_Detail__r.STP_Request_Type__c  : '';
            if(integrationName == 'Interest Certificate') {
                if(String.isNotBlank(financialYr) && String.isNotBlank(lan) && stpRequestType == ABHFL_Constants.EMAIL) {
                    result.status = 'Success';
                    result.response = Custom_Messages__mdt.getInstance('IC_EVALUATION_SUCCESS_RESPONSE').Message__c;
                }
                else if(String.isBlank(financialYr) && String.isBlank(lan)) {
                    result.status = 'Error';
                    result.response = Custom_Messages__mdt.getInstance('IC_EVALUATE_FAILED_FINAN_YEAR_AND_LAN').Message__c;
                }
                else if(String.isBlank(financialYr)){
                    result.status = 'Error';
                    result.response = Custom_Messages__mdt.getInstance('IC_EVALUATE_FAILED_FILL_FINAN_YEAR').Message__c;
                }
                else if(String.isBlank(lan)){
                    result.status = 'Error';
                    result.response = Custom_Messages__mdt.getInstance('IC_EVALUATE_FAILED_FILL_LAN').Message__c;
                }
            }
            else if(integrationName == 'Provisional Interest Certificate') {
                if(String.isNotBlank(lan) && stpRequestType == ABHFL_Constants.EMAIL) {
                    result.status = 'Success';
                    result.response = Custom_Messages__mdt.getInstance('PIC_EVALUATION_SUCCESS_RESPONSE').Message__c;
                }
                else if(String.isBlank(lan)){
                    result.status = 'Error';
                    result.response = Custom_Messages__mdt.getInstance('PIC_EVALUATION_FAILED').Message__c;
                }
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
    * @description - Invoked from the ASF_IntegrationsController class, this method runs the Interest Certificate Or Provisional Interest Certificate integration and creates Case Integration record.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integ, Case caseRec){

        String financialYr = ''; 
        String currentFiscalYear;
        ABHFL_ICAndPIC_IntegrationHelper abhflIcAndPicIntegrationHelperClass = new ABHFL_ICAndPIC_IntegrationHelper();
        
        ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
		List<ASF_Case_Integration__c> existingCaseIntRecords = [SELECT Id, Status__c FROM ASF_Case_Integration__c
                                                               WHERE Case__c =:caseRec.Id 
                                                               AND Integration_Ext_Id__c =:integ.External_Id__c ];
        
        Case caseRecord = [
            SELECT Id, Sub_Type_Text__c, Technical_Source__c, ABHFL_Case_Detail__r.Financial_Year__c, Asset.LAN__c
            FROM Case
            WHERE Id =: caseRec.Id 
        ];

        if(existingCaseIntRecords.size()>0){
        	for(ASF_Case_Integration__c cInt : existingCaseIntRecords){
                cInt.Status__c = 'Canceled';
            }
            if(Schema.sObjectType.ASF_Case_Integration__c.isUpdateable()){
            	update existingCaseIntRecords;                
            }
        }

        financialYr = getFinancialYr(caseRecord);

        String customLabelForSTPFLow = System.Label.STP_Flows;
        List<String> subTypeList = customLabelForSTPFLow.split(',');
        String caseSubType = caseRecord.Sub_Type_Text__c;
        String type = 'default';
        String jsonBody = '';

        if(subTypeList.contains(caseSubType)) {
            ABHFL_ICAndPIC_IntegrationRequestWrapper reqBodyObj = generateRequest(caseRecord, type, financialYr);
            jsonBody = JSON.serialize(reqBodyObj, true);
        }
   
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Case__c  = caseRec.Id;
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Status__c = 'Pending';
        caseInt.Response__c = 'Waiting for API response';
        caseInt.Request__c = jsonBody;
        if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
        	insert caseInt;    
        }

        if(String.isNotBlank(jsonBody)) {
            firePlatformEvtForCallout(caseInt, jsonBody, caseSubType);
        }

        wrap.status = 'Success';
        return wrap;
    }
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();

        String financialYr = ''; 
        String currentFiscalYear;
        
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
        
        // Case caseRecord = [
        //     SELECT Id, Sub_Type_Text__c, Technical_Source__c, ABHFL_Case_Detail__r.Financial_Year__c, Asset.LAN__c
        //     FROM Case
        //     WHERE Id =: caseRec.Id 
        // ];
        List<Case> caseRecords = new List<Case>();
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }

        String customLabelForSTPFLow = System.Label.STP_Flows;
        List<String> subTypeList = customLabelForSTPFLow.split(',');
        List<ASF_Case_Integration__c> newCaseIntegrations = new List<ASF_Case_Integration__c>();
        Map<Integer, Case_Integration_Outbound__e> peMap = new Map<Integer, Case_Integration_Outbound__e>();
        Integer index = 0;
        Map<Integer, Id> indexToCaseId = new Map<Integer, Id>();
        for(Case caseRecord : caseRecords){
            financialYr = getFinancialYr(caseRecord);
            String caseSubType = caseRecord.Sub_Type_Text__c;
            String type = 'default';
            String jsonBody = '';
            for(ASF_Integration__c integ : integs.get(caseRecord.Id))
            {
                if(subTypeList.contains(caseSubType)) {
                    ABHFL_ICAndPIC_IntegrationRequestWrapper reqBodyObj = generateRequest(caseRecord, type, financialYr);
                    jsonBody = JSON.serialize(reqBodyObj, true);
                    ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
                    caseInt.Case__c  = caseRecord.Id;
                    caseInt.Integration_Ext_Id__c = integ.External_Id__c;
                    caseInt.Status__c = 'Pending';
                    caseInt.Response__c = 'Waiting for API response';
                    caseInt.Request__c = jsonBody;
                    newCaseIntegrations.add(caseInt);

                    Case_Integration_Outbound__e caseIntOut = createPlatformEvtForCallout(jsonBody, caseSubType);
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
                wrap.status = 'Success';
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
    * @param caseInt - ASF_Case_Integration record.
    * @description - Invoked from the Case Integration trigger, this method processes the response of the integration received.
    *****************************************************************************************************************/
    public void processResponse(ASF_Case_Integration__c caseInt){
        
        Boolean integrationFailure = true;
        Boolean isTransferred = False;
        Boolean previousStatus;
        Case caseRecord = [SELECT Id,AccountId,ContactId,Source__c,Sub_Type_Text__c,CCC_External_Id__c,OwnerId,CreatedById,ABHFL_Case_Detail__r.STP_Failure__c,No_Auto_Communication__c
                           FROM Case WHERE Id =: caseInt.Case__c ];
        
        String caseSubType = caseRecord.Sub_Type_Text__c;
        String integrationName = getIntegrationName(caseSubType);

        if(caseInt.Status__c == ABHFL_Constants.SUCCESS){
            isTransferred = ABCL_IntegrationCommonUtility.transferAttachments(caseInt);
            if(caseRecord!=null){
                if(isTransferred){
                    integrationFailure = false;
                    List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id, Additional_Email_Templates__c, Additional_SMS_Metadata__c
                                                                   FROM ASF_Case_Category_Config__c 
                                                                   WHERE CCC_External_Id__c =:caseRecord.CCC_External_Id__c ];
                    
                    Map<String, String> emailTemplateMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_Email_Templates__c);
                    Map<String, String> smsMetadataMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_SMS_Metadata__c);

                    Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord,
                                                                                                                            emailTemplateMap.get('Resolved'), 
                                                                                                                            smsMetadataMap.get('Resolved'),
                                                                                                                            true); 

                    caseRecord.MoveToNext__c = true;
                    update caseRecord;       
                } 
            }
        }
        else if(caseInt.Status__c == ABHFL_Constants.FAILURE) {
            handleFailure(caseRecord, integrationName); 
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

    public void handleFailure(Case caseRecord, String integrationName) {
        if(caseRecord.Source__c == ABHFL_Constants.BRANCH){
            caseRecord.OwnerId = caseRecord.CreatedById;
            ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRecord,integrationName,null);
        } else {
            Group csQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Customer_Service_Team'  Limit 1];
            caseRecord.OwnerId = csQueue.Id;
        }
        if(Schema.sObjectType.Case.isUpdateable()){
            update caseRecord;    
        } 
    }
}