/*********************************************************
*Class        :  ABCL_CaseIntegrationHelper
*Author       :  Shubham Sinha 
*Created Date :  12/12/2023
*Last Modified:  12/12/2023
*@description  :  Case Integration Trigger Helper for ABHFL and ABFL according to the case Business Unit

*********************************************************/
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts')
public with sharing class ABCL_CaseIntegrationHelper {    
    /**
    * @description Processing Ebot Response for ABHFL and ABFL according to the case Business Unit
    * @author Shubham Sinha
    * @param newItems 
    * @param oldItems 
    **/
    public static void eBotHandler(map<Id, sObject> newItems,map<Id, sObject> oldItems){
        // Find eligible records
        Set<Id> caseIds = new Set<Id>();
        Set<Id> caseIntegrationIds = new Set<Id>();
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
        // If we have eligible records then run below
        if(caseIntegrationIds.size() >  0) {
            Map<Id, Case> caseIdMap = new Map<Id, Case>([Select id,Type,Business_Unit__c , CCC_External_Id__c,Status,Source__c,Origin from Case where id in: caseIds]);
            for(Id caseIntId : caseIntegrationIds){
                ASF_Case_Integration__c recordAfter = (ASF_Case_Integration__c)newItems.get(caseIntId);
                Case integrationCase = caseIdMap.get(recordAfter.Case__c);
                // used integrationCase.Business_Unit__c == 'Payments' as ABHFL email-to-case is not setup yet.
                if(String.isBlank(integrationCase.CCC_External_Id__c) && ABCL_EmailMessageHelper.originSet.contains(integrationCase.Origin)){
                    if(integrationCase.Business_Unit__c == 'ABHFL'){
                        ABHFL_EbotWrapper.EbotResponseWrapper ebotResponse = (ABHFL_EbotWrapper.EbotResponseWrapper)JSON.deserialize(recordAfter.Response__c,ABHFL_EbotWrapper.EbotResponseWrapper.class);
                        ABHFL_CaseIntegrationHelper.eBotResponseHandler(recordAfter.Case__c,ebotResponse);
                        //Boolean isTransferred = ABCL_IntegrationCommonUtility.transferAttachments(recordAfter);
                    }   
                    else if(ABFL_Constants.ABFL_ABWM_BUSINESSUNIT.contains(integrationCase.Business_Unit__c) ){
                        ABFL_EbotWrapper.EbotResponseWrapper ebotResponse = (ABFL_EbotWrapper.EbotResponseWrapper)JSON.deserialize(recordAfter.Response__c,ABFL_EbotWrapper.EbotResponseWrapper.class);
                        ABFL_EBOTCaseLogics.updateCaseDetailExtension(recordAfter.Case__c,ebotResponse);
                    }
                    else if(integrationCase.Business_Unit__c == ABSLI_Constants.BUSINESS_UNIT){
                        ABSLI_EBotWrapper.EbotResponseWrapper ebotResponse = (ABSLI_EBotWrapper.EbotResponseWrapper)JSON.deserialize(recordAfter.Response__c,ABSLI_EBotWrapper.EbotResponseWrapper.class);
                        ABSLI_CaseIntegrationHelper.eBotResponseHandler(recordAfter.Case__c,ebotResponse,recordAfter);
                    }
                }
            }     
        }
        
    }
}