/**
 * @description       : 
 * @author            : ABHFL Team
 * @group             : 
 * @last modified on  : 03-03-2024
 * @last modified by  : Vishal Gangwar
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
}
