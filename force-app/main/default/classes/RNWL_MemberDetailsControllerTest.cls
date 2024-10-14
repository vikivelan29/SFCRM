@isTest
public class RNWL_MemberDetailsControllerTest {
    
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    
    @TestSetup
    public static void setup(){
        User objUser = new User(profileId = SYSTEMADMIN_PROFILE.Id, email = 'test1@salesforce.com',
                                Username = 'Test1'+String.valueOf(Integer.valueof((Math.random() * 10)))+'@mock.com',
                                alias = 'test', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                                languagelocalekey = 'en_US', timezonesidkey = 'GMT',IsActive = true);
        insert objUser;
        Account acc = ASF_TestDataFactory.insertBusinessAccount('test', 'strCRN');
        
        //Asset asset = ASF_TestDataFactory.createAsset(acc.Id,''); 
        
        Asset asset = new Asset();
        asset.Name = 'Test Asset';
        asset.AccountId = acc.Id;
        asset.Type__c = 'TestAsset';
        asset.Policy_No__c = '12456';
        asset.ABHI_Policy_Id__c = '12456';
        
        
        insert asset;
        
        Opportunity objOpportunity = RNWL_TestDataFactory.createOpportunityRecords(acc.Id, asset.Id);
        
        //ContentDocumentLink docLink = new ContentDocumentLink();
        //doclink.LinkedEntityId = objOpportunity.Id;
        //LinkedEntity.Type = 'Opportunity';
        
        //insert docLink;
    }
    @isTest
    public static void test_ApiResponseDetails(){
        Account acc = [Select Id FROM Account LIMIT 1];
        Asset asset = [Select Id FROM Asset LIMIT 1];
        Opportunity opp = [Select Id, Name ,CloseDate, StageName, Policy__r.AccountId from Opportunity LIMIT 1];
        List<String> lstFileSrcAPI = new List<String>();
        
        lstFileSrcAPI.add('Renewal Check');
        
        String strBody = '{ "error": [ { "ErrorCode": "00", "ErrorMessage": "Success" } ], "Renew_Info": [ { "Renewed_Policy_Expiry_Date": "", "Renewed_Policy_Number": "", "Renewed_Policy_Proposal_Number": "240000621404", "Renewed_Policy_Start_Date": "" } ], "response": { "policyData": [ {"Policy_number":"21-24-0000759-01", "Policy_renewal_date": "09/01/2025", "Upsell_Flag": "No", "Renewable_Flag": "Yes", "Renewed_Flag": "No", "Sum_insured_type": "Individual", "SumInsured": "2000000", "sumInsuredtype": "IND", "Members": [ { "CB": "3000000", "Chronic": "Yes", "DoB": "03/30/1974", "Email": "rahul.ghimire@qualitykiosk.com", "Gender": "M", "healthReturn": ".00", "Name": "Vishwas Varma", "Mobile_Number": "9012737473", "SumInsured": "2000000", "SumInsuredPerUnit": "2000000", "Upsell_SumInsured": "", "Relation": "Mother" } ], "Nominee_Details": { "Nominee_Address": "test", "Nominee_Contact_No": "8707868534", "nominee_dob": "", "nominee_first_name": "Mona", "nominee_last_name": "Mona", "Nominee_Name": "Mona", "nominee_relationship_code": "Mother", "Relationship": "Mother" }, "premium": { "Renewal_Gross_Premium": "55774.0", "Renewal_Net_Premium": "47266.49", "Upsell_Gross_Premium": "0", "Upsell_Net_Premium": "0" } } ] } }';
        Test.setMock(HttpCalloutMock.class, new RNWL_MockHttpResponseGenerator(200, strBody)); 
        
        Opportunity objOpportunity = [Select Id From Opportunity LIMIT 1];
        
        Test.startTest();
        RNWL_MemberDetailsController.getAPIResponse(opp.Id,asset.Id,'21-24-0000759-01','12345',lstFileSrcAPI); 
        Test.stopTest();
    }
    
    @isTest
    public static void test1_ApiResponseDetails(){
        Account acc = [Select Id FROM Account LIMIT 1];
        Asset asset = [Select Id FROM Asset LIMIT 1];
        Opportunity opp = [Select Id, Name ,CloseDate, StageName, Policy__r.AccountId from Opportunity LIMIT 1];
        List<String> lstFileSrcAPI = new List<String>();
        
        lstFileSrcAPI.add('Renewal Group Check');
        
        String strBody = '{ "error": [ { "ErrorCode": "00", "ErrorMessage": "Success" } ], "response": { "policyData": [ { "MaterPolicyNumber": "62-20-00216-01-02", "Certificate_number": "GFB-HB-22-2024165-004", "Members": [ { "MemberproductComponents": [ { "PlanCode": "", "SumInsured": "1000000", "NetPremium": "1200.0", "NetPremium_U": "", "CB": "0", "Hr_Amount": "0.0" } ], "Name": "Sandip Naginbhai Andhariya .", "Title": "Mr.", "FirstName": "Sandip Naginbhai Andhariya", "LastName": ".", "Relationship_Code": "24", "GHDApplicable": "", "GHDRemarks": "", "Member_Code": "PT87552250", "DoB": "12/22/1982", "Gender": "M", "Email": "Sandipandhariya@Gmail.Com", "Mobile_Number": "9427496123", "Relation": "Self" }, { "MemberproductComponents": [ { "PlanCode": "", "SumInsured": "1000000", "NetPremium": "1200.0", "NetPremium_U": "", "CB": "0", "Hr_Amount": "0.0" } ], "Name": "Jalak Sandipbhai Andhariya .", "Title": "Ms.", "FirstName": "Jalak Sandipbhai Andhariya", "LastName": ".", "Relationship_Code": "13", "GHDApplicable": "", "GHDRemarks": "", "Member_Code": "PT87552251", "DoB": "09/18/1983", "Gender": "F", "Email": "Sandipandhariya@Gmail.Com", "Mobile_Number": "9427496123", "Relation": "Spouse" } ], "Nominee_Details": { "Nominee_Name": "Om Sandipbhai Andhariya", "Nominee_Address": "", "Nominee_Contact_No": "9999999999" } }, { "PolicyproductComponents": [ { "PlanCode": "", "SchemeCode": "5211", "NetPremium": "17493.45", "NetPremium_U": "" } ], "MaterPolicyNumber": "71-20-00040-01-02", "Certificate_number": "GHI-HB-22-2032552-004", "Members": [ { "Name": "Stuti Sandipbhai Andhariya .", "Title": "Ms.", "FirstName": "Stuti Sandipbhai Andhariya", "LastName": ".", "Relationship_Code": "19", "GHDApplicable": "", "GHDRemarks": "", "Member_Code": "000534230004567", "DoB": "01/22/2007", "Gender": "F", "Email": "Sandipandhariya@Gmail.Com", "Mobile_Number": "9427496123", "Relation": "Dependent Daughter" }, { "Name": "Jalak Sandipbhai Andhariya .", "Title": "Ms.", "FirstName": "Jalak Sandipbhai Andhariya", "LastName": ".", "Relationship_Code": "13", "GHDApplicable": "", "GHDRemarks": "", "Member_Code": "0005342300045678", "DoB": "09/18/1983", "Gender": "F", "Email": "Sandipandhariya@Gmail.Com", "Mobile_Number": "9427496123", "Relation": "Spouse" } ], "Proposer_Email": "Sandipandhariya@Gmail.Com", "Proposer_MobileNo": "9427496123", "Nominee_Details": { "Nominee_Name": "Om Sandipbhai Andhariya ", "Nominee_Address": "", "Nominee_Contact_No": "9999999999" } } ] }, "Renew_Info": [ { "Renewed_Certificate_Number": "", "Renewed_MaterPolicy_Number": "62-20-00216-01-02", "Renewed_Policy_Proposal_Number": "QU-23-4000-6350978-00", "Renewed_Policy_Start_Date": "", "Renewed_Policy_Expiry_Date": "" } ] }';
        
        Test.setMock(HttpCalloutMock.class, new RNWL_MockHttpResponseGenerator(200, strBody)); 
        
        Opportunity objOpportunity = [Select Id From Opportunity LIMIT 1];
        
        Test.startTest();
        RNWL_MemberDetailsController.getAPIResponse(opp.Id,asset.Id,'GFB-HB-22-2024165-004','123456',lstFileSrcAPI); 
         
        Test.stopTest();
    } 
    
        @isTest
    public static void test3_ApiResponseDetails(){
        Account acc = [Select Id FROM Account LIMIT 1];
        Asset asset = [Select Id FROM Asset LIMIT 1];
        Opportunity opp = [Select Id, Name ,CloseDate, StageName, Policy__r.AccountId from Opportunity LIMIT 1];
        List<String> lstFileSrcAPI = new List<String>();
        
        lstFileSrcAPI.add('Fitness Assessment');
        
        String strBody = '{ "Response": [ { "AHCdate": "", "EligibiltytoearnHRAHC": "YES", "EligibiltytoearnHRDHA": "YES", "EligibiltytoearnHRHA": "YES", "HHSDHA": "NO", "HHSExpiredDateDHA": "", "HHSExpiredDateHA": "", "HHSHA": "NO", "HealthAssesmentStatusAHC": "NO", "HealthAssesmentStatusDHA": "NO", "HealthAssesmentStatusHA": "NO", "Name": "Senthilkumar As", "vchClientCode": "PT87552251", "vchPolicyNumber": "21-24-0000759-01" }, { "AHCdate": "", "EligibiltytoearnHRAHC": "YES", "EligibiltytoearnHRDHA": "YES", "EligibiltytoearnHRHA": "YES", "HHSDHA": "NO", "HHSExpiredDateDHA": "", "HHSExpiredDateHA": "", "HHSHA": "NO", "HealthAssesmentStatusAHC": "YES", "HealthAssesmentStatusDHA": "YES", "HealthAssesmentStatusHA": "YES", "Name": "Test As", "vchClientCode": "PT87552250", "vchPolicyNumber": "21-24-0000759-01", "HR_Expiry_Date": "03/03/2025", "HHS_End_Date": "03/03/2025", "HHS_Start_Date": "03/03/2024" } ], "StatusCode": 1000, "message": "Success" }';
        Test.setMock(HttpCalloutMock.class, new RNWL_MockHttpResponseGenerator(200, strBody)); 
        
        Opportunity objOpportunity = [Select Id From Opportunity LIMIT 1];
        
        Test.startTest();
        RNWL_MemberDetailsController.getHealthReturnResponse(opp.Id,asset.Id,'GFB-HB-22-2024165-004','123456','GFB-HB-22-2024165-004',lstFileSrcAPI); 
        RNWL_MemberDetailsController.getAPIResponse(opp.Id,asset.Id,'GFB-HB-22-2024165-004','123456',lstFileSrcAPI); 
        Test.stopTest();
    }
    
           @isTest
    public static void test4_ApiResponseDetails(){
        Account acc = [Select Id FROM Account LIMIT 1];
        Asset asset = [Select Id FROM Asset LIMIT 1];
        Opportunity opp = [Select Id, Name ,CloseDate, StageName, Policy__r.AccountId from Opportunity LIMIT 1];
        List<String> lstFileSrcAPI = new List<String>();
        
        lstFileSrcAPI.add('Health Return');
        
        String strBody = '{ "Response": [ { "vchPolicyNumber": "31-24-0098014-00", "vchClientCode": "PT87552250", "Name": "PRADIP BHUIN", "Year": "2024", "Month": "8", "HealthAssessment": "0", "HealthyHeartScore": "G", "FitnessAssessment": "0", "ActiveDays": "10", "HealthReturnsforrespectivemonth": "0.0", "ChronicMgmtProgramCompliance": "", "HealthReturnsTMthroughBenefitforHospitalRoomchoice": "0.0", "HealthReturnsTMthroughCarriedforwardOPDexpensesandBonus": "0.0", "TotalHealthReturnsTMEarned": "0.0", "TotalHealthReturnsTMBurnt": "0.0", "TotalHealthReturnsTM": "0.0", "HealthQuestionnaire": "", "HRPercentage": "0.0" }, { "vchPolicyNumber": "31-24-0098014-00", "vchClientCode": "PT87552250", "Name": "PRADIP BHUIN", "Year": "2024", "Month": "9", "HealthAssessment": "0", "HealthyHeartScore": "G", "FitnessAssessment": "0", "ActiveDays": "20", "HealthReturnsforrespectivemonth": "0.0", "ChronicMgmtProgramCompliance": "", "HealthReturnsTMthroughBenefitforHospitalRoomchoice": "0.0", "HealthReturnsTMthroughCarriedforwardOPDexpensesandBonus": "0.0", "TotalHealthReturnsTMEarned": "0.0", "TotalHealthReturnsTMBurnt": "0.0", "TotalHealthReturnsTM": "0.0", "HealthQuestionnaire": "", "HRPercentage": "0.0" }, { "vchPolicyNumber": "31-24-0098014-00", "vchClientCode": "PT87552250", "Name": "PRADIP BHUIN", "Year": "2024", "Month": "10", "HealthAssessment": "0", "HealthyHeartScore": "G", "FitnessAssessment": "0", "ActiveDays": "4", "HealthReturnsforrespectivemonth": "0.0", "ChronicMgmtProgramCompliance": "", "HealthReturnsTMthroughBenefitforHospitalRoomchoice": "0.0", "HealthReturnsTMthroughCarriedforwardOPDexpensesandBonus": "0.0", "TotalHealthReturnsTMEarned": "0.0", "TotalHealthReturnsTMBurnt": "0.0", "TotalHealthReturnsTM": "0.0", "HealthQuestionnaire": "", "HRPercentage": "0.0" }, { "vchPolicyNumber": "31-24-0098014-00", "vchClientCode": "PT87552251", "Name": "PRADIP Second", "Year": "2024", "Month": "5", "HealthAssessment": "0", "HealthyHeartScore": "G", "FitnessAssessment": "0", "ActiveDays": "0", "HealthReturnsforrespectivemonth": "0.0", "ChronicMgmtProgramCompliance": "", "HealthReturnsTMthroughBenefitforHospitalRoomchoice": "0.0", "HealthReturnsTMthroughCarriedforwardOPDexpensesandBonus": "0.0", "TotalHealthReturnsTMEarned": "0.0", "TotalHealthReturnsTMBurnt": "0.0", "TotalHealthReturnsTM": "0.0", "HealthQuestionnaire": "", "HRPercentage": "0.0" }, { "vchPolicyNumber": "31-24-0098014-00", "vchClientCode": "PT87552251", "Name": "PRADIP Second", "Year": "2024", "Month": "9", "HealthAssessment": "0", "HealthyHeartScore": "G", "FitnessAssessment": "0", "ActiveDays": "7", "HealthReturnsforrespectivemonth": "0.0", "ChronicMgmtProgramCompliance": "", "HealthReturnsTMthroughBenefitforHospitalRoomchoice": "0.0", "HealthReturnsTMthroughCarriedforwardOPDexpensesandBonus": "0.0", "TotalHealthReturnsTMEarned": "0.0", "TotalHealthReturnsTMBurnt": "0.0", "TotalHealthReturnsTM": "0.0", "HealthQuestionnaire": "", "HRPercentage": "0.0" } ], "StatusCode": 1000, "message": "Success" }';
        Test.setMock(HttpCalloutMock.class, new RNWL_MockHttpResponseGenerator(200, strBody)); 
        
        Opportunity objOpportunity = [Select Id From Opportunity LIMIT 1];
        
        Test.startTest();
        RNWL_MemberDetailsController.getHealthReturnResponse(opp.Id,asset.Id,'GFB-HB-22-2024165-004','123456','GFB-HB-22-2024165-004',lstFileSrcAPI); 
        Test.stopTest();
    }
    
    
}