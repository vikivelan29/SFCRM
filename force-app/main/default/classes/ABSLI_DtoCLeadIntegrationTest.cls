@isTest
public class ABSLI_DtoCLeadIntegrationTest {
    @isTest
    public static void invokeIntegration(){
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
    }

}