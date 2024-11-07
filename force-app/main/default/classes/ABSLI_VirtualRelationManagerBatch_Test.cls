@IsTest
public with sharing class ABSLI_VirtualRelationManagerBatch_Test {
	@TestSetup
	static void setupTestData() {
		Account accRec = ASF_TestDataFactory.insertPersonAccount('Abinash', 'Panigrahi', '100');
		AccountTeamMember member = new AccountTeamMember(
			AccountId = accRec.Id,
			UserId = UserInfo.getUserId(),
			TeamMemberRole = 'ABSLI Virtual Relationship Manager'
		);
		insert member;
	}

	@IsTest
	public static void testBatch() {
        ASF_TestDataFactory.createCS60User();
		User userRec = [SELECT Id, UserRoleId FROM User WHERE Email = 'CS360@FCAAdmin.mock.com'];
		userRec.UserRoleId = [SELECT Id FROM UserRole WHERE Name = 'ABSLI Virtual Relationship Manager'].Id;
		update userRec;
		Test.startTest();
		Database.executeBatch(new ABSLI_VirtualRelationManagerBatch(), 1);
		Test.stopTest();
		List<AccountTeamMember> atmList = [
			SELECT Id
			FROM AccountTeamMember
			WHERE TeamMemberRole = 'ABSLI Virtual Relationship Manager'
		];
		System.Assert.areEqual(2, atmList.size());
	}
}