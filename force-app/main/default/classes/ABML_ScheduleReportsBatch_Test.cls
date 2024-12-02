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
        
        User userRecord = new User(Alias = 'usr1', Email = 'standarduser@testorg.com', EmailEncodingKey = 'UTF-8', LastName = 'Test', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', 
                                   ProfileId = SYSTEMADMIN_PROFILE.Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'testAbmlUser1@gmail.com', Business_Unit__c = 'ABML');
        insert userRecord;
        
        System.runAs(userRecord) {
            
            Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('ABML Franchisee').getRecordTypeId();
            
            Account objAccount = new Account(Name = 'Test Account', ABML_Branch_Code__c = 'Branch001', ABML_Franchisee_Code__c = 'Franchisee001', Line_of_Business__c = 'ABML', RecordTypeId = accRecordTypeId);
            insert objAccount;
            List<Case> listOfCases = new List<Case>();
            
            for(Integer caseCount = 0 ; caseCount < 2 ; caseCount++){
                Case objCase = new Case();
                objCase.Business_Unit__c = 'ABML';
                objCase.SuppliedEmail = 'testuser' + caseCount + '@example.com';
                objCase.AccountId = objAccount.Id;
                objCase.Source__c = 'Email';
                objCase.Stage__c = 'Resolved';
                objCase.Status = 'New';
                objCase.Subject = 'Test Subject';
                objCase.Type_Text__c = 'Type Test ' + caseCount;
                objCase.Sub_Type_Text__c = 'Sub Type Test';
                objCase.Origin = 'ABML Email';        
                
                listOfCases.add(objCase);
            }
            insert listOfCases;
            
            List<ABML_Case_Detail__c> listCaseDetails = new List<ABML_Case_Detail__c>();
            
            for(Case objCase : listOfCases){
                ABML_Case_Detail__c objCaseDetail = new ABML_Case_Detail__c();
                objCaseDetail.Case__c = objCase.Id;
                objCaseDetail.Assigned_User__c = userRecord.Id;
                listCaseDetails.add(objCaseDetail);            
            }            
            insert listCaseDetails;
        }        
        
        List<ABML_Daily_Report_Sender__c> listOfReportSender = new List<ABML_Daily_Report_Sender__c>();
        
        ABML_Daily_Report_Sender__c objReportSender = new ABML_Daily_Report_Sender__c( Name = 'test1', Email__c = 'test@test.com');
        listOfReportSender.add(objReportSender);
        insert listOfReportSender;
        
        //OrgWideEmailAddress[] addresses = [SELECT Id FROM OrgWideEmailAddress LIMIT 1];
    }
    
    @isTest
    static void scheduleReportTest(){
        User objUser = [SELECT Id, Name, UserName FROM User WHERE Business_Unit__c = 'ABML' and LastName = 'Test' LIMIT 1];
        System.runAs(objUser){
            Test.startTest();
            
            List<Id> listOfCaseDetailIds = new List<Id>();            
            for (Case objCase : [SELECT Type_Text__c, Sub_Type_Text__c, Assigned_Team__c, OwnerId, Owner.Name, Account.Name, Subject, CreatedDate, CaseNumber, Client_Code__c, 
                                 ABML_Case_Detail__c, Description, Account.PersonDepartment, Account.Type FROM case where Business_Unit__c =: System.Label.ABML_BU])
            {
                listOfCaseDetailIds.add(objCase.Id);
            }
            
            List<ABML_Case_Detail__c> listOfCaseDetails = new List<ABML_Case_Detail__c>();
            listOfCaseDetails = [SELECT Name, Assigned_User__c, Case__c, Case__r.Pending_Clarification__c, Case__r.Type_Text__c, Case__r.Sub_Type_Text__c, Case__r.Ageing_Business_Days__c,
                                 TAT_Deadline_Date__c, TAT_Days__c FROM ABML_Case_Detail__c where Case__c IN : listOfCaseDetailIds];            
            
            ABML_ScheduleReportsBatch objScheduleBatch = new ABML_ScheduleReportsBatch();
            String sch = '0 0 23 * * ?';
            System.schedule('Test Run', sch, objScheduleBatch);
            objScheduleBatch.execute(null);            
            System.AssertEquals(2,listOfCaseDetails.size(),'Case Details Match');
            
            Test.stopTest();
        }
    }

}
