@isTest
public class RNWL_NonIndAccountRenewalControllerTest {
    
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    private static final String FAKE_RESPONSE_JSON = '{"error":[{"ErrorCode":"00","ErrorMessage":"Success"}],"response":{"policyData":[{"PolicyproductComponents":[{"PlanCode":"","SchemeCode":"4000","NetPremium":"1200.0","NetPremium_U":""}],"MaterPolicyNumber":"62-20-00216-01-02","Certificate_number":"GFB-HB-22-2024165-004","Sum_insured_type":"Individual","Policy_start_date":"06/29/2023","Policy_renewal_date":"06/29/2024","Policy_expiry_date":"06/28/2024","Policy_lapsed_flag":"Yes","Group_Category":"GRP124","RefCode1":"","RefCode2":"","Upsell_Flag":"No","Renewable_flag":"Yes","Renewed_Flag":"No","Combi_Flag":"1","premium":{"Renewal_Net_Premium":"1200.0","Renewal_Gross_Premium":"1416.0","Renewal_Tax_Details":[{"Tax_Type":"CGST","TaxRate":"9.00","Tax_Amount":"108.0"},{"Tax_Type":"SGST","TaxRate":"9.00","Tax_Amount":"108.0"}],"Upsell_Net_Premium":"0","Upsell_Gross_Premium":"0","Upsell_Tax_Details":""},"NSTP_flag":"No","Name_of_the_proposer":"Sandip Naginbhai Andhariya .","Intermediary_Name":"HDFC Bank - Telesales Group Business","Intermediary_Code":"2103154","Customer_Code":"","Members":[{"MemberproductComponents":[{"PlanCode":"","SumInsured":"1000000","NetPremium":"1200.0","NetPremium_U":"","CB":"0","Hr_Amount":"0.0"}],"Name":"Sandip Naginbhai Andhariya .","Title":"Mr.","FirstName":"Sandip Naginbhai Andhariya","LastName":".","Relationship_Code":"24","GHDApplicable":"","GHDRemarks":"","Member_Code":"00053423015","DoB":"12/22/1982","Gender":"M","Email":"Sandipandhariya@Gmail.Com","Mobile_Number":"9427496123","Relation":"Self"},{"MemberproductComponents":[{"PlanCode":"","SumInsured":"1000000","NetPremium":"1200.0","NetPremium_U":"","CB":"0","Hr_Amount":"0.0"}],"Name":"Jalak Sandipbhai Andhariya .","Title":"Ms.","FirstName":"Jalak Sandipbhai Andhariya","LastName":".","Relationship_Code":"13","GHDApplicable":"","GHDRemarks":"","Member_Code":"00053423016","DoB":"09/18/1983","Gender":"F","Email":"Sandipandhariya@Gmail.Com","Mobile_Number":"9427496123","Relation":"Spouse"}],"Name_of_product":"Group Activ Secure ","Auto_Debit":"0","SplitFlag":"0","Proposer_Email":"Sandipandhariya@Gmail.Com","Proposer_MobileNo":"9427496123","EWFlag":"","Renewed_Masterpolicy_Number":"62-20-00216-01-02","Nominee_Details":{"Nominee_Name":"Om Sandipbhai Andhariya","Nominee_Address":"","Nominee_Contact_No":"9999999999"},"optionalCoverages":[]},{"PolicyproductComponents":[{"PlanCode":"","SchemeCode":"5211","NetPremium":"17493.45","NetPremium_U":""}],"MaterPolicyNumber":"71-20-00040-01-02","Certificate_number":"GHI-HB-22-2032552-004","Sum_insured_type":"Family Floater","Policy_start_date":"06/29/2023","Policy_renewal_date":"06/29/2024","Policy_expiry_date":"06/28/2024","Policy_lapsed_flag":"Yes","Group_Category":"GRP022","RefCode1":"","RefCode2":"","Upsell_Flag":"No","Renewable_flag":"Yes","Renewed_Flag":"No","Combi_Flag":"1","premium":{"Renewal_Net_Premium":"17493.45","Renewal_Gross_Premium":"20642.27","Renewal_Tax_Details":[{"Tax_Type":"CGST","TaxRate":"9.00","Tax_Amount":"1574.0"},{"Tax_Type":"SGST","TaxRate":"9.00","Tax_Amount":"1574.0"}],"Upsell_Net_Premium":"0","Upsell_Gross_Premium":"0","Upsell_Tax_Details":""},"NSTP_flag":"No","Name_of_the_proposer":"Sandip Naginbhai Andhariya .","Intermediary_Name":"HDFC Bank - Telesales Group Business","Intermediary_Code":"2103154","Customer_Code":"","Members":[{"MemberproductComponents":[{"PlanCode":"","SumInsured":"1000000","NetPremium":"1200.0","NetPremium_U":"","CB":"0","Hr_Amount":"0.0"}],"Name":"Sandip Naginbhai Andhariya .","Title":"Mr.","FirstName":"Sandip Naginbhai Andhariya","LastName":".","Relationship_Code":"24","GHDApplicable":"","GHDRemarks":"","Member_Code":"0005342300045","DoB":"12/22/1982","Gender":"M","Email":"Sandipandhariya@Gmail.Com","Mobile_Number":"9427496123","Relation":"Self"},{"MemberproductComponents":[{"PlanCode":"","SumInsured":"1000000","NetPremium":"1200.0","NetPremium_U":"","CB":"0","Hr_Amount":"0.0"}],"Name":"Om Sandipbhai Andhariya .","Title":"Mr.","FirstName":"Om Sandipbhai Andhariya","LastName":".","Relationship_Code":"23","GHDApplicable":"","GHDRemarks":"","Member_Code":"00053423000456","DoB":"09/05/2011","Gender":"M","Email":"Sandipandhariya@Gmail.Com","Mobile_Number":"9427496123","Relation":"Dependent Son"},{"MemberproductComponents":[{"PlanCode":"","SumInsured":"1000000","NetPremium":"1200.0","NetPremium_U":"","CB":"0","Hr_Amount":"0.0"}],"Name":"Stuti Sandipbhai Andhariya .","Title":"Ms.","FirstName":"Stuti Sandipbhai Andhariya","LastName":".","Relationship_Code":"19","GHDApplicable":"","GHDRemarks":"","Member_Code":"000534230004567","DoB":"01/22/2007","Gender":"F","Email":"Sandipandhariya@Gmail.Com","Mobile_Number":"9427496123","Relation":"Dependent Daughter"},{"MemberproductComponents":[{"PlanCode":"","SumInsured":"1000000","NetPremium":"1200.0","NetPremium_U":"","CB":"0","Hr_Amount":"0.0"}],"Name":"Jalak Sandipbhai Andhariya .","Title":"Ms.","FirstName":"Jalak Sandipbhai Andhariya","LastName":".","Relationship_Code":"13","GHDApplicable":"","GHDRemarks":"","Member_Code":"0005342300045678","DoB":"09/18/1983","Gender":"F","Email":"Sandipandhariya@Gmail.Com","Mobile_Number":"9427496123","Relation":"Spouse"}],"Name_of_product":"Group Activ Health V2","Auto_Debit":"0","SplitFlag":"0","Proposer_Email":"Sandipandhariya@Gmail.Com","Proposer_MobileNo":"9427496123","EWFlag":"","Renewed_Masterpolicy_Number":"71-20-00040-01-02","Nominee_Details":{"Nominee_Name":"Om Sandipbhai Andhariya ","Nominee_Address":"","Nominee_Contact_No":"9999999999"},"optionalCoverages":[]}]},"Renew_Info":[{"Renewed_Certificate_Number":"","Renewed_MaterPolicy_Number":"62-20-00216-01-02","Renewed_Policy_Proposal_Number":"QU-23-4000-6350978-00","Renewed_Policy_Start_Date":"","Renewed_Policy_Expiry_Date":""},{"Renewed_Certificate_Number":"","Renewed_MaterPolicy_Number":"71-20-00040-01-02","Renewed_Policy_Proposal_Number":"QU-23-5211-7900211-00","Renewed_Policy_Start_Date":"","Renewed_Policy_Expiry_Date":""}]}';  
    
    private class Mock implements HttpCalloutMock { 
        public HTTPResponse respond(HTTPRequest req) { 
            HTTPResponse res = new HTTPResponse();
            res.setBody(FAKE_RESPONSE_JSON);
            res.setStatusCode(200);
            return res;
        }
    } 
    
    @TestSetup
    public static void setup(){
        Account acc=  new Account(name='Test Account');
        insert acc;
        
        Opportunity oppRec = new Opportunity();
        oppRec.Name = 'Testabc' ;
        oppRec.AccountId = acc.Id;
        oppRec.CloseDate = Date.today();
        oppRec.StageName = 'In Progress';
        oppRec.Policy_Number__c = 'GFB-HB-22-2024165-004';
       	insert oppRec;
    }
    
    @IsTest
    static void testExecuteCallout(){  
        Opportunity objOpportunity = [Select Id From Opportunity LIMIT 1];
        Test.startTest();
        RNWL_NonIndAccountRenewalController.getRenewalDetails_NonIndAcc(objOpportunity.Id);
        Test.stopTest();
        RNWL_NonIndAccountRenewalController.getRenewalDetails_NonIndAcc(objOpportunity.Id);
	}
}