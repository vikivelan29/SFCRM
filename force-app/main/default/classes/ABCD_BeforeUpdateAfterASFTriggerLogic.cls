/**
 * @description       : BSLI BeforeUpdateTrigger Logic After ASF Code
 * @author            : Dhinesh
 * @group             : 
 * @last modified on  : 12-18-2024
 * @last modified by  : Dhinesh
**/
public class ABCD_BeforeUpdateAfterASFTriggerLogic {
     /**
     * @description This method is called from ASF_CaseTriggerBUSpecificHandler whenever a case is
     * updated. This is the parent method
     * @param newMap
     * @param oldMap
     */
    public Static Map<Id, Case> oneABCCasesAdditionalFields;
    public static void executeBeforeLogic(Map<Id, Case> newMap, Map<Id, Case> oldMap){
        Id frameworkRTId = ASF_Constants.RT_FRAMEWORK;
        Map<Id,Case> oneABCCases = new Map<Id,Case>();
        Map<ID,List<Case>> mRecordTypeVsCases = ASF_CaseDistributionBasedOnRT.getCaseByRecordType((List<Case>)newMap.values());
        if(mRecordTypeVsCases.containsKey(frameworkRTId)){
            Map<Id,Case> frameworkCases = new Map<Id,Case>(mRecordTypeVsCases.get(frameworkRTId));
            for(Case caseRec : frameworkCases.values()){
                if(caseRec.Business_Unit__c == ONEABC_Constants.ONEABC_BU){
                    oneABCCases.put(caseRec.Id,caseRec);
                }
            }
        }
        if(!oneABCCases.isEmpty()){
            oneABCCasesAdditionalFields = new Map<Id, Case>([SELECT Id,CCC_External_Id__c,CaseNumber,Nature__c,Stage__c,Technical_Source__c
                                       FROM Case 
                                       WHERE Id IN :oneABCCases.keySet() WITH SECURITY_ENFORCED]);
            System.debug('Inside ABSLI before Update Trigger logic');
            System.debug(oneABCCasesAdditionalFields);
        }
        ABCD_BeforeUpdateAfterASFTriggerLogic.restrictRejection(oneABCCases.values(),oldMap, newMap);
    }
    
    public static void restrictRejection(List<Case> oneABCCases, Map<Id, Case> oldMap,Map<Id, Case> newMap){
        if(!oneABCCases.isEmpty()){
            for (Case caseRec : oneABCCasesAdditionalFields.values()) {
                Case caseError = newMap.get(caseRec.Id);                
        		// Check if the Case record is related to ABSLI business unit
                if (caseError.Stage__c == 'Unresolved')  {
                       	   caseError.addError('OneABC Cases cannot be Unresolved.');
                           newMap.put(caseRec.Id,caseError);
                    	
                	}
            }
        }
	}
}