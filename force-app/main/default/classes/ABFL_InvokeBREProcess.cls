/*********************************************************
*Class        :  ABFL_InvokeBREProcess 
*Author       :  Aditee Churiwala
*Description  :  Update STP Flow - BRE
*********************************************************/
public with sharing class ABFL_InvokeBREProcess implements ASF_IntegrationInvocable {
    /****************************************************************************************************************
    * @LOB - ABFL
    * @Function - evaluate
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @Description - This method will be used to evaluate criteria for BRE API invocations.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = ABFL_Constants.SUCCESS;
        result.response = ABFL_Constants.EVALUATION_SUCCESS;

        Case caseRecord = ABFL_SOQL_Case.getCaseInfo(caseRec.Id);
        // * Manual fulfillment, will be handled by default queue specified on case stage.
        //Integer assetCount = ABFL_SOQL_Case.getLANCount(caseRecord.AccountId);
        if(caseRecord.AssetId == null) { // Check LAN
            //Proceed to manual fulfilment
            result.status = ABFL_Constants.ERROR;
            result.response = ABFL_Constants.EVALUATION_FAILED_LAN_ERROR;
        }
        else if(caseRecord.ABFL_Case_Detail__r.IsSMT__c) { // Check trailFlag
            //Proceed to manual fulfilment if yes
            result.status = ABFL_Constants.ERROR;
            result.response = ABFL_Constants.EVALUATION_FAILED_SMT_ERROR;
        }
        else if(caseRecord.ABFL_Case_Detail__r.Autoclosure_IN_RR__c) { // Check trailFlag
            //Proceed to manual fulfilment if yes
            result.status = ABFL_Constants.ERROR;
            result.response = ABFL_Constants.EVALUATION_FAILED_AUTOCLOSURE;
        } 
        else if(caseRecord.ABFL_Case_Detail__r.IsRegisteredCustomer__c != null && caseRecord.ABFL_Case_Detail__r.IsRegisteredCustomer__c?.equalsIgnoreCase(ABFL_Constants.NO)) { // Check Registered Customer
            //No --- Proceed to manual fulfilment
            result.status = ABFL_Constants.ERROR;
            result.response = ABFL_Constants.EVALUATION_FAILED_IS_REGIS_ERROR;
        }
        return result;
    }
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        
        //Case caseRecord = ABFL_SOQL_Case.getCaseInfo(caseRec.Id);
        List<Case> caseRecords = new List<Case>();
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }

        for(Case caseRecord : caseRecords){
            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            // * Manual fulfillment, will be handled by default queue specified on case stage.
            //Integer assetCount = ABFL_SOQL_Case.getLANCount(caseRecord.AccountId);
            result.status = ABFL_Constants.SUCCESS;
            result.response = ABFL_Constants.EVALUATION_SUCCESS;
            if(caseRecord.AssetId == null) { // Check LAN
                //Proceed to manual fulfilment
                result.status = ABFL_Constants.ERROR;
                result.response = ABFL_Constants.EVALUATION_FAILED_LAN_ERROR;
            }
            else if(caseRecord.ABFL_Case_Detail__r.IsSMT__c) { // Check trailFlag
                //Proceed to manual fulfilment if yes
                result.status = ABFL_Constants.ERROR;
                result.response = ABFL_Constants.EVALUATION_FAILED_SMT_ERROR;
            }
            else if(caseRecord.ABFL_Case_Detail__r.Autoclosure_IN_RR__c) { // Check trailFlag
                //Proceed to manual fulfilment if yes
                result.status = ABFL_Constants.ERROR;
                result.response = ABFL_Constants.EVALUATION_FAILED_AUTOCLOSURE;
            } 
            else if(caseRecord.ABFL_Case_Detail__r.IsRegisteredCustomer__c != null && caseRecord.ABFL_Case_Detail__r.IsRegisteredCustomer__c?.equalsIgnoreCase(ABFL_Constants.NO)) { // Check Registered Customer
                //No --- Proceed to manual fulfilment
                result.status = ABFL_Constants.ERROR;
                result.response = ABFL_Constants.EVALUATION_FAILED_IS_REGIS_ERROR;
            }
            resultMap.put(caseRecord.Id, result);
        }
        return resultMap;
    }
    /****************************************************************************************************************
    * @LOB - ABFL
    * @Function - run
    * @param integ - ASF_Integration record.
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @Description - Invoked from the ASF_IntegrationsController class, this method runs the STP integration and creates Case Integration record.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integRec, Case caseRec){
        
        // Perform additional checks as per STP identifier i.e. integration
        ASF_IntegrationsController.IntegrationWrapper result = doAdditionalChecks(integRec, caseRec);

        if(result.status==NULL){ // i.e. Additional check were successful
        
            //Cancel existing records in ASF_Case_Integration__c
            ASF_IntegrationsController.cancelPendingCaseIntegrations(caseRec.Id, integRec.External_Id__c);

            if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
                insert new ASF_Case_Integration__c(
                    Case__c  = caseRec.Id,
                    Integration_Ext_Id__c = integRec.External_Id__c,
                    Status__c = ABFL_Constants.PENDING,
                    Type__c = 'BRE', // Identifier needs to be passed to middleware
                    Response__c = ABFL_Constants.WAITING_API_RESPONSE
                );
            }
            ABFL_BRE_APIImplementation.callout(integRec, caseRec);
        }
        // Fire Actual Integration---Ends
        
        result.status = ABFL_Constants.SUCCESS;
        result.response = ABFL_Constants.WAITING_API_RESPONSE;
        return result;
    }
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();

        // Perform additional checks as per STP identifier i.e. integration
        //ASF_IntegrationsController.IntegrationWrapper result = doAdditionalChecks(integRec, caseRec);

        //if(result.status==NULL){ // i.e. Additional check were successful
        
            //Cancel existing records in ASF_Case_Integration__c
            //ASF_IntegrationsController.cancelPendingCaseIntegrations(caseRec.Id, integRec.External_Id__c);
        Set<String> intIds = new Set<String>();
        for(Case caseRec : caseRecs){
            for(ASF_Integration__c integ : integs.get(caseRec.Id)){
                if(integ.Processing_Class__c == 'ABFL_InvokeBREProcess'){
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
        for(Case caseRec : caseRecords){
            for(ASF_Integration__c integ : integs.get(caseRec.Id))
            {
                if(integ.Processing_Class__c == 'ABFL_InvokeBREProcess'){
                    ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
                    caseInt.Case__c  = caseRec.Id;
                    caseInt.Integration_Ext_Id__c = integ.External_Id__c;
                    caseInt.Status__c = ABFL_Constants.PENDING;
                    caseInt.Type__c = 'BRE';
                    caseInt.Response__c = ABFL_Constants.WAITING_API_RESPONSE;
                    newCaseIntegrations.add(caseInt);
                }
            }
        }

        insert newCaseIntegrations;
        Map<Id, List<ASF_Case_Integration__c>> caseIdToCaseInts = new Map<Id, List<ASF_Case_Integration__c>>();
        for(ASF_Case_Integration__c caseInt : [SELECT Name, Case__c FROM ASF_Case_Integration__c WHERE Id IN :newCaseIntegrations ])
        {
            if(!caseIdToCaseInts.containsKey(caseInt.Case__c)){
                caseIdToCaseInts.put(caseInt.Case__c, new List<ASF_Case_Integration__c>());
            }
            caseIdToCaseInts.get(caseInt.Case__c).add(caseInt);
        }
        List<Case_Integration_Outbound__e> peList = new List<Case_Integration_Outbound__e>();
        for(Case caseRec : caseRecords){
            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            result.status = ABFL_Constants.SUCCESS;
            result.response = ABFL_Constants.WAITING_API_RESPONSE;
            resultMap.put(caseRec.Id, result);
            for(ASF_Integration__c integ : integs.get(caseRec.Id))
            {
                Case_Integration_Outbound__e peRec = ABFL_BRE_APIImplementation.callout(integ, caseRec, caseIdToCaseInts.get(caseRec.Id));
                if(peRec != null){
                    peList.add(peRec);
                }
            }
        }
        if(!peList.isEmpty()){
            List<Database.SaveResult> publishResults = EventBus.publish(peList);
        }
        //}
        // Fire Actual Integration---Ends
        
        
        return resultMap;
    }

    /****************************************************************************************************************
    * @LOB - ABFL
    * @Function - doAdditionalChecks
    * @param caseInteg - ASF_Case_Integration record.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @Description - Invoked to do Additional check for 
    *****************************************************************************************************************/
    private ASF_IntegrationsController.IntegrationWrapper doAdditionalChecks(ASF_Integration__c integ, Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        // Get case record for date validations
        // ! Not applicable for now
        // Case caseRecord = ABFL_SOQL_Case.getCaseInfo(caseRec.Id);
        // switch on integ.STP_API_Identifier__c {
        //     when 'BRE_ProInterestCert_Retail' {
        //         if(caseRecord.ABFL_Case_Detail__r.From_Date__c==NULL || caseRecord.ABFL_Case_Detail__r.To_Date__c==NULL){
        //             //Proceed to manual fulfilment
        //             // Todo: Remove hardcoding
        //             result.status = ABFL_Constants.ERROR;
        //             result.response = 'Please add required date field values.';
        //         }
        //     }
        // }
        return result;
    }

    /****************************************************************************************************************
    * @LOB - ABFL
    * @Function - processResponse
    * @param caseInteg - ASF_Case_Integration record.
    * @return - void.
    * @Description - Invoked when status Case Intg is updated to success, it processes the response of the integration received.
    *****************************************************************************************************************/
    public void processResponse(ASF_Case_Integration__c caseInteg){
        try {
            if(caseInteg.Status__c == ABFL_Constants.SUCCESS) {
                Case caseRecord = ABFL_SOQL_Case.getCaseInfo(caseInteg.Case__c);
                ASF_Integration__c intg = ABFL_SOQL_Integration.getIntegrationInfo(caseInteg.Integration_Ext_Id__c);
                Map<Id, ASF_CaseMovementHelper.StageWrapper> resultWrap = new Map<Id, ASF_CaseMovementHelper.StageWrapper>();
                //Update Case Int from Response
                // Assume the following response from Integration
                String val = '{"STPFlag":"STP_SUCCESS", "STPDescription":"STPDescription", "DocumentURL":"https://docs.google.com/spreadsheets/d/1Nd2-XHHwWzsmRnSnR7O4UEYqv5wzigMXN27ftYqQ2C8/edit#gid=0"}';
                ResponseWrapper jsonMap = (ResponseWrapper)JSON.deserialize(caseInteg.Response__c, ResponseWrapper.class);
                List<Case> caseListToUpdate = new List<Case>();
                List<ABFL_Case_Detail__c> caseDetailListToUpdate = new List<ABFL_Case_Detail__c>();
                Boolean isUpdateCase = false;
               
                if(jsonMap.stpFlag == ABFL_Constants.BRESUCCESS && caseRecord.Source__c == ABFL_Constants.RM_NO_EMAIL) {
                    //Update Document URL on ABFL Case detail, proceed to manual fulfilment
                    caseDetailListToUpdate.add(
                        new ABFL_Case_Detail__c(Id=caseRecord.ABFL_Case_Detail__c, Document_URL__c = jsonMap.documentURL)
                    );
                    // * Manual fulfillment, will be handled by default queue specified on case stage.
                }
                else if(jsonMap.stpFlag == ABFL_Constants.BRESUCCESS && caseRecord.Source__c  == ABFL_Constants.IVR_NO_EMAIL) {
                    //Update Document URL on ABFL Case detail, proceed to next stage.
                    caseDetailListToUpdate.add(
                        new ABFL_Case_Detail__c(Id=caseRecord.ABFL_Case_Detail__c, Document_URL__c = jsonMap.documentURL,
                                            Resolution_Comments__c = System.Label.ABFL_RESOLVED_STP)
                    );
                    isUpdateCase = true;
                }
                else if(jsonMap.stpFlag == ABFL_Constants.BRESUCCESS) {
                    //Sync the email tagged to Case record US-121
                    isUpdateCase = true;
                    caseDetailListToUpdate.add(
                        new ABFL_Case_Detail__c(Id=caseRecord.ABFL_Case_Detail__c,
                                            Resolution_Comments__c = System.Label.ABFL_RESOLVED_STP)
                    );
                }


                if(Schema.sObjectType.ABFL_Case_Detail__c.isUpdateable() && caseDetailListToUpdate.size() > 0){
                    update caseDetailListToUpdate;
                }
                if(Schema.sObjectType.Case.isUpdateable() && isUpdateCase) {
                    resultWrap = ASF_CaseMovementHelper.moveToForwardStage(new List<Case> {caseRecord}, new Map<Id, String>{caseRecord.Id => 'Resolved'}, 
                                                                           new Map<Id, String>{caseRecord.Id => 'Open'});
                    System.debug('@@@resultWrap'+resultWrap);
                    resultWrap.get(caseRecord.Id).caseToBeUpdated.OwnerId = Userinfo.getuserId();
                    update resultWrap.get(caseRecord.Id)?.caseToBeUpdated;
                }
                
                if(intg.STP_Config_External_Id__c != null && jsonMap.stpFlag == ABFL_Constants.BRESUCCESS)  {
                        createCase(intg.STP_Config_External_Id__c, caseRecord);
                }
                /*User us = [SELECT Id FROM User where username = 'admin-dev@example.com.dev'];
                caseRecord.OwnerId = us.Id;
                update caseRecord;*/
            }
        }
        catch(Exception e) {
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABFL_InvokeBREProcess.processResponse');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
        }
       
    }
    public void createCase(String externalId, Case caseRec) {
        List<ASF_Case_Category_Config__c> cccRec = ASF_CaseQueryHandler.getCaseCategoryConfigs(new List<String>{externalId});
        if(!cccRec.isEmpty()) {
            //create Case detail
            ABFL_Case_Detail__c detail = new ABFL_Case_Detail__c(IsRegisteredCustomer__c = 'Yes');
            if(Schema.sObjectType.ABFL_Case_Detail__c.isCreateable()) {

                insert detail;
            } 

            //Create Case
            if(Schema.sObjectType.Case.isCreateable()) {
                insert new Case(CCC_External_Id__c = cccRec[0].CCC_External_Id__c, Technical_Source__c = ABFL_Constants.API, 
                                parentId = caseRec.Id, AssetId = caseRec.AssetId, AccountId = caseRec.AccountId,
                                Business_Unit__c = caseRec.Business_Unit__c, LAN__c = caseRec.LAN__c,
                                ABFL_Case_Detail__c = detail.Id, Source__c = ABFL_Constants.SOURCE,
                                Description = ABFL_Constants.DESCRIPTION_MSG);
            }           
        }   
    }
    public class ResponseWrapper {
        public String ticketNo;
        public String sTPFlag;
        public String sTPDescription;
        public String documentURL;
    }
}