@isTest
public class ABSLAMC_OmniChannelServResBatchCtrlTest {
 private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name = 'System Administrator' LIMIT 1];
   
    @testSetup
    static void setup() {

        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser9199@example.com',
            Alias = 'tuser',
            CommunityNickname = 'tuser012',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = SYSTEMADMIN_PROFILE.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        // Run as the new user to perform setup operations (PermissionSet insert)
        System.runAs(testUser) {
            // Insert a Permission Set to simulate permission assignments
            PermissionSet permSet = new PermissionSet(Name = 'ABSLAMC_Test_Omnichannel',Label = 'Test PS');
            insert permSet;
        }

        // Create Users with various Omnichannel_Status__c values and an active status
        User userToAdd = new User(
            FirstName = 'John',
            LastName = 'Add',
            Omnichannel_Status__c = 'Add',
            IsActive = true,
            Business_Unit__c = 'ABSLAMC',
            Username = 'john.add@test.com',
            Email = 'john.add@test.com',
            Alias = 'jad',
            CommunityNickname = 'jad',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = SYSTEMADMIN_PROFILE.Id,
            LanguageLocaleKey = 'en_US'
        );
        
        User userToRemove = new User(
            FirstName = 'Jane',
            LastName = 'Remove',
            Omnichannel_Status__c = 'Remove',
            IsActive = true,
            Business_Unit__c = 'ABSLAMC',
            Username = 'jane.remove@test.com',
            Email = 'jane.remove@test.com',
            Alias = 'jrm',
            CommunityNickname = 'jrm',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = SYSTEMADMIN_PROFILE.Id,
            LanguageLocaleKey = 'en_US'
        );
        
        User userToReprocess = new User(
            FirstName = 'Doe',
            LastName = 'Reprocess',
            Omnichannel_Status__c = 'Reprocess',
            IsActive = true,
            Business_Unit__c = 'ABSLAMC',
            Username = 'doe.reprocess@test.com',
            Email = 'doe.reprocess@test.com',
            Alias = 'dor',
            CommunityNickname = 'dor',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = SYSTEMADMIN_PROFILE.Id,
            LanguageLocaleKey = 'en_US'
        );

        insert new List<User>{ userToAdd, userToRemove, userToReprocess };
        
        // Insert existing ServiceResource for Reprocess and Remove
        
        
        ServiceResource existingResourceRemove = new ServiceResource(
            Name = 'Jane Remove',
            ResourceType = 'A',
            RelatedRecordId = userToRemove.Id,
            IsActive = true
        );
        
        ServiceResource existingResourceReprocess = new ServiceResource(
            Name = 'Doe Reprocess',
            ResourceType = 'A',
            RelatedRecordId = userToReprocess.Id,
            IsActive = true
        );
        
        insert new List<ServiceResource>{ existingResourceRemove, existingResourceReprocess };
    }

    @IsTest(seeAllData = false)
    static void testBatchExecute() {
        Test.startTest();
        
        // Start the batch process
        ABSLAMC_OmniChannelServResBatchCtrl batch = new ABSLAMC_OmniChannelServResBatchCtrl();
        Database.executeBatch(batch);
        
        Test.stopTest();

        // Validate ServiceResource insertions and updates
        List<ServiceResource> insertedResources = [
            SELECT Name, ResourceType, RelatedRecordId, IsActive
            FROM ServiceResource
            WHERE RelatedRecordId =: [SELECT Id FROM User WHERE LastName = 'Add'].Id
        ];
        System.debug('servRes:'+insertedResources);
        
        System.assertEquals(1, insertedResources.size(), 'Expected one ServiceResource to be inserted');
        System.assertEquals('John Add', insertedResources[0].Name);
        System.assertEquals(true, insertedResources[0].IsActive);
        
        // Validate updates for Remove
        ServiceResource updatedResourceRemove = [
            SELECT Id, IsActive FROM ServiceResource 
            WHERE RelatedRecordId = :[SELECT Id FROM User WHERE LastName = 'Remove'].Id
        ];
        
        System.assertEquals(false, updatedResourceRemove.IsActive, 'Expected ServiceResource for "Remove" user to be inactive');
        
        // Validate updates for Reprocess
        ServiceResource updatedResourceReprocess = [
            SELECT Id, Name FROM ServiceResource 
            WHERE RelatedRecordId = :[SELECT Id FROM User WHERE LastName = 'Reprocess'].Id
        ];
        
        System.assertEquals('Doe Reprocess', updatedResourceReprocess.Name, 'Expected ServiceResource name to be updated for "Reprocess"');
        
        // Verify PermissionSet assignments
        List<PermissionSetAssignment> psaList = [
            SELECT Id FROM PermissionSetAssignment 
            WHERE AssigneeId =:[SELECT Id FROM User WHERE LastName = 'Add'].Id
        ];
        
        System.assertEquals(1, psaList.size(), 'Expected permission set assignment for "Add" user'); 
    }
}