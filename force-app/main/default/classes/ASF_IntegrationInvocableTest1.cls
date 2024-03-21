/*********************************************************
*Class        :  ASF_IntegrationInvocableTest1
*Author       :  Ritika Dhandia
*Description  :  Test Class, which implements the Integration Invocable
*********************************************************/
@isTest
public with sharing class ASF_IntegrationInvocableTest1 implements ASF_IntegrationInvocable{
    
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = 'Error';
        return result;
    }

    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integ, Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = 'Success';
        return result;
    }

    public void processResponse(ASF_Case_Integration__c caseInteg){

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