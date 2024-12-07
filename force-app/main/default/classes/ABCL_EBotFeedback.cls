/*********************************************************
*Class        :  ABCL_EBotFeedback
*Author       :  Anirudh Raturi
*Created Date :  21/12/2023
*Last Modified:  21/12/2023
*Description  :  Class for EBot Feedback Integration
*********************************************************/

public with sharing class ABCL_EBotFeedback implements ASF_IntegrationInvocable{

    public Case getCaseRec(String caseId){
        Case caseRecord = [
            SELECT CaseNumber, Recategorisation_Reason__c, CCC_External_Id__c, Type_Text__c, Sub_Type_Text__c, 
            Source__c, Business_Unit__c, Bot_Feedback__c, Issue_Type__c
            FROM Case
            WHERE Id =:caseId
        ];

        return caseRecord;
    }
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - evaluate
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @Description - Invoked from the ASF_IntegrationsController class, this method evaluates whether Ebot Feedback Integration should be fired or not.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = 'Error';

        String caseRecId = caseRec.Id;
        Case caseRecord = getCaseRec(caseRecId);
        String source = caseRecord.Source__c;
        String bussUnit = caseRecord.Business_Unit__c;

        if(source == 'Email' && (bussUnit == 'ABFL' || bussUnit == 'ABHFL')) {
            result.status = 'Success';
            result.response = 'Ebot Feedback submitted successfully';
        }

        return result;
    }

    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - run
    * @param integ - ASF_Integration record.
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @Description - Invoked from the ASF_IntegrationsController class, this method runs the Ebot Feedback Integration and creates Case Integration record.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integ, Case caseRec){
        
        ASF_IntegrationsController.IntegrationWrapper response = new ASF_IntegrationsController.IntegrationWrapper();
        callEbotFeedbackApi(caseRec.Id);
        response.status = 'Success';
        return response;
    }

     /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - processResponse
    * @param caseInteg - ASF_Case_Integration record.
    * @return - void.
    * @Description - Invoked from the Case Integration trigger, this method processes the response of the integration received.
    *****************************************************************************************************************/
    public void processResponse(ASF_Case_Integration__c caseInt){
        
    }

    // @Description - Callout for Ebot Feedback Integration.
    @AuraEnabled
    public static void callEbotFeedbackApi(String caseId){
        
        ABCL_EBotFeedback ebotFeedbackObj = new ABCL_EBotFeedback();

        Case caseRecord = ebotFeedbackObj.getCaseRec(caseId); 
        String cccExtId = caseRecord.CCC_External_Id__c;
        String caseSubType = caseRecord.Sub_Type_Text__c;

        List<ASF_Case_Integration__c> existingCaseIntRecords = [SELECT Id, Status__c FROM ASF_Case_Integration__c
                                                               WHERE Case__c =:caseRecord.Id 
                                                               AND Type__c = 'eBOTFeedback'];

        if(existingCaseIntRecords.size()>0){
        	for(ASF_Case_Integration__c cInt : existingCaseIntRecords){
                cInt.Status__c = 'Canceled';
            }
            update existingCaseIntRecords;            
        }

        String jsonBody = ebotFeedbackObj.generateReqBody(caseRecord);

        system.debug('jsonBody-- '+jsonBody);    
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Case__c  = caseRecord.Id;
        caseInt.Type__c = 'eBOTFeedback';
        caseInt.Status__c = 'Pending';
        caseInt.Request__c = jsonBody;
        insert caseInt;

        if(String.isNotBlank(jsonBody)) {
            ebotFeedbackObj.firePlatformEvtForCallout(caseInt, jsonBody, caseSubType);
        }
    }

    // @Description - Preparing JSON body for Ebot Feedback Integration.
    public String generateReqBody(Case caseRecord) {
        
        EBotFeedbackWrapper ebotFeedbackWrappObj = new EBotFeedbackWrapper();
        ebotFeedbackWrappObj.Case_X = caseRecord.CaseNumber;
        ebotFeedbackWrappObj.CATEGORY = caseRecord.CCC_External_Id__c;
        ebotFeedbackWrappObj.TYPE = caseRecord.Type_Text__c;
        ebotFeedbackWrappObj.SUB_TYPE = caseRecord.Sub_Type_Text__c;
        ebotFeedbackWrappObj.DESCRIPTION = String.isNotBlank(caseRecord.Recategorisation_Reason__c) ? caseRecord.Recategorisation_Reason__c : '';
        ebotFeedbackWrappObj.COMMENTS = caseRecord.Bot_Feedback__c;
        if(caseRecord.Business_Unit__c == ASF_Constants.ABSLI_BU){
            ebotFeedbackWrappObj.ISSUE_TYPE = caseRecord.Issue_Type__c;
            ebotFeedbackWrappObj.SOURCE = ABSLI_Constants.ESB_SOURCE_ID;
        }
        String reqBody = JSON.serialize(ebotFeedbackWrappObj);
        String actualReqBody = reqBody.replace('"Case_X":', '"case":');

        return actualReqBody;
    }

    // @Description - Firing Platform Event to make Callout for Ebot Feedback Api.
    public void firePlatformEvtForCallout(ASF_Case_Integration__c caseInteg, String jsonBody, String caseSubType) {

        ASF_Case_Integration__c caseInt = [SELECT Name, Case__r.Business_Unit__c FROM ASF_Case_Integration__c WHERE id =: caseInteg.Id];
        
        Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
        caseIntOut.Business_Unit__c  = String.isNotBlank(caseInt.Case__r.Business_Unit__c) ? caseInt.Case__r.Business_Unit__c : '';
        caseIntOut.Case_Integration_ID__c = caseInt.Name;
        caseIntOut.Integration_Name__c  = 'Ebot Feedback';
        caseIntOut.ServiceName__c  = 'eBotFeedback';
        caseIntOut.Request_Payload__c  =  jsonBody;
        Database.SaveResult publishResult = EventBus.publish(caseIntOut);
    }

    public class EBotFeedbackWrapper {
        public String Case_X;
        public String CATEGORY;
        public String TYPE;
        public String SUB_TYPE;
        public String DESCRIPTION;
        public String COMMENTS;
        public String ISSUE_TYPE;
        public String SOURCE;
        
    }

    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){return null;}
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs){return null;}

}