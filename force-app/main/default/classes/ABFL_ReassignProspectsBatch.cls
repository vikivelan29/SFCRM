/*********************************************************
** Class        :  ABFL_ReassignProspectsBatch
** Author       :  Srjana
** Description  :  Reassigns cases from prospects to existing customers
** Created Date :  15/12/2023
*********************************************************/
global class ABFL_ReassignProspectsBatch implements Database.Batchable<sObject> {
    
        global Database.QueryLocator start(Database.BatchableContext BC) {
        // Fetch the configurable number of days from Custom Label
        Integer numberOfDays = Integer.valueOf(System.Label.ABFL_Reassign_Case_Days);
        Date startDate = Date.today().addDays(-numberOfDays);
            system.debug('Start Date:' + startDate);
        // Query for cases where Business_Unit__c is 'ABFL' and SuppliedEmail is not null
        return Database.getQueryLocator([
            SELECT Id, Subject, Lead__c, SuppliedEmail 
            FROM Case 
            WHERE Business_Unit__c = :ASF_Constants.ABFL_BU
            AND SuppliedEmail != null 
            AND AccountId = null 
            AND CreatedDate >= :startDate
        ]);
    }

    global void execute(Database.BatchableContext BC, List<Case> scope) {
        Map<String, Id> emailToAccountIdMap = new Map<String, Id>();
        
        // Populate email to Account Id mapping
        for (Case caseRecord : scope) {
            // Query for the most recent Account related to the SuppliedEmail
            for (Account acc : [SELECT Id, PersonEmail, Office_Email__c, IsPersonAccount 
                                FROM Account 
                                WHERE PersonEmail = :caseRecord.SuppliedEmail OR Office_Email__c = :caseRecord.SuppliedEmail 
                                ORDER BY CreatedDate DESC LIMIT 1]) {
                if (acc.IsPersonAccount) {
                    emailToAccountIdMap.put(acc.PersonEmail, acc.Id);
                } else {
                    emailToAccountIdMap.put(acc.Office_Email__c, acc.Id);
                }
            }
        }
        
        // Update cases to remove Lead and assign to Account
        List<Case> casesToUpdate = new List<Case>();
        for (Case caseRecord : scope) {
            if (emailToAccountIdMap.containsKey(caseRecord.SuppliedEmail)) {
                caseRecord.AccountId = emailToAccountIdMap.get(caseRecord.SuppliedEmail);
                casesToUpdate.add(caseRecord);
            }
        }
        
        // Update cases
        if (!casesToUpdate.isEmpty()) {
            try {
                update casesToUpdate;
            } catch (Exception e) {
                // Handle exceptions
                System.debug('Error: ' + e.getMessage());
                ABCL_Logger.enableExceptionLogging();
            	ABCL_Logger.push('ABFL_ReassignProspectsBatch.execute');
            	ABCL_Logger.message(e.getMessage());
            	ABCL_Logger.emit();
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Batch job finished successfully.');
    }
}