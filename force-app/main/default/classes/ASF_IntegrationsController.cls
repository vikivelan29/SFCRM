/*********************************************************
*Class        :  ASF_IntegrationsController
*Author       :  Ritika Dhandia
*Description  :  Backend Controller for ASF Integrations
*********************************************************/
public with sharing class ASF_IntegrationsController {

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
                SELECT Id, Processing_Class__c, STP_Processing_Class__c,
                    External_Id__c, Type__c, Display_Name__c
                FROM ASF_Integration__c
                WHERE C3ExternalId__c =: c3ExtId
                AND Case_Stage_Config__r.StageName__c =: stageName
                AND (Type__c = 'Process' OR Type__c = 'Pre Populate')
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
                    UI_Component__c, Auto_Run_on_Load__c
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
    }

}