/*********************************************************
*Class        :  ABHFL_ICAndPIC_Integration
*Author       :  Anirudh Raturi
*Created Date :  11/12/2023
*Last Modified:  14/12/2023
*Description  :  Class for Interest Certificate And Provisional Interest Certificate Integration
*********************************************************/

public with sharing class ABHFL_ICAndPIC_Integration extends ABHFL_ICAndPIC_IntegrationHelper implements ASF_IntegrationInvocable {
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - evaluate
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @Description - Invoked from the ASF_IntegrationsController class, this method evaluates whether Interest Certificate Or Provisional Interest Certificate Integration should be fired or not.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = 'Error';
        result.response = 'Evaluation Failed, cannot retrieve Interest Certificate.';

        Case caseRecord = [
            SELECT Id, ABHFL_Case_Detail__r.Financial_Year__c, Technical_Source__c, Asset.LAN__c 
            FROM Case
            WHERE Id =: caseRec.Id
        ];

        String finYr = caseRecord.ABHFL_Case_Detail__r.Financial_Year__c;
        String lan   = caseRecord.Asset.LAN__c;

        if(caseRecord.Technical_Source__c == 'Api' || caseRecord.Technical_Source__c == 'LWC') {
                if(String.isNotBlank(finYr) && String.isNotBlank(lan)) {
                    result.status = 'Success';
                    result.response = 'Evaluation Success, Submit to get the Interest Certificate.';
                }
                else if(String.isBlank(finYr)){
                    result.status = 'Error';
                    result.response = 'Please fill the Financial Year';
                }
                else if(String.isBlank(lan)){
                    result.status = 'Error';
                    result.response = 'Please fill the LAN';
                }
        }
        return result;
    }

    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - run
    * @param integ - ASF_Integration record.
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @Description - Invoked from the ASF_IntegrationsController class, this method runs the Interest Certificate Or Provisional Interest Certificate integration and creates Case Integration record.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integ, Case caseRec){

        String financialYr = '', currentFinYr = '';
        ABHFL_ICAndPIC_IntegrationHelper abhfl_ICAndPIC_IntegrationHelperClass = new ABHFL_ICAndPIC_IntegrationHelper();
        
        ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
		List<ASF_Case_Integration__c> existingCaseIntRecords = [SELECT Id, Status__c FROM ASF_Case_Integration__c
                                                               WHERE Case__c =:caseRec.Id 
                                                               AND Integration_Ext_Id__c =:integ.External_Id__c];
        
        Case caseRecord = [
            SELECT Id, Sub_Type_Text__c, Technical_Source__c, ABHFL_Case_Detail__r.Financial_Year__c, LAN__c
            FROM Case
            WHERE Id =: caseRec.Id
        ];

        String caseSubType = caseRecord.Sub_Type_Text__c;
        String integName = String.isNotBlank(getIntegrationName(caseSubType)) ? getIntegrationName(caseSubType) : '';
        
        if(integName == 'Interest Certificate') {
            String
        }
        else if(integName == 'Provisional Interest Certificate') {

        }

        if(existingCaseIntRecords.size()>0){
        	for(ASF_Case_Integration__c cInt : existingCaseIntRecords){
                cInt.Status__c = 'Canceled';
            }
            update existingCaseIntRecords;            
        }

        String customLabelForSTPFLow = System.Label.STP_Flows;
        List<String> subTypeList = customLabelForSTPFLow.split(',');
        String caseSubType = caseRecord.Sub_Type_Text__c;
        String technicalSrc = caseRecord.Technical_Source__c;
        String type = 'default';
        String jsonBody = '';

        if(technicalSrc == 'LWC' || technicalSrc == 'Api') {
            if(subTypeList.contains(caseSubType)) {
                ABHFL_ICAndPIC_IntegrationRequestWrapper reqBodyObj = generateRequest(caseRecord, type);
                jsonBody = JSON.serialize(reqBodyObj);
            }
        }
                
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Case__c  = caseRec.Id;
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Status__c = 'Pending';
        caseInt.Response__c = 'Waiting for API response';
        insert caseInt;

        if(String.isNotBlank(jsonBody)) {
            firePlatformEvtForCallout(caseInt, jsonBody, caseSubType);
        }

        return wrap;
    }

    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - processResponse
    * @param caseInteg - ASF_Case_Integration record.
    * @return - void.
    * @Description - Invoked from the Case Integration trigger, this method processes the response of the integration received.
    *****************************************************************************************************************/
    public void processResponse(ASF_Case_Integration__c caseInteg){
        system.debug('Inside process response Interest Certificate');
      /*  if(caseInteg.Status__c=='Success'){
        	Case caseRec =[SELECT Id, MoveToNext__c,Attachment_Status__c  FROM Case WHERE Id=:caseInteg.Case__c];
            if(caseRec!=null){
                caseRec.MoveToNext__c = true;
                caseRec.Attachment_Status__c = 'Completed';
                update caseRec;    
            }    
        }  */    
    }

}