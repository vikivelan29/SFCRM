/**
 * @description       : Test Class for ABSLI Legacy View Controller
 * @author            : Aditya Mehrotra
 * @group             : 
 * @last modified on  : 21/08/2024
 * @last modified by  : Aditya Mehrotra
 * Modifications Log
 * Ver   Date         Author                           Modification
 * 1.0   08-21-2024   aditya.mehrotra@salesforce.com   Initial Version
**/
@isTest
public class ABSLI_LegacyViewController_Test {
	private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
	@TestSetup
    static void makeData(){
        Group slaGroup = new Group();
        
        slaGroup = new Group(Name='SLAManagerGroup', DeveloperName='SLAManagerGroup', Type = 'Queue');
        insert slaGroup;
        
        User superManagerUser = new User(
            IsActive = true,
            Business_Unit__c='ABFL',
            FirstName = 'Test',
            LastName='Super Manager User Test 12',
            Username='supermanageruserTest12@test.com',
            Email='supermanageruserTest12@test.com',
            Alias = 'mgrt',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', 
            ProfileId = SYSTEMADMIN_PROFILE.Id, 
            TimeZoneSidKey='America/Los_Angeles', managerGroupId__c=slaGroup.Id
        );
        insert superManagerUser;
        
        User userRecord1 = new User(Alias = 'standt', Email='stanrduserEmails@testorg.com', 
                                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                    LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                    TimeZoneSidKey='America/Los_Angeles', UserName='Testcdefghijk567@gmail.com',
                                    managerGroupId__c=slaGroup.Id, managerID = superManagerUser.Id
                                    );
        insert userRecord1;        
        Test.startTest();
        List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();
        PermissionSet ps = [SELECT Id 
                            FROM PermissionSet 
                            WHERE Name = 'Admin_User' ];
        psa.add(new PermissionSetAssignment(AssigneeId = userRecord1.Id, PermissionSetId = ps.Id));
        psa.add(new PermissionSetAssignment(AssigneeId = superManagerUser.Id, PermissionSetId = ps.Id));
        
        
        insert psa;
        Test.stopTest();
        System.runAs(userRecord1) {
            Account acc = ASF_TestDataFactory.insertPersonAccount('Test','Account','');
                       
            List<Asset> listAsset = new List<Asset>();
            Asset assetObj = new Asset();
            assetObj.Name = 'BSLI-Policy1';
            assetObj.Policy_No__c = '000000036';
            assetObj.AccountId = acc.Id;
            assetObj.Business_Unit__c ='ABSLI';
            
            listAsset.add(assetObj);
            assetObj = new Asset();
            assetObj.Name = 'BSLI-Policy2';
            assetObj.LAN__c = '008593136';
            assetObj.AccountId = acc.Id;
            assetObj.Business_Unit__c ='ABSLI';
            listAsset.add(assetObj);
            
            insert listAsset;
        }
        
    }
    @isTest
    static void testGetRelatedPolicyNames(){
        List<Account> acc = [SELECT ID FROM Account LIMIT 1];
        Test.startTest();
        	List<ABSLI_LegacyViewController.PolicyName> listPolicy = ABSLI_LegacyViewController.getRelatedPolicyNames(acc[0].Id);
        	Assert.areEqual(2, listPolicy.size(), 'BSLI');
        Test.stopTest();
    } 
    
	@isTest static void testgetLegacyData() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new ABSLI_LegacyMockResponseGenerator());
        Test.startTest();
        ABSLI_LegacyViewController.ResponseWrapper res = ABSLI_LegacyViewController.getLegacyData('277956','','','','ABFL','');
        Test.stopTest();
        System.assertEquals(200,res.statusCode, 'code');
        System.assertEquals('1', res.ReturnCode, 'return code');
    }
    
    @isTest static void testgetLegacyFailureData() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new ABSLI_LegacyMockFailureResponseGenerator());
        Test.startTest();
        ABSLI_LegacyViewController.ResponseWrapper res = ABSLI_LegacyViewController.getLegacyData('27795','','','','ABFL','');
        Test.stopTest();
        System.assertEquals(404,res.statusCode, 'statusCode');
    }
    /**
    * @description  Mocking success response
    */ 
    public class ABSLI_LegacyMockResponseGenerator implements HttpCalloutMock {
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
    public class ABSLI_LegacyMockFailureResponseGenerator implements HttpCalloutMock {
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
