/**
 * @description       : Test Class for 
 * @author            : Aditee Churiwala
 * @group             : 
 * @last modified on  : 01/11/2024
 * @last modified by  : Aditee Churiwala
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   12-22-2023   achuriwala@salesforce.com   Initial Version
**/
@isTest
public class ABHI_KavachPolicies_Test {
	@isTest static void testgetLegacyData() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new ABHI_KavachPoliciesMockResponseGenerator());
        Test.startTest();
        List<ABHI_KavachPolicies.KavachResponseWrapper> res = ABHI_KavachPolicies.getPolicyExternalData('31-24-0004016-22','');
        Test.stopTest();
        
        //System.assertEquals('13882784-01',res[0].clientCode,'client code' );
        //System.assertEquals('1', res.ReturnCode, 'return code');
    }
    /*@isTest static void testgetLegacyFailureData() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new ABFL_LegacyMockFailureResponseGenerator());
        Test.startTest();
        ABFL_LegacyView.ResponseWrapper res = ABFL_LegacyView.getLegacyData('277956','','','','ABFL');
        Test.stopTest();
        
        System.assertEquals(404,res.statusCode, 'statusCode');
    }*/
    /**
    * @description  Mocking success response
    */ 
    public class ABHI_KavachPoliciesMockResponseGenerator implements HttpCalloutMock {
        /**
            * @description  Mocking success response
            * @param req
            ** @return HTTPResponse
        */ 
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String s = '{\"Customer\":[{\"AadharNo\":null,\"AddressLine1\":\"250/13NearSatJindaKalayanaMandirChottaPanna,Kalanaur\",\"AddressLine2\":\"NA\",\"AddressLine3\":null,\"AddressType\":\"Permanent\",\"PIN\":\"124113\",\"City\":\"Rohtak\",\"State\":\"HARYANA\",\"Email\":\"ab@xyz.com\",\"HomePhone\":null,\"Alternatemobile\":\"9999999999\",\"CoreSystemId\":\"13882784-01\",\"CountryCode\":\"India\",\"DateofBirth\":\"1995-10-21\",\"Designation\":\"Others\",\"EmployeeCode\":\"75226810\",\"FirstName\":\"MrParas\",\"FullName\":\"MrParas.\",\"Gender\":\"Male\",\"LastName\":\".\",\"HealthCardNumber\":\"6051092413469349\",\"Height\":\"0\",\"Weight\":\"0\",\"MaritualStatus\":null,\"MobilePhone\":\"9999999999\",\"Nationality\":\"Indian\",\"Nationality1\":\"India\",\"PanNo\":\"AACCE9326L\",\"ParentCode\":null,\"WhatsappNumber\":\"YES\",\"CustomerSegments\":[{\"Segment\":\"HNI\"}],\"CustomerRoles\":[{\"CustomerType\":\"MemberCustomer\"},{\"CustomerType\":\"DependentCustomer\"}]}],\"CustomerMemberMapping\":[{\"ClientId\":\"13882784-01\",\"MemberId\":\"13882784-01\",\"MemberStatus\":\"Active\",\"MemberSubStatus\":null,\"PreExistingDiseaseWaitingPeriod\":null,\"TotalNCB\":\"0\",\"RidersOpted\":null,\"SumInsured\":\"9500000\",\"UpfrontDiscount\":\"No\"}],\"NomineeDetails\":[{\"Gender\":null,\"NomineeContactNumber\":\"9999999999\",\"NomineeDOB\":null,\"NomineeName\":\"RoshanLal\",\"NomineePercentage\":\"100\",\"Relationship\":\"Father\"}],\"Policy\":{\"AgentStatus\":null,\"ARU\":\"STP\",\"ActiveHealthVersion\":null,\"ApplicationDate\":\"2024-07-29\",\"ProposalNumber\":\"QU-23-5211-8454629-00-01\",\"AutoDebitFlag\":null,\"AutoDebitRegistrationStatus\":null,\"BalanceHR\":null,\"BasicPremium\":\"4650.0\",\"BusinessType\":\"Renewal\",\"Channel\":\"ABHI\",\"COILink\":null,\"CountOfLives\":\"1\",\"CombiPolicyNo\":null,\"CombiPolicyType\":\"No\",\"ConsumedHR\":null,\"CrossSellNumber\":null,\"DRMCustomer\":\"No\",\"DebitFrequency\":null,\"DebitReason\":null,\"Discount\":null,\"FamilyType\":null,\"FamilyDefinition\":null,\"GoGreen\":\"Yes\",\"GrossPremium\":\"5487.0\",\"HA\":null,\"HHS\":null,\"CustomerSegment\":null,\"HR\":null,\"IntermediaryCode\":\"5100357\",\"IntermediaryEmailId\":\"crthealth@policybazaar.com\",\"IntermediaryMobileNumber\":\"18002585970\",\"IntermediaryName\":\"POLICYBAZAARINSURANCEBROKERSPRIVATELIMITED\",\"LeadId\":null,\"MandateEndDate\":null,\"MandateStartDate\":null,\"MasterPolicy\":null,\"MasterPolicyNumber\":\"ABC-71-21-00036-01-02\",\"MaturityDate\":\"2025-07-28\",\"Mode\":\"OnlinePayment\",\"NameOfEW\":null,\"NetPremium\":\"4650.0\",\"NextPremiumDate\":\"2025-07-29\",\"OwnerClientCode\":\"13882784-01\",\"PaymentStatus\":\"Raisedandpaid\",\"PlanName\":\"GroupActivHealthv2\",\"PolicyCancellationReason\":null,\"PolicyIssueDate\":\"2024-07-29\",\"PolicyNumber\":31-24-0004016-2201\",\"PolicyStatus\":\"IF\",\"PolicySubStatus\":null,\"PolicyTerm\":\"1Year\",\"PolicyType\":\"Affinity\",\"PolicySubType\":\"Certificate\",\"PortalCertificate\":null,\"ProductName\":\"GroupActivHealthV2\",\"ProposalType\":\"STP\",\"RejectionReason\":null,\"SNCB\":null,\"SalesManagerEmail\":null,\"SalesManagerMobile\":\"9899937413\",\"SalesRelationshipManagerCode\":\"417457\",\"SalesRelationshipManagerName\":\"NaveenSehrawat\",\"SandboxPolicy\":\"No\",\"ServicingBranchName\":\"HeadOffice\",\"Source\":\"TCSBaNCS\",\"TAXDetails\":\"837.0\",\"TPA\":null,\"TPAContactDetails\":null,\"TotalSumInsured\":\"9500000\",\"UR\":null,\"UWLoading\":\"0\",\"ZoneOfCover\":\"ZoneIII\",\"TotalHR\":null,\"UtilizedHR\":null,\"SponsoredFlag\":\"No\",\"RenewableFlag\":\"YES\",\"PreviousPolicyNumber\":null}}';
            res.setBody(s);
            res.setStatusCode(200);
            return res;
        }
    }
    /**
    * @description Mocking failure response
    */ 
    public class ABHI_KavachPoliciesMockFailureResponseGenerator implements HttpCalloutMock {
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