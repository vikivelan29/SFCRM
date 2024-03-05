/*********************************************************
 *Class        :  ABFL_InvokeSTPProcess
 *Author       :  Udit Singhal
 *Description  :  Update STP Flow
 *********************************************************/
//@SuppressWarnings('PMD.CognitiveComplexity', 'PMD.AvoidDeeplyNestedIfStmts')
public without sharing class ABFL_InvokeSTPProcess implements ASF_IntegrationInvocable{
    public enum Response{
        STP_SUCCESS, 
        STP_FAILURE, 
        STP_VALIDATION_ERROR, 
        STP_CLOSURE_IN_PROGRESS
    }

    /****************************************************************************************************************
     * @LOB - ABFL
     * @Function - evaluate
     * @param caseRec - Case record from the framework.
     * @return - ASF_IntegrationsController.IntegrationWrapper.
     * @Description - Invoked from the ASF_IntegrationsController class
     *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = ABFL_Constants.SUCCESS;
        result.response = ABFL_Constants.EVALUATION_SUCCESS;

        return result;
    }
     public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        for(Case caseRecord : caseRecs){
            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            result.status = ABFL_Constants.SUCCESS;
            result.response = ABFL_Constants.EVALUATION_SUCCESS;
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
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integ, Case caseRec){

        //Get case record for validation
        Case caseRecord = ABFL_SOQL_Case.getCaseInfo(caseRec.Id);
        // Perform additional checks as per STP identifier i.e. integration
        ASF_IntegrationsController.IntegrationWrapper result = doAdditionalChecks(integ, caseRecord);

        if (result.status == NULL){
            // i.e. Additional check were successful
            //Cancel existing records in ASF_Case_Integration__c - Canceling will call the trigger
            ASF_IntegrationsController.cancelPendingCaseIntegrations(caseRec.Id, integ.External_Id__c);

            ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c(
                Case__c = caseRec.Id, 
                Integration_Ext_Id__c = integ.External_Id__c, 
                Status__c = ABFL_Constants.PENDING, 
                Response__c = ABFL_Constants.WAITING_API_RESPONSE
            );
			if (integ.STP_API_Identifier__c == 'SOA_Corp' || integ.STP_API_Identifier__c == 'InterestDebitNote_Corp'){
                caseInt.Is_Validation_Success__c = true;
            }    
            if (Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
                insert caseInt;
            }

            //Fire Actual Integration---Begins
            ABFL_STP_APIImplementation.callout(integ, caseRecord);
            //Fire Actual Integration---Ends

            result.status = ABFL_Constants.SUCCESS;
            result.response = ABFL_Constants.WAITING_API_RESPONSE;
        }
        return result;
    }
     public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();

        //Get case record for validation
        //Case caseRecord = ABFL_SOQL_Case.getCaseInfo(caseRec.Id);
        List<Case> caseRecords = new List<Case>();
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }

        List<Case> addlCheckPassedCases = new List<Case>();
        for(Case caseRecord : caseRecords){
            for(ASF_Integration__c integ : integs.get(caseRecord.Id)){
                // Perform additional checks as per STP identifier i.e. integration
                ASF_IntegrationsController.IntegrationWrapper result = doAdditionalChecks(integ, caseRecord);
                if (result.status == NULL){
                    addlCheckPassedCases.add(caseRecord);
                }
                resultMap.put(caseRecord.Id, result);
            }
        }
        if(!addlCheckPassedCases.isEmpty()){
            // i.e. Additional check were successful
            Set<String> intIds = new Set<String>();
            for(Case caseRec : addlCheckPassedCases){
                for(ASF_Integration__c integ : integs.get(caseRec.Id)){
                    intIds.add(integ.External_Id__c);
                }
            }

            List<ASF_Case_Integration__c> existingCaseIntegrations = new List<ASF_Case_Integration__c>();
            for(ASF_Case_Integration__c caseInt : [SELECT Id, Status__c, Case__c, Integration_Ext_Id__c FROM ASF_Case_Integration__c
                                                    WHERE Case__c IN :addlCheckPassedCases 
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

            //Cancel existing records in ASF_Case_Integration__c - Canceling will call the trigger
            //ASF_IntegrationsController.cancelPendingCaseIntegrations(caseRec.Id, integ.External_Id__c);
            ASF_TriggerSkipperUtility.markTriggerRun('ASF_Case_Integration__c');
            update existingCaseIntegrations;
            ASF_TriggerSkipperUtility.resetTriggerRun('ASF_Case_Integration__c');

            List<ASF_Case_Integration__c> newCaseIntegrations = new List<ASF_Case_Integration__c>();
            for(Case caseRec : addlCheckPassedCases){
                for(ASF_Integration__c integ : integs.get(caseRec.Id))
                {
                    ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c(
                        Case__c = caseRec.Id, 
                        Integration_Ext_Id__c = integ.External_Id__c, 
                        Status__c = ABFL_Constants.PENDING, 
                        Response__c = ABFL_Constants.WAITING_API_RESPONSE
                    );
                    if (integ.STP_API_Identifier__c == 'SOA_Corp' || integ.STP_API_Identifier__c == 'InterestDebitNote_Corp'){
                        caseInt.Is_Validation_Success__c = true;
                    }
                    newCaseIntegrations.add(caseInt);
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
            for(Case caseRec : addlCheckPassedCases){
                ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
                result.status = ABFL_Constants.SUCCESS;
                result.response = ABFL_Constants.WAITING_API_RESPONSE;
                resultMap.put(caseRec.Id, result);
                for(ASF_Integration__c integ : integs.get(caseRec.Id))
                {
                    Case_Integration_Outbound__e peRec = ABFL_STP_APIImplementation.callout(integ, caseRec, caseIdToCaseInts.get(caseRec.Id));
                    if(peRec != null){
                        peList.add(peRec);
                    }
                }
            }

            if(!peList.isEmpty()){
                List<Database.SaveResult> publishResults = EventBus.publish(peList);
            }
        }
        return resultMap;
    }

    /****************************************************************************************************************
     * @LOB - ABFL
     * @Function - doAdditionalChecks
     * @param integ - ASF_Integration record.
     * @param caseRecord - Case record from the framework.
     * @return - ASF_IntegrationsController.IntegrationWrapper.
     * @Description - Invoked from the run method, this method is used to perform additional checks before creating the case integration record
     *****************************************************************************************************************/
    private ASF_IntegrationsController.IntegrationWrapper doAdditionalChecks(ASF_Integration__c integ, Case caseRecord){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();

        if ((integ.STP_API_Identifier__c == 'SOA_Corp' || integ.STP_API_Identifier__c == 'InterestDebitNote_Corp') && (caseRecord.ABFL_Case_Detail__r.From_Date__c == NULL || caseRecord.ABFL_Case_Detail__r.To_Date__c == NULL)){
            //Proceed to manual fulfilment
            result.status = ABFL_Constants.ERROR;
            result.response = ABFL_Constants.BLANK_DATE_FIELD;
        }
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
        try{
            if (caseInteg.Status__c == ABFL_Constants.SUCCESS){
                Case caseRecord = ABFL_SOQL_Case.getCaseInfo(caseInteg.Case__c);
                Map<Id, ASF_CaseMovementHelper.StageWrapper> resultWrap = new Map<Id, ASF_CaseMovementHelper.StageWrapper>();

                //Attach the file to case (Attaching the files on case on both the scenarios due to current implementation of the framework)
                Boolean isTransferred = ABCL_IntegrationCommonUtility.transferAttachments(caseInteg);

                //If source of case is "RM-no email" then attach the pdf to case and auto-close the case after 24 hours.
                if (caseRecord.Source__c == ABFL_Constants.RM_NO_EMAIL){

                    //Auto close the case after 24 hours (Handled via record trigger flow on ABFL_Case_Detail__c)
                    ABFL_Case_Detail__c caseDetailRecord = new ABFL_Case_Detail__c();
                    caseDetailRecord.Id = caseRecord.ABFL_Case_Detail__c;
                    caseDetailRecord.Closure_Time__c = System.now();
                    caseDetailRecord.Autoclosed__c = true;
                    caseDetailRecord.Resolution_Comments__c = System.Label.ABFL_RESOLVED_STP;
                    if (Schema.sObjectType.ABFL_Case_Detail__c.isUpdateable()){
                        update caseDetailRecord;
                    }

                    //If source of case is not "RM-no email" then send the PDF in an email to the customer and auto close the Case immediately
                } else if (isTransferred){
                    // Get template stored on asf_integration record
                    System.debug('***Integration_Ext_Id__c' + caseInteg.Integration_Ext_Id__c);
                    ASF_Integration__c intRec = [SELECT Id, STP_Template__c
                                                 FROM ASF_Integration__c
                                                 WHERE External_Id__c = :caseInteg.Integration_Ext_Id__c
                                                 WITH SECURITY_ENFORCED];
                    // List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id, CCC_External_Id__c, Resolved_Case_Email_Template__c,
                    //                                                New_Case_Email_Template__c
                    //                                                FROM ASF_Case_Category_Config__c
                    //                                                WHERE CCC_External_Id__c = :caseRecord.CCC_External_Id__c
                    //                                                WITH SECURITY_ENFORCED];
                    if (String.isNotBlank(intRec.STP_Template__c)){
                        Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord, intRec.STP_Template__c, null, isTransferred);

                        Boolean isEmailSentToCustomer = true;

                        if (!platformEventResult.isSuccess()){
                            isEmailSentToCustomer = false;
                        }

                        if (isEmailSentToCustomer){
                            ABFL_Case_Detail__c caseDetailRecord = new ABFL_Case_Detail__c();
                            caseDetailRecord.Id = caseRecord.ABFL_Case_Detail__c;
                            caseDetailRecord.Resolution_Comments__c = System.Label.ABFL_RESOLVED_STP;
                            update caseDetailRecord;

                            resultWrap = ASF_CaseMovementHelper.moveToForwardStage(new List<Case> {caseRecord}, new Map<Id, String>{caseRecord.Id => 'Resolved'}, 
                                                                           new Map<Id, String>{caseRecord.Id => 'Open'});
                            System.debug('@@@resultWrap'+resultWrap);
                            resultWrap.get(caseRecord.Id).caseToBeUpdated.OwnerId = Userinfo.getuserId();
                            update resultWrap.get(caseRecord.Id).caseToBeUpdated;
                        }
                    }
                }
            }
        } catch (Exception e){
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABFL_InvokeSTPProcess.processResponse');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
        }
    }

    /****************************************************************************************************************
     * @LOB - ABFL
     * @Function - closeSTPCaseFromFlow
     * @param caseInteg - List of ABFL_Case_Detail__c Ids
     * @return - void.
     * @Description - Invoked from flow to close the case
     *****************************************************************************************************************/
    @InvocableMethod(label = 'Close Related Cases')
    public static void closeSTPCaseFromFlow(List<Id> caseDetailList){
        List<Case> casesToUpdateList = new List<Case>();

        List<Case> caseList = [SELECT Id, CCC_External_Id__c
                               FROM Case
                               WHERE ABFL_Case_Detail__c IN:caseDetailList AND IsClosed = FALSE
                               WITH SYSTEM_MODE];

        List<User> userList = ABFL_SOQL_Util.getUserInfo(System.label.ABCL_Integration_User_Nickname);

        for (Case caseRecord : caseList){
            Map<Id, ASF_CaseMovementHelper.StageWrapper> resultWrap = new Map<Id, ASF_CaseMovementHelper.StageWrapper>();
            resultWrap = ASF_CaseMovementHelper.moveToForwardStage(new List<Case> {caseRecord}, new Map<Id, String>{caseRecord.Id => 'Resolved'}, 
                                                                           new Map<Id, String>{caseRecord.Id => 'Open'});
            System.debug('@@@resultWrap'+resultWrap);
            if(userList != null && userList.size() > 0) {
                resultWrap.get(caseRecord.Id).caseToBeUpdated.OwnerId = userList[0].Id;
            }
            casesToUpdateList.add(resultWrap.get(caseRecord.Id).caseToBeUpdated);
        }

        if (casesToUpdateList.size() > 0){
            if (Schema.sObjectType.Case.isUpdateable()){
                update casesToUpdateList;
            }
        }
    }

}