/**
 * @description       : Batch Class to assign ABSLI VRM Role Users to Account Teams for the Assets they have access to.
 * @author            : dhinesh.t@salesforce.com
 * @group             :
 * @last modified on  : 06-03-2024
 * @last modified by  : dhinesh.t@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   06-03-2024   dhinesh.t@salesforce.com   Initial Version
**/
global class ABSLI_AssignAccountTeamBatch implements Database.Batchable<sObject>,  Schedulable {
     /****************************************************************************************************************
     * @LOB - ABSLI
     * @Function - start function of batch
     * @param bC - Batchable Context
     * @return Database.getQueryLocator
     * @description - Method to get the satsifying asset records that VRM Role have access to
     *****************************************************************************************************************/
    global Database.QueryLocator start(Database.BatchableContext bC) {
    return Database.getQueryLocator([
        SELECT Id, Name, Assign_to_DM__c, Channel__c, Loyalty_Service_Agent_Name__c, AccountId
        FROM Asset
        WHERE (Assign_to_DM__c = 'Yes' OR Channel__c = 'DM' OR Loyalty_Service_Agent_Name__c != null) AND Business_Unit__c = 'ABSLI' AND Processing_State__c = 'Pending' AND LastModifiedDate >= LAST_N_DAYS:2
    ]);
	}

     /****************************************************************************************************************
     * @LOB - ABSLI
     * @Function - execute function of batch
     * @param bC - Batchable Context
     * @param scope - List of Assets
     * @description - Method to assign VRM role users as account Team Members to the accounts retrieved.
     *****************************************************************************************************************/
    global void execute(Database.BatchableContext bC, List<Asset> scope) {
    	Map<Id, Set<Id>> accountUserMap = new Map<Id, Set<Id>>();
    	//System.debug('Scope of records: ' + scope);

    	// Query users with the role 'ABSLI Virtual Relationship Manager'
    	Set<Id> roleUserIds = new Set<Id>();
    	for (User user : [SELECT Id FROM User WHERE UserRole.DeveloperName = 'ABSLI_Virtual_Relationship_Manager' AND IsActive = true]) {
        	roleUserIds.add(user.Id);
    	}

    	for (Asset asset : scope) {
        	if (!accountUserMap.containsKey(asset.AccountId)) {
            	accountUserMap.put(asset.AccountId, new Set<Id>());
        	}

        	// Add user ids from the role to the accountUserMap
        	accountUserMap.get(asset.AccountId).addAll(roleUserIds);
    	}
    	//System.debug(accountUserMap);

    	List<AccountTeamMember> accountTeamMembersToInsert = new List<AccountTeamMember>();

    	// Create AccountTeamMember records
    	for (Id accountId : accountUserMap.keySet()) {
        	for (Id userId : accountUserMap.get(accountId)) {
            	AccountTeamMember atm = new AccountTeamMember();
            	atm.AccountId = accountId;
            	atm.UserId = userId;
            	atm.TeamMemberRole = 'ABSLI Virtual Relationship Manager';
            	atm.AccountAccessLevel = 'Read';
            	atm.CaseAccessLevel = 'Edit';
            	atm.OpportunityAccessLevel = 'None';
            	accountTeamMembersToInsert.add(atm);
        	}
    	}
    	//System.debug(accountTeamMembersToInsert);
    	// Insert AccountTeamMember records
    	if (!accountTeamMembersToInsert.isEmpty()) {
        	insert accountTeamMembersToInsert;
    	}
        
        ABCL_AssetTriggerHandler.TriggerDisabled = True;
         try {
            List<Asset> assetsToUpdate = new List<Asset>();
            for (Asset asset : scope) {
                asset.Processing_State__c = 'Completed'; 
                assetsToUpdate.add(asset);
            }
    
            if (!assetsToUpdate.isEmpty()) {
                update assetsToUpdate;
            }
        } finally {
            ABCL_AssetTriggerHandler.TriggerDisabled = false;
        }
	}


    /****************************************************************************************************************
     * @LOB - ABSLI
     * @Function - finish function of batch
     * @param bC - Batchable Context
     * @description - Method to assign VRM role users as account Team Members to the accounts retrieved.
     *****************************************************************************************************************/
    global void finish(Database.BatchableContext bC) {
        //nothing to process here
    }

    /****************************************************************************************************************
     * @LOB - ABSLI
     * @Function - execute function of Schedulable
     * @param SC - Batchable Context
     * @description - Execute function of Schedulable
     *****************************************************************************************************************/
    public void execute(SchedulableContext sc) {
        // specify the task or method to be executed
    }
}