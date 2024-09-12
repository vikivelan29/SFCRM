/**
* @description       : 
* @author            : Salesforce
* @group             : 
* @last modified on  : 08-01-2024
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
* Modifications Log
* Ver   Date         Author                       Modification
* 1.0   04-24-2024   Salesforce   Initial Version
**/
@SuppressWarnings('PMD.MethodNamingConventions, PMD.LocalVariableNamingConventions, PMD.VariableNamingConventions')
public with sharing class ABSLI_AfterUpdateLogic {
    // This method is used to invoke all the ABSLI Classes to be used in AfterUpdateLogic.
    public static void executeAfterInsertLogic(List<Case> newCases, Map<Id,Case> oldCasesMap){
        List<Case> absliCases = new List<Case>();
        Map<Id,Case> litmusInvocableCases = new Map<Id,Case>();
        Map<Id,Case> oldMaplitmusInvocableCases = new Map<Id,Case>();
        
        Map<Id,Case> absliOldCasesMap = new Map<Id,Case>();
        for(Case currentCase : newCases){
            if(currentCase.Business_Unit__c == ABSLI_Constants.BUSINESS_UNIT){
                absliCases.add(currentCase);
                absliOldCasesMap.put(currentCase.Id,oldCasesMap.get(currentCase.Id));
            }
            if(currentCase.Business_Unit__c == ABSLI_Constants.BUSINESS_UNIT && 
               ((currentCase.IsClosed == true && (oldCasesMap.get(currentCase.Id).IsClosed != true) 
               && ASF_Constants.RESOLVEDSTAGES.contains(currentCase.Status)) || ASF_Constants.RESOLVEDSTAGES.contains(currentCase.Stage__c)))
            {
                // THIS LOOP RUNS ADD CASES THOSE ARE RESOLVED AND ELIGIBLE FOR LITMUS CALLOUT.
                litmusInvocableCases.put(currentCase.Id,currentCase);
                oldMaplitmusInvocableCases.put(currentCase.Id,oldCasesMap.get(currentCase.Id));                
                
            }
        }
        
        if(absliCases.size()>0){
            updateTeamResolutionStatus(absliCases,absliOldCasesMap);
        }
        if(litmusInvocableCases.keySet().size()>0){
            ABSLI_LitmusIntegration.evaluateCasesForLitmus(litmusInvocableCases, oldMaplitmusInvocableCases);
        }
    }
    public static void updateTeamResolutionStatus(List<Case> newCases, Map<Id,Case> oldMap){
        List<ABSLI_Case_Detail__c> caseExtnList = new List<ABSLI_Case_Detail__c>();
        Set<Id> absliCaseExtnIds = new Set<Id>();
        for(Case currentCase : newCases){
            System.debug(currentCase.Stage__c != oldMap.get(currentCase.Id).Stage__c);
            System.debug(currentCase.Stage__c);
            System.debug(currentCase.ABSLI_Case_Detail__c);            
            if((currentCase.Stage__c != oldMap.get(currentCase.Id).Stage__c
              && (currentCase.Stage__c == ABSLI_Constants.RESOLVED_TEAM_RES_STATUS || 
                 currentCase.Stage__c == ABSLI_Constants.UNRESOLVED_TEAM_RES_STATUS))
              && currentCase.ABSLI_Case_Detail__c != null)
            {
                absliCaseExtnIds.add(currentCase.ABSLI_Case_Detail__c);
                System.debug('currentCase.ABSLI_Case_Detail__r.Resolution__c '+currentCase.ABSLI_Case_Detail__r.Resolution__c);
            }
        }
        if(absliCaseExtnIds.size()>0){
            Map<String, List<ASF_customPicklistUtility.picklistValues>> mResolutionVal = ASF_customPicklistUtility.getDependentPicklistValues('ABSLI_Case_Detail__c', 'Resolution__c');
            Map<String,Set<String>> mControlValVsDependentVal = new Map<String,Set<String>>();
            
            for(String controlVal : mResolutionVal.keySet()){
                if(!mControlValVsDependentVal.containsKey(controlVal)){
                    mControlValVsDependentVal.put(controlVal,new Set<String>());
                }
                for(ASF_customPicklistUtility.picklistValues dependentVal : mResolutionVal.get(controlVal)){
                    mControlValVsDependentVal.get(controlVal).add(dependentVal.label);
                }
            }
            Map<Id,ABSLI_Case_Detail__c> mCaseExtn = new Map<Id,ABSLI_Case_Detail__c>([SELECT ID,Outcome__c,Resolution__c FROM ABSLI_Case_Detail__c WHERE Id=:absliCaseExtnIds]);
            for(Case currentCase : newCases){
                if(mCaseExtn.containsKey(currentCase.ABSLI_Case_Detail__c)){
                    ABSLI_Case_Detail__c absliCaseExtn = mCaseExtn.get(currentCase.ABSLI_Case_Detail__c);
                    System.debug('before trim: ' + absliCaseExtn.Resolution__c);
                    absliCaseExtn.Outcome__c = ASF_Constants.RESOLVEDSTAGES.contains(currentCase.Stage__c) ? ABSLI_Constants.RESOLVED_TEAM_RES_STATUS : (ASF_Constants.REJECTIONSTATUSES.contains(currentCase.Stage__c) ? ABSLI_Constants.UNRESOLVED_TEAM_RES_STATUS : '');
                        if(mControlValVsDependentVal.containsKey(absliCaseExtn.Outcome__c)){
                            String allResolutions = String.join(mControlValVsDependentVal.get(absliCaseExtn.Outcome__c), ';');
                            System.debug('All Resolutions: ' + allResolutions);
                            
                            if(allResolutions != null && allResolutions != '' && absliCaseExtn.Resolution__c != null && absliCaseExtn.Resolution__c != ''){
                                List<String> resolutionValues = absliCaseExtn.Resolution__c.split(';');
                                Boolean allValuesValid = true;
                                for(String resolutionValue : resolutionValues){
                                    resolutionValue = resolutionValue.trim();
                                    if(!allResolutions.contains(resolutionValue)){
                                        allValuesValid = false;
                                        break;
                                    }
                                }
                                if(!allValuesValid){
                                    absliCaseExtn.Resolution__c = '';
                                }
                            }
                        }
                    caseExtnList.add(absliCaseExtn);
                }
            }
            if(caseExtnList.size()>0){
                update caseExtnList;
            }
        }
    }
    
     /**
     * @description This method is called from ASF_CaseTriggerBUSpecificHandler
     * If the case is Resolved by API, update the owner to API User
     * @param newCases
     * @param oldMap 
	 */
     public static void changeOwnerOnAutoResolve(List<Case> newCases, Map<Id, Case> oldMap){
        List<Case> eligibleCases = new List<Case>();
        for(Case caseRec : newCases){
            if(caseRec.Business_Unit__c == ABSLI_Constants.BUSINESS_UNIT && String.isBlank(caseRec.IRDAI_Token_Number__c) 
               && caseRec.Stage__c != oldMap.get(caseRec.Id).Stage__c 
               && caseRec.Stage__c == 'Resolved' && UserInfo.getName() == System.Label.ABCL_Integration_UserName){
                   eligibleCases.add(caseRec);
               }
        }
        if(!eligibleCases.isEmpty()){
            Map<Id, Case> caseFinalDMLMap = ASF_CaseTriggerModularHelper.getCaseFinalDMLMap();
            for(Case caseRec : eligibleCases){
                if(!caseFinalDMLMap.containsKey(caseRec.Id)){
                    Case caseObj = new Case(Id = caseRec.Id);
                    caseFinalDMLMap.put(caseRec.Id, caseObj);
                }
                Case caseRecFromMap = caseFinalDMLMap.get(caseRec.Id);
                caseRecFromMap.OwnerId = UserInfo.getUserId();
                caseFinalDMLMap.put(caseRecFromMap.Id, caseRecFromMap);
            }
        }   
    }
}