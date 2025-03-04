public class ABSLAMC_CaseCreationDuplicateChecker {
    
    public static void runDuplicateCheck2(List<Case> caseList) {
        
        string ruleByPassProfs = label.ABSLAMC_CaseDuplicateAdminByPass; 
        List<String> adminBypassList = new List<String>(ruleByPassProfs.split(','));
        
        Map<Id, Profile> bypassProfilesMap = new Map<Id, Profile>(
            [SELECT Id, Name FROM Profile WHERE Name IN :adminBypassList]
        );
        if (bypassProfilesMap.containsKey(UserInfo.getProfileId())) {
            return;
        }
  
        string errorMsg = Label.ABSLAMC_Duplicate_Case_Error_Message;         
        Map<String, List<Case>> caseKeyToCases = new Map<String, List<Case>>();
        List<Case> existingCases = [
            SELECT Id, CaseNumber, CCC_External_Id__c, Type_text__c , Sub_Type_Text__c, AccountId, AssetId, Status,Source__c,Business_Unit__c
            FROM Case
            WHERE Status IN ('New', 'In Progress')
            AND Business_Unit__c =: ABSLAMC_Constants.ABSLAMCBU
            AND AccountId != null
            AND AssetId != null
            AND CCC_External_Id__c != null
            AND Type_text__c  != null
            AND Sub_Type_Text__c != null
        ];
        
        for (Case c : existingCases) {
            String key = c.CCC_External_Id__c + '|' + c.Type_text__c  + '|' + c.Sub_Type_Text__c + '|' + c.AccountId + '|' + c.AssetId;
            if (!caseKeyToCases.containsKey(key)) {
                caseKeyToCases.put(key, new List<Case>());
            }
            caseKeyToCases.get(key).add(c);
        }
        
        for (Case newCase : caseList) {
            if (newCase.Technical_Source__c == 'LWC' &&
                newCase.CCC_External_Id__c != null &&
                newCase.Type_text__c  != null &&
                newCase.Sub_Type_Text__c != null &&
                newCase.AccountId != null &&
                newCase.AssetId != null &&
                (newCase.Status == 'New' || newCase.Status == 'In Progress')) {
                    String newKey = newCase.CCC_External_Id__c + '|' + newCase.Type_text__c  + '|' + newCase.Sub_Type_Text__c + '|' + newCase.AccountId + '|' + newCase.AssetId;
                    if (caseKeyToCases.containsKey(newKey)) {
                        for (Case existingCase : caseKeyToCases.get(newKey)) {
                            errorMsg = errorMsg.replace('<CaseNumber>', existingCase.CaseNumber).replace('<SOURCE>', existingCase.Source__c);
                            newCase.addError(errorMsg);
                        }
                    }
                }
        }
    }
}