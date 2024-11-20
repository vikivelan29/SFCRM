/******************************************************  
* Author           - Dinoy Pauly
* Date             - 13-November-2024
* Description      - Test class for ABML_ScheduleReportsBatch
********************************************************
*/
@isTest
public class ABML_ScheduleReportsBatch_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    
    @testSetup
    static void setupTestData(){
        
        User userRecord = new User(Alias = 'usr1', Email='standarduser@testorg.com', 
                               EmailEncodingKey='UTF-8', LastName='Test', LanguageLocaleKey='en_US', 
                               LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, 
                               TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghijk561123@gmail.com', Business_Unit__c = 'ABML');
        insert userRecord;
        
        System.runAs(userRecord) {
            
            Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('ABML Franchisee').getRecordTypeId();
        
            Account acc = new Account(
               Name = 'Test Account',
               ABML_Branch_Code__c = 'Branch001',
               ABML_Franchisee_Code__c = 'Franchisee001',
               Line_of_Business__c = 'ABML',
               RecordTypeId = accRecordTypeId);
            insert acc;
            List<Case> caseList = new List<Case>();
        
        // Create a Case record
        Case testCase = new Case(
            Business_Unit__c = 'ABML',
            SuppliedEmail = 'testuser@example.com',
            AccountId = acc.Id,
            Source__c = 'Email',
            Stage__c = 'Email',
            Status = 'New',
            Subject = 'Test Subject',
            Type_Text__c = 'Type Test',
            Sub_Type_Text__c = 'Sub Type Test',
            CCC_External_Id__c ='',
          	Origin = 'ABML Email'
        );
        caseList.add(testCase);
            
        Case testCase1 = new Case(
            Business_Unit__c = 'ABML',
            SuppliedEmail = 'testuser2@example.com',
            AccountId = acc.Id,
            Source__c = 'Email',
            Stage__c = 'Resolved',
            Status = 'New',
            Subject = 'Test Subject2',
            Type_Text__c = 'Type Testt',
            Sub_Type_Text__c = 'Sub Type Testt',
            CCC_External_Id__c ='',
          	Origin = 'ABML Email'
        );
        caseList.add(testCase1);
        insert caseList;
            
        Case cas = [Select Id from Case Where Business_Unit__c = 'ABML' and Type_Text__c = 'Type Testt' LIMIT 1];
        Case cs = [Select Id from Case Where Business_Unit__c = 'ABML' and Type_Text__c = 'Type Testt' LIMIT 1];
            
        List<ABML_Case_Detail__c> caseDetails = new List<ABML_Case_Detail__c>();
            
        ABML_Case_Detail__c abmlCaseDetail = new ABML_Case_Detail__c();
        abmlCaseDetail.Case__c = cas.Id;
        abmlCaseDetail.Assigned_User__c = userRecord.Id;
        caseDetails.add(abmlCaseDetail);
            
        ABML_Case_Detail__c abmlCaseDetail1 = new ABML_Case_Detail__c();
        abmlCaseDetail1.Case__c = cs.Id;
        abmlCaseDetail1.Assigned_User__c = userRecord.Id;
        caseDetails.add(abmlCaseDetail1);
        insert caseDetails;
        }
        
    }
    
    @isTest
    static void testReportScheduler(){
        String abml=System.Label.ABML_BU;
        List<id> caseDetailsId = new List<id>();
        List<case> cases = [SELECT Type_Text__c,Sub_Type_Text__c,Assigned_Team__c, OwnerId, Owner.Name, Account.Name, Subject, CreatedDate,CaseNumber, Client_Code__c,ABML_Case_Detail__c,Description,Account.PersonDepartment, Account.Type 
                            FROM case 
                            where Business_Unit__c =:abml];
       
        for (case cs : cases) {
            caseDetailsId.add(cs.Id);
        }
        List<ABML_Case_Detail__c> caseDetails =[SELECT Name,Assigned_User__c,Case__c,Case__r.Pending_Clarification__c,Case__r.Type_Text__c,Case__r.Sub_Type_Text__c,Case__r.Ageing_Business_Days__c,TAT_Deadline_Date__c,TAT_Days__c 
                                                FROM ABML_Case_Detail__c 
                                                where Case__c IN:caseDetailsId];
        
        Test.startTest();

            ABML_ScheduleReportsBatch batchCls = new ABML_ScheduleReportsBatch();
            String sch = '0 0 23 * * ?';
            system.schedule('Test Run', sch, batchCls);
            batchCls.execute(null);

        Test.stopTest();
        System.AssertEquals(2,caseDetails.size(),'caseDetails');
    }

}