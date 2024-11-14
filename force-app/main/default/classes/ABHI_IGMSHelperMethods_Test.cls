/*********************************************************
*Class        :  ABHI_AttendedIGMSComplaint_Test 
*Author       :  Shubham Sinha
*Created Date :  14/10/2024
*@description  : Test class for ABHI_AttendedIGMSComplaint 
***********************************************************/ 
@isTest
public class ABHI_IGMSHelperMethods_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @testSetup
    static void setUpData(){
        Group slaGroup = new Group();        
        slaGroup = new Group(Name='SLAManagerGroup', DeveloperName='SLAManagerGroup');
            insert slaGroup;
        Group g1 = new Group(Name='OCC-Test-Group', type='Queue');
            insert g1;
        User userRecord = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                    TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk567@gmail.com',
                                    managerGroupId__c=slaGroup.Id);
        insert userRecord;
        User userRecord1 = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,Business_Unit__c = 'ABHI',
                                    TimeZoneSidKey='America/Los_Angeles', UserName='cdefghijk5657@gmail.com'
                                    );
        insert userRecord1;
    
        System.runAs(userRecord1){
        Account testAccount = new Account(
            Name = 'Test Account',
            Business_Unit__c = 'ABHI'
        );
        insert testAccount;
        
        // Create Contacts for testing phone number association
        Contact testContact1 = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            MobilePhone = '1234567890',
            AccountId = testAccount.Id
        );
        insert testContact1;

     
        Asset assetRec = ASF_TestDataFactory.createAsset(testAccount.Id, 'Loans');
            assetRec.Policy_No__c = '1234';
            update assetRec;
        ABHI_Case_Detail__c detailRec = new ABHI_Case_Detail__c();
        	insert detailRec;
        Case caseRec = ASF_TestDataFactory.createInteractionCaseRecords()[0];
        caseRec.Source__c = 'Email';
        caseRec.Business_Unit__c = 'ABHI';
        caseRec.Status = 'Open';
        caseRec.AssetId = assetRec.Id;
        caseRec.Stage__c = 'In Progress with SA';
        caseRec.ABHI_Case_Detail__c = detailRec.Id;
        caseRec.CCC_External_Id__c = 'PNFT008';
        caseRec.Technical_Source__c = 'API';
            caseRec.Is_STP__c = true;
            caseRec.IGMS_Complaint_Type_Code__c = '1';
    update caseRec;
        }
    }
      @isTest
    static void testgetActiveDayEventsDetail(){
        Test.startTest(); 
        List<Case> recCs = [Select Id,Business_Unit__c,Technical_Source__c ,accountId,SuppliedPhone FROM CASE WHERE Business_Unit__c = 'ABHI' LIMIT 1 ];
        recCs[0].SuppliedPhone = '1234567890';
        update recCs;
       ABHI_IGMSHelperMethods.associateCustomerForAPIFromPhoneNumber(recCs);
       	
        Test.stopTest();
     //   System.assertNotEquals(null, res, 'response should not be null');
            
        }
}