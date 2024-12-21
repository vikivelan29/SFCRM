@isTest
public class ASF_DynamicButtonsControllerTest {
    
    @isTest
    public static void getButtonsConfigTest(){
        Test.startTest();

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
                Business_Unit__c = 'ABSLI',
                Client_Code__c = 'CLIENTCODE01'
            );
            insert acc;  
        
        List<ASF_ButtonCardConfig__mdt> btnMetadatas = ASF_DynamicButtonsController.getButtonsConfig('Account',acc.Id);
        System.AssertEquals(btnMetadatas.size()>0,true);
        Test.stopTest();
    }
    
    
}