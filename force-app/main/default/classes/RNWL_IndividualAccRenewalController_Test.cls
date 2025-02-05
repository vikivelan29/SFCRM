@IsTest
public class RNWL_IndividualAccRenewalController_Test {
     
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    
    private class Mock implements HttpCalloutMock { 
        public HTTPResponse respond(HTTPRequest req) { 
            HTTPResponse res = new HTTPResponse();
            res.setBody('');
            res.setStatusCode(200);
            return res;
        }
    } 
    
    @TestSetup
    public static void setup(){
        User objUser = new User(profileId = SYSTEMADMIN_PROFILE.Id, email = 'test1@salesforce.com',
                                Username = 'Test1'+String.valueOf(Integer.valueof((Math.random() * 10)))+'@mock.com',
                                alias = 'test', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                                languagelocalekey = 'en_US', timezonesidkey = 'GMT',IsActive = true);
        insert objUser;
        
        Account acc=  new Account(name='Test Account' , Client_Code__c = 'PT87552250' , Chronic_Disease__c = 'test', PED__c = 'test');
        insert acc;
        
        Asset objAsset =  new Asset(name='21-24-0000759-02', ABHI_Policy_Id__c='21-24-0000759-02', LAN__c = '21-24-0000759-02');
        insert objAsset;
        
        Opportunity oppRec = new Opportunity();
        oppRec.Name = 'Testabc' ;
        oppRec.Policy__c = objAsset.Id;
        oppRec.AccountId = acc.Id;
        oppRec.CloseDate = Date.today();
        oppRec.StageName = 'In Progress';
        oppRec.Policy_Number__c = '21-24-0000759-02';
        insert oppRec;
        
        Dispositions__c disp = new Dispositions__c();
        disp.Category__c = 'Renewal';
        disp.Policy_Number__c = objAsset.Id;
        disp.Renewal_Request__c = oppRec.Id;
        insert disp;
        
    }
    
    @IsTest
    static void testExecuteFailCallout(){   
                
        String strBody = '{ "error": [ { "ErrorCode": "01", "ErrorMessage": "Success" } ],"response": []}';
        
        Test.setMock(HttpCalloutMock.class, new RNWL_MockHttpResponseGenerator(400, strBody)); 
        
        Opportunity objOpportunity = [Select Id From Opportunity LIMIT 1];
 
        Test.startTest();  
             RNWL_IndividualAccRenewalController.getPolicyRenewalDetails(objOpportunity.Id);
        Test.stopTest(); 
         
    }
    
       @IsTest
    static void testExecuteSuccessCallout(){   
         
        String strBody = '{ "error": [ { "ErrorCode": "00", "ErrorMessage": "Success" } ], "Renew_Info": [ { "Renewed_Policy_Expiry_Date": "", "Renewed_Policy_Number": "", "Renewed_Policy_Proposal_Number": "240000621404", "Renewed_Policy_Start_Date": "" } ], "response": { "policyData": [ { "Is_cross_sell": "Y", "Cross_sell_Reference_Number": "2433234", "Loading_Rate": "10", "Loading_Reason": "test", "Policy_number": "21-24-0000759-02", "Policy_renewal_date": "09/01/2025","Combi_Flag":"Yes","Combi_Policy_Number":"21-24-0000759-02", "Upsell_Flag": "No", "Renewable_Flag": "Yes", "Renewed_Flag": "No", "Sum_insured_type": "Individual", "SumInsured": "2000000", "sumInsuredtype": "IND", "Members": [ { "MemberId": "PT87552250", "CB": "3000000", "Chronic": "Yes", "DoB": "03/30/1974", "Email": "rahul.ghimire@qualitykiosk.com", "Gender": "M", "healthReturn": ".00", "Name": "Vishwas Varma", "Mobile_Number": "9012737473", "SumInsured": "2000000", "SumInsuredPerUnit": "2000000", "Upsell_SumInsured": "", "Relation": "Mother" } ], "Nominee_Details": { "Nominee_Address": "test", "Nominee_Contact_No": "8707868534", "nominee_dob": "", "nominee_first_name": "Mona", "nominee_last_name": "Mona", "Nominee_Name": "Mona", "nominee_relationship_code": "Mother", "Relationship": "Mother" }, "premium": { "Renewal_Gross_Premium": "55774.0", "Renewal_Net_Premium": "47266.49", "Upsell_Gross_Premium": "0", "Upsell_Net_Premium": "0" } } ] } }';
        
        Test.setMock(HttpCalloutMock.class, new RNWL_MockHttpResponseGenerator(200, strBody)); 
      
        
        Opportunity objOpportunity = [Select Id ,Policy_Number__c From Opportunity LIMIT 1];
        system.debug('objOpportunity'+objOpportunity);
        
        user objUser = [Select Id From user WHERE email = 'test1@salesforce.com' LIMIT 1];
       
        System.runAs(objUser){
            Test.startTest();  
            RNWL_IndividualAccRenewalController.getPolicyRenewalDetails(objOpportunity.Id);
            Test.stopTest();             
        }
   
    }
     @IsTest
     static void testExecuteAPIFailedCallout(){   
         
        String strBody = '';
        
         Test.setMock(HttpCalloutMock.class, new RNWL_MockHttpResponseGenerator(500, strBody)); 
        
        Opportunity objOpportunity = [Select Id From Opportunity LIMIT 1];
 
        Test.startTest();  
             RNWL_IndividualAccRenewalController.getPolicyRenewalDetails(objOpportunity.Id);
        Test.stopTest(); 
         
    }
}