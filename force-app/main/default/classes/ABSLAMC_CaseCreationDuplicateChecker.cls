public class ABSLAMC_CaseCreationDuplicateChecker {
    
    public static void runDuplicateCheck2(List<Case> caseList) {
        
        if (UserInfo.getProfileId() == [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id) {
            return;
        }
        string errorMsg = Label.ABSLAMC_Duplicate_Case_Error_Message; 
        Map<String, List<Case>> caseKeyToCases = new Map<String, List<Case>>();
        List<Case> existingCases = [
            SELECT Id, CaseNumber, CCC_External_Id__c, Type_text__c , Sub_Type_Text__c, AccountId, AssetId, Status,Source__c
            FROM Case
            WHERE Status IN ('New', 'In Progress')
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
            if (newCase.CCC_External_Id__c != null &&
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