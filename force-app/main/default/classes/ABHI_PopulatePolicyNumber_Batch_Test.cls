@IsTest
public class ABHI_PopulatePolicyNumber_Batch_Test {
	private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @testSetup
    static void setUpData(){
    	Group SLAGroup = new Group();        
        SLAGroup = new Group(Name='SLAManagerGroup', DeveloperName='SLAManagerGroup');
        	insert SLAGroup;
        Group g1 = new Group(Name='OCC-Test-Group', type='Queue');
        	insert g1;
        UserRole role = [SELECT Id FROM UserRole WHERE DeveloperName = 'ABFL_Sales' LIMIT 1];
        User userRecord = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                    TimeZoneSidKey='America/Los_Angeles',FederationIdentifier='FED12345', UserName='cdefghijk567@gmail.com',
                                    managerGroupId__c=SLAGroup.Id,UserRoleId  = role.Id);
        insert userRecord;
        User userRecord1 = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,Business_Unit__c = 'ABFL',
                                    TimeZoneSidKey='America/Los_Angeles',FederationIdentifier='FED12346',UserRoleId  = role.Id, UserName='cdefghijk5657@gmail.com'
                                    );
        insert userRecord1;
        System.runAs(userRecord) {
         Id rtId = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
         Account acc= new Account(
            FirstName='Test FName',
            RecordTypeId = rtId,
            LastName='Test LName',
            PersonMailingStreet='test@yahoo.com',
            PersonMailingPostalCode='12345',
            PersonMailingCity='SFO',
            PersonEmail='test@yahoo.com',
            PersonHomePhone='1234567',
            PersonMobilePhone='12345678'
        );
            insert acc;  
            Asset assetObj = new Asset();
            assetObj.Name = '981726345';
            assetObj.LAN__c = 'ABhi12345';
            assetObj.AccountId = acc.Id;
            assetObj.RM_Code__c = 'FED12346';
            assetObj.RM_Assignment__c = 'Pending';
            assetObj.Business_Unit__c ='ABFL';
            insert assetObj;
            
            Customer_Member_Mapping__c cmRec = new Customer_Member_Mapping__c(
                Client_Id__c = acc.Id,
                Business_Unit__c = 'ABHI',
                Customer_Type__c = 'VIP',
                MemberExternalId__c = '28282192',
                Policy_Number_Text__c = 'ABhi123456',
                MemberId__c = acc.Id,
                Policy_Number__c = assetObj.Id
            );
        insert cmRec;
        }
    }
    
    @isTest
    static void testPopulate(){
        User usr = [SELECT Id FROM User WHERE Username = 'cdefghijk567@gmail.com' LIMIT 1];
        
 		system.runAs(usr)
        { 
           Test.startTest(); 
           Database.executeBatch(new ABHI_PopulatePolicyNumber_Batch(),5);  
           Test.stopTest();    
           Customer_Member_Mapping__c cust = [SELECT Id,Policy_Number_Text__c,Policy_Number__r.LAN__c FROM Customer_Member_Mapping__c WHERE
                       Business_Unit__c = 'ABHI' LIMIT 1];
		   System.assertEquals(cust.Policy_Number__r.LAN__c, cust.Policy_Number_Text__c, 'Policy Number Text updated');

         }
    }     
}
