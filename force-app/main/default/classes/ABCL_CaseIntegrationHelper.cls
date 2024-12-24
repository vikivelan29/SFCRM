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
				Case c=[Select Id,Winning_Email__c from Case where Id=:recordAfter.Case__c Limit 1];
                List<ASF_PriorityEmailAddressesByBU__mdt> metadataList = [ SELECT Business_Unit__c,Email2CaseAddress__c,Send_to_UNFYD__c FROM ASF_PriorityEmailAddressesByBU__mdt WHERE Email2CaseAddress__c =:c.Winning_Email__c];
				if(metadataList[0].Send_to_UNFYD__c == true && integrationCase.Business_Unit__c == 'ABFL' && recordAfter.Type__c == 'EMAILRESPONSE'){
                            
                    ABFL_UNFYDEmailWrapper unfydResponse = (ABFL_UNFYDEmailWrapper)JSON.deserialize(recordAfter.Response__c,ABFL_UNFYDEmailWrapper.class);
                    ABFL_CaseIntegrationHelper.unfydEmailResponseHandler(recordAfter.Case__c,unfydResponse);
                            
                }
                // used integrationCase.Business_Unit__c == 'Payments' as ABHFL email-to-case is not setup yet.
                if(String.isBlank(integrationCase.CCC_External_Id__c) && ABCL_EmailMessageHelper.originSet.contains(integrationCase.Origin)){
                    if(integrationCase.Business_Unit__c == 'ABHFL'){
                        ABHFL_EbotWrapper.EbotResponseWrapper ebotResponse = (ABHFL_EbotWrapper.EbotResponseWrapper)JSON.deserialize(recordAfter.Response__c,ABHFL_EbotWrapper.EbotResponseWrapper.class);
                        ABHFL_CaseIntegrationHelper.eBotResponseHandler(recordAfter.Case__c,ebotResponse);
                        //Boolean isTransferred = ABCL_IntegrationCommonUtility.transferAttachments(recordAfter);
                    }
                    else if (integrationCase.Business_Unit__c == 'ABFL'){
                        if(metadataList[0].Send_to_UNFYD__c == true){
                            if(recordAfter.Type__c == 'CATEGORIZATION'){
                                //String unfdydResponseString = '{"CASENUMBER": "8879656","CUSTOMERNO": "8879656","AUTORESPONSE": "No","ISSMT":"No","ISMULTIPLEINTENT": "No", "LOB": "UNSECURED","ISREGISTEREDCUSTOMER": "YES”,"DEDUPE": "Yes","PAYTMINTERACTIONID": "PAYTM4832738","PRIORITY": "Medium","ISSUECODE": "hfl027","LAN": "ABFL-1234","MOODSTAMP": "Neutral","POTENTIALCOMPLAINT": "No","CONFIDENCESCORE": 0.90,"ISTRAILMAIL": "NO”,"ISATTACHMENT": "NO”,"ISMULTIPLELAN": "NO”,"DISPOSITION": "LOAN DETAILS/PARTNER RELATED”,"COMMENT": "","OWNERFULLNAME": "True","INTENT":"Loan Settlement","REMARKS":"In Json key value pair: Intent, Casetype, Subtype","CASE_INTEGRATION_ID":"ABWM1619"}';
                                ABFL_UNFYDWrapper unfydResponse = (ABFL_UNFYDWrapper)JSON.deserialize(recordAfter.Response__c,ABFL_UNFYDWrapper.class);
                                //ABFL_UNFYDWrapper unfydResponse = (ABFL_UNFYDWrapper)JSON.deserialize(unfdydResponseString,ABFL_UNFYDWrapper.class);
                                ABFL_CaseIntegrationHelper.unfydResponseHandler(recordAfter.Case__c,unfydResponse);
                            }
                            
                        }else{
                            ABFL_EbotWrapper.EbotResponseWrapper ebotResponse = (ABFL_EbotWrapper.EbotResponseWrapper)JSON.deserialize(recordAfter.Response__c,ABFL_EbotWrapper.EbotResponseWrapper.class);
                        	ABFL_EBOTCaseLogics.updateCaseDetailExtension(recordAfter.Case__c,ebotResponse);
                        }
                        
                    }
                    else if(ABFL_Constants.ABFL_ABWM_BUSINESSUNIT.contains(integrationCase.Business_Unit__c) ){
                        ABFL_EbotWrapper.EbotResponseWrapper ebotResponse = (ABFL_EbotWrapper.EbotResponseWrapper)JSON.deserialize(recordAfter.Response__c,ABFL_EbotWrapper.EbotResponseWrapper.class);
                        ABFL_EBOTCaseLogics.updateCaseDetailExtension(recordAfter.Case__c,ebotResponse);
                    }
                    else if(integrationCase.Business_Unit__c == ABSLI_Constants.BUSINESS_UNIT){
                        ABSLI_EBotWrapper.EbotResponseWrapper ebotResponse = (ABSLI_EBotWrapper.EbotResponseWrapper)JSON.deserialize(recordAfter.Response__c,ABSLI_EBotWrapper.EbotResponseWrapper.class);
                        ABSLI_CaseIntegrationHelper.eBotResponseHandler(recordAfter.Case__c,ebotResponse,recordAfter);
                    }
                    else if(integrationCase.Business_Unit__c == ABHI_Constants.ABHI){
                        ABHI_EBOTCaseLogics.UpdateCaseWrapper ebotResponse = (ABHI_EBOTCaseLogics.UpdateCaseWrapper)JSON.deserialize(recordAfter.Response__c,ABHI_EBOTCaseLogics.UpdateCaseWrapper.class);
                        ABHI_EBOTCaseLogics.updateCaseExtension(recordAfter.Case__c,ebotResponse); 
                    }
                }
            }      
        }
        
    }
}
