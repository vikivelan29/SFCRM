@isTest
public class ABCL_CasePlatformEventHandler_Test {

    @isTest
    static void testPublishPlatformEvent() {
        String objectApiName = 'CRM_to_EBOT_Event__e'; // Replace with your platform event API name
        Map<String, String> fieldsMap = new Map<String, String>{
            'Business_Unit__c' => 'ABFL',
            'Case_Number__c' => '1233'
        };

        Test.startTest();
        Database.SaveResult result = ABCL_CasePlatformEventHandler.publishPlatformEvent(objectApiName, fieldsMap);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Database.SaveResult should not be null');
        System.assertEquals(true, result.isSuccess(), 'Event publishing should be successful');

        System.assertEquals(1, result.getErrors().size(), 'There should be no errors in the save result');

    }
}