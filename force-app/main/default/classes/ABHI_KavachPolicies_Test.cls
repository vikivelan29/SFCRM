/**
 * @description       : Test Class for ABHI_KavachPolicies
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
    /**
   * @description Test Data Setup for this Test Class
   */
    @testSetup
    static void setupTestData() {
         Account accRec = ASF_TestDataFactory.insertBusinessAccount('Test_Cmp','Test_1');
        accRec.Is_Chronic__c = true;
        accRec.CMP_OPD__c = true;
        accRec.Chronic_care__c = false;
        update accRec;
        
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        Datetime testingday = Datetime.now().addDays(-2);
		Test.setCreatedDate(astRec.Id, testingday);
        
        astRec.LAN__c = '31-24-0004016-22';
        astRec.Business_Unit__c = ABHI_Constants.ABHI;
        astRec.Plan_Name__c = 'Max+';
        astRec.ProductName__c = 'Active One';
        update astRec; 
    }    
    @isTest static void testKavachPolicyCallout() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new ABHI_KavachPoliciesMockResponseGenerator());
        Test.startTest();
        List<ABHI_KavachPolicies.KavachResponseWrapper> res = ABHI_KavachPolicies.getPolicyExternalData('31-24-0003333-00','');
        Test.stopTest();
        
        //System.assertEquals('13882784-01',res[0].clientCode,'client code' );
        //System.assertEquals('1', res.ReturnCode, 'return code');
    }
    @isTest static void testKavachPolicyData() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new ABHI_KavachPoliciesMockResponseGenerator());
        Test.startTest(); 
        List<ABHI_KavachPolicies.KavachResponseWrapper> res = ABHI_KavachPolicies.getPolicyData('31-24-0004016-22');
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
            // String s = '{\"Customer\":[{\"AadharNo\":null,\"AddressLine1\":\"250/13NearSatJindaKalayanaMandirChottaPanna,Kalanaur\",\"AddressLine2\":\"NA\",\"AddressLine3\":null,\"AddressType\":\"Permanent\",\"PIN\":\"124113\",\"City\":\"Rohtak\",\"State\":\"HARYANA\",\"Email\":\"ab@xyz.com\",\"HomePhone\":null,\"Alternatemobile\":\"9999999999\",\"CoreSystemId\":\"13882784-01\",\"CountryCode\":\"India\",\"DateofBirth\":\"1995-10-21\",\"Designation\":\"Others\",\"EmployeeCode\":\"75226810\",\"FirstName\":\"MrParas\",\"FullName\":\"MrParas.\",\"Gender\":\"Male\",\"LastName\":\".\",\"HealthCardNumber\":\"6051092413469349\",\"Height\":\"0\",\"Weight\":\"0\",\"MaritualStatus\":null,\"MobilePhone\":\"9999999999\",\"Nationality\":\"Indian\",\"Nationality1\":\"India\",\"PanNo\":\"AACCE9326L\",\"ParentCode\":null,\"WhatsappNumber\":\"YES\",\"CustomerSegments\":[{\"Segment\":\"HNI\"}],\"CustomerRoles\":[{\"CustomerType\":\"MemberCustomer\"},{\"CustomerType\":\"DependentCustomer\"}]}],\"CustomerMemberMapping\":[{\"ClientId\":\"13882784-01\",\"MemberId\":\"13882784-01\",\"MemberStatus\":\"Active\",\"MemberSubStatus\":null,\"PreExistingDiseaseWaitingPeriod\":null,\"TotalNCB\":\"0\",\"RidersOpted\":null,\"SumInsured\":\"9500000\",\"UpfrontDiscount\":\"No\"}],\"NomineeDetails\":[{\"Gender\":null,\"NomineeContactNumber\":\"9999999999\",\"NomineeDOB\":null,\"NomineeName\":\"RoshanLal\",\"NomineePercentage\":\"100\",\"Relationship\":\"Father\"}],\"Policy\":{\"AgentStatus\":null,\"ARU\":\"STP\",\"ActiveHealthVersion\":null,\"ApplicationDate\":\"2024-07-29\",\"ProposalNumber\":\"QU-23-5211-8454629-00-01\",\"AutoDebitFlag\":null,\"AutoDebitRegistrationStatus\":null,\"BalanceHR\":null,\"BasicPremium\":\"4650.0\",\"BusinessType\":\"Renewal\",\"Channel\":\"ABHI\",\"COILink\":null,\"CountOfLives\":\"1\",\"CombiPolicyNo\":null,\"CombiPolicyType\":\"No\",\"ConsumedHR\":null,\"CrossSellNumber\":null,\"DRMCustomer\":\"No\",\"DebitFrequency\":null,\"DebitReason\":null,\"Discount\":null,\"FamilyType\":null,\"FamilyDefinition\":null,\"GoGreen\":\"Yes\",\"GrossPremium\":\"5487.0\",\"HA\":null,\"HHS\":null,\"CustomerSegment\":null,\"HR\":null,\"IntermediaryCode\":\"5100357\",\"IntermediaryEmailId\":\"crthealth@policybazaar.com\",\"IntermediaryMobileNumber\":\"18002585970\",\"IntermediaryName\":\"POLICYBAZAARINSURANCEBROKERSPRIVATELIMITED\",\"LeadId\":null,\"MandateEndDate\":null,\"MandateStartDate\":null,\"MasterPolicy\":null,\"MasterPolicyNumber\":null,\"MaturityDate\":\"2025-07-28\",\"Mode\":\"OnlinePayment\",\"NameOfEW\":null,\"NetPremium\":\"4650.0\",\"NextPremiumDate\":\"2025-07-29\",\"OwnerClientCode\":\"13882784-01\",\"PaymentStatus\":\"Raisedandpaid\",\"PlanName\":\"GroupActivHealthv2\",\"PolicyCancellationReason\":null,\"PolicyIssueDate\":\"2024-07-29\",\"PolicyNumber\":\"GHI-HB-22-2007426-007-01\",\"PolicyStatus\":\"IF\",\"PolicySubStatus\":null,\"PolicyTerm\":\"1Year\",\"PolicyType\":\"Affinity\",\"PolicySubType\":\"Certificate\",\"PortalCertificate\":null,\"ProductName\":\"GroupActivHealthV2\",\"ProposalType\":\"STP\",\"RejectionReason\":null,\"SNCB\":null,\"SalesManagerEmail\":null,\"SalesManagerMobile\":\"9899937413\",\"SalesRelationshipManagerCode\":\"417457\",\"SalesRelationshipManagerName\":\"NaveenSehrawat\",\"SandboxPolicy\":\"No\",\"ServicingBranchName\":\"HeadOffice\",\"Source\":\"TCSBaNCS\",\"TAXDetails\":\"837.0\",\"TPA\":null,\"TPAContactDetails\":null,\"TotalSumInsured\":\"9500000\",\"UR\":null,\"UWLoading\":\"0\",\"ZoneOfCover\":\"ZoneIII\",\"TotalHR\":null,\"UtilizedHR\":null,\"SponsoredFlag\":\"No\",\"RenewableFlag\":\"YES\",\"PreviousPolicyNumber\":null}}';
           // String s = '{\"Customer\":[{\"AadharNo\":\"\",\"AddressLine1\":\"thane\",\"AddressLine2\":\"thane\",\"AddressLine3\":\"thane\",\"AddressType\":\"Permanent\",\"PIN\":\"400607\",\"City\":\"Thane\",\"State\":\"MAHARASHTRA\",\"Email\":\"satyam.bhardwaj@qualitykiosk.com\",\"CMP_OPD\":\"No\",\"Chronic_care\":\"No\",\"HomePhone\":\"\",\"Alternatemobile\":\"\",\"CoreSystemId\":\"PT87709599\",\"Country\":\"\",\"DateofBirth\":\"1992-01-01\",\"Occupation\":\"Lawyers\",\"EmployeeCode\":\"\",\"Title\":\"Mr.\",\"FirstName\":\"HEMANT\",\"FullName\":\"HemantShinde\",\"Gender\":\"Male\",\"LastName\":\"Shinde\",\"HealthCardNumber\":\"6051092444125480\",\"Height\":\"165.1\",\"Weight\":\"55\",\"MaritualStatus\":\"\",\"MobilePhone\":\"9889899898\",\"Nationality\":\"Indian\",\"PanNo\":null,\"ParentCode\":null,\"WhatsappNumber\":\"\",\"hni_customer\":\"No\",\"sensitive_customer\":\"No\",\"priority_customer\":\"No\",\"ceo_club_advisor_customer\":\"No\",\"risk_class\":\"\",\"ped_waiting_period\":\"\",\"IsChronicDisease\":\"No\",\"ChronicDiseaseDescription\":\"\",\"politically_exposed_person\":\"No\",\"UpfrontDiscount\":\"No\",\"District\":\"Thane\",\"Relation\":\"Self\",\"ped_name\":\"\"}],\"CustomerMemberMapping\":[{\"ClientId\":\"PT87709599\",\"Policy_Number\":null,\"MemberId\":\"PT87709599\",\"MemberStatus\":\"Active\",\"MemberSubStatus\":\"\",\"TotalNCB\":\"0\",\"RidersOpted\":null,\"appdownloadstatus\":\"Yes\",\"SumInsured\":\"2000000\",\"cumulative_bonus_earned\":\"0\",\"super_ncb_amount\":\"\"}],\"NomineeDetails\":[{\"Gender\":\"\",\"NomineeContactNumber\":\"\",\"NomineeDOB\":\"1980-01-01\",\"NomineeName\":\"dfsfgh\",\"NomineePercentage\":\"100\",\"Relationship\":\"Brother\"}],\"Policy\":{\"AgentStatus\":\"\",\"cover_type\":\"Individual\",\"ARU\":\"STP\",\"ActiveHealthVersion\":\"\",\"ApplicationDate\":\"2024-10-07\",\"ProposalNumber\":\"240000665645\",\"AutoDebitFlag\":\"\",\"AutoDebitRegistrationStatus\":null,\"BalanceHR\":null,\"BasicPremium\":\"11974.15\",\"BusinessType\":\"NewBusiness\",\"Channel\":\"AGENCY\",\"Copay_Applicability\":null,\"COILink\":null,\"CountOfLives\":\"1\",\"CombiPolicyNo\":null,\"CombiPolicyType\":\"No\",\"ConsumedHR\":null,\"CrossSellNumber\":null,\"DRMCustomer\":\"No\",\"DebitFrequency\":\"B\",\"DebitReason\":\"\",\"Discount\":null,\"FamilyType\":\"\",\"FamilyDefinition\":\"\",\"GoGreen\":\"Yes\",\"GrossPremium\":\"14130.0\",\"HA\":null,\"HHS\":null,\"CustomerSegment\":null,\"HR\":null,\"IntermediaryCode\":\"ABH1102588\",\"IntermediaryEmailId\":\"pavan2226@gmail.com\",\"IntermediaryMobileNumber\":\"8143603990\",\"IntermediaryName\":\"AdirajuPavanKumar\",\"LeadId\":\"\",\"MandateEndDate\":\"\",\"MandateStartDate\":\"\",\"MasterPolicyNumber\":null,\"MaturityDate\":\"2025-10-06\",\"Mode\":\"RN\",\"NameOfEW\":null,\"NetPremium\":\"11974.15\",\"NextPremiumDate\":\"2025-10-07\",\"OwnerClientCode\":\"PT87709599\",\"PaymentStatus\":\"Raisedandpaid\",\"loan_account_number\":null,\"PlanName\":\"ActivOneMAX\",\"PolicyCancellationReason\":\"\",\"PolicyIssueDate\":\"2024-10-07\",\"PolicyNumber\":\"GHI-HB-22-2007426-007\",\"PolicyStatus\":\"IF\",\"PolicySubStatus\":\"\",\"PolicyTerm\":\"1Year\",\"PolicyType\":\"Retail\",\"PolicySubType\":\"Policy\",\"PortalCertificate\":null,\"ProductName\":\"ActivOne\",\"ProposalType\":\"STP\",\"RejectionReason\":\"\",\"SNCB\":null,\"SalesManagerEmail\":null,\"SalesManagerMobile\":\"6302959344\",\"SalesRelationshipManagerCode\":\"565546\",\"SalesRelationshipManagerName\":\"MuralaMounika\",\"SandboxPolicy\":\"No\",\"ServicingBranchName\":\"Hyderabad-Somjiguda1ABC\",\"Source\":\"TCSBaNCS\",\"TAXDetails\":\"2155.35\",\"TPA\":null,\"TPAContactDetails\":null,\"TotalSumInsured\":\"2000000\",\"branch_name\":\"Hyderabad-Somjiguda1ABC\",\"UR\":null,\"UWLoading\":\"0\",\"ZoneOfCover\":\"ZoneI\",\"TotalHR\":null,\"UtilizedHR\":null,\"SponsoredFlag\":\"No\",\"RenewableFlag\":\"NO\",\"PreviousPolicyNumber\":null},\"PreviousPolicyDetails\":[{\"PreviousPolicyNumber\":null,\"nameOfInsuredPerson\":null,\"dateOfFirstEnrollment\":null,\"insurer\":null,\"policyYear\":null,\"previous_policy_start_date\":null,\"product\":null,\"typeOfCover\":null,\"expiringBaseSI\":null,\"cumulativeBonus\":null,\"expiringWaitingPeriod\":null,\"optedSi\":null,\"optedProductWP\":null,\"waiverOfWPforSI\":null}],\"StatusCode\":\"1000\",\"Message\":\"<GenericMessage>\"}';
            String s = '{\"CustomerDetails\":[{\"Customer\":[{\"AadharNo\":\"\",\"AddressLine1\":\"B2008Viva\",\"AddressLine2\":\"Naupada,Tenx2008\",\"AddressLine3\":\"Pokhran2\",\"AddressType\":\"Permanent\",\"PIN\":\"500001\",\"City\":\"Hyderabad\",\"State\":\"TELANGANA\",\"Email\":\"\",\"HomePhone\":\"7021420695\",\"Alternatemobile\":\"\",\"CoreSystemId\":\"PT87684855\",\"Country\":\"INDIA\",\"DateofBirth\":\"01/01/1960\",\"Occupation\":\"Others\",\"EmployeeCode\":\"\",\"Title\":\"\",\"FirstName\":\"bjkdjynzet\",\"FullName\":\"bjkdjynzet\",\"Gender\":\"M\",\"LastName\":\"\",\"MaritualStatus\":\"Single\",\"MobilePhone\":\"7021420695\",\"Nationality\":\"Indian\",\"PanNo\":\"\",\"ParentCode\":\"\",\"WhatsappNumber\":\"\",\"hni_customer\":\"\",\"sensitive_customer\":\"\",\"priority_customer\":\"\",\"ceo_club_advisor_customer\":\"\",\"Chronic_care\":\"\",\"ChronicDiseaseDescription\":\"\",\"CMP_OPD\":\"\",\"District\":\"Hyderabad\",\"HealthCardNumber\":\"6051092444071577\",\"Height\":\"156\",\"IsChronicDisease\":\"NO\",\"ped_name\":\"\",\"ped_waiting_period\":\"\",\"politically_exposed_person\":\"N\",\"Relation\":\"LIW\",\"risk_class\":\"\",\"UpfrontDiscount\":\"\",\"Weight\":\"55\"},{\"AadharNo\":\"\",\"AddressLine1\":\"B2008Viva\",\"AddressLine2\":\"Naupada,Tenx2008\",\"AddressLine3\":\"Pokhran2\",\"AddressType\":\"Permanent\",\"PIN\":\"500001\",\"City\":\"Hyderabad\",\"State\":\"TELANGANA\",\"Email\":\"TEST@GMAIL.COM\",\"HomePhone\":\"7021420695\",\"Alternatemobile\":\"\",\"CoreSystemId\":\"PT87684856\",\"Country\":\"INDIA\",\"DateofBirth\":\"01/01/1965\",\"Occupation\":\"Others\",\"EmployeeCode\":\"\",\"Title\":\"\",\"FirstName\":\"jcghnqrheb\",\"FullName\":\"jcghnqrheb\",\"Gender\":\"F\",\"LastName\":\"\",\"MaritualStatus\":\"Single\",\"MobilePhone\":\"7021420695\",\"Nationality\":\"Indian\",\"PanNo\":\"\",\"ParentCode\":\"\",\"WhatsappNumber\":\"\",\"hni_customer\":\"\",\"sensitive_customer\":\"\",\"priority_customer\":\"\",\"ceo_club_advisor_customer\":\"\",\"Chronic_care\":\"\",\"ChronicDiseaseDescription\":\"\",\"CMP_OPD\":\"\",\"District\":\"Hyderabad\",\"HealthCardNumber\":\"6051092444071569\",\"Height\":\"156\",\"IsChronicDisease\":\"NO\",\"ped_name\":\"\",\"ped_waiting_period\":\"\",\"politically_exposed_person\":\"N\",\"Relation\":\"FRI\",\"risk_class\":\"\",\"UpfrontDiscount\":\"\",\"Weight\":\"55\"}],\"CustomerMemberMapping\":[{\"ClientId\":\"PT87684855\",\"Policy_Number\":\"31-24-0003333-00\",\"MemberId\":\"PT87684855\",\"MemberStatus\":\"ACTIVE\",\"MemberSubStatus\":\"\",\"TotalNCB\":\"0\",\"appdownloadstatus\":\"Yes\",\"cumulative_bonus_earned\":\"\",\"RidersOpted\":\"\",\"SumInsured\":\"\",\"super_ncb_amount\":\"\"},{\"ClientId\":\"PT87684856\",\"Policy_Number\":\"31-24-0003333-00\",\"MemberId\":\"PT87684856\",\"MemberStatus\":\"ACTIVE\",\"MemberSubStatus\":\"\",\"TotalNCB\":\"0\",\"appdownloadstatus\":\"Yes\",\"cumulative_bonus_earned\":\"\",\"RidersOpted\":\"\",\"SumInsured\":\"\",\"super_ncb_amount\":\"\"}],\"NomineeDetails\":[{\"NomineeName\":\"\",\"NomineeDOB\":\"\",\"Relationship\":\"\",\"Gender\":\"\",\"NomineeContactNumber\":\"\",\"NomineePercentage\":\"\"}],\"Policy\":{\"AgentStatus\":\"\",\"cover_type\":\"Individual\",\"ARU\":\"STP\",\"ActiveHealthVersion\":\"\",\"ApplicationDate\":\"\",\"ProposalNumber\":\"240000657904\",\"BusinessType\":\"NewBusiness\",\"GrossPremium\":\"\",\"NetPremium\":\"\",\"PolicyNumber\":\"31-24-0003333-00\",\"PolicyStatus\":\"05\",\"PolicyTerm\":\"1.0\",\"PlanName\":\"ActivOne\",\"ZoneOfCover\":\"\",\"ServicingBranchName\":\"\",\"AutoDebitFlag\":\"\",\"AutoDebitRegistrationStatus\":\"\",\"BalanceHR\":\"\",\"BasicPremium\":\"\",\"branch_name\":\"\",\"Channel\":\"\",\"COILink\":\"\",\"CombiPolicyNo\":\"\",\"CombiPolicyType\":\"\",\"ConsumedHR\":\"\",\"Copay_Applicability\":\"\",\"CountOfLives\":\"\",\"CrossSellNumber\":\"\",\"CustomerSegment\":\"\",\"DebitFrequency\":\"\",\"DebitReason\":\"\",\"Discount\":\"\",\"DRMCustomer\":\"\",\"FamilyDefinition\":\"\",\"FamilyType\":\"\",\"GoGreen\":\"\",\"HA\":\"\",\"HHS\":\"\",\"HR\":\"\",\"IntermediaryCode\":\"\",\"IntermediaryEmailId\":\"\",\"IntermediaryMobileNumber\":\"\",\"IntermediaryName\":\"\",\"LeadId\":\"\",\"loan_account_number\":\"\",\"MandateEndDate\":\"\",\"MandateStartDate\":\"\",\"MasterPolicyNumber\":\"\",\"MaturityDate\":\"\",\"Mode\":\"\",\"NameOfEW\":\"\",\"NextPremiumDate\":\"\",\"OwnerClientCode\":\"PT87684856\",\"PaymentStatus\":\"\",\"PolicyCancellationReason\":\"\",\"PolicyIssueDate\":\"\",\"PolicySubStatus\":\"\",\"PolicySubType\":\"\",\"PolicyType\":\"\",\"PortalCertificate\":\"\",\"PreviousPolicyNumber\":\"\",\"ProductName\":\"\",\"ProposalType\":\"\",\"RejectionReason\":\"\",\"RenewableFlag\":\"\",\"SalesManagerEmail\":\"\",\"SalesManagerMobile\":\"\",\"SalesRelationshipManagerCode\":\"\",\"SalesRelationshipManagerName\":\"\",\"SandboxPolicy\":\"\",\"SNCB\":\"\",\"Source\":\"\",\"SponsoredFlag\":\"\",\"TAXDetails\":\"\",\"TotalHR\":\"\",\"TotalSumInsured\":\"\",\"TPA\":\"\",\"TPAContactDetails\":\"\",\"UR\":\"\",\"UtilizedHR\":\"\",\"UWLoading\":\"\"},\"PreviousPolicyDetails\":[{\"PreviousPolicyNumber\":\"\",\"nameOfInsuredPerson\":\"\",\"dateOfFirstEnrollment\":\"\",\"insurer\":\"\",\"policyYear\":\"\",\"product\":\"\",\"typeOfCover\":\"\",\"expiringBaseSI\":\"\",\"cumulativeBonus\":\"\",\"expiringWaitingPeriod\":\"\",\"optedSi\":\"\",\"optedProductWP\":\"\",\"waiverOfWPforSI\":\"\"}]}],\"StatusCode\":1000,\"Message\":\"Success\"}';
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
			//String s = '{\"ReturnCode\":\"2\",\"ReturnMessage\":\"Nodatafound\"}';
			String s = '{\"CustomerDetails\":[],\"StatusCode\":1002,\"Message\":\"Nodataavailable\"}';
            res.setBody(s);
            res.setStatusCode(404);
            return res;
        }
    }
}