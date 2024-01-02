/*********************************************************
 *Class        :  ABFL_InvokeSTPProcess
 *Author       :  Aditee Churiwala
 *Description  :  Update STP Flow
 *********************************************************/
public with sharing class ABFL_InvokeSTPProcess implements ASF_IntegrationInvocable{
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
        System.debug('In evaluate');
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
        System.debug('In run');
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();

        //Cancel existing records in ASF_Case_Integration__c
        //Canceling will call the trigger
        ASF_IntegrationsController.cancelPendingCaseIntegrations(caseRec.Id, integ.External_Id__c);

        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Case__c = caseRec.Id;
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Status__c = ABFL_Constants.PENDING;
        caseInt.Response__c = ABFL_Constants.WAITING_API_RESPONSE;
        insert caseInt;

        System.debug('@@@@case' + caseInt);
        System.debug('@@@@case' + integ.STP_API_Identifier__c);

        //Fire Actual Integration---Begins
        ABFL_STP_APIImplementation.callout(integ, caseRec);
        //Fire Actual Integration---Ends

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

        if (caseInteg.Status__c == ABFL_Constants.SUCCESS){
            Case caseRecord = ABFL_SOQL_Case.getCaseInfo(caseInteg.Case__c);

            //Attach the file to case (Attaching the files on case on both the scenarios due to current implementation of the framework)
            Boolean isTransferred = ABCL_IntegrationCommonUtility.transferAttachments(caseInteg);

            //If source of case is "RM-no email" then attach the pdf to case and auto-close the case after 24 hours.
            if (caseRecord.Source__c == ABFL_Constants.RM_NO_EMAIL){

                //Auto close the case after 24 hours (Handled via record trigger flow on ABFL_Case_Detail__c)
                ABFL_Case_Detail__c caseDetailRecord = new ABFL_Case_Detail__c();
                caseDetailRecord.Id = caseRecord.ABFL_Case_Detail__c;
                caseDetailRecord.Closure_Time__c = System.now();
                caseDetailRecord.Autoclosed__c = true;

                update caseDetailRecord;
                System.debug('Case detail updated');

                //If source of case is not "RM-no email" then send the PDF in an email to the customer and auto close the Case immediately
            } else{
                if (isTransferred){
                    List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id, CCC_External_Id__c, Resolved_Case_Email_Template__c
                                                                   FROM ASF_Case_Category_Config__c
                                                                   WHERE CCC_External_Id__c = :caseRecord.CCC_External_Id__c
                                                                   WITH SECURITY_ENFORCED];
                    Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord, cccRecord[0].Resolved_Case_Email_Template__c, null, isTransferred);
                }
                //close the case
                caseRecord.MoveToNext__c = true;
                update caseRecord;
            }
        }
    }
}