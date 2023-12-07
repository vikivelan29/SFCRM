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
    * @param oldItems - map of cases from trigger.newMap(),newItems - map of cases from trigger.newMap()
    * @return - void .
    * @Description - Processing Ebot Response
    *****************************************************************************************************************/   
    public static void eBotHandler(map<Id, sObject> newItems,map<Id, sObject> oldItems){
        Set<Id> caseIds = new Set<Id>();
        Set<Id> caseIntegrationIds = new Set<Id>();
        List<Case> caseListToUpdate = new List<Case>();
        List<ABHFL_Case_Detail__c> caseDetailList = new List<ABHFL_Case_Detail__c>();
        
        for(ASF_Case_Integration__c recordAfter : (List<ASF_Case_Integration__c>)newItems.values()){
            ASF_Case_Integration__c recordBefore = (ASF_Case_Integration__c)oldItems.get(recordAfter.Id);
            if(String.isNotBlank(recordAfter.Response__c) &&  String.isBlank(recordBefore.Response__c) 
               && recordAfter.Status__c == 'Success' && String.isNotBlank(recordAfter.Case__c)){
                caseIds.add(recordAfter.Case__c);
                caseIntegrationIds.add(recordAfter.Id);
            }
        }
		system.debug('caseIds'+caseIds);
        system.debug('caseIntegrationIds'+caseIntegrationIds);
        Map<Id, Case> caseIdMap = new Map<Id, Case>([Select id,Type, CCC_External_Id__c,Status,Source__c,Origin from Case where id in: caseIds]);
        system.debug('caseIdMap'+caseIdMap);
        if(caseIntegrationIds.size() >  0) {
            for(Id caseIntId : caseIntegrationIds){
                ASF_Case_Integration__c recordAfter = (ASF_Case_Integration__c)newItems.get(caseIntId);
                if(caseIdMap.containsKey(recordAfter.Case__c)){
                    Case integrationCase = caseIdMap.get(recordAfter.Case__c);
                    system.debug(integrationCase);
                    if(String.isBlank(integrationCase.CCC_External_Id__c) && integrationCase.Source__c == 'Email'){
                        ABHFL_EbotWrapper.EbotResponseWrapper ebotResponse = (ABHFL_EbotWrapper.EbotResponseWrapper)JSON.deserialize(recordAfter.Response__c,ABHFL_EbotWrapper.EbotResponseWrapper.class);
                        integrationCase.CCC_External_Id__c = ebotResponse.CASESUBTYPE;
                        integrationCase.Comments = ebotResponse.COMMENT;
                        system.debug(ASF_Constants.RT_FRAMEWORK);
                        integrationCase.RecordTypeId = ASF_Constants.RT_FRAMEWORK;
                        if(integrationCase.Origin == 'ABHFL Email'){
                        	ABHFL_Case_Detail__c caseDetails = new ABHFL_Case_Detail__c();
                            caseDetails.Ebot_Owner_Full_Name__c  = ebotResponse.OWNERFULLNAME;
                            caseDetails.Confidence_Score__c  = Decimal.valueof(ebotResponse.CONFIDENCESCORE);
                            caseDetails.Case__c = integrationCase.Id;
                            caseDetailList.add(caseDetails);
                        }
                        //added by Ashish to test
                        //integrationCase.stage__c ='Open';
                        caseListToUpdate.add(integrationCase);
                    }   
                }
            }
            
            Map<Id,Id> caseIdToCaseDetailIdMap = new Map<Id,Id>();
            if(caseDetailList.size() > 0){
                insert caseDetailList;
                for(ABHFL_Case_Detail__c caseDetail : caseDetailList){
                    caseIdToCaseDetailIdMap.put(caseDetail.Case__c,caseDetail.Id);
                }
                for(Case cs : caseListToUpdate){
                    if(caseIdToCaseDetailIdMap.containsKey(cs.Id)){
                        cs.ABHFL_Case_Detail__c = caseIdToCaseDetailIdMap.get(cs.Id);
                    }
                }
            }
            
            if(caseListToUpdate.size() > 0){
                Database.SaveResult[] updateResult = Database.update(caseListToUpdate,false); 
                System.debug('updateResult'+updateResult);      
                System.debug('updateResult'+updateResult[0].getErrors());  
            }
        }
        transferAttachments(newItems,oldItems);
    }
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - transferAttachments
    * @param oldItems - map of cases from trigger.newMap(),newItems - map of cases from trigger.newMap()
    * @return - void .
    * @Description - Transfers Attachments from ASF_Case_Integration__c to Case
    *****************************************************************************************************************/       
    public static void transferAttachments(map<Id, sObject> newItems,map<Id, sObject> oldItems){
        Set<Id> caseIntegrationIds = new Set<Id>();
        for(ASF_Case_Integration__c recordAfter : (List<ASF_Case_Integration__c>)newItems.values()){
            ASF_Case_Integration__c recordBefore = (ASF_Case_Integration__c)oldItems.get(recordAfter.Id);
            if(String.isNotBlank(recordAfter.Response__c) &&  String.isBlank(recordBefore.Response__c) 
               && recordAfter.Status__c == 'Success' && String.isNotBlank(recordAfter.Case__c)){
					caseIntegrationIds.add(recordAfter.Id);
               }
        }
        List<ContentDocumentLink> relatedAttachments = [Select LinkedEntityId,ContentDocumentId from ContentDocumentLink 
                                                        where LinkedEntityId in: caseIntegrationIds];
        List<ContentDocumentLink> contentLinkToBeInserted = new List<ContentDocumentLink>();
        for(ContentDocumentLink contentLink : relatedAttachments){
            ContentDocumentLink link = new ContentDocumentLink();
            link.LinkedEntityId = ((ASF_Case_Integration__c)newItems.get(contentLink.LinkedEntityId)).Case__c;
            link.ContentDocumentId= contentLink.ContentDocumentId;
            link.ShareType = 'V';
            contentLinkToBeInserted.add(link);
        }
        
        if(contentLinkToBeInserted.size() > 0){
            Database.SaveResult[] upsertResult = Database.insert(contentLinkToBeInserted,false);         
        }
    }
}