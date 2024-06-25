global class ABSLI_RemoveAccountTeamBatch implements Database.Batchable<sObject>, Schedulable {

    global Database.QueryLocator start(Database.BatchableContext bC) {
        // Query AccountTeamMember records where the role is 'ABSLI Virtual Relationship Manager'
        return Database.getQueryLocator([
            SELECT Id, AccountId, UserId 
            FROM AccountTeamMember 
            WHERE TeamMemberRole = 'ABSLI Virtual Relationship Manager'
        ]);
    }

    global void execute(Database.BatchableContext bC, List<AccountTeamMember> scope) {
        Set<Id> accountIds = new Set<Id>();
        for (AccountTeamMember atm : scope) {
            accountIds.add(atm.AccountId);
        }

        // Query assets for the retrieved account IDs
        Map<Id, List<Asset>> accountAssetsMap = new Map<Id, List<Asset>>();
        for (Asset asset : [SELECT Id, AccountId, Assign_to_DM__c, Channel__c, Loyalty_Service_Agent_Name__c 
                            FROM Asset 
                            WHERE AccountId IN :accountIds]) {
            if (!accountAssetsMap.containsKey(asset.AccountId)) {
                accountAssetsMap.put(asset.AccountId, new List<Asset>());
            }
            accountAssetsMap.get(asset.AccountId).add(asset);
        }

        List<AccountTeamMember> accountTeamMembersToDelete = new List<AccountTeamMember>();

        // Check if the account's assets meet the criteria
        for (AccountTeamMember atm : scope) {
            Boolean meetsCriteria = false;
            if (accountAssetsMap.containsKey(atm.AccountId)) {
                for (Asset asset : accountAssetsMap.get(atm.AccountId)) {
                    if (asset.Assign_to_DM__c == 'Yes' || asset.Channel__c == 'DM' || asset.Loyalty_Service_Agent_Name__c != null) {
                        meetsCriteria = true;
                        break;
                    }
                }
            }

            // If the account's assets do not meet the criteria, add the AccountTeamMember to the list to delete
            if (!meetsCriteria) {
                accountTeamMembersToDelete.add(atm);
            }
        }

        // Delete AccountTeamMember records that do not meet the criteria
        if (!accountTeamMembersToDelete.isEmpty()) {
            delete accountTeamMembersToDelete;
        }
    }

    global void finish(Database.BatchableContext bC) {
        //nothing to process here
    }

    public void execute(SchedulableContext SC) {
        Database.executeBatch(new ABSLI_RemoveAccountTeamBatch());
    }
}