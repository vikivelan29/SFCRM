/*********************************************************
** Class        :  ABFL_ReassignProspectsBatch
** Author       :  Srjana
** @description  :  Reassigns cases from prospects to existing customers
** Created Date :  15/12/2023
*********************************************************/
public class ABFL_ReassignProspectsBatch implements Database.Batchable<sObject>, schedulable {
    /**
     * @description Start method to return the query locator for the batch job.
     * @param bc The batchable context.
     * @return Database.QueryLocator containing the query for fetching assets.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Fetch the configurable number of days from Custom Label
        Integer numberOfDays = Integer.valueOf(System.Label.ABFL_Reassign_Case_Days);
        Date startDate = Date.today().addDays(-numberOfDays);
        // Query for cases where Business_Unit__c is 'ABFL' and SuppliedEmail is not null
        return Database.getQueryLocator([
            SELECT Id, Subject, Lead__c, SuppliedEmail,Business_Unit__c 
            FROM Case 
            WHERE Business_Unit__c IN :ABFL_Constants.ABFL_ABWM_BUSINESSUNIT
            AND SuppliedEmail != null 
            AND AccountId = null 
            AND CreatedDate >= :startDate
        ]);
    }
    
    /**
     * @description Execute method to process the batch records.
     * @param bc The batchable context.
     * @param scope The list of asset records to process.
     */
    public void execute(Database.BatchableContext bc, List<Case> scope) {
        try{
            Set<String> setEmailID =  new Set<String>();
            Set<String> setBusinessUnit =  new Set<String>();
            
            Map<integer,List<Case>> mHashkeyVsCase = new Map<integer,List<Case>>();
            Map<Id, Case> casesToUpdate = new Map<Id, Case>();
            
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
            
            for(Contact con : [SELECT ID,Email,Account.Office_Email__c,IsPersonAccount,Account.Business_Unit__c,AccountId FROM Contact WHERE AccountId != null AND (Email IN : setEmailID OR Account.Office_Email__c IN : setEmailId)
                               AND Account.Business_Unit__c IN : setBusinessUnit ORDER BY CreatedDate DESC])
            {
                String caseBusinessUnit = con.Account.Business_Unit__c;
                String caseEmailSupplied = setEmailID.contains(con.Email) ? con.Email : con.Account.Office_Email__c;
                String compositeKey = caseBusinessUnit+'_'+caseEmailSupplied;
                integer iCompositeKey = compositeKey.hashCode(); 
                
                if(mHashkeyVsCase.containsKey(iCompositeKey)){
                    for(Case c : mHashkeyVsCase.get(iCompositeKey)){
                        if(! casesToUpdate.containsKey(c.Id)){
                            c.AccountId = con.AccountId;
                            c.Lead__c = null;
                            c.typeSubTypeMismatch__c  = false;
                            c.Type_Sub_Type_Mismatch_Reason__c = null;
                            casesToUpdate.put(c.Id, c);
                        }
                    }
                    
                }
            }
            
            if (!casesToUpdate.isEmpty()) {
                ASF_TriggerSkipperUtility.markTriggerRun('Case');
                Database.update(casesToUpdate.values(),false);
            }
        }catch (Exception e) {
            // Handle exceptions
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABFL_ReassignProspectsBatch.execute');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.message(e.getStackTraceString());
            ABCL_Logger.emit();
        }
    }
    
     /**
     * @description Finish method to perform post-processing tasks after batch execution.
     * @param bc The batchable context.
     */
    public void finish(Database.BatchableContext bc) {
    }
    
    /**
     * @description execute method to schedule the ABFL_ReassignProspectsBatch
     * @param sc The schedulable context
     */
    public void execute(SchedulableContext sc) {
        database.executebatch(new ABFL_ReassignProspectsBatch(), 100);
    }
}