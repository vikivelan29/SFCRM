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

        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = 'Error';
        result.response = 'Evaluation Failed, cannot retrieve Interest Certificate.';

        Case caseRecord = [
            SELECT Id, ABHFL_Case_Detail__r.Financial_Year__c, Technical_Source__c, Asset.LAN__c, Sub_Type_Text__c 
            FROM Case
            WHERE Id =: caseRec.Id
        ];
		//system.debug('caseRecord-- '+caseRecord);
        financialYr = getFinancialYr(caseRecord);
        String lan   = caseRecord.Asset.LAN__c;

        if(caseRecord.Technical_Source__c == 'Api' || caseRecord.Technical_Source__c == 'LWC') {
                if(String.isNotBlank(financialYr) && String.isNotBlank(lan)) {
                    result.status = 'Success';
                    result.response = 'Evaluation Success, Submit to get the Interest Certificate.';
                }
                else if(String.isBlank(financialYr) && String.isBlank(lan)) {
                    result.status = 'Error';
                    result.response = 'Please fill the Financial Year and Loan Account Number';
                }
                else if(String.isBlank(financialYr)){
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
    * @description - Invoked from the ASF_IntegrationsController class, this method runs the Interest Certificate Or Provisional Interest Certificate integration and creates Case Integration record.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integ, Case caseRec){

        String financialYr = ''; 
        String currentFiscalYear;
        ABHFL_ICAndPIC_IntegrationHelper abhflIcAndPicIntegrationHelperClass = new ABHFL_ICAndPIC_IntegrationHelper();
        
        ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
		List<ASF_Case_Integration__c> existingCaseIntRecords = [SELECT Id, Status__c FROM ASF_Case_Integration__c
                                                               WHERE Case__c =:caseRec.Id 
                                                               AND Integration_Ext_Id__c =:integ.External_Id__c WITH SECURITY_ENFORCED];
        
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
            jsonBody = JSON.serialize(reqBodyObj);
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
        Case caseRecord = [SELECT Id,AccountId,ContactId,Source__c,Sub_Type_Text__c,CCC_External_Id__c,OwnerId,CreatedById,ABHFL_Case_Detail__r.STP_Failure__c
                           FROM Case WHERE Id =: caseInt.Case__c];
        
        String caseSubType = caseRecord.Sub_Type_Text__c;
        String integrationName = getIntegrationName(caseSubType);

        if(caseInt.Status__c == ABHFL_Constants.SUCCESS){
            isTransferred = ABCL_IntegrationCommonUtility.transferAttachments(caseInt);
            if(caseRecord!=null){
                if(isTransferred){
                    integrationFailure = false;
                    List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id,Resolved_Case_Email_Template__c FROM ASF_Case_Category_Config__c 
                                                                   WHERE CCC_External_Id__c =:caseRecord.CCC_External_Id__c WITH SECURITY_ENFORCED];
                    Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord, 
                                                                                                                            cccRecord[0].Resolved_Case_Email_Template__c, 
                                                                                                                            null, 
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
    }

    public void handleFailure(Case caseRecord, String integrationName) {
        if(caseRecord.Source__c == ABHFL_Constants.BRANCH){
            caseRecord.OwnerId = caseRecord.CreatedById;
            ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRecord,integrationName,null);
        } else {
            Group csQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Customer_Service_Team' WITH SECURITY_ENFORCED Limit 1];
            caseRecord.OwnerId = csQueue.Id;
        }
        if(Schema.sObjectType.Case.isUpdateable()){
            update caseRecord;    
        } 
    }
}
