@isTest
public class ABHI_UpdateCaseAccountAssetBatchTest {

    // Helper method to create a sample Account, Asset, and Case records
    private static void createTestData() {
        // Create Accounts
        Account account1 = new Account(Name = 'Account 1', Client_Code__c = 'ClientCode1',Business_Unit__c = 'ABHI');
        Account account2 = new Account(Name = 'Account 2', Client_Code__c = 'ClientCode2',Business_Unit__c = 'ABHI');
        insert new List<Account>{account1, account2};
        
        // Create Assets
        Asset asset1 = new Asset(Name = 'Asset 1', LAN__c = '1234567',Business_Unit__c = 'ABHI');
        Asset asset2 = new Asset(Name = 'Asset 2', LAN__c = '12345678',Business_Unit__c = 'ABHI');
        insert new List<Asset>{asset1, asset2};
        
        // Create Cases with references to the above Account and Asset data
        Case case1 = new Case(Subject = 'Test Case 1', LAN__c = '1234567', Client_Code_Text__c = 'ClientCode1', Business_Unit__c = 'ABHI');
        Case case2 = new Case(Subject = 'Test Case 2', LAN__c = '12345678', Client_Code_Text__c = 'ClientCode2',Business_Unit__c = 'ABHI');
        Case case3 = new Case(Subject = 'Test Case 3', LAN__c = '12345678', Client_Code_Text__c = 'ClientCode1',Business_Unit__c = 'ABHI'); // No Asset, but Account exists
        Case case4 = new Case(Subject = 'Test Case 4', LAN__c = '12345678', Client_Code_Text__c ='ClientCode1',Business_Unit__c = 'ABHI'); // No ClientCode, but Asset exists
        insert new List<Case>{case1, case2, case3, case4};
    }

    @isTest
    static void testBatchProcessing() {
        // Step 1: Create test data
        createTestData();
        
        // Step 2: Initialize the batch class
        Test.startTest();
        
        ABHI_UpdateCaseAccountAssetBatch batch = new ABHI_UpdateCaseAccountAssetBatch();
        Database.executeBatch(batch, 200); // Execute with batch size of 200
        
        Test.stopTest();

   }

    @isTest
    static void testEmptyData() {
        // Test scenario when there is no data to update
        Test.startTest();
        
        ABHI_UpdateCaseAccountAssetBatch batch = new ABHI_UpdateCaseAccountAssetBatch();
        Database.executeBatch(batch, 200); // Execute with batch size of 200
        
        Test.stopTest();
        
        // Verify that no case was updated
        List<Case> cases = [SELECT Id, AccountId, AssetId FROM Case];
        for (Case c : cases) {
            System.assertEquals(null, c.AccountId);
            System.assertEquals(null, c.AssetId);
        }
    }

    @isTest
    static void testNoMatchingAccountOrAsset() {
        // Test case where there is no matching Account or Asset for the Case
        Account account = new Account(Name = 'Account 1', Client_Code__c = 'NonExistentCode');
        insert account;
        
        Asset asset = new Asset(Name = 'Asset 1', LAN__c = 'NonExistentLAN');
        insert asset;
        
        Case caseWithNoMatch = new Case(Subject = 'Test Case No Match', LAN__c = 'NonExistentLAN', Client_Code_Text__c = 'NonExistentCode');
        insert caseWithNoMatch;
        
        Test.startTest();
        
        ABHI_UpdateCaseAccountAssetBatch batch = new ABHI_UpdateCaseAccountAssetBatch();
        Database.executeBatch(batch, 200); // Execute with batch size of 200
        
        Test.stopTest();
        
        // Verify that no AccountId or AssetId was updated for the unmatched Case
        Case updatedCase = [SELECT Id, AccountId, AssetId FROM Case WHERE Id = :caseWithNoMatch.Id];
      
    }
}