/*********************************************************
** Class        :  ABFL_CaseReassignmentBatch
** Author       :  Srjana
** Description  :  Reassigned cases to active user in owner’s manager hierarchy.
** Created Date :  15/12/2023
*********************************************************/

global class ABFL_CaseReassignmentBatch implements Database.Batchable<sObject>, Database.Stateful {
    Map<Id, User> allactiveUser = new Map<Id, User>();

    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Query cases with inactive owner users
        List<String> closedCaseList = new List<String>{
            'Closed', 'Resolved', 'Unresolved', 'Closed Duplicate', 'Merged'
        };
        return Database.getQueryLocator([SELECT Id, OwnerId FROM Case WHERE Owner.IsActive = false AND Status NOT IN :closedCaseList]);
    }

    global void execute(Database.BatchableContext BC, List<Case> scope) {
        if (allactiveUser.isEmpty()) {
            allactiveUser = new Map<Id, User>([SELECT Id, ManagerId FROM User WHERE IsActive = true]);
        }

        List<Case> casesToUpdate = new List<Case>();
        for (Case cs : scope) {
            String activeId = getActiveManagerId(cs.OwnerId);
            if (String.isNotBlank(activeId)) {
                cs.OwnerId = activeId;
                casesToUpdate.add(cs);
            }
        }

        if (!casesToUpdate.isEmpty()) {
            try {
                Database.update(casesToUpdate);
            } catch (Exception e) {
                System.debug('Error updating cases: ' + e.getMessage());
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
    }

    public Id getActiveManagerId(Id userId) {
        if (allactiveUser.isEmpty() || userId == null) {
            return userId;
        } else if (allactiveUser.containsKey(userId)) {
            return allactiveUser.get(userId).ManagerId;
        } else {
            return userId;
        }
    }
}