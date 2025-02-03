@isTest
public class ABCL_cx360Controller_Test {
    @isTest
    static void testCreateCases() {
        Account account = new Account(Name = 'Test Account',Business_Unit__c = 'ABHFL');
        insert account;
        
        Account acc = new Account(Client_Code__c = 'ABCTest321', PersonBirthDate =Date.newInstance(1960, 2, 17), FirstName = 'test', LastName = 'test2', Business_Unit__c ='ABHFL');
            insert acc;

        Asset asset = new Asset(
            AccountId = account.Id,
            LAN__c = 'LAN123',
            Status = 'Active',
            Business_Unit__c='ABHFL',
            Name = 'Test Asset' 
        );
        insert asset;

        ASF_Case_Category_Config__c caseCatConfig = new ASF_Case_Category_Config__c();
        caseCatConfig.CCC_External_Id__c = 'hfl073';
        caseCatConfig.Type__c = 'Bureau Related';
        caseCatConfig.Sub_Type__c = 'CIBIL Related Details - Ownership Related';
        caseCatConfig.Nature__c = 'Request';
        caseCatConfig.Business_Unit__c='ABHFL';
        insert caseCatConfig;
        ASF_Integration__c integration = new ASF_Integration__c(
            External_Id__c = 'hfl073'
        );
        insert integration;
      
        Case newCase = new Case(Status = 'In Progress', Origin = 'Email', Subject = 'Test Case Creation', Stage__c = 'Pending with Initiator',
                               CCC_External_Id__c = 'hfl073');
        insert newCase;
        
        ABHFL_Asset_Detail__c assetDetail = new ABHFL_Asset_Detail__c();
        assetDetail.Asset__c = asset.Id;
        insert assetDetail;
        ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
        insert caseDetail;
        
        List<String> docs = new List<String>{'SOA', 'RS', 'IC'};
       
        Test.startTest();
        ABCL_cx360Controller.createCases(account.Id, asset.Id, docs);
        ABCL_cx360Controller.getCustomerInfo(account.Id);
        ABCL_cx360Controller.getProductsOwned(account.Id);
        ABCL_cx360Controller.getQuickActions(account.Id);
        ABCL_cx360Controller.getAllIntegrationDetails('','', '');
        ABCL_cx360Controller.getCurrentFinancialYear('');
        ABCL_cx360Controller.getAccountInfoFields(acc.Id,'ABHFL',''); 
        ABCL_cx360Controller.getHNIorHWCField(acc.Id,'ABHFL','test'); 
        ABCL_cx360Controller.getInteractionInfo(account.Id);
        ABCL_cx360Controller.getAccountFields(account.Id);
        ABCL_cx360Controller.createCasesForLang(account.Id,'');
        Test.stopTest(); 
    }
    
    @isTest
    static void testCreateCases2() {
        Account account = new Account(Name = 'Test Account');
        insert account;

        Asset asset = new Asset(
            AccountId = account.Id,
            Status = 'Active',
            Name = 'Test Asset',
            LAN__c = 'LAN123',
            Business_Unit__c = 'ABHFL'
        );
        insert asset;

        ASF_Case_Category_Config__c caseCatConfig = new ASF_Case_Category_Config__c();
        caseCatConfig.CCC_External_Id__c = 'hfl004';
        caseCatConfig.Type__c = 'Bureau Related';
        caseCatConfig.Sub_Type__c = 'CIBIL Related Details - Ownership Related';
        caseCatConfig.Nature__c = 'Request';
        caseCatConfig.Business_Unit__c='ABHFL';
        insert caseCatConfig;
        ASF_Integration__c integration = new ASF_Integration__c(
            External_Id__c = 'hfl004'
        );
        insert integration;
      
        Case newCase = new Case(Status = 'In Progress', Origin = 'Email', Subject = 'Test Case Creation', Stage__c = 'Pending with Initiator',
                                CCC_External_Id__c = 'hfl004');
        insert newCase;
        
        ABHFL_Asset_Detail__c assetDetail = new ABHFL_Asset_Detail__c();
        assetDetail.Asset__c = asset.Id;
        insert assetDetail;
        ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
        insert caseDetail;
        
        List<String> docs1 = new List<String>{'RS', 'IC'};
        
        Test.startTest();
        ABCL_cx360Controller.createCases(account.Id, asset.Id, docs1);
        Test.stopTest();
    }
    @isTest
    static void testCreateCases3() {
        Account account = new Account(Name = 'Test Account');
        insert account;

        Asset asset = new Asset(
            AccountId = account.Id,
            Status = 'Active',
            Name = 'Test Asset',
            LAN__c = 'LAN123',
            Business_Unit__c = 'ABHFL'
        );
        insert asset;

        ASF_Case_Category_Config__c caseCatConfig = new ASF_Case_Category_Config__c();
        caseCatConfig.CCC_External_Id__c = 'hfl037';
        caseCatConfig.Type__c = 'Bureau Related';
        caseCatConfig.Sub_Type__c = 'CIBIL Related Details - Ownership Related';
        caseCatConfig.Nature__c = 'Request';
        caseCatConfig.Business_Unit__c='ABHFL';
        insert caseCatConfig;
        ASF_Integration__c integration = new ASF_Integration__c(
            External_Id__c = 'hfl037'
        );
        insert integration;
      
        Case newCase = new Case(Status = 'In Progress', Origin = 'Email', Subject = 'Test Case Creation', Stage__c = 'Pending with Initiator',
                                CCC_External_Id__c = 'hfl037');
        insert newCase;
        
        ABHFL_Asset_Detail__c assetDetail = new ABHFL_Asset_Detail__c();
        assetDetail.Asset__c = asset.Id;
        insert assetDetail;
        ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
        insert caseDetail;
        List<String> docs2 = new List<String>{'IC'};
        
        Test.startTest();
        ABCL_cx360Controller.createCases(account.Id, asset.Id, docs2);
        Test.stopTest();
    }
    @isTest
    static void testCreateCases4() {
        Account account = new Account(Name = 'Test Account');
        insert account;

        Asset asset = new Asset(
            AccountId = account.Id,
            Status = 'Active',
            Name = 'Test Asset',
            LAN__c = 'LAN123',
            Business_Unit__c = 'ABHFL'
        );
        insert asset;

        ASF_Case_Category_Config__c caseCatConfig = new ASF_Case_Category_Config__c();

        caseCatConfig.CCC_External_Id__c = 'hfl078';
        caseCatConfig.Type__c = 'Bureau Related';
        caseCatConfig.Sub_Type__c = 'CIBIL Related Details - Ownership Related';
        caseCatConfig.Nature__c = 'Request';
        caseCatConfig.Business_Unit__c='ABHFL';
        insert caseCatConfig;
        ASF_Integration__c integration = new ASF_Integration__c(
            External_Id__c = 'hfl078'
        );
        insert integration;
      
        Case newCase = new Case(Status = 'In Progress', Origin = 'Email', Subject = 'Test Case Creation', Stage__c = 'Pending with Initiator',
                                CCC_External_Id__c = 'hfl078');
        insert newCase;
        
        ABHFL_Asset_Detail__c assetDetail = new ABHFL_Asset_Detail__c();
        assetDetail.Asset__c = asset.Id;
        insert assetDetail;
        ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
        insert caseDetail;
        List<String> docs2 = new List<String>{'PIC'};
        
        Test.startTest();
        ABCL_cx360Controller.createCases(account.Id, asset.Id, docs2);
        Test.stopTest();
    }
    @isTest
    static void testCreateCases5() {
        Account account = new Account(Name = 'Test Account');
        insert account;

        Asset asset = new Asset(
            AccountId = account.Id,
            Status = 'Active',
            Name = 'Test Asset',
            LAN__c = 'LAN123',
            Business_Unit__c = 'ABHFL'
        );
        insert asset;

        ASF_Case_Category_Config__c caseCatConfig = new ASF_Case_Category_Config__c();
        caseCatConfig.CCC_External_Id__c = 'QLOANDUSNDC';
        caseCatConfig.Type__c = 'Bureau Related';
        caseCatConfig.Sub_Type__c = 'CIBIL Related Details - Ownership Related';
        caseCatConfig.Nature__c = 'Request';
        caseCatConfig.Business_Unit__c='ABHFL';
        insert caseCatConfig;
        ASF_Integration__c integration = new ASF_Integration__c(
            External_Id__c = 'QLOANDUSNDC'
        );
        insert integration;
      
        Case newCase = new Case(Status = 'In Progress', Origin = 'Email', Subject = 'Test Case Creation', Stage__c = 'Pending with Initiator',
                                CCC_External_Id__c = 'QLOANDUSNDC');
        insert newCase;
        
        ABHFL_Asset_Detail__c assetDetail = new ABHFL_Asset_Detail__c();
        assetDetail.Asset__c = asset.Id;
        insert assetDetail;
        ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
        insert caseDetail;
        List<String> docs2 = new List<String>{'NDC'};
        
        Test.startTest();
        ABCL_cx360Controller.createCases(account.Id, asset.Id, docs2);
        Test.stopTest();
    }
    @isTest
    static void testCreateCases6() {
        Account account = new Account(Name = 'Test Account');
        insert account;

        Asset asset = new Asset(
            AccountId = account.Id,
            Status = 'Active',
            Name = 'Test Asset',
            LAN__c = 'LAN123',
            Business_Unit__c = 'ABHFL'
        );
        insert asset;

        ASF_Case_Category_Config__c caseCatConfig = new ASF_Case_Category_Config__c();
        caseCatConfig.CCC_External_Id__c = 'RSTAWEITHFC';
        caseCatConfig.Type__c = 'Bureau Related';
        caseCatConfig.Sub_Type__c = 'CIBIL Related Details - Ownership Related';
        caseCatConfig.Overall_Case_Closure_SLA__c = 56;
        caseCatConfig.Nature__c = 'Request';
        caseCatConfig.Business_Unit__c='ABHFL';
        insert caseCatConfig;
        ASF_Integration__c integration = new ASF_Integration__c(
            External_Id__c = 'RSTAWEITHFC'
        );
        insert integration;
      
        Case newCase = new Case(Status = 'In Progress', Origin = 'Email', Subject = 'Test Case Creation', Stage__c = 'Pending with Initiator',
                                CCC_External_Id__c = 'RSTAWEITHFC');
        insert newCase;
        
        ABHFL_Asset_Detail__c assetDetail = new ABHFL_Asset_Detail__c();
        assetDetail.Asset__c = asset.Id;
        insert assetDetail;
        ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
        insert caseDetail;
        List<String> docs2 = new List<String>{'WK'};
        
        Test.startTest();
        ABCL_cx360Controller.createCases(account.Id, asset.Id, docs2);
        Test.stopTest();
    }
     @isTest
    static void testCreateCases7() {
        Account account = new Account(Name = 'Test Account');
        insert account;

        Asset asset = new Asset(
            AccountId = account.Id,
            Status = 'Active',
            Name = 'Test Asset',
            LAN__c = 'LAN123',
            Business_Unit__c = 'ABHFL'
        );
        insert asset;

        ASF_Case_Category_Config__c caseCatConfig = new ASF_Case_Category_Config__c();

        caseCatConfig.CCC_External_Id__c = 'hfl042';
        caseCatConfig.Type__c = 'Bureau Related';
        caseCatConfig.Sub_Type__c = 'CIBIL Related Details - Ownership Related';
        caseCatConfig.Overall_Case_Closure_SLA__c = 56;
        caseCatConfig.Nature__c = 'Request';
        caseCatConfig.Business_Unit__c='ABHFL';
        insert caseCatConfig;
        ASF_Integration__c integration = new ASF_Integration__c(
            External_Id__c = 'hfl042'
        );
        insert integration;
      
        Case newCase = new Case(Status = 'In Progress', Origin = 'Email', Subject = 'Test Case Creation', Stage__c = 'Pending with Initiator',
                                CCC_External_Id__c = 'hfl042');
        insert newCase;
        
        ABHFL_Asset_Detail__c assetDetail = new ABHFL_Asset_Detail__c();
        assetDetail.Asset__c = asset.Id;
        insert assetDetail;
        ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
        insert caseDetail;
        List<String> docs2 = new List<String>{'LOD'};
            
            List<Map<String, String>> fieldList = new List<Map<String, String>>();
        
        Test.startTest();
        ABCL_cx360Controller.createCases(account.Id, asset.Id, docs2);
        try {
            ABCL_cx360Controller.getQuickActions('str');
            System.assert(false, 'Exception was expected but not thrown');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
        }
        Test.stopTest();
    }
}