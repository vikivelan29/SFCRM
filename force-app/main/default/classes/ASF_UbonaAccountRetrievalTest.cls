@isTest
public class ASF_UbonaAccountRetrievalTest {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    private final static Profile ABHFL_BASE_USER_PROFILE = [SELECT Id FROM Profile WHERE Name = 'ABHFL Base Profile' LIMIT 1];
    @TestSetup
    public static void dataSetup(){
        UserRole role = [SELECT Id FROM UserRole WHERE DeveloperName = 'ABHFL_Service_Agent' LIMIT 1];
        User userRecord = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                   EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                   TimeZoneSidKey='America/Los_Angeles',FederationIdentifier='FED12345', UserName='cdefghijk567@gmail.com',
                                   UserRoleId  = role.Id);
        insert userRecord;
        User userRecord1 = new User(Alias = 'standt', Email='abhflbaseuser@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = ABHFL_BASE_USER_PROFILE.Id,Business_Unit__c = 'ABHFL',
                                    TimeZoneSidKey='America/Los_Angeles',FederationIdentifier='ABHFL234',UserRoleId  = role.Id, UserName='cdefghijk5657@gmail.com'
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
                PersonMobilePhone='91234567890',
                Business_Unit__c = 'ABHFL',
                Client_Code__c = 'CLIENTCODE01'
            );
            insert acc;  
        }
    }
    
    @isTest
    public static void getAccountTest(){
        String str_Accounts_1 = ASF_UbonaAccountRetrieval.getAccount('91234567890', 'ABHFL', 'CLIENTCODE01');    
        List<Account> accounts1 = (List<Account>)JSON.deserialize(str_Accounts_1, List<Account>.Class) ;
        System.assertEquals('Test FName Test LName',accounts1[0].Name, 'Success');
        String str_Accounts_2 = ASF_UbonaAccountRetrieval.getAccount('91234567890', 'ABHFL', null); 
        List<Account> accounts2 = (List<Account>)JSON.deserialize(str_Accounts_2, List<Account>.Class) ;
        System.assertEquals('Test FName Test LName',accounts2[0].Name, 'Success');
    }
    
}