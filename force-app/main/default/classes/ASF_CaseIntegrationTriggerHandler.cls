/**
 * @description       : After Update, when Response is received from External System on Case Integration, the processing of response needs to be done
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 05-13-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   05-13-2024   rsinghnagar@salesforce.com   Initial Version
**/
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts')
public without sharing class ASF_CaseIntegrationTriggerHandler extends ASF_VTriggerHandler {
    
    public static Boolean TriggerDisabled = false;
    
    /**
    * @description 
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param newItems 
    **/
    public override void beforeInsert(list<sObject> newItems) {
        for(ASF_Case_Integration__c caseInteg : (List<ASF_Case_Integration__c>)newItems){
            if(caseInteg.Do_Not_Retry_Integration__c){
                caseInteg.Retry__c = false;
            }
            else{
                caseInteg.Next_Retry__c = System.now().addMinutes(15);
            }
            
        }
    }
    
   /**
    * @description : Framework Method - to Process the Response on Case Integration, Used when Async Integrations are called, the Case Integration is updated back and status is modified
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param newItems 
    * @param oldItems 
    **/
    public override void afterUpdate(map<Id, sObject> newItems,map<Id, sObject> oldItems) {
        
        if(!ASF_TriggerSkipperUtility.isAllowedToRun('ASF_Case_Integration__c', 'After')){return;}
        // Query ASF Integration Record, and Process the Response from 
        // Processing Class indicated on ASF Integration Record
        Map<Id, String> asfItegExtIds = new Map<Id, String>();
        Map<Id, sObject> eBotNewItems = new Map<Id, sObject>();
        Map<Id, sObject> eBotOldItems = new Map<Id, sObject>();
        for(ASF_Case_Integration__c caseInteg : (List<ASF_Case_Integration__c>)newItems.values()){
            if(caseInteg.Integration_Ext_Id__c != null){
                if(caseInteg.Status__c != ((ASF_Case_Integration__c)oldItems.get(caseInteg.Id)).Status__c){
                    asfItegExtIds.put(caseInteg.Id, caseInteg.Integration_Ext_Id__c);
                }
            }
            else if(caseInteg.Type__c == 'eBOT'){
                eBotNewItems.put(caseInteg.Id, caseInteg);
                eBotOldItems.put(caseInteg.Id, oldItems.get(caseInteg.Id));
            }
        }

        // Call eBot Handler for Generic Case Integraitons
        if(!eBotNewItems.isEmpty()){
            ABCL_CaseIntegrationHelper.eBotHandler(eBotNewItems,eBotOldItems);
        }

        // Call Framework Handler Processing for Framework Case Integraitons
        Map<String, String> asfProcessingClass = new Map<String, String>();
        if(!asfItegExtIds.isEmpty()){
            for(ASF_Integration__c asfInteg : [
                                                SELECT Id, Processing_Class__c, External_Id__c
                                                FROM ASF_Integration__c
                                                WHERE External_Id__c in: asfItegExtIds.values()
            ]){
                asfProcessingClass.put(asfInteg.External_Id__c, asfInteg.Processing_Class__c);
            }
        }
        
        for(ASF_Case_Integration__c caseInteg : (List<ASF_Case_Integration__c>)newItems.values()){
            
            // Regular Framework Case Integration Updates
            if(asfItegExtIds.containsKey(caseInteg.Id)){
            
                String extId = asfItegExtIds.get(caseInteg.Id);
                String cls = asfProcessingClass.get(extId);
                if(cls != null){
                    Type customType = Type.forName(cls);
                    ASF_IntegrationInvocable instance = (ASF_IntegrationInvocable)customType.newInstance();
                    instance.processResponse(caseInteg);
                }
            }
        }
    }    

}