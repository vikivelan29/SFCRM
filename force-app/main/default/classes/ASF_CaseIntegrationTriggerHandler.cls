/**
 * ASF_CaseIntegrationTriggerHandler
 * After Update, when Response is received from External System on
 * Case Integration, the processing of response needs to be done
 */
public class ASF_CaseIntegrationTriggerHandler extends ASF_VTriggerHandler {
    
    public static Boolean TriggerDisabled = false;
    
    /**
     * Framework Method - to Process the Response on Case Integration
     * Used when Async Integrations are called, the Case Integration
     * is updated back and status is modified
     */
    public override void afterUpdate(map<Id, sObject> newItems,map<Id, sObject> oldItems) {
        
        
        // Query ASF Integration Record, and Process the Response from 
        // Processing Class indicated on ASF Integration Record
        Map<Id, String> asfItegExtIds = new Map<Id, String>();
        Set<Id> eBotCaseIntegrations = new Set<Id>();
        Map<Id, sObject> eBotNewItems = new Map<Id, sObject>();
        Map<Id, sObject> eBotOldItems = new Map<Id, sObject>();
        for(ASF_Case_Integration__c caseInteg : (List<ASF_Case_Integration__c>)newItems.values()){
            system.debug('Case Integration test:'+caseInteg);
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
            system.debug('eBotHandler:');
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
		System.debug('***asfItegExtIds:'+asfItegExtIds);
        System.debug('***asfProcessingClas:'+asfProcessingClass);
        
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