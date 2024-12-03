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
        
        ABML_Daily_Report_Sender__c objReportSender = new ABML_Daily_Report_Sender__c( Name = 'test1', Email__c = 'test@test.com');
        ABML_Daily_Report_Sender__c objReportSenderTwo = new ABML_Daily_Report_Sender__c( Name = 'ordWideAddress', Email__c = 'abctsl.crmteam-noreply@adityabirlacapital.com');
        listOfReportSender.add(objReportSender);
        listOfReportSender.add(objReportSenderTwo);
        insert listOfReportSender;
        
        //OrgWideEmailAddress[] addresses = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
        
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