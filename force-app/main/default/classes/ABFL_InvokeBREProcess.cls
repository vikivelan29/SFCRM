/*********************************************************
*Class        :  ABFL_InvokeBREProcess 
*Author       :  Aditee Churiwala
*Description  :  Update STP Flow - BRE
*********************************************************/
public with sharing class ABFL_InvokeBREProcess implements ASF_IntegrationInvocable {
    // Response enum
    public enum Response {STP_SUCCESS, STP_FAILURE, STP_VALIDATION_ERROR, STP_CLOSURE_IN_PROGRESS}
   
    /****************************************************************************************************************
    * @LOB - ABFL
    * @Function - evaluate
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @Description - This method will be used to evaluate criteria for BRE API invocations.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        System.debug('***ABFL_InvokeBREProcess'+caseRec);
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = ABFL_Constants.SUCCESS;
        result.response = ABFL_Constants.EVALUATION_SUCCESS;

        Case caseRecord = ABFL_SOQL_Case.getCaseInfo(caseRec.Id);
        // * Manual fulfillment, will be handled by default queue specified on case stage.
        //Integer assetCount = ABFL_SOQL_Case.getLANCount(caseRecord.AccountId);
        if(caseRecord.LAN__c == null || caseRecord.LAN__c == '' || caseRecord.LAN__c == 'NA') { // Check LAN
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
        else if(!caseRecord.ABFL_Case_Detail__r.IsRegisteredCustomer__c) { // Check Registered Customer
            //No --- Proceed to manual fulfilment
            result.status = ABFL_Constants.ERROR;
            result.response = ABFL_Constants.EVALUATION_FAILED_IS_REGIS_ERROR;
        }
        System.debug('***ABFL_InvokeBREProcess:result>'+result);
        return result;
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
        
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        
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
        // System.debug('@@@@case'+integRec.ABFL_BRE_CalloutClass__c);

        // Fire Actual Integration---Begins

       // Type customType = Type.forName(integRec.ABFL_BRE_CalloutClass__c);
       // ABFL_BRECallouts instance = (ABFL_BRECallouts)customType.newInstance();
        // invoke api - via platform events
        ABFL_BRE_APIImplementation.callout(integRec, caseRec);
        
        // Fire Actual Integration---Ends
        
        result.status = ABFL_Constants.SUCCESS;
        result.response = ABFL_Constants.WAITING_API_RESPONSE;
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
        System.debug('***processResponse invoked.');
        try {
            if(caseInteg.Status__c == ABFL_Constants.SUCCESS) {
                Case caseRecord = ABFL_SOQL_Case.getCaseInfo(caseInteg.Case__c);
                ASF_Integration__c intg = ABFL_SOQL_Integration.getIntegrationInfo(caseInteg.Integration_Ext_Id__c);
                
                //Update Case Int from Response
                // Assume the following response from Integration
                String val = '{"STPFlag":"STP_SUCCESS", "STPDescription":"STPDescription", "DocumentURL":"https://docs.google.com/spreadsheets/d/1Nd2-XHHwWzsmRnSnR7O4UEYqv5wzigMXN27ftYqQ2C8/edit#gid=0"}';
                ResponseWrapper jsonMap = (ResponseWrapper)JSON.deserialize(caseInteg.Response__c, ResponseWrapper.class);
                System.debug('@@jsonMap'+jsonMap);
                List<Case> caseListToUpdate = new List<Case>();
                List<ABFL_Case_Detail__c> caseDetailListToUpdate = new List<ABFL_Case_Detail__c>();
                Boolean isUpdateCase = false;
               
                if(jsonMap.stpFlag == Response.STP_SUCCESS.name() && caseRecord.Source__c == ABFL_Constants.RM_NO_EMAIL) {
                    //Update Document URL on ABFL Case detail, proceed to manual fulfilment
                    caseDetailListToUpdate.add(
                        new ABFL_Case_Detail__c(Id=caseRecord.ABFL_Case_Detail__c, Document_URL__c = jsonMap.documentURL)
                    );
                    // * Manual fulfillment, will be handled by default queue specified on case stage.
                }
                else if(jsonMap.stpFlag == Response.STP_SUCCESS.name() && caseRecord.Source__c  == ABFL_Constants.IVR_NO_EMAIL) {
                    //Update Document URL on ABFL Case detail, proceed to next stage.
                    caseDetailListToUpdate.add(
                        new ABFL_Case_Detail__c(Id=caseRecord.ABFL_Case_Detail__c, Document_URL__c = jsonMap.documentURL,
                                            Resolution_Comments__c = 'Resolved')
                    );
                    isUpdateCase = true;
                }
                else if(jsonMap.stpFlag == Response.STP_SUCCESS.name()) {
                    //Sync the email tagged to Case record US-121
                    isUpdateCase = true;
                    caseDetailListToUpdate.add(
                        new ABFL_Case_Detail__c(Id=caseRecord.ABFL_Case_Detail__c,
                                            Resolution_Comments__c = 'Resolved')
                    );
                }

                if(Schema.sObjectType.ABFL_Case_Detail__c.isUpdateable() && isUpdateCase) {
                    resultWrap = ASF_CaseMovementHelper.moveToForwardStage(caseRecord.Id, 'Resolved');
                    System.debug('@@@@Inside run STP Flow'+resultWrap);
                    update resultWrap?.caseToBeUpdated;
               
                }
                if(Schema.sObjectType.Case.isUpdateable() && caseDetailListToUpdate.size() > 0){
                    update caseDetailListToUpdate;
                }
                if(intg.STP_Config_External_Id__c != null && jsonMap.stpFlag == Response.STP_SUCCESS.name())  {
                        createCase(intg.STP_Config_External_Id__c, caseRecord);
                }
            }
        }
        catch(Exception ex) {
            System.debug(ex.getMessage());
        }
       
    }
    public void createCase(String externalId, Case caseRec) {
        List<ASF_Case_Category_Config__c> cccRec = ASF_CaseQueryHandler.getCaseCategoryConfigs(new List<String>{externalId});
        if(!cccRec.isEmpty()) {
            //create Case detail
            ABFL_Case_Detail__c detail = new ABFL_Case_Detail__c(IsRegisteredCustomer__c = true);
            if(Schema.sObjectType.ABFL_Case_Detail__c.isCreateable()) {

                insert detail;
            }    

            //Create Case
            if(Schema.sObjectType.Case.isCreateable()) {
                insert new Case(CCC_External_Id__c = cccRec[0].CCC_External_Id__c, Technical_Source__c = 'API', 
                                parentId = caseRec.Id, AssetId = caseRec.AssetId,
                                Source__c = caseRec.Source__c, AccountId = caseRec.AccountId,
                                Business_Unit__c = caseRec.Business_Unit__c, LAN__c = caseRec.LAN__c,
                                ABFL_Case_Detail__c = detail.Id);
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