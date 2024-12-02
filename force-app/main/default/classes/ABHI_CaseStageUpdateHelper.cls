/***************************************
 *Class        :  ABHI_CaseStageUpdateHelper
 *Author       :  Kuldeep Mishra
 *Created Date :  15/10/2024
 *Last Modified:  15/10/2024
 *@description :  This class is used as trigger helper class.
 ***************************************/
@SuppressWarnings('PMD.CyclomaticComplexity,PMD.StdCyclomaticComplexity,PMD.CognitiveComplexity,PMD.NcssTypeCount')
public with sharing class ABHI_CaseStageUpdateHelper {
     /**********
     Method Name - MoveToStageMethod
     @description :  Method to update MoveToNext__c on required conditions.
     ***********/
    public static void moveToStageMethod(
        List<Case> newCases,
        List<Case> oldCases
    ) {
        Boolean stpCheck;
        Set<String> cccExternalIds = new Set<String>();
        for (Case newCase : newCases) {
            if(newCase.CCC_External_Id__c != null && newCase.Rejection_Reason__c==null) {
                cccExternalIds.add(newCase.CCC_External_Id__c);
            }
        }

        Map<String, ASF_Case_Category_Config__c> caseConfigMap = new Map<String, ASF_Case_Category_Config__c>(
            [
                SELECT
                    Id,
                    CCC_External_Id__c,
                    Overall_Case_Closure_SLA__c,
                    Nature__c,
                    Is_STP__c,
                    (
                        SELECT Id, Order__c, StageName__c
                        FROM Case_Stage_Configs__r
                    )
                FROM ASF_Case_Category_Config__c
                WHERE CCC_External_Id__c IN :cccExternalIds AND Is_STP__c = True AND Save_to_Next_Stage__c = True AND Nature__c = 'Request']);

        Map<String, ASF_Case_Category_Config__c> configMapByExternalId = new Map<String, ASF_Case_Category_Config__c>();
        for (ASF_Case_Category_Config__c config : caseConfigMap.values()) {
            configMapByExternalId.put(config.CCC_External_Id__c, config);
        }

        for (Integer i = 0; i < newCases.size(); i++) {
            Case newCase = newCases[i];
            Case oldCase = oldCases[i];

            if (newCase.CCC_External_Id__c !=oldCase.CCC_External_Id__c ||
                newCase.OwnerId != oldCase.OwnerId ||
                newCase.No_Auto_Communication__c !=
                oldCase.No_Auto_Communication__c ||
                newCase.Is_Recategorise_Allowed__c !=
                oldCase.Is_Recategorise_Allowed__c ||
                newCase.IsEscalated != oldCase.IsEscalated ||
                newCase.Recategorisation_Date__c !=
                oldCase.Recategorisation_Date__c ||
                newCase.Recategorisation_Reason__c !=
                oldCase.Recategorisation_Reason__c ||
                newCase.Escalation_Comment__c != oldCase.Escalation_Comment__c
            ) {
                //continue; // Skip processing this case if above condtions met.
                return; // Skip processing if the field has changed
            }
            //Integer orderValue = 0;
            //String stageName;
            if (newCase.CCC_External_Id__c != null) {
                ASF_Case_Category_Config__c config = configMapByExternalId.get(newCase.CCC_External_Id__c);
                if (config == null || config.Case_Stage_Configs__r.isEmpty()) {
                    return; // Skip if no config found
                }

                Integer orderValue = (Integer) config.Case_Stage_Configs__r[0].Order__c;
                String stageName = config.Case_Stage_Configs__r[0].StageName__c;
                String nature = config.Nature__c;

                    // Check for specific condition When stage move from  Previous Stage.
                    if ((oldCase.Previous_Stage__c == 'In Progress'|| oldCase.Previous_Stage__c =='Underwriting (In-Progress)'||oldCase.Previous_Stage__c =='Endorsement (In-Progress)') && 
                        newCase.Stage__c == 'Open' && nature == 'Request') {
                        newCase.MoveToNext__c = true;
                       }
                    if (
                        nature == 'Request' &&
                        orderValue == 1 &&
                        newCase.Stage__c == stageName &&
                        newCase.moved_back__c == false
                    ) {
                        newCase.MoveToNext__c = true;
                        
                    }
                }
            }
        }
    }