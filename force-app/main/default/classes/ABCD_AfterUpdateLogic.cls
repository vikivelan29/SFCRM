/**
* @description       : 
* @author            : Salesforce
* @group             : 
* @last modified on  : 09-12-2024
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
* Modifications Log
* Ver   Date         Author                       Modification
* 1.0   04-24-2024   Salesforce   Initial Version
**/
public with sharing class ABCD_AfterUpdateLogic {
    public static void executeAfterInsertLogic(List<Case> newCases, Map<Id,Case> oldCasesMap){
        Map<Id,Case> litmusInvocableCases = new Map<Id,Case>();
        Map<Id,Case> oldMaplitmusInvocableCases = new Map<Id,Case>();

        for(Case currentCase : newCases){
            if(((currentCase.IsClosed == true && (oldCasesMap.get(currentCase.Id).IsClosed != true) 
               && ASF_Constants.RESOLVEDSTAGES.contains(currentCase.Status)) || ASF_Constants.RESOLVEDSTAGES.contains(currentCase.Stage__c)))
            {
                // THIS LOOP RUNS ADD CASES THOSE ARE RESOLVED AND ELIGIBLE FOR LITMUS CALLOUT.
                litmusInvocableCases.put(currentCase.Id,currentCase);
                oldMaplitmusInvocableCases.put(currentCase.Id,oldCasesMap.get(currentCase.Id));                
                
            }
        }
        if(litmusInvocableCases.keySet().size()>0){
            ABCD_LitmusIntegration.evaluateCasesForLitmus(litmusInvocableCases, oldMaplitmusInvocableCases);
        }
    }
}