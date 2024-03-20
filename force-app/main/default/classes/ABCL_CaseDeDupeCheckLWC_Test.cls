@isTest
public class ABCL_CaseDeDupeCheckLWC_Test {
    @TestSetup
    private static void dataSetup(){
        Account testAcc = ASF_TestDataFactory.insertBusinessAccount('','');
        
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                            Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                            Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
        
        Asset assetObj = new Asset();
        assetObj.Name = '981726345';
        assetObj.AccountId = testAcc.Id;
        insert assetObj;
        
        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_Case_Category_Config__c ccc = [Select Id from ASF_Case_Category_Config__c where CCC_External_Id__c = 'CCC-CC-CCLTD-01' limit 1];
        
        Asset ast = [Select Id from Asset where Name =: '981726345'];
        
        PAY_Payment_Detail__c payDetailRecord = new PAY_Payment_Detail__c();
        payDetailRecord.Txn_ref_no__c = '1011010110';
        insert payDetailRecord;
        
        ASF_Case_Stage_Config__c stage1 = new ASF_Case_Stage_Config__c();
        stage1.Case_Category_Config__c = ccc.Id;
        stage1.Order__c = 1;
        stage1.StageName__c = 'New';
        stage1.Stage_SLA_1__c = 1;
        stage1.Status_Mapping__c = 'New';
        // stage1.Stage_SLA_3__c = 3;
        stage1.SLA_Target_1_Type__c = 'Manager';
        stage1.Query_Fields__c = 'Id,Stage__c';
        stage1.Manual_Stage__c = false;
        
        insert stage1;
        
        Contact con = new Contact();
        con.Lastname ='Test con';
        con.AccountId = testAcc.Id;
        con.Email = 'test@test.com';
        con.Phone = '8329673314';
        insert con;
        List<Case> caseList = ASF_TestDataFactory.createCaseRecords(1);
        caseList[0].AssetId = ast.Id;
        caseList[0].OwnerId = UserInfo.getUserId();
        caseList[0].PAY_Payment_Detail__c = payDetailRecord.Id;
        caseList[0].Status = 'New';
        caseList[0].Stage__c='New';
        caseList[0].contactId = con.Id;
        //caseList[0].CCC_External_Id__c = 'CCC-CC-CCLTD-01';
        update caseList;
    }
    
    @isTest
    private static void getDuplicateCasesWithDiffTransactionIdTest(){
        List<Case> existingSR = [SELECT ID,CaseNumber FROM Case WHERE CCC_External_Id__c ='CCC-CC-CCLTD-01'];

        try{
            Case c = new Case();
            c.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
            c.Subject = 'Test Subject';
            c.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
            c.Status = 'New';
            c.Stage__c='New';
            c.Business_Unit__c = 'Payments';
            c.Technical_Source__c = 'API';
            c.Client_Code_Text__c = 'ABC1234';
            insert c;
            ABCL_CaseDeDupeCheckLWC.getDuplicateCases(new List<Case>{c},'Payments','1011010220');
        }
        catch(exception e){
            System.assertEquals(true,e.getMessage().contains('Duplicate Case found.'),'Success');
        }
        
    }
    @isTest
    private static void getDuplicateCasesWithSameTransactionIdTest(){
        ASF_Case_Category_Config__c ccc = [Select Id from ASF_Case_Category_Config__c where CCC_External_Id__c = 'CCC-CC-CCLTD-01' limit 1];
        ccc.Is_Transaction_Related__c = true;
        update ccc;
        
        List<Case> existingSR = [SELECT ID,CaseNumber FROM Case WHERE CCC_External_Id__c ='CCC-CC-CCLTD-01'];
        Case c = new Case();
        c.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        c.Subject = 'Test Subject';
        c.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
        c.Status = 'New';
		c.Stage__c='New';
        insert c;
        try{
            ABCL_CaseDeDupeCheckLWC.getDuplicateCases(new List<Case>{c},'Payments','1011010110');
        }
        catch(exception e){
            System.assertEquals(true,e.getMessage().contains('Duplicate Case found.'),'Success');
        }
        
    }
    
}