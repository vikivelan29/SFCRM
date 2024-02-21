/*********************************************************
 *Class        :  ABFL_InvokeSTPProcess
 *Author       :  Aditee Churiwala
 *Description  :  Update STP Flow
 *********************************************************/
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
                ASF_CaseMovementHelper.StageWrapper resultWrap = new ASF_CaseMovementHelper.StageWrapper();

                //Attach the file to case (Attaching the files on case on both the scenarios due to current implementation of the framework)
                Boolean isTransferred = ABCL_IntegrationCommonUtility.transferAttachments(caseInteg);

                //If source of case is "RM-no email" then attach the pdf to case and auto-close the case after 24 hours.
                if (caseRecord.Source__c == ABFL_Constants.RM_NO_EMAIL){

                    //Auto close the case after 24 hours (Handled via record trigger flow on ABFL_Case_Detail__c)
                    ABFL_Case_Detail__c caseDetailRecord = new ABFL_Case_Detail__c();
                    caseDetailRecord.Id = caseRecord.ABFL_Case_Detail__c;
                    caseDetailRecord.Closure_Time__c = System.now();
                    caseDetailRecord.Autoclosed__c = true;
                    caseDetailRecord.Resolution_Comments__c = 'Resolved by STP';
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
                            caseDetailRecord.Resolution_Comments__c = 'Resolved by STP';
                            update caseDetailRecord;

                            resultWrap = ASF_CaseMovementHelper.moveToForwardStage(caseRecord, 'Resolved', 'Open');
                            update resultWrap.caseToBeUpdated;
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

        for (Case caseRecord : caseList){
            ASF_CaseMovementHelper.StageWrapper resultWrap = new ASF_CaseMovementHelper.StageWrapper();
            resultWrap = ASF_CaseMovementHelper.moveToForwardStage(caseRecord, 'Resolved', 'Open');
            casesToUpdateList.add(resultWrap.caseToBeUpdated);
        }

        if (casesToUpdateList.size() > 0){
            if (Schema.sObjectType.Case.isUpdateable()){
                update casesToUpdateList;
            }
        }
    }

}