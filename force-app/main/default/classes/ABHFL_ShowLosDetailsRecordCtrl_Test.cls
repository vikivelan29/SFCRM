@isTest
private class ABHFL_ShowLosDetailsRecordCtrl_Test {

    @isTest
    static void testGetLosDetailsRecord() {
        // Test data setup
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
             mobilephone = '1234567890'
        );
        insert testLead;
        
        Lead testLead2 = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            mobilephone = '1234567890'
        );
        insert testLead2;

        LOS_Details__c testLosDetail = new LOS_Details__c(
            SF_Lead_ID__c = testLead.Id,
            Name = 'Test Details'
            // Add any other necessary fields here
        );
        insert testLosDetail;

        // Test the controller method
        Test.startTest();

        Id result = ABHFL_ShowLosDetailsRecordController.getLosDetaisRecord(testLead.Id);
        
        Id result2 = ABHFL_ShowLosDetailsRecordController.getLosDetaisRecord(testLead2.Id);

        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, result, 'LOS Details record not found for the given leadId');
        // Add any additional assertions based on your requirements
    }
} 