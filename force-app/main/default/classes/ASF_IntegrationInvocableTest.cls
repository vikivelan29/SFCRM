/*********************************************************
*Class        :  ASF_IntegrationInvocableTest
*Author       :  Ritika Dhandia
*Description  :  Test Class, which implements the Integration Invocable
*********************************************************/
@isTest
public with sharing class ASF_IntegrationInvocableTest implements ASF_IntegrationInvocable{
    
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = 'Success';
        return result;
    }

    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integ, Case caseRec){
        // Create New Case Integration with Pending Type
        ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
        caseInteg.Integration_Ext_Id__c = integ.External_Id__c;
        caseInteg.Case__c = caseRec.Id;

        // Accroding to the Integration Result above, set
        // to Success / Failure. Pending will be used for Async Integrations
        caseInteg.Status__c = 'Pending';
        insert caseInteg;
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = 'Success';
        return result;
    }

    public void processResponse(ASF_Case_Integration__c caseInteg){
        // Close the Case
        Case cs = new Case();
        cs.Id = caseInteg.Case__c;
        cs.Status = 'Closed';
        update cs;

    }

    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> returnMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        for(Case caseRec : caseRecs){
            returnMap.put(caseRec.Id, evaluate(caseRec));
        }
        return returnMap;
    }
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> returnMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        for(Case caseRec : caseRecs){
            for(ASF_Integration__c integ : integs.get(caseRec.Id)){
                returnMap.put(caseRec.Id, run(integ, caseRec));
            }
        }
        return returnMap;
    }

}