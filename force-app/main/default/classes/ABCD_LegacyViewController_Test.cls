@IsTest
public class ABCD_LegacyViewController_Test {
    @testSetup
    static void testSetup() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        System.runAs(adminUser) {
            Account acc = new Account(Name = 'Test Account');
            insert acc;
            Asset asset = new Asset(Name = 'Test Asset', AccountId = acc.Id);
            insert asset;
        }
    }
    @IsTest
    static void testGetRelatedPolicyNames() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        System.runAs(adminUser) {
            Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account'];
            Test.startTest();
            List<ABCD_LegacyViewController.PolicyName> policyNames = ABCD_LegacyViewController.getRelatedPolicyNames(acc.Id);
            Test.stopTest();
            System.assertEquals(1, policyNames.size());
        }
    }
    @IsTest
    static void testGetLegacyData() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        System.runAs(adminUser) {
            Test.startTest();
            ABCD_LegacyViewController.ResponseWrapper response = ABCD_LegacyViewController.getLegacyData('1234567890', 'test@test.com');
            Test.stopTest();
            System.assertEquals(0, response.statusCode);
            System.assertEquals(null, response.legacyCaseResponse);
        }
    }
}