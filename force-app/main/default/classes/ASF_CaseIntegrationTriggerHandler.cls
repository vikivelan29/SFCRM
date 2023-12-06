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
        for(ASF_Case_Integration__c caseInteg : (List<ASF_Case_Integration__c>)newItems.values()){
            
            // Only on change of Stage
            // TODO - should we retrict from stage to 'Pending' ?
            if(caseInteg.Status__c != ((ASF_Case_Integration__c)oldItems.get(caseInteg.Id)).Status__c){
                asfItegExtIds.put(caseInteg.Id, caseInteg.Integration_Ext_Id__c);
            }
        }

        Map<String, String> asfProcessingClass = new Map<String, String>();
        for(ASF_Integration__c asfInteg : [
                                            SELECT Id, Processing_Class__c, External_Id__c
                                            FROM ASF_Integration__c
                                            WHERE External_Id__c in: asfItegExtIds.values()
        ]){
            asfProcessingClass.put(asfInteg.External_Id__c, asfInteg.Processing_Class__c);
        }

        for(ASF_Case_Integration__c caseInteg : (List<ASF_Case_Integration__c>)newItems.values()){
            
            if(caseInteg.Status__c != ((ASF_Case_Integration__c)oldItems.get(caseInteg.Id)).Status__c){

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