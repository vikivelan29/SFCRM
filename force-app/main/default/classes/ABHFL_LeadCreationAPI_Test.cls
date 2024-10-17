/**
 * @description       : 
 * @author            : ABHFL Team
 * @group             : 
 * @last modified on  : 10-16-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   03-03-2024   ABHFL Team   Initial Version
**/
@isTest
public class ABHFL_LeadCreationAPI_Test {
    @TestSetup
    static void testData(){
        Lead testLead = new Lead(
            Company = 'Test Company',
            //Email = 'test@example.com',
            FirstName = 'Test',
            LastName = 'Lead',
            Employment_Type__c = 'Salaried',
            //External_Lead_ID__c = 'EXT001',
            ABHFL_Prospect_Type__c = 'Non Individual',
            MobilePhone = '1234567890',
            //PANNO__c = 'ABCDE1234F',
           Preferred_Communication__c = 'Email',
            Product__c = 'Product X',
            
            //API_Response_Message__c = 'Success',
            Requested_Loan_Amount__c = 100000,
            Source_System_API__c = 'System A',
            Source_Type__c = 'External',
            //Create_Lead_To_CRM_Status__c = 'Pending',
            LeadSource = 'Customer Service',
            Sourcing_Branch__c = 'Branch A',
            Sub_Source__c = 'Email',
           SPOC_Name__c = 'Test SPOC',
           Business_Unit__c = 'ABHFL'
        );
        
        INSERT testLead;
    }


    @isTest
    static void testSendLead() {
        
        Test.startTest();
        Lead leadobj = [SELECT Id,API_Error_Code__c from Lead];
        String result = ABHFL_LeadCreationAPI.sendLead(leadobj.Id, true);
        System.assertEquals(leadobj.API_Error_Code__c,Null);
        
        Test.stopTest();
    }

    @isTest
    static void testByPassTriggerMethod() {
               
        // Create a permission set that includes the custom permission
        PermissionSet abslig_UserPS = new PermissionSet(
            Name = 'Test_ABSLIG_User',
            Label = 'Test ABSLIG User'
        );
        insert abslig_UserPS;

        SetupEntityAccess sea = new SetupEntityAccess(
            ParentId = abslig_UserPS.Id,
            SetupEntityId = [
            SELECT Id
            FROM CustomPermission
            WHERE DeveloperName = 'By_Pass_Trigger'
            LIMIT 1
            ].Id
        );
        insert sea;

        // Create a user with the permission set
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User u = new User(Alias = 'testuse1', Email = 'testuser1@example.com',
            EmailEncodingKey = 'UTF-8', LastName = 'User', LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'test_user123432323@example.com');
        insert u;
        
        // Assign the permission set to the user
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetId = abslig_UserPS.Id
        );
        insert psa;

        System.runAs(u)
        {
            Lead byPassLeadTrigger = new Lead(
                FirstName = 'Test',
                LastName = 'Lead',
                Business_Unit__c = 'ABSLIG'
            );

            insert byPassLeadTrigger;
        }
        // Verify that the custom permission was checked correctly
        System.assertEquals(false, FeatureManagement.checkPermission('By_Pass_Trigger'));
    }
}