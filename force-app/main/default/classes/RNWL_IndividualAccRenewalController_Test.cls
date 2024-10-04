@IsTest
public class RNWL_IndividualAccRenewalController_Test {
    
    private static final String FAKE_RESPONSE_JSON = '{ "error": [ { "ErrorCode": "00", "ErrorMessage": "Success" } ], "Renew_Info": [ { "Renewed_Policy_Expiry_Date": "", "Renewed_Policy_Number": "", "Renewed_Policy_Proposal_Number": "240000621404", "Renewed_Policy_Start_Date": "" } ], "response": { "policyData": [ {"Policy_number":21-24-0000759-01", "Policy_renewal_date": "09/01/2025", "Upsell_Flag": "No", "Renewable_Flag": "Yes", "Renewed_Flag": "No", "Sum_insured_type": "Individual", "SumInsured": "2000000", "sumInsuredtype": "IND", "Members": [ { "CB": "3000000", "Chronic": "Yes", "DoB": "03/30/1974", "Email": "rahul.ghimire@qualitykiosk.com", "Gender": "M", "healthReturn": ".00", "Name": "Vishwas Varma", "Mobile_Number": "9012737473", "SumInsured": "2000000", "SumInsuredPerUnit": "2000000", "Upsell_SumInsured": "", "Relation": "Mother" } ], "Nominee_Details": { "Nominee_Address": "test", "Nominee_Contact_No": "8707868534", "nominee_dob": "", "nominee_first_name": "Mona", "nominee_last_name": "Mona", "Nominee_Name": "Mona", "nominee_relationship_code": "Mother", "Relationship": "Mother" }, "premium": { "Renewal_Gross_Premium": "55774.0", "Renewal_Net_Premium": "47266.49", "Upsell_Gross_Premium": "0", "Upsell_Net_Premium": "0" } } ] } }'; 
    
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
        oppRec.Policy_Number__c = '21-24-0000759-01';
        insert oppRec;
    }
    
    
    @IsTest
    static void testExecuteCallout(){  
        //Test.setMock(HttpCalloutMock.class, new Mock());
         
        Opportunity objOpportunity = [Select Id From Opportunity LIMIT 1];
        Test.startTest();
        RNWL_IndividualAccRenewalController.getPolicyRenewalDetails(objOpportunity.Id);
        Test.stopTest();
        
        //System.assertEquals(true,failedResponse != null,'PASS');
    }
}