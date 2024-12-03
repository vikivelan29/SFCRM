/**
* @description       : Test Class for ABML_LegacyView
* @author            : saravpreet.arora@in.ey.com
* @group             : 
* @last modified on  : 
* @last modified by  : 
* Modifications Log
* Ver   Date         Author                       Modification
* 1.0   06/11/2024   Saravpreet Arora             Initial Version
**/
@isTest
public class ABML_LegacyView_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @TestSetup
    static void makeData(){
        
        Id FraAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('ABML Franchisee').getRecordTypeId();
        Id BranchEmpAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('ABML Branch Employee').getRecordTypeId();
        Id CustAccRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('ABML Customer').getRecordTypeId();
        
        
        User userRecord = new User(Alias = 'standt', Email='stantarduserEmails@testorg.com', EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US', 
                                   LocaleSidKey = 'en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'testUserAbml@gmail.com');
        insert userRecord; 
        
        System.runAs(userRecord) {
            List<Account> listOfAccountsToInsert = new  List<Account>();
            Account testAccount = new Account(Name = 'Franchisee Acc', RecordTypeId = FraAccRecordTypeId, ABML_Franchisee_Code__c = 'Franchisee001', Line_of_Business__c = 'ABML');
            listOfAccountsToInsert.add(testAccount); 
            Account testAccountBr = new Account(LastName = 'Branch Employee Account', RecordTypeId = BranchEmpAccRecordTypeId, Line_of_Business__c = 'ABML', 
                                                ABML_Client_Branch_Franchisee__pc = testAccount.Id);
            listOfAccountsToInsert.add(testAccountBr);
            Account testAccountCa = new Account( LastName = 'Customer Account', RecordTypeId = CustAccRecordTypeId, Line_of_Business__c = 'ABML', 
                                                ABML_Client_Branch_Franchisee__pc = testAccount.Id, Client_Code__c = 'Client001', PAN__c = 'PAN001' );            
            listOfAccountsToInsert.add(testAccountCa);
            insert listOfAccountsToInsert;
        }
        
    }
    
    @isTest
    static void abmlGetFranchiseeAccountData(){
        User objUser = [SELECT Id, Name FROM User WHERE Business_Unit__c = 'ABML' LIMIT 1];
        System.runAs(objUser){            
            Test.startTest();
            Id franchiseeAccountId = [SELECT ID FROM Account Where Name = 'Franchisee Acc'].Id;
            ABML_LegacyView.abmlPersonAccountWrapper result = ABML_LegacyView.abmlGetPersonAccountData(franchiseeAccountId);
            System.assertEquals('Franchisee001', result.franchiseeCode, 'Franchisee Code match!');
            Test.stopTest();
        }
    }
    
    @isTest
    static void testabmlGetBranchAccountData(){
        User objUser = [SELECT Id, Name FROM User WHERE Business_Unit__c = 'ABML' LIMIT 1];
        System.runAs(objUser){            
            Test.startTest();
            Id branchEmpAccId = [SELECT ID FROM Account Where LastName = 'Branch Employee Account'].Id;
            ABML_LegacyView.abmlPersonAccountWrapper resultBr = ABML_LegacyView.abmlGetPersonAccountData(branchEmpAccId);
            System.assertNotEquals(null, resultBr, 'The result should not be null!');
            Test.stopTest();
        }
    }
    
    @isTest
    static void testabmlGetCustAccData(){
        User objUser = [SELECT Id, Name FROM User WHERE Business_Unit__c = 'ABML' LIMIT 1];
        System.runAs(objUser){
            
            Test.startTest();
            Id customerAccId = [SELECT ID FROM Account WHERE  LastName = 'Customer Account'].Id;
            ABML_LegacyView.abmlPersonAccountWrapper resultCa = ABML_LegacyView.abmlGetPersonAccountData(customerAccId);
            System.assertEquals('Client001', resultCa.clientCode, 'Client Code matched!');
            Test.stopTest();
        }
    }
    
    
    @isTest static void abmlGetLegacyDataTest() {
        // Set mock callout class 
        User objUser = [SELECT Id, Name FROM User WHERE Business_Unit__c = 'ABML' LIMIT 1];
        System.runAs(objUser){
            
            Test.startTest();
            
            Test.setMock(HttpCalloutMock.class, new ABML_LegacyMockResponseGenerator());            
            ABML_LegacyView.AbmlResponseWrapper res = ABML_LegacyView.abmlGetLegacyData('277956','','','','','','','');            
            System.assertEquals(200, res.statusCode, 'Success Response Code!');
            
            Test.stopTest();
        }
    }
    
    @isTest static void abmlGetLegacyDataFailTest() {
        // Set mock callout class 
        User objUser = [SELECT Id, Name FROM User WHERE Business_Unit__c = 'ABML' LIMIT 1];
        System.runAs(objUser){
            
            Test.startTest();
            
            Test.setMock(HttpCalloutMock.class, new ABML_LegacyMockFailureResponseGenerator());
            ABML_LegacyView.AbmlResponseWrapper res = ABML_LegacyView.abmlGetLegacyData('','','','','','','','');
            System.assertEquals(404, res.statusCode, 'Failure Response Code!');
            
            Test.stopTest();            
        }
    }
    
    /**
* @description  Mocking success response
*/ 
    public class ABML_LegacyMockResponseGenerator implements HttpCalloutMock {
        /**
* @description  Mocking success response
* @param req
** @return HTTPResponse
*/ 
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String s = '{\"ReturnCode\":\"1\",\"ReturnMessage\":\"Recordretrievedsuccessfully\",\"lstDetails\":[{\"Customer\":\"RITESHYadav\",\"CaseID\":\"CAS-2395728-C4Z3V6\",\"Category\":\"Request\",\"CaseType\":\"Pre-Closure\\/Closure\",\"SubType\":\"PreClosure\",\"Source\":\"Walkin\",\"LoanAccountNo\":\"LNIND0HL-07200068831\",\"CreatedOn\":\"08-04-202411:24:20\",\"CaseStatus\":\"Resolved\",\"LastUpdatedOn\":\"13-04-202409:18:33\",\"Owner\":\"MeghnaKadam\"},{\"Customer\":\"RITESHYadav\",\"CaseID\":\"CAS-2389442-V0H3V7\",\"Category\":\"Request\",\"CaseType\":\"Statements&Documents\",\"SubType\":\"ListofDocuments\\/Postdisbursaldocs\",\"Source\":\"WhatsApp\",\"LoanAccountNo\":\"LNIND0HL-07200068831\",\"CreatedOn\":\"03-04-202409:12:03\",\"CaseStatus\":\"Canceled\",\"LastUpdatedOn\":\"03-04-202409:12:42\",\"Owner\":\"SunilYadav10\"},{\"Customer\":\"RITESHYadav\",\"CaseID\":\"CAS-2342421-D2H4R5\",\"Category\":\"Request\",\"CaseType\":\"Statements&Documents\",\"SubType\":\"StatementofAccount\",\"Source\":\"WhatsApp\",\"LoanAccountNo\":\"LNIND0HL-07200068831\",\"CreatedOn\":\"23-02-202414:10:47\",\"CaseStatus\":\"Resolved\",\"LastUpdatedOn\":\"23-02-202414:10:58\",\"Owner\":\"ABFSSLCRMADMIN03\"},{\"Customer\":\"RITESHYadav\",\"CaseID\":\"CAS-2166297-Z9D3V0\",\"Category\":\"Query\",\"CaseType\":\"LoanAccountDetailsRelated\",\"SubType\":\"LoanAccountDetails\",\"Source\":\"WhatsApp\",\"LoanAccountNo\":\"LNIND0HL-07200068831\",\"CreatedOn\":\"13-10-202315:07:54\",\"CaseStatus\":\"Resolved\",\"LastUpdatedOn\":\"13-10-202315:08:03\",\"Owner\":\"CustomerService\"},{\"Customer\":\"RITESHYadav\",\"CaseID\":\"CAS-2125970-Z8S6T2\",\"Category\":\"Query\",\"CaseType\":\"LoanAccountDetailsRelated\",\"SubType\":\"LoanAccountDetails\",\"Source\":\"WhatsApp\",\"LoanAccountNo\":\"LNIND0HL-07200068831\",\"CreatedOn\":\"13-09-202315:54:18\",\"CaseStatus\":\"Resolved\",\"LastUpdatedOn\":\"13-09-202315:54:27\",\"Owner\":\"CustomerService\"},{\"Customer\":\"RITESHYadav\",\"CaseID\":\"CAS-994441-R9Z1G3\",\"Category\":\"Query\",\"CaseType\":\"Campaign\",\"SubType\":\"Non-Contactable\",\"Source\":\"Email\",\"LoanAccountNo\":\"LNIND0HL-07200068831\",\"CreatedOn\":\"25-09-202113:00:37\",\"CaseStatus\":\"Resolved\",\"LastUpdatedOn\":\"25-09-202113:00:49\",\"Owner\":\"CustomerService\"},{\"Customer\":\"RITESHYadav\",\"CaseID\":\"CAS-984667-K6K1P3\",\"Category\":\"Query\",\"CaseType\":\"LoanAccountDetailsRelated\",\"SubType\":\"LoanAccountDetails\",\"Source\":\"WhatsApp\",\"LoanAccountNo\":\"LNIND0HL-07200068831\",\"CreatedOn\":\"20-09-202109:10:54\",\"CaseStatus\":\"Resolved\",\"LastUpdatedOn\":\"20-09-202109:11:04\",\"Owner\":\"CustomerService\"},{\"Customer\":\"RITESHYadav\",\"CaseID\":\"CAS-984665-M2B6B1\",\"Category\":\"Query\",\"CaseType\":\"LoanAccountDetailsRelated\",\"SubType\":\"LoanAccountDetails\",\"Source\":\"WhatsApp\",\"LoanAccountNo\":\"LNIND0HL-07200068831\",\"CreatedOn\":\"20-09-202109:10:28\",\"CaseStatus\":\"Resolved\",\"LastUpdatedOn\":\"20-09-202109:10:33\",\"Owner\":\"CustomerService\"},{\"Customer\":\"RITESHYadav\",\"CaseID\":\"CAS-984664-G7B6N3\",\"Category\":\"Query\",\"CaseType\":\"LoanAccountDetailsRelated\",\"SubType\":\"LoanAccountDetails\",\"Source\":\"WhatsApp\",\"LoanAccountNo\":\"LNIND0HL-07200068831\",\"CreatedOn\":\"20-09-202109:10:13\",\"CaseStatus\":\"Resolved\",\"LastUpdatedOn\":\"20-09-202109:10:21\",\"Owner\":\"CustomerService\"},{\"Customer\":\"RITESHYadav\",\"CaseID\":\"CAS-984663-X6R1C0\",\"Category\":\"Request\",\"CaseType\":\"Statements&Documents\",\"SubType\":\"ListofDocuments\\/Postdisbursaldocs\",\"Source\":\"WhatsApp\",\"LoanAccountNo\":\"LNIND0HL-07200068831\",\"CreatedOn\":\"20-09-202109:09:57\",\"CaseStatus\":\"Resolved\",\"LastUpdatedOn\":\"28-09-202114:31:26\",\"Owner\":\"GautamSejwal\"},{\"Customer\":\"RITESHYadav\",\"CaseID\":\"CAS-984647-K7N9D2\",\"Category\":\"Request\",\"CaseType\":\"Statements&Documents\",\"SubType\":\"InsuranceCopy\",\"Source\":\"CallCentre-Inbound\",\"LoanAccountNo\":\"LNIND0HL-07200068831\",\"CreatedOn\":\"20-09-202109:07:05\",\"CaseStatus\":\"Resolved\",\"LastUpdatedOn\":\"22-09-202105:30:18\",\"Owner\":\"DipeshVarekar\"}]}';
            res.setBody(s);
            res.setStatusCode(200);
            return res;
        }
    }
    /**
* @description Mocking failure response
*/ 
    public class ABML_LegacyMockFailureResponseGenerator implements HttpCalloutMock {
        /**
* @description  Mocking failure response
* @param req
** @return HTTPResponse
*/ 
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String s = '{\"ReturnCode\":\"2\",\"ReturnMessage\":\"Nodatafound\"}';
            res.setBody(s);
            res.setStatusCode(404);
            return res;
        }
    }
}