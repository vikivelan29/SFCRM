/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 05-13-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   05-13-2024   rsinghnagar@salesforce.com   Initial Version
**/
@IsTest
public class ASF_CaseUIController_Test{
    /**
    * @description : data setup
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    **/
    @TestSetup
    public static void setupData(){
        
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                           Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                           Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);

        Account a = new Account();
        a.Name = '12344';
        //a.CRN__c = '12344'; added comment
        insert a;
        
        ASF_Case_Category_Config__c ccc = new ASF_Case_Category_Config__c();
        ccc.Type__c = 'tes';
        ccc.CCC_External_Id__c = '12345';
        ccc.Business_Unit__c = 'ABFL';
        ccc.Sub_Type__c = 'TDC Refund';
        ccc.Overall_Case_Closure_SLA__c = 10;
        insert ccc;

        Asset ast = new Asset();
        ast.accountId = a.id;
        //ast.Financial_Account_Number__c ='2333423';
        ast.Name = 'aas';
        insert ast;

        LAN_Mapping__c lanMap = new LAN_Mapping__c();
        lanMap.Customer__c = a.Id;
        lanMap.LAN__c = ast.Id;
        insert lanMap;
        
        Contact con = new Contact();
        con.Lastname ='Test con';
        con.AccountId = a.Id;
        con.Email = 'test@test.com';
        con.Phone = '8329673314';
        insert con;
        
        ASF_Case_Stage_Config__c stage1 = new ASF_Case_Stage_Config__c();
        stage1.Case_Category_Config__c = ccc.Id;
        stage1.Order__c = 1;
        stage1.StageName__c  = 'New';
        stage1.Stage_SLA_1__c = 1;
        stage1.Status_Mapping__c = 'New';
            // stage1.Stage_SLA_3__c = 3;
        stage1.SLA_Target_1_Type__c = 'Manager';
        stage1.Query_Fields__c = 'Id,Stage__c';
        stage1.Manual_Stage__c = false;
        
        insert stage1;
        
        Case cs = new Case();
        cs.AccountId = a.Id;
        cs.CCC_External_Id__c = '12345';
        cs.contactId = con.Id;
        cs.Status = 'New';
        cs.Stage__c='New';
        insert cs;
        

    }
    
    @isTest
    public static void checkAccountsTest(){
        Account acc = [select id from account limit 1];

        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = acc.Id;
        test.startTest();
        List<ASF_CaseUIController.searchResponse> wrapper = ASF_CaseUIController.getMatchingAccount('12344',false);
        test.stopTest();
        system.assertEquals(wrapper.size(), 0, 'Size is 0');
        }

    @isTest
    public static void checkAccountsTestwithParam(){
        Account acc = [select id from account limit 1];
        acc.Client_Code__c = 'abc1234';
        update acc;
        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = acc.Id;
        test.startTest();
        List<ASF_CaseUIController.searchResponse> wrapper = ASF_CaseUIController.getMatchingAccount('abc1234',false);
        test.stopTest();
        system.assertEquals(wrapper.size(), 0, 'Size is 0');
        }
    @isTest
    public static void checkContactsTest(){
        Account acc = [select id from account limit 1];
        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = acc.Id;
        List<ASF_CaseUIController.searchResponse> wrapper = ASF_CaseUIController.getMatchingAccount('12344',false);
        system.assertEquals(wrapper.size(), 0, 'Size is 0');
        }
    
    @isTest
    public static void caseExtensionTest(){
		ABHFL_Case_Detail__c record = new ABHFL_Case_Detail__c();
        Case caseRec = [select id from Case limit 1];
        ASF_Case_Category_Config__c cc =[select id,CCC_External_Id__c from ASF_Case_Category_Config__c limit 1];
        ASF_CaseUIController.createCaseExtension(record,cc,caseRec.Id, 'ABHFL_Case_Detail__c');
    }
    
    @isTest
    public static void getMatchingContactsTest(){
        Account acc = [select id from account limit 1];
        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = acc.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        
        List<ASF_CaseUIController.searchResponse> wrapper = ASF_CaseUIController.getMatchingAccount('12344',false);
        //Asset asst = [SELECT Id, AccountId FROM Asset];
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            mobilephone = '1234567890',
            PANNO__c = 'ABCDE1234E'
        );
        insert testLead;
        Case cs = [select id,contactId,AccountId,AssetId,Lead__c from case limit 1];
        Id assetId = [select Id from Asset where accountId =: wrapper[0].recordId LIMIT 1].Id;
        ASF_CaseUIController.updateCRN(wrapper[0].recordId,assetId,cs.Id,'2333423',false);
        //ASF_CaseUIController.updateCRN(testLead.Id,assetId,cs.Id,'2333423',false);
        ASF_CaseUIController.getAccountData('tes','WBG','true', 'Industry','','{"accountLOB":"ABFL"}');
        //ASF_CaseUIController.getAccountData('tes','WBG','false', 'Industry','','{"accountLOB":"ABFL"}');
        
        ASF_Case_Category_Config__c cc =[select id,CCC_External_Id__c from ASF_Case_Category_Config__c limit 1];
        
        Map<string,string> fieldsData = new Map<string,string>();
        fieldsData.put('Id', cs.Id);
        fieldsData.put('CCC_External_Id__c', cc.CCC_External_Id__c);
        fieldsData.put('Type_Text__c', 'test');
        fieldsData.put('Sub_Type_Text__c', 'test');
        fieldsData.put('ContactId', cs.ContactId);
        fieldsData.put('AccountId', cs.AccountId);
        fieldsData.put('AssetId', cs.AssetId);
        
        //ASF_Case_Category_Config__c ccc = [select id from ASF_Case_Category_Config__c limit 1];
        string assetTest = 'closeCRN';
        ASF_CaseUIController.updateCase(JSON.serialize(fieldsData),assetTest);
        //ASF_CaseUIController.fetchNatureMetadata('L2','Complaint');
        string relObjName = ASF_CaseUIController.getCaseRelatedObjName(cc.id);
        Lead testLead2 = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            mobilephone = '1234567890',
            PANNO__c = 'ABCDE1234E'
        );
        ASF_CaseUIController.CreateProspectAndUpdateOnCase(cs,testLead2);
        System.assertEquals(null, relObjName, 'not equal to null');
        //}
        
    }
    @isTest
    public static void getMatchingContactsTest2(){
        Account acc = [select id from account limit 1];
        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = acc.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        
        List<ASF_CaseUIController.searchResponse> wrapper = ASF_CaseUIController.getMatchingAccount('12344',false);
        //Asset asst = [SELECT Id, AccountId FROM Asset];
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            mobilephone = '1234567890',
            PANNO__c = 'ABCDE1234E'
        );
        insert testLead;
        Case cs = [select id,contactId,AccountId,AssetId,Lead__c from case limit 1];
        Id assetId = [select Id from Asset where accountId =: wrapper[0].recordId LIMIT 1].Id;
        //ASF_CaseUIController.updateCRN(wrapper[0].recordId,assetId,cs.Id,'2333423',false);
        ASF_CaseUIController.updateCRN(testLead.Id,assetId,cs.Id,'2333423',false);
        //ASF_CaseUIController.getAccountData('tes','WBG','true', 'Industry','','{"accountLOB":"ABFL"}');
        ASF_CaseUIController.getAccountData('tes','WBG','false', 'Industry','','{"accountLOB":"ABFL"}');
        
        ASF_Case_Category_Config__c cc =[select id,CCC_External_Id__c from ASF_Case_Category_Config__c limit 1];
        
        Map<string,string> fieldsData = new Map<string,string>();
        fieldsData.put('Id', cs.Id);
        fieldsData.put('CCC_External_Id__c', cc.CCC_External_Id__c);
        fieldsData.put('Type_Text__c', 'test');
        fieldsData.put('Sub_Type_Text__c', 'test');
        fieldsData.put('ContactId', cs.ContactId);
        fieldsData.put('AccountId', cs.AccountId);
        fieldsData.put('AssetId', cs.AssetId);
        
        //string assetTest = 'closeCRN';
        //ASF_CaseUIController.updateCase(JSON.serialize(fieldsData),assetTest);
        //ASF_CaseUIController.fetchNatureMetadata('L2','Complaint');
        string relObjName = ASF_CaseUIController.getCaseRelatedObjName(cc.id);
        Lead testLead2 = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            mobilephone = '1234567890'
        );
        //ASF_CaseUIController.CreateProspectAndUpdateOnCase(cs,testLead2);
        System.assertEquals(null, relObjName, 'not equal to null');
        //}
        
    }
    @isTest
    public static void CreateProspectAndUpdateOnCaseTest(){
		Case caseRecord = new Case();
        Lead leadRecord = new Lead();
        leadRecord.MobilePhone  = '9855494949';
        leadRecord.LastName = 'test';
        leadRecord.PANNO__c = 'ABCDE1234E';
        insert caseRecord;
        //insert leadRecord;
        //caseRecord.Lead__c =leadRecord.Id;
        ASF_CaseUIController.CreateProspectAndUpdateOnCase(null,leadRecord);
        ASF_CaseUIController.CreateProspectAndUpdateOnCase(caseRecord,null);
    }
    

}