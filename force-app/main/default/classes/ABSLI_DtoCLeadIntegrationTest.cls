@isTest
public class ABSLI_DtoCLeadIntegrationTest {
    @isTest
    public static void invokeIntegration(){
        Id salesLeadRecordTypeId = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Lead' AND DeveloperName='Sales'].Id;
        
        Asset policy = new Asset();
        policy.Name = '000000001';
        policy.Policy_No__c = '000000001';
        policy.LAN__c = 'ABSLI_000000001';
        policy.Business_Unit__c = 'ABSLI';
        policy.Channel__c = 'DM';
        insert policy;
        
        
        Lead ld = new Lead();
        ld.FirstName= 'MyFirstName';
        ld.LastName= 'MyLastName';
        ld.MobilePhone = '1234567890';
        ld.Email = 'myemail@mydomain.com.invalid';
        ld.Lead_Type__c = 'Contact Centre';
        ld.RecordTypeId = salesLeadRecordTypeId;
        ld.Business_Unit__c = 'ABSLI';
        ld.Asset__c = policy.Id;
        
        insert ld;
    }

}