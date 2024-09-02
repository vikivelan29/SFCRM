/*********************************************************
*@Class        :  ABSLAMC_BU_CTSTHelper
*@Author       :  Santosh
*@Created Date :  8/30/2024
*@Last Modified:  8/30/2024
*@description  :  Class for ABSLAMC BU Specific Methods. 
*********************************************************/

public with sharing class ABSLAMC_BU_CTSTHelper {
    
    
    /**
* @param newCaseList - list of new value cases from trigger
* @param olCasesMap - Map of old value cases from trigger
* @return null
* @description - calling this method in Before update trigger to Restring agent's backward movement from Stage 3 to Stage 1 for ABSLAMC BU for Journey 5 - US PR1030924-53
*/
    public static void restrictBackStageMovementFromStage3ToSatage1(Map<Id, Case> newCaseMap, Map<Id, Case> oldCasesMap){
        String backstageError = System.label.ABSLAMC_Back_Stage_Movement_Error;
        for(Case currentCase: newCaseMap.values()){
            Case oldCase = oldCasesMap.get(currentCase.Id);
            if(currentCase.Stage__c != oldCase.Stage__c  && currentCase.Pending_Clarification__c && currentCase.Business_Unit__c == ABSLAMC_Constants.ABSLAMCBU
               && oldCase.Stage__c == ABSLAMC_Constants.REPLY_RECEIVED_FROM_APP_SUPPORT && currentCase.Stage__c == ABSLAMC_Constants.OPEN_STAGE){
                   currentCase.addError(backstageError);
               }
        }
    }
    
}