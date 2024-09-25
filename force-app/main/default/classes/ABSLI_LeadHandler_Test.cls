/**
 * @description       : Test class for ABSLI_LeadHandler
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 16-Sep-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@IsTest
public class ABSLI_LeadHandler_Test {
	@isTest
    static void testafterInsertLogic() {
        
        Test.startTest();
        Id salesLeadRecordTypeId = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Lead' AND DeveloperName='Sales'].Id;
 		Lead ld = new Lead();
        ld.FirstName= 'MyFirstName';
        ld.LastName= 'MyLastName';
        ld.MobilePhone = '1234567890';
        ld.Email = 'myemail@mydomain.com.invalid';
        ld.ABSLI_Lead_Type__c = 'Contact Centre';
        ld.RecordTypeId = salesLeadRecordTypeId;
        ld.Business_Unit__c = 'ABSLI';
        
        insert ld;
        Test.stopTest();
    }
}