@isTest
public class ABHI_CaseCreationValidationTest {
    
    @testSetup
    static void setupData() {
        // Insert some Assets (policies) with various statuses and plan names
        List<Asset> assets = new List<Asset>{
            new Asset(Name = 'Policy 1', Status = 'Active', Plan_Name__c = 'Premier Plan'),
            new Asset(Name = 'Policy 2', Status = 'RJ', Plan_Name__c = 'Classic Plan'),
            new Asset(Name = 'Policy 3', Status = 'Active', Plan_Name__c = 'Standard Plan')
        };
        insert assets;
    }
    
    @isTest
    static void testCheckCreateCaseValidations() {
        // Retrieve Assets created in setup
        List<Asset> assets = [SELECT Id, Status, Plan_Name__c FROM Asset];
        
        // Query existing ABHI_Create_Case_Validations__mdt records (adjust filter as needed)
        List<ABHI_Create_Case_Validations__mdt> mdtRecords = [
            SELECT Label, Business_Unit__c, Issue_Code__c, Operator__c, Asset_Status__c, Error_Message__c
            FROM ABHI_Create_Case_Validations__mdt
            WHERE Business_Unit__c = 'ABHI'
            LIMIT 1
        ];
        
        if (mdtRecords.isEmpty()) {
            System.assert(false, 'No metadata records found for ABHI_Create_Case_Validations__mdt');
            return;
        }
        
        // Create test cases
        Case case1 = new Case(
            Business_Unit__c = 'ABHI',
            Technical_Source__c = 'LWC',
            CCC_External_Id__c = mdtRecords[0].Issue_Code__c,
            AssetId = assets[0].Id
        );
        
        Case case2 = new Case(
            Business_Unit__c = 'ABHI',
            Technical_Source__c = 'LWC',
            CCC_External_Id__c = 'NonMatchingCode',
            AssetId = assets[1].Id
        );
        
        // Insert test cases
        insert new List<Case>{case1, case2};
        
        // Load cases and prepare map
        List<Case> cases = [SELECT Id, Business_Unit__c, Technical_Source__c, CCC_External_Id__c, AssetId FROM Case];
        Map<Id, Case> mapOfIdToOldCase = new Map<Id, Case>(cases);
        
        Test.startTest();
        
        // Call the validation method
        ABHI_CaseCreationValidation.checkCreateCaseValidations(cases, mapOfIdToOldCase, 'BEFORE_INSERT');
        
        Test.stopTest();
        
        // Reload cases to check if errors were added
        cases = [SELECT Id, Business_Unit__c, Technical_Source__c, CCC_External_Id__c, AssetId FROM Case];
        
        // Assertions
        for (Case c : cases) {
            if (c.CCC_External_Id__c == mdtRecords[0].Issue_Code__c) {
                System.assert(c.getErrors().size() > 0, 'Expected error message for case with matching Issue_Code__c');
                System.assertEquals(mdtRecords[0].Error_Message__c, c.getErrors()[0].getMessage());
            } else {
                System.assertEquals(0, c.getErrors().size(), 'No errors should be added for non-matching cases');
            }
        }
    }
}