@isTest
private class ABSLI_AssignAccountTeamBatch_Test {
    
    @testSetup
    static void setupTestData() {
        UserRole role = [SELECT Id FROM UserRole WHERE DeveloperName = 'ABSLI_Virtual_Relationship_Manager' LIMIT 1];
        Profile pro = [SELECT Id FROM Profile WHERE Name = 'ABSLI Base Profile' LIMIT 1];
        // Create test users with the above role
        User user1 = new User(
            Alias = 'txt2',
            Email = 'testuser1@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User1',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser1@exampleABSLI.com',
            UserRoleId = role.Id,
            ProfileId = pro.Id
        );
        
        User user2 = new User(
            Alias = 'txt2',
            Email = 'testuser2@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User2',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser2@exampleABSLI.com',
            UserRoleId = role.Id,
            ProfileId = pro.Id
        );
        
        insert new List<User> { user1, user2 };
        
        // Create test account
         System.runAs(user1) {
            // Create test account
            Account acc = new Account(Name = 'Test Account');
            insert acc;
            
            // Create test assets
            List<Asset> assets = new List<Asset>();
            assets.add(new Asset(
                Name = 'Test Asset 1',
                AccountId = acc.Id,
                Assign_to_DM__c = 'Yes'
            ));
            
            assets.add(new Asset(
                Name = 'Test Asset 2',
                AccountId = acc.Id,
                Channel__c = 'DM'
            ));
            
            assets.add(new Asset(
                Name = 'Test Asset 3',
                AccountId = acc.Id,
                Loyalty_Service_Agent_Name__c = 'Agent Name'
            ));
            
            insert assets;
        }
    }
    
    @isTest
    static void testBatch() {
        Test.startTest();
        
        ABSLI_AssignAccountTeamBatch batch = new ABSLI_AssignAccountTeamBatch();
        system.debug('');
        Database.executeBatch(batch);
        
        Test.stopTest();
        
        List<AccountTeamMember> atmList = [SELECT Id, AccountId, UserId, TeamMemberRole 
                                           FROM AccountTeamMember];
        
        System.assertEquals(2, atmList.size(), 'There should be 2 AccountTeamMember records inserted.');
        
        // Verify the details of the inserted records
        Set<Id> userIds = new Set<Id>();
		for (User user : [SELECT Id FROM User WHERE UserRole.DeveloperName = 'ABSLI_Virtual_Relationship_Manager']) {
    		userIds.add(user.Id);
		}
        
        for (AccountTeamMember atm : atmList) {
            System.assertEquals('ABSLI Virtual Relationship Manager', atm.TeamMemberRole,'Should be Virtual Relationship Manager');
            System.assert(userIds.contains(atm.UserId), 'The UserId should belong to a user with the correct role.');
        }
    }
}
