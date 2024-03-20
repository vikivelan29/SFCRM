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
            SELECT Id, Subject, Lead__c, SuppliedEmail,Business_Unit__c 
            FROM Case 
            WHERE Business_Unit__c IN :ABFL_Constants.ABFL_ABWM_BUSINESSUNIT
            //AND Lead__c != null
            AND SuppliedEmail != null
            AND AccountId = null 
            AND CreatedDate >= :startDate
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<Case> scope) {
        Set<String> setEmailID =  new Set<String>();
        Set<String> setBusinessUnit =  new Set<String>();
        Set<String> accountTagCheck = new Set<String>();
        Map<integer,List<Case>> mHashkeyVsCase = new Map<integer,List<Case>>();
        List<Case> casesToUpdate = new List<Case>();
        
        for (Case caseRecord : scope) {
            String caseBusinessUnit = caseRecord.Business_Unit__c;
            String caseEmailSupplied = caseRecord.SuppliedEmail;
            String compositeKey = caseBusinessUnit+'_'+caseEmailSupplied;
            integer iCompositeKey = compositeKey.hashCode();
            if(!mHashkeyVsCase.containsKey(iCompositeKey)){
                mHashkeyVsCase.put(iCompositeKey, new List<Case>());
            }
            mHashkeyVsCase.get(iCompositeKey).add(caseRecord);
            
            setEmailID.add(caseRecord.SuppliedEmail);  
            setBusinessUnit.add(caseRecord.Business_Unit__c);             
        }
        
        for(Contact con : [SELECT ID,Email,IsPersonAccount,Account.Business_Unit__c,AccountId FROM Contact WHERE (Email IN : setEmailID OR Account.Office_Email__c IN : setEmailId)
                           AND Account.Business_Unit__c IN : setBusinessUnit ORDER BY CreatedDate DESC])
        {
            String caseBusinessUnit = con.Account.Business_Unit__c;
            String caseEmailSupplied = con.Email;
            String compositeKey = caseBusinessUnit+'_'+caseEmailSupplied;
            integer iCompositeKey = compositeKey.hashCode();

            if(mHashkeyVsCase.containsKey(iCompositeKey) && !accountTagCheck.contains(compositeKey)){
                for(Case c : mHashkeyVsCase.get(iCompositeKey)){
                        c.AccountId = con.AccountId;
                    casesToUpdate.add(c);
                }
                accountTagCheck.add(compositeKey);
            }
        }
                
        if (!casesToUpdate.isEmpty()) {
            try {
                ASF_TriggerSkipperUtility.markTriggerRun('Case');
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