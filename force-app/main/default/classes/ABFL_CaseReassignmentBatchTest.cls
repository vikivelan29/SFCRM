@isTest
private class ABFL_CaseReassignmentBatchTest {
    @testSetup
    static void setupTestData(){
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        // Create test data with inactive owner users and cases
        User superManagerUser = new User(
            IsActive = true,
            Business_Unit__c='ABFL',
            FirstName = 'Test',
            LastName='Super Manager User',
            Username='supermanageruser1155@test.com',
            Email='supermanageruser1155@test.com',
            Alias = 'mgrt',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', 
            ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles'
        );
        insert superManagerUser;
        User managerUser = new User(
            IsActive = true,
            Business_Unit__c='ABFL',
            ManagerId = superManagerUser.id,
            FirstName = 'Test',
            LastName='Manager User',
            Username='manageruser1155@test.com',
            Email='manageruser1155@test.com',
            Alias = 'mgrt',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', 
            ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles'
        );
        insert managerUser;
        User user = new User(
            IsActive = true,
            Business_Unit__c='ABFL',
            FirstName = 'Test',
            LastName='Inactive User',
            Username='inactiveuser2255@test.com',
            Email='inactiveuser2255@test.com',
            ManagerId = managerUser.id,
            Alias = 'inact',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', 
            ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles'
        );
        insert user;
        System.runAs(user) {
        List<ABFL_Case_Detail__c> caseDetailList=ABFL_TestDataFactory.createCaseDetail('Corporate',true);
        Id caseDetailId=[select id from ABFL_Case_Detail__c limit 1].id;
        ABFL_TestDataFactory.createCaseRecords(100, caseDetailId, true);
        }
    }
    
    // Check for No Manager
    @isTest
    static void caseReassignmentNoManager(){
        User au=[select id,IsActive from User where Username=:'inactiveuser2255@test.com'];
        au.managerId = null;
        au.IsActive = false;
        update au;
        System.debug('***au'+au);
        // Start the batch job
        Test.startTest();
            ABFL_CaseReassignmentBatch batchJob = new ABFL_CaseReassignmentBatch();
            Database.executeBatch(batchJob);
        Test.stopTest();
        System.debug('***check->'+[select id,IsActive,managerId from User where Username=:'inactiveuser2255@test.com'].managerId);
        // Verify that the case owner has not been reassigned, as owner's manager is blank
        Case updatedCase = [SELECT Id, OwnerId FROM Case LIMIT 1];
        Assert.areEqual(au.Id, updatedCase.OwnerId);
       
    }

    // Check for 1 hierarchy
    @isTest
    static void caseReassignmentOneHierarchy(){
        System.debug('***check'+[SELECT Id, OwnerId,owner.Name FROM Case LIMIT 1].owner.Name);
        User au=[select id,IsActive,managerId from User where Username=:'inactiveuser2255@test.com'];
        au.IsActive = false;
        update au;
        
        // get user with 'Case Ownership Management' custom permission
        //Id psId = [SELECT id,Name from PermissionSet where name='Admin_User'].Id;
        //insert new PermissionSetAssignment(AssigneeId=UserInfo.getUserId(),PermissionSetId=psId);
        
        //System.runAs(new User(Id = UserInfo.getUserId())){
            // Start the batch job
            Test.startTest();
                ABFL_CaseReassignmentBatch batchJob = new ABFL_CaseReassignmentBatch();
                Database.executeBatch(batchJob);
            Test.stopTest();
        //}

        // Verify that the case owner has been reassigned to the active manager
        Case updatedCase = [SELECT Id, OwnerId FROM Case LIMIT 1];
        System.debug('***check'+[SELECT Id, OwnerId,owner.Name FROM Case LIMIT 1].owner.Name);
        Assert.areEqual(au.managerId, updatedCase.OwnerId);
       
    }
    
    // Check for 2 hierarchy
    @isTest
    static void caseReassignmentTwoHierarchy(){
        List<User> ulist = new List<User>();
        User manager = new User();
        for(User au: [select id,IsActive,ManagerId, Username from User where Username=:'inactiveuser2255@test.com' or Username=:'manageruser1155@test.com']){
            au.IsActive = false;
            ulist.add(au);
            if(au.username=='manageruser1155@test.com')
                manager = au; 
        }
        update ulist;
        
        // Start the batch job
        Test.startTest();
            ABFL_CaseReassignmentBatch batchJob = new ABFL_CaseReassignmentBatch();
            Database.executeBatch(batchJob);
        Test.stopTest();

        // Verify that the case owner has been reassigned to the active manager
        Case updatedCase = [SELECT Id, OwnerId FROM Case LIMIT 1];
        Assert.areEqual(manager.ManagerId, updatedCase.OwnerId);
       
    }
    
}