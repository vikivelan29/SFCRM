/*********************************************************
** Class        :  ABFL_CaseReassignmentBatch
** Author       :  Srjana
** Description  :  Reassigned cases to active user in owner’s manager hierarchy.
** Created Date :  15/12/2023
*********************************************************/

global class ABFL_CaseReassignmentBatch implements Database.Batchable<sObject>, Database.Stateful {
    private Map<Id, User> allactiveUser = new Map<Id, User>();
    private Map<Id, User> allInactiveUser = new Map<Id, User>();

    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Get active and inactive user map
        for(User rec: [SELECT Id, IsActive, ManagerId,Manager.Name FROM User]){
            if(rec.IsActive){
                allactiveUser.put(rec.Id, rec);
            }else{
                allInactiveUser.put(rec.Id, rec);
            }
        }
        
        // Query cases with inactive owner users
        List<String> closedCaseList = new List<String>{
            'Closed', 'Resolved', 'Unresolved', 'Closed Duplicate', 'Merged'
        };
        return Database.getQueryLocator([SELECT Id, OwnerId FROM Case WHERE Owner.IsActive = false AND Status NOT IN :closedCaseList]);
    }

    global void execute(Database.BatchableContext BC, List<Case> scope) {
        List<Case> casesToUpdate = new List<Case>();
        for (Case cs : scope) {
            String activeId = getActiveManagerId(cs.OwnerId);
            // Check for null cases as well
            if (String.isNotBlank(activeId)) {
                cs.OwnerId = activeId;
                casesToUpdate.add(cs);
            }
        }

        if (!casesToUpdate.isEmpty()) {
            try {
                Database.update(casesToUpdate);
            } catch (Exception e) {
                ABCL_Logger.enableExceptionLogging();
                ABCL_Logger.push('ABFL_CaseReassignmentBatch.execute');
                ABCL_Logger.message(e.getMessage());
                ABCL_Logger.emit();
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
    }

    // recurssive method to get manager Id
    private Id getActiveManagerId(Id userId){
        Id mgrId=userId;
        // in case userId (ManagerId in recurssive call) is not null
        if(userId!=null){
            if (allactiveUser.containsKey(allInactiveUser.get(userId).managerId)){
                // in case manager is active
                mgrId = allInactiveUser.get(userId).managerId;           
            }else if (!allactiveUser.containsKey(allInactiveUser.get(userId).managerId)){
                // in case manager is inactive - recurrsive call
                mgrId = getActiveManagerId(allInactiveUser.get(userId).managerId);            
            }
        }
        return mgrId;
    }
}