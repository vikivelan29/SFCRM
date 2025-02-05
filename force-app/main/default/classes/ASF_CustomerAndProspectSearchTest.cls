/**
 * @description       : 
 * @author            : virendra.patil@salesforce.com
 * @group             : 
 * @last modified on  : 05-14-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   05-13-2024   rsinghnagar@salesforce.com   Initial Version
**/
@isTest
public class ASF_CustomerAndProspectSearchTest {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    
    /**
    * @description 
    * @author rsinghnagar@salesforce.com | 05-14-2024 
    **/
    @TestSetup
    public static void setupData(){
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                            Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                            Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
        
        User userRecord = new User(Alias = 'standt', Email='standarduser@testorg.com', 
                                   EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                   LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                                   TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghijk56@gmail.com',Business_Unit__c = 'ABHFL');
        
        System.runAs(userRecord) {
            
            PermissionSet ps1 = [SELECT Id FROM PermissionSet WHERE Name = 'Manage_Case_Config'];
            PermissionSetAssignment psa1 = new PermissionSetAssignment();
            psa1.AssigneeId = userRecord.Id;
            psa1.PermissionSetId = ps1.Id;
            insert psa1;
            
            PermissionSet ps2 = [SELECT Id FROM PermissionSet WHERE Name = 'Create_Case'];
            PermissionSetAssignment psa2 = new PermissionSetAssignment();
            psa2.AssigneeId = userRecord.Id;
            psa2.PermissionSetId = ps2.Id;
            insert psa2;
            
        }
        String recordTypeId = (String)Schema.SObjectType.Account.getRecordTypeInfosByName().get('Non-Individual').getRecordTypeId(); 
        Account acc= new Account(
            Name ='Test FName',
            Client_Code__c = '10110',
            RecordTypeId= recordTypeId,
            Business_Unit__c = 'ABHFL',
            Line_Of_Business__c = 'ABHFL'
        );
        insert acc;
        
        Contact con = new Contact();
        con.Lastname ='Test con';
        con.FirstName ='Test con';
        con.AccountId = acc.Id;
        con.Email = 'test@test.com';
        con.Phone = '8329673314';
        con.Business_Unit__c = 'ABHFL';
        con.Line_of_Business__c = 'ABHFL';
        insert con;
        
    }
    
    @isTest
    public static void getRecordsTest(){
        Account a = [SELECT ID FROM Account LIMIT 1];
        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = a.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        List<ASF_CustomerAndProspectSearch.returnVal> returnVal = ASF_CustomerAndProspectSearch.getRecords('10110');
        if(returnVal.size()>0){
            System.assertEquals('Account',returnVal[0].objectName,'Success');
            System.assertEquals('10110',returnVal[0].objRecords[0].get('Client_Code__c'),'Success');
        }
    }
    @isTest
    public static void createProspectWithCaseExtnAndCaseTest(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        ASF_TestDataFactory.createCaseCategoryConfig();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        Lead ld = ASF_TestDataFactory.createServiceProspectRecord();
        ld.PANNO__c = 'ABCDE1234E';
        //update ld;
        ABHFL_Case_Detail__c abhflCaseDetail = new ABHFL_Case_Detail__c();
        
        casesList[0].Technical_Source__c = 'LWC';
        Test.startTest();
        Map<String,sObject> mObjNameVsRecord = ASF_CustomerAndProspectSearch.createProspectWithCaseExtnAndCase(casesList[0],abhflCaseDetail,ld);
        Test.stopTest();
        
        System.AssertEquals(true, mObjNameVsRecord.containsKey('Case'),'Success');
        System.AssertEquals(true, mObjNameVsRecord.containsKey('CaseExt'),'Success');
        System.AssertEquals(true, mObjNameVsRecord.containsKey('Lead'),'Success');
        
        
    }
    @isTest
    public static void createProspectWithCaseExtnAndCaseSalesProspectTest(){
        ASF_TestDataFactory.createCaseCategoryConfigWithSTP();
        ASF_TestDataFactory.createCaseCategoryConfig();
        List<Case> casesList = ASF_TestDataFactory.createCaseRecordsWithoutInsertSTP();
        Lead ld = ASF_TestDataFactory.createSalesProspectRecord();
        ld.PANNO__c = 'ABCDE1234E';
        //update ld;
        ABHFL_Case_Detail__c abhflCaseDetail = new ABHFL_Case_Detail__c();
        
        casesList[0].Technical_Source__c = 'LWC';
        Test.startTest();
        Map<String,sObject> mObjNameVsRecord = ASF_CustomerAndProspectSearch.createProspectWithCaseExtnAndCase(casesList[0],abhflCaseDetail,ld);
        Test.stopTest();
        
        System.AssertEquals(true, mObjNameVsRecord.containsKey('Case'),'Success');
        System.AssertEquals(true, mObjNameVsRecord.containsKey('CaseExt'),'Success');
        System.AssertEquals(true, mObjNameVsRecord.containsKey('Lead'),'Success');
        
        
    }
}