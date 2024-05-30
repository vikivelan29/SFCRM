global class ABSLI_AssignAccountTeamBatch implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
    return Database.getQueryLocator([
        SELECT Id, Name, Assign_to_DM__c, Channel__c, Loyalty_Service_Agent_Name__c, AccountId 
        FROM Asset 
        WHERE (Assign_to_DM__c = 'Yes' OR Channel__c = 'DM' OR Loyalty_Service_Agent_Name__c != null)
    ]);
	}

    global void execute(Database.BatchableContext BC, List<Asset> scope) {
    	Map<Id, Set<Id>> accountUserMap = new Map<Id, Set<Id>>();
    	System.debug('Scope of records: ' + scope);

    	// Query users with the role 'ABSLI Virtual Relationship Manager'
    	Set<Id> roleUserIds = new Set<Id>();
    	for (User user : [SELECT Id FROM User WHERE UserRole.DeveloperName = 'ABSLI_Virtual_Relationship_Manager']) {
        	roleUserIds.add(user.Id);
    	}

    	for (Asset asset : scope) {
        	if (!accountUserMap.containsKey(asset.AccountId)) {
            	accountUserMap.put(asset.AccountId, new Set<Id>());
        	}

        	// Add user ids from the role to the accountUserMap
        	accountUserMap.get(asset.AccountId).addAll(roleUserIds);
    	}
    	System.debug(accountUserMap);

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
    	System.debug(accountTeamMembersToInsert);
    	// Insert AccountTeamMember records
    	if (!accountTeamMembersToInsert.isEmpty()) {
        	insert accountTeamMembersToInsert;
    	}	
	}



    global void finish(Database.BatchableContext BC) {
    }
}