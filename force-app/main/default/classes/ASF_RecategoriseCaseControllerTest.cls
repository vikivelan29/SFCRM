@SuppressWarnings('PMD.MethodNamingConventions')
@IsTest
public class ASF_RecategoriseCaseControllerTest {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];

    @testSetup
    static void setupTestData(){
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                          Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                          Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
        List<User> lstUser = new List<User>();
        User userRecord = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                                   EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                   TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghijk561123@gmail.com', Business_Unit__c = 'ABHFL');//LOB__c='ABHFL',
        lstUser.add(userRecord);
        
        User userRecord2 = new User(Alias = 'standt2', Email='standarduser2@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                    TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghijk781234@gmail.com', Business_Unit__c = 'ABHFL', CC__c ='0141');//LOB__c='ABHFL',
        lstUser.add(userRecord2);
        
         User userRecord3 = new User(Alias = 'standt2', Email='standarduser2@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, Business_Unit__c = 'ABHFL',//type__c='SQ User',
                                    TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghijk90900@gmail.com', CC__c ='0153');//LOB__c='ABHFL',
        lstUser.add(userRecord3);
        
        User userRecord4 = new User(Alias = 'standt2', Email='standarduser2@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, Business_Unit__c = 'ABHFL',
                                    TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghijk901991@gmail.com', CC__c ='');//LOB__C='ABHFL',
        lstUser.add(userRecord4);
        insert lstUser;
        
        Id recordTypeId =Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
        Account acc= new Account(
            FirstName='Test FName',
            LastName='Test LName',
            PersonMailingStreet='test@yahoo.com',
            PersonMailingPostalCode='12345',
            PersonMailingCity='SFO',
            PersonEmail='test@yahoo.com',
            PersonHomePhone='1234567',
            PersonMobilePhone='12345678',
            RecordTypeId = recordTypeId
            //CRN__c= 'abcd'
        );
        insert acc;  
        LOB_Master__c lob = new LOB_Master__c(LOB_Code__c = 'ABC', BusinessUnit__c = 'ABHFL');
        insert lob;
        Asset ast = new Asset(
        Name='TestAccountFinacial'
        ,AccountId=acc.Id
        , LOB_Code__c = lob.Id
        ,Price=100
        //,Financial_Account_Number__c = '0123456789123'
        );
        ast.Name = 'TestAccountFinacial';
        ast.Aggrement_Date__c = Date.newInstance(2023, 06, 09);
        ast.Application_Number__c = '12345';
        ast.Approved_Date__c = Date.newInstance(2023, 06, 10);
        ast.Approved_Limit__c = 200;
        ast.Branch_Code__c = 'AST';
        insert ast;
        
    }

    @IsTest
    static void getTypeSubTypeDataByCustomerType_Test(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        Test.startTest();
        ASF_Case_Category_Config__c config = [Select Id, CCC_External_Id__c from ASF_Case_Category_Config__c LIMIT 1];
        User userObj = [Select Id from User where Email='standarduser@testorg.com' LIMIT 1];
        System.runAs(userObj){
            ASF_RecategoriseCaseController.getTypeSubTypeDataByCustomerType('CIBIL', '', 'false', 'Individual', config.CCC_External_Id__c, '');
        }
        Test.stopTest();
    }

    @IsTest
    static void getCaseRecordDetails_Test(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        casesList[0].Technical_Source__c = 'LWC';
        insert casesList;
        Test.startTest();
        ASF_RecategoriseCaseController.getCaseRecordDetails(casesList[0].Id);
        Test.stopTest();
        
    }

    @IsTest
    static void updateCaseWithNewCCCId_Test(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        ASF_TestDataFactory.createCaseCategoryConfig();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        casesList[0].Technical_Source__c = 'LWC';
        insert casesList;
        Id accId = [select Id from account].Id;
        Test.startTest();
        String jsonString = '{"apiName":"Case","fields":{"CCC_External_Id__c":"CCC-CC-CCLTD-01","Nature__c":"Query","Source__c":"Branch","Channel__c":"Walk in","Is_send_Bot_Feedback":true,"AccountId":"'+String.valueOf(accId)+'"}}';
        ASF_RecategoriseCaseController.updateCaseWithNewCCCId(casesList[0].Id, casesList[0].CCC_External_Id__c, jsonString, '');
        Test.stopTest();
        
    }

    @IsTest
    static void fetchCCCDetails_Test(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        casesList[0].Technical_Source__c = 'LWC';
        insert casesList;
        Test.startTest();
        ASF_RecategoriseCaseController.fetchCCCDetails(casesList[0].CCC_External_Id__c);
        Test.stopTest();
        
    }
    @IsTest
    static void getMatchingAccountTest(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        casesList[0].Technical_Source__c = 'LWC';
        casesList[0].AccountId = [select id from account LIMIT 1].Id;
        insert casesList;
        Test.startTest();
        ASF_RecategoriseCaseController.getMatchingAccount('12345',false,casesList[0].Id);
        ASF_RecategoriseCaseController.getMatchingAccount('12345',true,casesList[0].Id);
        Test.stopTest();
    } 
    @IsTest
    static void validateIfCurrentCTSTForAccountAndAssetTest(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        ASF_Case_Category_Config__c config = [Select Id, CCC_External_Id__c, LOB__c from ASF_Case_Category_Config__c LIMIT 1];
        config.LOB__c = 'Retail - Secured';
        config.Business_Unit__c = 'ABFL';
        update config;
        
        Account accountRec = [select id,Business_Unit__c,Line_of_Business__c from account LIMIT 1];
        accountRec.Business_Unit__c = 'ABFL';
        accountRec.Line_of_Business__c = 'ABFL';
        update accountRec;
        
        Asset assetRec = [select id,Business_Unit__c,LOB__c from asset where accountId =: accountRec.Id LIMIT 1];
        assetRec.Business_Unit__c = 'ABFL';
        assetRec.LOB__c = 'Retail - Secured';
        assetRec.AccountId = accountRec.Id;
        update assetRec;
        
        casesList[0].Technical_Source__c = 'LWC';
        casesList[0].AccountId = accountRec.Id;
        casesList[0].AssetId = assetRec.Id;
        insert casesList;
        
        Test.startTest();
        ASF_RecategoriseCaseController.validateIfCurrentCTSTForAccountAndAsset(accountRec.Id,assetRec.Id,config.CCC_External_Id__c);
        
        config.LOB__c = 'Retail - Secured';
        config.Business_Unit__c = 'Payments';
        config.Custom_Segment__c = 'Individual';
        update config;
        
        accountRec.Business_Unit__c = 'Payments';
        accountRec.Line_of_Business__c = 'Payments';
        update accountRec;
        
        assetRec.Business_Unit__c = 'Payments';
        assetRec.LOB__c = 'Retail - Secured';
        update assetRec;
        
        ASF_RecategoriseCaseController.validateIfCurrentCTSTForAccountAndAsset(accountRec.Id,assetRec.Id,config.CCC_External_Id__c);
        
        Test.stopTest();
    }
    @IsTest
    static void validateIfCurrentCTSTForAccountAndPropectTest(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        ASF_Case_Category_Config__c config = [Select Id, CCC_External_Id__c from ASF_Case_Category_Config__c LIMIT 1];
        Account accountRec = [select id,Business_Unit__c,Line_of_Business__c from account LIMIT 1];
        accountRec.Business_Unit__c = 'ABFL';
        accountRec.Line_of_Business__c = 'ABFL';
        update accountRec;
        config.Business_Unit__c = 'ABFL';
        update config;
        
        casesList[0].Technical_Source__c = 'LWC';
        casesList[0].AccountId = accountRec.Id;
        insert casesList;
        Test.startTest();
        ASF_RecategoriseCaseController.validateIfCurrentCTSTForAccountAndPropect(accountRec.Id,config.CCC_External_Id__c);
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            mobilephone = '1234567890',
            Business_Unit__c = 'Payments',
            PANNO__c = 'ABCDE1234E'
        );
        insert testLead;
        config.Business_Unit__c = 'Payments';
        config.Custom_Segment__c = 'Individual';
        update config;
        ASF_RecategoriseCaseController.validateIfCurrentCTSTForAccountAndPropect(testLead.Id,config.CCC_External_Id__c);
        Test.stopTest();
    }
    @isTest
    static void updateRequestedCCCTest(){
        ASF_TestDataFactory.createCaseCategoryConfig();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        casesList[0].Technical_Source__c = 'LWC';
        insert casesList;
        Id accId = [select Id from account].Id;
        Test.startTest();
        String jsonString = '{"apiName":"Case","fields":{"CCC_External_Id__c":"CCC-CC-CCLTD-01","Nature__c":"Query","Source__c":"Branch","Channel__c":"Walk in","Is_send_Bot_Feedback":true,"AccountId":"'+String.valueOf(accId)+'"}}';
        String result = ASF_RecategoriseCaseController.updateRequestedCCC(casesList[0].Id, jsonString, 'Type', 'SubType', 'Query');
        Case caseRec = [Select id, Type_Text__c, CCC_External_Id__c,Requested_Recat_Json__c, Sub_Type_Text__c from case where id=: casesList[0].Id];
        system.debug('Requested_Recat_Json__c--'+caseRec.Requested_Recat_Json__c);
        Assert.areNotEqual('Error - ', result, 'Result should not be error');
        Map<Id, Case> caseMap = new Map<Id, Case>();
        caseMap.put(caseRec.Id,caseRec);
        ASF_ApprovalRecatController.updateCCCIdBulk(caseMap);
        Test.stopTest();
    }
}