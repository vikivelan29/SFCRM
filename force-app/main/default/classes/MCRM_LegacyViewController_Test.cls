/**
 * @description       : Test Class for ABSLI Legacy View Controller
 * @author            : Rajendra Singh Nagar
 * @group             : 
 * @last modified on  : 11-20-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                           Modification
 * 1.0   08-21-2024   rsinghnagar@salesforce.com   Initial Version
**/
@isTest
public class MCRM_LegacyViewController_Test {
	private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
	@TestSetup
    static void makeData(){
        //Create user record.
        User userRecord = MCRM_TestDataFactory.createWellnessUser();

        System.runAs(userRecord) {
            Account acc = ASF_TestDataFactory.insertPersonAccount('Test','Account','');
                       
            List<Asset> listAsset = new List<Asset>();
            Asset assetObj = new Asset();
            assetObj.Name = 'BSLI-Policy1';
            assetObj.Policy_No__c = '000000036';
            assetObj.AccountId = acc.Id;
            assetObj.Business_Unit__c ='Wellness';
            
            listAsset.add(assetObj);
            assetObj = new Asset();
            assetObj.Name = 'BSLI-Policy2';
            assetObj.LAN__c = '008593136';
            assetObj.AccountId = acc.Id;
            assetObj.Business_Unit__c ='Wellness';
            listAsset.add(assetObj);
            
            insert listAsset;
        }
        
    }
    @isTest
    static void testGetRelatedContracts(){
        User userRecord = [SELECT Id FROM User WHERE Alias = 'standt' LIMIT 1];
        System.runAs(userRecord){
            Test.startTest();
            List<Account> acc = [SELECT Id FROM Account LIMIT 1];
            List<MCRM_LegacyViewController.ContractName> listPolicy = MCRM_LegacyViewController.getRelatedContracts(acc[0].Id);
            Assert.areEqual(2, listPolicy.size(), 'BSLI');
            Test.stopTest();
        }
    } 

    
	@isTest static void testgetLegacyData() {
        User userRecord = [SELECT Id FROM User WHERE Alias = 'standt' LIMIT 1];
        System.runAs(userRecord){
            // Set mock callout class 
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MCRM_LegacyViewController_Test.MCRM_LegacyMockResponseGenerator());

            MCRM_LegacyViewController.ResponseWrapper res = MCRM_LegacyViewController.getLegacyData('277956','','','','ABFL','');
            Test.stopTest();
            System.assertEquals(200,res.statusCode, 'code');
            System.assertEquals('1', res.ReturnCode, 'return code');
        }
    }
    
    @isTest static void testgetLegacyFailureData() {
        User userRecord = [SELECT Id FROM User WHERE Alias = 'standt' LIMIT 1];
        System.runAs(userRecord){
            // Set mock callout class 
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MCRM_LegacyViewController_Test.MCRM_LegacyMockFailureResponseGenerator());
            MCRM_LegacyViewController.ResponseWrapper res = MCRM_LegacyViewController.getLegacyData('27795','','','','ABFL','');
            Test.stopTest();
            System.assertEquals(404,res.statusCode, 'statusCode');
        }
    }

    /**
    * @description  Mocking success response
    */ 
    public class MCRM_LegacyMockResponseGenerator implements HttpCalloutMock {
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
    public class MCRM_LegacyMockFailureResponseGenerator implements HttpCalloutMock {
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