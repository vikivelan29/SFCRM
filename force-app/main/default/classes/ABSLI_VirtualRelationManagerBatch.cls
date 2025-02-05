public with sharing class ABSLI_VirtualRelationManagerBatch implements Database.Batchable<sObject>, Database.Stateful {
	public Database.QueryLocator start(Database.BatchableContext bc) {
		string query = 'SELECT Id, AccountId, UserId, TeamMemberRole FROM AccountTeamMember WHERE TeamMemberRole = \'ABSLI Virtual Relationship Manager\'';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext bc, List<AccountTeamMember> teams) {
		Set<Id> uniqueAccIds = new Set<Id>();
		for (AccountTeamMember team : teams) {
			uniqueAccIds.add(team.AccountId);
		}

		List<User> recentlyCreatedUser = [
			SELECT Id
			FROM User
			WHERE LastModifiedDate = LAST_N_DAYS:1 AND UserRole.Name = 'ABSLI Virtual Relationship Manager' and IsActive = true
		];

		List<AccountTeamMember> defaultTeams = new List<AccountTeamMember>();
		for (Id accId : uniqueAccIds) {
			for (User us : recentlyCreatedUser) {
				defaultTeams.add(
					new AccountTeamMember(
						AccountId = accId,
						UserId = us.Id,
						TeamMemberRole = 'ABSLI Virtual Relationship Manager',
                        AccountAccessLevel = 'Read',
            			CaseAccessLevel = 'Edit',
            			OpportunityAccessLevel = 'None'
					)
				);
			}
		}

		Database.SaveResult[] cmdList = Database.insert(defaultTeams, false);

		for (Database.SaveResult sr : cmdList) {
			if (!sr.isSuccess()) {
				for (Database.Error err : sr.getErrors()) {
					System.debug('The following error has occurred.');
					System.debug(err.getStatusCode() + ': ' + err.getMessage());
					System.debug('Account fields that affected this error: ' + err.getFields());
				}
			}
		}
	}

	public void finish(Database.BatchableContext bc) {
	}
}