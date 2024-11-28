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
            assetRec.Business_Unit__c = 'ABHI';
            update assetRec;
			Asset asts = new Asset();
            asts.Id = assetRec.Id;
            asts.SerialNumber = '123456789';
            update asts; 
               Asset assetRec1 = ASF_TestDataFactory.createAsset(testAccount.Id, 'Loans');
            assetRec1.Policy_No__c = '1234';
            assetRec1.Business_Unit__c = 'ABHI';
            update assetRec1;
			
        ABHI_Case_Detail__c detailRec = new ABHI_Case_Detail__c();
        detailRec.Policy_Proposal_Cert_Claim_Number__c  = '123456789';
        	insert detailRec;
        Case caseRec = ASF_TestDataFactory.createInteractionCaseRecords()[0];
        caseRec.Source__c = 'Email';
        caseRec.Business_Unit__c = 'ABHI';
        caseRec.Status = 'Open';
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
       //ABHI_IGMSHelperMethods.associateCustomerForAPIFromPhoneNumber(recCs);
       	
        Test.stopTest();
     //   System.assertNotEquals(null, res, 'response should not be null');
            
        }
   
     @IsTest
    static void testAssociateCustomerForAPIFromPhoneNumber(){
       // try{
            string frameworkRecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
            List<Case> caseRec = ASF_TestDataFactory.createCaseRecords(1);
            Account acc = ASF_TestDataFactory.insertPersonAccount('first','last','test');
            caseRec[0].Business_Unit__c = 'ABHI';
            caseRec[0].Technical_Source__c = 'API';
            caseRec[0].SuppliedPhone = '1234';
            List<Case> caseRec1 =[SELECT ID,Business_Unit__c,Technical_Source__c,SuppliedPhone FROM CASE WHERE Business_Unit__c = 'ABHI' LIMIT 1];
            ABHI_IGMSHelperMethods.associateCustomerForAPIFromPhoneNumber(new List<Case>{caseRec[0]});
           // ABHI_IGMSHelperMethods.associateAssetIgms(new List<Case>{caseRec1[0]});
        
       // }catch(exception e){}
    }
       @IsTest
    static void testAsset(){
       // try{
         Account testAccount1 = new Account(
            Name = 'Test Account',
            Business_Unit__c = 'ABHI'
        );
        insert testAccount1;
              Asset assetRec1 = ASF_TestDataFactory.createAsset(testAccount1.Id, 'Loans');
            assetRec1.Policy_No__c = '1234';
            assetRec1.Business_Unit__c = 'ABHI';
            update assetRec1;
			
        ABHI_Case_Detail__c detailRec1 = new ABHI_Case_Detail__c();
        detailRec1.Policy_Proposal_Cert_Claim_Number__c  = '123456789';
        	insert detailRec1;
        Case caseRec1 = ASF_TestDataFactory.createInteractionCaseRecords()[0];
        caseRec1.Source__c = 'Email';
        caseRec1.Business_Unit__c = 'ABHI';
        caseRec1.Status = 'Open';
        caseRec1.Stage__c = 'In Progress with SA';
        caseRec1.ABHI_Case_Detail__c = detailRec1.Id;
        caseRec1.CCC_External_Id__c = 'PNFT008';
        caseRec1.Technical_Source__c = 'API';
    		update caseRec1;
        Claim__c testClaim = new Claim__c(ClaimExternalId__c = 'CLAIM123',Name= '123456789', Policy_Number__c  = assetRec1.ID);
        	insert testClaim;
            //List<Case> caseRec1 =[SELECT ID,Business_Unit__c,Technical_Source__c,SuppliedPhone FROM CASE WHERE Business_Unit__c = 'ABHI' LIMIT 1];
            ABHI_IGMSHelperMethods.associateAssetIgms(new List<Case>{caseRec1});
        
       // }catch(exception e){}
    }
        @IsTest
    static void testAsset1(){
       // try{
         Account testAccount1 = new Account(
            Name = 'Test Account',
            Business_Unit__c = 'ABHI'
        );
        insert testAccount1;
         List<Asset> assets =[SELECT ID,SerialNumber FROM Asset WHERE SerialNumber = '123456789' LIMIT 1];
            assets[0].SerialNumber = '12as34';
            update assets;
			
        ABHI_Case_Detail__c detailRec1 = new ABHI_Case_Detail__c();
        detailRec1.Policy_Proposal_Cert_Claim_Number__c  = '123456789';
        	insert detailRec1;
        Case caseRec1 = ASF_TestDataFactory.createInteractionCaseRecords()[0];
        caseRec1.Source__c = 'Email';
        caseRec1.Business_Unit__c = 'ABHI';
        caseRec1.Status = 'Open';
        caseRec1.Stage__c = 'In Progress with SA';
        caseRec1.ABHI_Case_Detail__c = detailRec1.Id;
        caseRec1.CCC_External_Id__c = 'PNFT008';
        caseRec1.Technical_Source__c = 'API';
    		update caseRec1;
        Claim__c testClaim = new Claim__c(ClaimExternalId__c = 'CLAIM123',Name= '123456789', Policy_Number__c  = assets[0].ID);
        	insert testClaim;
            //List<Case> caseRec1 =[SELECT ID,Business_Unit__c,Technical_Source__c,SuppliedPhone FROM CASE WHERE Business_Unit__c = 'ABHI' LIMIT 1];
            ABHI_IGMSHelperMethods.associateAssetIgms(new List<Case>{caseRec1});
        
       // }catch(exception e){}
    }
}