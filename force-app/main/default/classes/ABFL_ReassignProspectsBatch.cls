/*********************************************************
** Class        :  ABFL_ReassignProspectsBatch
** Author       :  Srjana
** Description  :  Reassigns cases from prospects to existing customers
** Created Date :  15/12/2023
*********************************************************/
global class ABFL_ReassignProspectsBatch implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('SELECT Id, Subject, Lead__c, SuppliedEmail FROM Case WHERE Business_Unit__c = \'ABFL\' AND Lead__c != null AND SuppliedEmail != null');
    }

    global void execute(Database.BatchableContext BC, List<Case> scope) {
        List<Case> casesToUpdate = new List<Case>();
        Set<String> SuppliedEmailSet = new Set<String>();
        List<Case> csList = new List<Case>();
        
        // Collect unique SuppliedEmail from the cases
        for (Case c : scope) {
            if (c.Lead__c != null && c.SuppliedEmail != null) {
                SuppliedEmailSet.add(c.SuppliedEmail);
                casesToUpdate.add(c); // Prepare for update
            }
        }
        
        // Map for Account - Key (Email)
        Map<String, Id> accKeyMap = new Map<String, Id>();
        for (Account acc : [SELECT Id, PersonEmail FROM Account WHERE PersonEmail IN :SuppliedEmailSet Order By CreatedDate desc limit 1]) {
            accKeyMap.put(acc.PersonEmail, acc.Id);
        }

        for (Case cs : casesToUpdate) {
            if (accKeyMap.containsKey(cs.SuppliedEmail)) {
                // Map cases to Account
                cs.AccountId = accKeyMap.get(cs.SuppliedEmail);
                csList.add(cs);
            }
        }
        
        // Update cases to remove Lead and assign to Account
        try {
            update csList;
        } catch (Exception e) {
            // Handle exceptions
            System.debug('Error: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Batch job finished successfully.');
    }
}