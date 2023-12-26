/*********************************************************
*Class        :  ABHFL_CaseIntegrationHelper
*Author       :  Siddarth Jaitly
*Created Date :  28/11/2023
*Last Modified:  30/11/2023
*Description  :  Case Integration Trigger Helper for ABHFL LOB
*********************************************************/
public with sharing class ABHFL_CaseIntegrationHelper {
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - eBotHandler
    * @param caseId - Case Record ID
    * @param ebotResponse - Ebot Response Wrapper
    * @return - void .
    * @Description - Processing Ebot Response
    *****************************************************************************************************************/   
    public static void eBotResponseHandler(String caseId,ABHFL_EbotWrapper.EbotResponseWrapper ebotResponse){
        
        ABHFL_Case_Detail__c caseDetails = new ABHFL_Case_Detail__c();
        caseDetails.Ebot_Owner_Full_Name__c  = ebotResponse.OWNERFULLNAME;
        caseDetails.Confidence_Score__c  = Decimal.valueof(ebotResponse.CONFIDENCESCORE);
        if(Schema.sObjectType.ABHFL_Case_Detail__c.isCreateable()){
            insert caseDetails;
        }

        Case caseRecord = new Case();
        caseRecord.Id = caseId;
        caseRecord.ABHFL_Case_Detail__c = caseDetails.Id;
        caseRecord.CCC_External_Id__c = ebotResponse.CASESUBTYPE;
        caseRecord.Comments = ebotResponse.COMMENT;
        caseRecord.RecordTypeId = ASF_Constants.RT_FRAMEWORK;
        if(Schema.sObjectType.Case.isUpdateable()){
            update caseRecord;
        }
        /*ASF_Case_Category_Config__c categoryConfig = [Select Nature__c from ASF_Case_Category_Config__c 
                                                      where CCC_External_Id__c =: ebotResponse.CASESUBTYPE Limit 1];
        if(categoryConfig.Nature__c == 'Complaint'){
        	caseRecord.MoveToNext__c = true;
            update caseRecord;
        }*/
            
    }
}