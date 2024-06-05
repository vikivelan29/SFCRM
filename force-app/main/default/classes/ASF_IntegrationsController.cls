/*********************************************************
*Class        :  ASF_IntegrationsController
*Author       :  Ritika Dhandia
*Description  :  Backend Controller for ASF Integrations
*********************************************************/
public with sharing class ASF_IntegrationsController {

    public static Map<Id, Case> queriedCasesForIntegration = new Map<Id, Case>();

    /**
     * getAllIntegrations - Fetches All Integrations to be fired
     * for specific Case Category Config and Stage Config
     * Fetches Integrations for Process and Pre Populate Types
     */
    @AuraEnabled(cacheable=true)
    public static List<ASF_Integration__c> getAllIntegrations(string c3ExtId, string stageName){
        List<ASF_Integration__c> returnList = new List<ASF_Integration__c>();
        if(c3ExtId != null && stageName != null){
            returnList = [
                SELECT Id, Processing_Class__c, STP_Processing_Class__c,UI_Component__c,
                    External_Id__c, Type__c, Display_Name__c,STP_API_Identifier__c, Query_Fields__c
                FROM ASF_Integration__c
                WHERE C3ExternalId__c =: c3ExtId
                AND Case_Stage_Config__r.StageName__c =: stageName
                AND (Type__c = 'Process' OR Type__c = 'Pre Populate' OR Type__c = 'UI Action')
                ORDER BY Display_Order__c
            ];
        }
        return returnList;
    }

    /**
     * getAllIntegrations - Fetches All Integrations to be fired
     * for specific Case Category Config and Stage Config
     * Fetches Integrations for UI Integration types
     */
    @AuraEnabled(cacheable=true)
    public static List<ASF_Integration__c> getAllUIIntegrations(string c3ExtId, string stageName){
        List<ASF_Integration__c> returnList = new List<ASF_Integration__c>();
        if(c3ExtId != null && stageName != null){
            returnList = [
                SELECT Id, Processing_Class__c, STP_Processing_Class__c, 
                    External_Id__c, Type__c, Display_Name__c, 
                    UI_Component__c, Auto_Run_on_Load__c, STP_API_Identifier__c
                FROM ASF_Integration__c
                WHERE C3ExternalId__c =: c3ExtId
                AND Case_Stage_Config__r.StageName__c =: stageName
                AND Type__c = 'UI Card'
                ORDER BY Display_Order__c
            ];
        }
        return returnList;
    }

    /**
     * runIntegration - Fires the specific integration, by running the 
     * Processing Class's process method. Dynamic initialization of the class
     * and invoking of interface implemented method
     * First checks if it needs to be invoked by checking Visiblity Class evalutate method
     * Returning the response back from the business class
     */
    @AuraEnabled
    public static IntegrationWrapper runIntegration(ASF_Integration__c integ, Case caseRec){
        try {
            IntegrationWrapper result = new IntegrationWrapper();
            //Object result;
            Set<String> all_fields = new Set<String>{'id'};
            if(integ.Query_Fields__c != null){
                all_fields.addAll(integ.Query_Fields__c.toLowerCase().split(','));
            }

            Set<Id> caseRecs = new Set<Id>{caseRec.Id};
            ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>((List<Case>)Database.query(
                'SELECT ' +
                String.join(all_fields, ',') +
                ' FROM Case WHERE Id IN :caseRecs'
            ));
            // First check evaluation
            Type customType = Type.forName(integ.Processing_Class__c);
            ASF_IntegrationInvocable instance = (ASF_IntegrationInvocable)customType.newInstance();
            IntegrationWrapper invokeIntegration = instance.evaluate(caseRec);
            
            // Then run the actual integration
            if(invokeIntegration.status != 'Success'){
                return invokeIntegration;
                
            }
            result = instance.run(integ, caseRec);
            return result;
        } catch (Exception e) {
            //throw new AuraHandledException(e.getMessage());    
            throw e;	
        }
    }

    /**
     * runIntegration - Fires the specific integration, by running the 
     * Processing Class's process method. Dynamic initialization of the class
     * and invoking of interface implemented method
     * First checks if it needs to be invoked by checking Visiblity Class evalutate method
     * Returning the response back from the business class
     * BULKIFIED
     */
    public static Map<Id, IntegrationWrapper> runIntegration(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs){

        Map<Id, ASF_IntegrationsController.IntegrationWrapper> wrapperMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        try {
            //Object result;
            // First check evaluation
            Map<String, List<Case>> apexClassToCasesForEvaluate = new Map<String, List<Case>>();
            Map<String, List<Case>> apexClassToCasesForRun = new Map<String, List<Case>>();
            Set<String> all_fields = new Set<String>{'id'};
            for(Case caseRec : caseRecs){
                if(integs.containsKey(caseRec.Id)){
                    for(ASF_Integration__c integ : integs.get(caseRec.Id)){
                        if(integ.Query_Fields__c != null){
                            all_fields.addAll(integ.Query_Fields__c.toLowerCase().split(','));
                        }
                        if(!apexClassToCasesForEvaluate.containsKey(integ.Processing_Class__c)){
                            apexClassToCasesForEvaluate.put(integ.Processing_Class__c, new List<Case>());
                        }
                        apexClassToCasesForEvaluate.get(integ.Processing_Class__c).add(caseRec);
                    }
                }
            }

            ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>((List<Case>)Database.query(
                'SELECT ' +
                String.join(all_fields, ',') +
                ' FROM Case WHERE Id IN :caseRecs'
            ));
            system.debug('apexClassToCasesForEvaluate'+apexClassToCasesForEvaluate);
            for(String apexClass : apexClassToCasesForEvaluate.keySet()){
                Type customType = Type.forName(apexClass);
                ASF_IntegrationInvocable instance = (ASF_IntegrationInvocable)customType.newInstance();
                Map<Id, IntegrationWrapper> intResults = instance.evaluate(apexClassToCasesForEvaluate.get(apexClass));
                system.debug('intResults--->'+intResults);
                for(Case caseRec : apexClassToCasesForEvaluate.get(apexClass)){
                    if(intResults.containsKey(caseRec.Id)){
                        if(intResults.get(caseRec.Id).status == 'Success'){
                            //Success responses are passed to run method
                            if(!apexClassToCasesForRun.containsKey(apexClass)){
                                apexClassToCasesForRun.put(apexClass, new List<Case>());
                            }
                            apexClassToCasesForRun.get(apexClass).add(caseRec);
                        }else{
                            system.debug('caseRec.Id--->'+caseRec.Id);
                            system.debug('intResults.get(caseRec.Id)--->'+intResults.get(caseRec.Id));
                            
                            for(ASF_Integration__c integ : integs.get(caseRec.Id)){
                                if(integ.Processing_Class__c == apexClass){
                                    Decimal currentPriority = integ.Priority__c!=null?integ.Priority__c:999;
                                    IntegrationWrapper returnWrap = intResults.get(caseRec.Id);
                                    returnWrap.priority = currentPriority;
                                    //check if already an entry exists in wrappermap for this case
                                    //if yes, compare the priority of that integration with current one, smaller the number, higher the priority.
                                        //keep the higher priority item in the wrappermap, 
                                        //if already a entry present with same priority, skip entering new entry
                                    //if no, make an entry in wrapper map with current item
                                    if(wrapperMap.containsKey(caseRec.Id)){
                                        if(currentPriority < wrapperMap.get(caseRec.Id).priority){
                                            wrapperMap.put(caseRec.Id, returnWrap);
                                        }
                                    }else{
                                        wrapperMap.put(caseRec.Id, returnWrap);//Error response, hence store.
                                    }
                                }
                            }
                        }
                    }
                }
            }
            system.debug('wrapperMap--->'+wrapperMap);
            // Then run the actual integration
            // if(invokeIntegration.status != 'Success'){
            //     return invokeIntegration;
                
            // }
            system.debug('apexClassToCasesForRun--->'+apexClassToCasesForRun);
            for(String apexClass : apexClassToCasesForRun.keySet()){
                Type customType = Type.forName(apexClass);
                ASF_IntegrationInvocable instance = (ASF_IntegrationInvocable)customType.newInstance();
                
                Map<Id, IntegrationWrapper> intResults = instance.run(integs, apexClassToCasesForRun.get(apexClass));
                for(Case caseRec : apexClassToCasesForRun.get(apexClass)){
                    if(intResults.containsKey(caseRec.Id)){
                        if(intResults.get(caseRec.Id).status == 'Success'){
                            //Success, store only if there is no response stored for this case yet. 
                            //If success present, no point storing again
                            //If error present, can't overwrite with success.
                            if(!wrapperMap.containsKey(caseRec.Id)){
                                wrapperMap.put(caseRec.Id, intResults.get(caseRec.Id));
                            }
                        }else{
                            if(wrapperMap.containsKey(caseRec.Id) && wrapperMap.get(caseRec.Id).status == 'Success'){
                                //store only of previous responses were success only.
                                wrapperMap.put(caseRec.Id, intResults.get(caseRec.Id));
                            }
                        }
                    }
                }
            }
            system.debug('wrapperMap Final--->'+wrapperMap);
            return wrapperMap;
        } catch (Exception e) {
            //throw new AuraHandledException(e.getMessage());    
            throw e;	
        }
    }

    /**
     * getAllCaseIntegrations - Fetches the Case Integration records
     * Specifically need this for Status and showing Buttons
     */
    @AuraEnabled(cacheable=true)
    public static List<ASF_Case_Integration__c> getAllCaseIntegrations(string caseId, list<string> intExtIds){
        List<ASF_Case_Integration__c> returnList = new List<ASF_Case_Integration__c>();
        if(caseId != null && intExtIds.size() > 0){
            returnList = [
                SELECT Id, Status__c, Integration_Ext_Id__c, LastModifiedDate
                FROM ASF_Case_Integration__c
                WHERE Integration_Ext_Id__c in:intExtIds
                AND Case__c =: caseId
                AND Status__c != 'Canceled'
                ORDER BY LastModifiedDate desc
            ];
        }
        return returnList;
    }

    /**
     * cancelPendingCaseIntegrations - Fetches the Case Integration records
     * which are Pending, and Cancels them. Needs to be invoked before a
     * Re Try Scenario is fired, and a new Case Integration record
     * is created
     */
    public static void cancelPendingCaseIntegrations(string caseId, string intExtId){
        List<ASF_Case_Integration__c> aciPending = [
            SELECT Id
            FROM ASF_Case_Integration__c
            WHERE Case__c =: caseId
            AND Integration_Ext_Id__c =: intExtId
            AND Status__c = 'Pending'
        ];

        for(ASF_Case_Integration__c aci: aciPending){
            aci.Status__c = 'Canceled';
        }
        update aciPending;
    }
      
    public class IntegrationWrapper{
        
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String response;
        @AuraEnabled
        public Id assignToId;
        @AuraEnabled
        public Case updatedCase;
        @AuraEnabled
        public Decimal priority;
    }

}