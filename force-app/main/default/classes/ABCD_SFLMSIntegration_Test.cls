/******************************************************  
* Author           - Salesforce
* Date             - 24-Dec-2024
* Description      - Test class for ONEABC_CreateCaseWithTypeHelper
********************************************************
*/

@isTest
public class ABCD_SFLMSIntegration_Test {
	@isTest
    public static void invokeIntegration(){
        Id salesLeadRecordTypeId = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Lead' AND DeveloperName='Sales'].Id;
        
        Lead ld = new Lead();
        ld.FirstName= 'MyFirstName';
        ld.LastName= 'MyLastName';
        ld.MobilePhone = '1234567890';
        ld.Email = 'myemail@mydomain.com.invalid';
        ld.Prospect_Type__c = 'Sales';
        ld.RecordTypeId = salesLeadRecordTypeId;
        ld.Business_Unit__c = 'ABCD';
        
        insert ld;
    }
}