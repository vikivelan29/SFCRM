/*********************************************************
*Class        :  ABCL_CaseIntegrationHelper
*Author       :  Shubham Sinha 
*Created Date :  12/12/2023
*Last Modified:  12/12/2023
*Description  :  Case Integration Trigger Helper for ABHFL and ABFL according to the case Business Unit

*********************************************************/
public with sharing class ABCL_CaseIntegrationHelper {
    /****************************************************************************************************************
    * @param oldItems - map of cases from trigger.newMap(),newItems - map of cases from trigger.newMap()
    * @return - void .
    * @Description - Processing Ebot Response for ABHFL and ABFL according to the case Business Unit
    *****************************************************************************************************************/   
    public static void eBotHandler(map<Id, sObject> newItems,map<Id, sObject> oldItems){
        // Find eligible records
        Set<Id> caseIds = new Set<Id>();
        Set<Id> caseIntegrationIds = new Set<Id>();
        Set<Id> caseIntIds = new Set<Id>();
        List<ABHFL_Case_Detail__c> caseDetailList = new List<ABHFL_Case_Detail__c>();
        for(ASF_Case_Integration__c recordAfter : (List<ASF_Case_Integration__c>)newItems.values()){
            ASF_Case_Integration__c recordBefore = (ASF_Case_Integration__c)oldItems.get(recordAfter.Id);
            if(
                recordAfter.Status__c == 'Success' && 
                String.isNotBlank(recordAfter.Case__c) && 
                String.isNotBlank(recordAfter.Response__c) &&  
                String.isBlank(recordBefore.Response__c)
            ){
                caseIds.add(recordAfter.Case__c);
                caseIntegrationIds.add(recordAfter.Id);
            } 
        } 
        system.debug('****caseIntegrationIds:'+caseIntegrationIds);
        
        // If we have eligible records then run below
        if(caseIntegrationIds.size() >  0) {
            Map<Id, Case> caseIdMap = new Map<Id, Case>([Select id,Type,Business_Unit__c , CCC_External_Id__c,Status,Source__c,Origin from Case where id in: caseIds]);
            for(Id caseIntId : caseIntegrationIds){
                ASF_Case_Integration__c recordAfter = (ASF_Case_Integration__c)newItems.get(caseIntId);
                Case integrationCase = caseIdMap.get(recordAfter.Case__c);
                system.debug('****integrationCase:'+integrationCase);
                // used integrationCase.Business_Unit__c == 'Payments' as ABHFL email-to-case is not setup yet.
                if(String.isBlank(integrationCase.CCC_External_Id__c) && integrationCase.Source__c == 'Email'){
                    if(integrationCase.Business_Unit__c == 'ABHFL'){
                        ABHFL_EbotWrapper.EbotResponseWrapper ebotResponse = (ABHFL_EbotWrapper.EbotResponseWrapper)JSON.deserialize(recordAfter.Response__c,ABHFL_EbotWrapper.EbotResponseWrapper.class);
                        ABHFL_CaseIntegrationHelper.eBotResponseHandler(recordAfter.Case__c,ebotResponse);
                        Boolean isTransferred = ABCL_IntegrationCommonUtility.transferAttachments(recordAfter);
                    }   
                    else if(integrationCase.Business_Unit__c == 'ABFL'){
                        ABFL_EbotWrapper.EbotResponseWrapper ebotResponse = (ABFL_EbotWrapper.EbotResponseWrapper)JSON.deserialize(recordAfter.Response__c,ABFL_EbotWrapper.EbotResponseWrapper.class);
                        system.debug('ebotResponseABFL '+ebotResponse);
                        ABFL_EBOTCaseLogics.updateCaseDetailExtension(recordAfter.Case__c,ebotResponse);
                    }  
                }
            }      
        }
        
    }
}
