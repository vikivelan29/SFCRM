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
@isTest
public class ASF_AssocCustomerForAPICases_Test {
    /**
    * @description 
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    **/
    @TestSetup
    private static void dataSetup(){
        Account testAcc = ASF_TestDataFactory.insertPersonAccount('John', 'Smith','10110000');
        testAcc.Business_Unit__c = 'ABFL';
        testAcc.Client_Code__c='CCC-CC-CCLTD-01';
        update testAcc;
        
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                            Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                            Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
        
        Asset assetObj = new Asset();
        assetObj.Name = '981726345';
        assetObj.LAN__c = '981726345';
        assetObj.Business_Unit__c = 'ABFL';
        assetObj.AccountId = testAcc.Id;
        insert assetObj;
        
        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_Case_Category_Config__c ccc = [Select Id from ASF_Case_Category_Config__c where CCC_External_Id__c = 'CCC-CC-CCLTD-01' limit 1];
        
        Asset ast = [Select Id from Asset where Name =: '981726345'];
        
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
        
        List<Case> caseList = ASF_TestDataFactory.createCaseRecords(1);
        caseList[0].AssetId = ast.Id;
        caseList[0].OwnerId = UserInfo.getUserId();
        caseList[0].Status = 'New';
        caseList[0].Stage__c='New';
        caseList[0].accountId = testAcc.Id;
        //caseList[0].CCC_External_Id__c = 'CCC-CC-CCLTD-01';
        update caseList;
    }
    
    /**
    * @description 
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    **/
    @isTest
    private static void getDuplicateCasesWithDiffTransactionIdTest(){
        Case c = new Case();
        c.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        c.Subject = 'Test Subject';
        c.CCC_External_Id__c = 'CCC-CC-CCLTD-01';
        c.LAN__c = '981726345';
        c.Status = 'New';
        c.Stage__c='New';
        c.Business_Unit__c = 'ABFL';
        c.Technical_Source__c = 'Email';
        c.Client_Code_Text__c = 'CCC-CC-CCLTD-01';
        insert c;
        
        // Query and check assetId and Accountid population
        List<Case> con = [select id, AccountId, AssetId from Case where Id=:c.Id];
        Assert.isNotNull(con[0].AccountId, 'Account Id is not null');
        Assert.isNotNull(con[0].AssetId, 'Asset Id is not null');
    }
}