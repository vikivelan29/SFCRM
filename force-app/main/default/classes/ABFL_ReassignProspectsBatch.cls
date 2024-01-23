/*********************************************************
** Class        :  ABFL_ReassignProspectsBatch
** Author       :  Srjana
** Description  :  Reassigns cases from prospects to existing customers
** Created Date :  15/12/2023
*********************************************************/
global class ABFL_ReassignProspectsBatch implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        //String abfl = 'ABFL';
        // Query cases with lead lookup field and associated lead information
        return Database.getQueryLocator('SELECT Id, Subject, Lead__c, Lead__r.Email, Lead__r.PANNO__c FROM Case WHERE Business_Unit__c = \'ABFL\' AND Lead__c != null AND Lead__r.PANNO__c!=null AND Lead__r.Email!=null');
    }

    global void execute(Database.BatchableContext BC, List<Case> scope) {
        List<Case> casesToUpdate = new List<Case>();
        Set<String> leadEmailSet = new Set<String>();
        Set<String> leadPANSet = new Set<String>();
		List<Case> csList = new List<Case>();
			
        // Collect unique Email and PAN information from the cases
        for (Case c : scope) {
            if (c.Lead__c != null && c.Lead__r.Email != null && c.Lead__r.PANNO__c != null) {
                leadEmailSet.add(c.Lead__r.Email);
                leadPANSet.add(c.Lead__r.PANNO__c);
                casesToUpdate.add(c); // Remove the Lead association 
            }
        }
        
        // Map for Account - Key (Email-PAN)
        Map<String, Id> accKeyMap = new Map<String, Id>();
        for(Account rec: [Select id, PersonEmail,PAN__c from account where PersonEmail IN: leadEmailSet AND PAN__c IN: leadPANSet]){
            accKeyMap.put(rec.PersonEmail+':'+rec.PAN__c, rec.Id);
        }
        system.debug('***accKeyMap:'+accKeyMap);

        for(Case cs : casesToUpdate){
            if(accKeyMap.containsKey(cs.Lead__r.Email+':'+cs.Lead__r.PANNO__c)){
                // Map cases to Account
                cs.AccountId = accKeyMap.get(cs.Lead__r.Email+':'+cs.Lead__r.PANNO__c);
                // We can keep existing relationship to lead as well
                // cs.Lead__c = null;
                csList.add(cs);
            } 
        }
        
        // Update cases to remove Lead and assign to Account
        try {
            System.debug('csList: ' + csList);
            update csList;
        }catch (Exception e) {
            // Handle other exceptions
            System.debug('Error: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Batch job finished successfully.');
    }
}