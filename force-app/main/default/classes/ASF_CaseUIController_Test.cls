@IsTest
public class ASF_CaseUIController_Test {
    @TestSetup
    public static void setupData(){
        
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                           Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                           Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);

        Account a = new Account();
        a.Name = '12344';
        //a.CRN__c = '12344';
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
        List<account> wrapper = ASF_CaseUIController.getMatchingAccount('12344');
        test.stopTest();
        system.assertEquals(wrapper.size(), 0);
        }
    @isTest
    public static void checkContactsTest(){
        Account acc = [select id from account limit 1];
        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = acc.Id;
        List<account> wrapper = ASF_CaseUIController.getMatchingAccount('12344');
        system.assertEquals(wrapper.size(), 0);
        }
    
    @isTest
    public static void getMatchingContactsTest(){
        Account acc = [select id from account limit 1];
        ASF_CaseUIController.resWrapper reswrap = new ASF_CaseUIController.resWrapper('222','111');
        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = acc.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        
        List<account> wrapper = ASF_CaseUIController.getMatchingAccount('12344');
        Asset ass = [SELECT Id, AccountId FROM Asset];
        System.debug('@@@ass'+ass+' '+ wrapper);
        ASF_CaseUIController.conAssetWrapper wrap = ASF_CaseUIController.getMatchingContacts(wrapper[0].Id);
        Case cs = [select id,contactId,AccountId,AssetId from case limit 1];
        
        ASF_CaseUIController.updateCRN(wrapper[0].Id,wrap.asstList[0].Id,cs.Id,'2333423');
        ASF_CaseUIController.getAccountData('tes','WBG','true', 'Industry','');
        ASF_CaseUIController.getAccountData('tes','WBG','false', 'Industry','');
        
        ASF_Case_Category_Config__c cc =[select id,CCC_External_Id__c from ASF_Case_Category_Config__c limit 1];
        
        Map<string,string> fieldsData = new Map<string,string>();
        fieldsData.put('Id', cs.Id);
        fieldsData.put('CCC_External_Id__c', cc.CCC_External_Id__c);
        fieldsData.put('Type_Text__c', 'test');
        fieldsData.put('Sub_Type_Text__c', 'test');
        fieldsData.put('ContactId', cs.ContactId);
        fieldsData.put('AccountId', cs.AccountId);
        fieldsData.put('AssetId', cs.AssetId);
        
        ASF_Case_Category_Config__c ccc = [select id from ASF_Case_Category_Config__c limit 1];
        string assetTest = '';
        ASF_CaseUIController.updateCase(JSON.serialize(fieldsData),assetTest);
        //ASF_CaseUIController.fetchNatureMetadata('L2','Complaint');
        string relObjName = ASF_CaseUIController.getCaseRelatedObjName(ccc.id);
        System.assertEquals(null, relObjName);
    }
}