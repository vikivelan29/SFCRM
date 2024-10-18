public with sharing class ABHI_CaseStageUpdateHelper {
      public static void MoveToStageMethod(List<Case> newCases, List<Case> oldCases) {
        DateTime currentDateTime = System.now();
        DateTime twoHoursFromNow = currentDateTime.addHours(2);
          
          Set<String> cccExternalIds = new Set<String>();
    for (Case newCase : newCases) {
        if (newCase.CCC_External_Id__c != null) {
            cccExternalIds.add(newCase.CCC_External_Id__c);
        }
    }

Map<String, ASF_Case_Category_Config__c > caseConfigMap = new Map<String, ASF_Case_Category_Config__c >(
        [SELECT Id,CCC_External_Id__c,(SELECT Id, Order__c FROM Case_Stage_Configs__r)
         FROM ASF_Case_Category_Config__c 
         WHERE CCC_External_Id__c IN :cccExternalIds]
    );
          
          Map<String, ASF_Case_Category_Config__c> configMapByExternalId = new Map<String, ASF_Case_Category_Config__c>();
        for (ASF_Case_Category_Config__c config : caseConfigMap.values()) {
            configMapByExternalId.put(config.CCC_External_Id__c, config);
        }

        for (Integer i = 0; i < newCases.size(); i++) {
            Case newCase = newCases[i];
            Case oldCase = oldCases[i];
            
            if (newCase.OwnerId != oldCase.OwnerId || newCase.No_Auto_Communication__c != oldCase.No_Auto_Communication__c || newCase.Is_Recategorise_Allowed__c!= oldCase.Is_Recategorise_Allowed__c || newCase.IsEscalated!= oldCase.IsEscalated || newCase.Recategorisation_Date__c != oldCase.Recategorisation_Date__c || newCase.Recategorisation_Reason__c != oldCase.Recategorisation_Reason__c || newCase.Escalation_Comment__c != oldCase.Escalation_Comment__c) {
                return; // Skip processing if the field has changed
                
            }

            Integer orderValue = 0;
          if (newCase.CCC_External_Id__c != null) {
        if (configMapByExternalId.containsKey(newCase.CCC_External_Id__c)) {
                    ASF_Case_Category_Config__c config = configMapByExternalId.get(newCase.CCC_External_Id__c);
            if (!config.Case_Stage_Configs__r.isEmpty()) {
                orderValue = (Integer)config.Case_Stage_Configs__r[0].Order__c;
                System.debug('Order value for case ' + newCase.Id + ': ' + orderValue);
            }
        } else {
            System.debug('CCC_External_Id not found in config map: ' + newCase.CCC_External_Id__c);
        }
    } else {
        System.debug('CCC_External_Id is null for case: ' + newCase.Id);
    }

            // Check Overall_Case_Closure_SLA__c and required condtions
            if (orderValue == 1 && newCase.Overall_Case_Closure_SLA__c != null && newCase.Overall_Case_Closure_SLA__c <= twoHoursFromNow && newCase.Overall_Case_Closure_SLA__c > currentDateTime) { 
                newCase.MoveToNext__c  = true;    
            }else{
                System.debug('MoveToNext__c condition not met');
            }
        }
    }

}