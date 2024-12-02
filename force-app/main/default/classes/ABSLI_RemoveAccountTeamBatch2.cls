global class ABSLI_RemoveAccountTeamBatch2 implements Database.Batchable<sObject>, Schedulable {

    /****************************************************************************************************************
     * @Function - start function of batch
     * @param bC - Batchable Context
     * @return Database.getQueryLocator
     * @description - Method to get the assets where Business Unit = 'ABSLI' and Processing State = 'Pending'
     *****************************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext bC) {
        return Database.getQueryLocator([
            SELECT Id, AccountId, Assign_to_DM__c, Channel__c, Loyalty_Service_Agent_Name__c 
            FROM Asset 
            WHERE Business_Unit__c = 'ABSLI' 
            AND Processing_State__c = 'Pending' AND LastModifiedDate >= LAST_N_DAYS:2 ORDER BY AccountId ASC
        ]);
    }

    /****************************************************************************************************************
     * @Function - execute function of batch
     * @param bC - Batchable Context
     * @param scope - List of Assets
     * @description - Method to remove VRM role users as account team members if no assets for that account match the conditions
     *****************************************************************************************************************/
    global void execute(Database.BatchableContext bC, List<Asset> scope) {
        Set<Id> accountIdsInScope = new Set<Id>();
        for (Asset asset : scope) {
            accountIdsInScope.add(asset.AccountId);
        }

        Map<Id, Boolean> accountAssetConditionMap = new Map<Id, Boolean>();
        
        Map<Id, aggregateResult> mAccountVsEligibleAssets = new Map <Id, aggregateResult>([SELECT AccountId Id, COUNT(Id) FROM Asset WHERE AccountId IN :accountIdsInScope 
                                      														AND (Assign_to_DM__c = 'Yes' OR Channel__c = 'DM' OR Loyalty_Service_Agent_Name__c != null) GROUP BY AccountId]);
        List<AccountTeamMember> teamMembersToDelete = new List<AccountTeamMember>();

        // Find the account team members to remove for accounts with no valid assets
        for (Id accountId : accountIdsInScope) {
            if (!mAccountVsEligibleAssets.containsKey(accountId)) {
                teamMembersToDelete.addALL([SELECT Id 
                                            FROM AccountTeamMember 
                                            WHERE AccountId = :accountId 
                                            AND TeamMemberRole = 'ABSLI Virtual Relationship Manager']);
            }
        }

        if (!teamMembersToDelete.isEmpty()) {
            delete teamMembersToDelete;
        }
        
        ABCL_AssetTriggerHandler.TriggerDisabled = True;
        List<Asset> assetsToUpdate = new List<Asset>();
        
        for (Asset asset : scope) {
            if (asset.Assign_to_DM__c != 'Yes' && asset.Channel__c != 'DM' && (asset.Loyalty_Service_Agent_Name__c == null || asset.Loyalty_Service_Agent_Name__c == '')) {
                asset.Processing_State__c = 'Completed';  
                assetsToUpdate.add(asset);
            }
        }

        if (!assetsToUpdate.isEmpty()) {
            update assetsToUpdate;
        }
        ABCL_AssetTriggerHandler.TriggerDisabled = False;
    }

    /****************************************************************************************************************
     * @Function - finish function of batch
     * @param bC - Batchable Context
     * @description - Nothing specific to process in the finish method for now
     *****************************************************************************************************************/
    global void finish(Database.BatchableContext bC) {
        Database.executeBatch(new ABSLI_AssignAccountTeamBatch(), 200);
    }

    /****************************************************************************************************************
     * @Function - execute function of Schedulable
     * @param SC - Schedulable Context
     * @description - Method to schedule the batch job
     *****************************************************************************************************************/
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ABSLI_RemoveAccountTeamBatch(), 200);
    }
}