@IsTest
private class RNWL_EmailTemplateVFCControllerTest {
    
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
      
    @TestSetup
    public static void setup(){
        User objUser = new User(profileId = SYSTEMADMIN_PROFILE.Id, email = 'test1@salesforce.com',
                                Username = 'Test1'+String.valueOf(Integer.valueof((Math.random() * 10)))+'@mock.com',
                                alias = 'test', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                                languagelocalekey = 'en_US', timezonesidkey = 'GMT',IsActive = true);
        insert objUser;
        
        System.runAs(objUser){
            RecordType individualRecordType = [SELECT Id FROM RecordType WHERE Name = 'Individual' AND SObjectType = 'Account' LIMIT 1];
            
            List<Account> lstAccount = new List<Account>();
            
            Account acc = ASF_TestDataFactory.createPersonAccountWithoutInsert('Test', 'Individual', 'strCRN'); 
            lstAccount.add(acc);
            insert lstAccount; 
            
            Asset asset = new Asset();
            asset.Name = 'Test Asset';
            asset.AccountId = acc.Id;
            asset.Type__c = 'TestAsset';
            asset.Policy_No__c = '12456';
            asset.ABHI_Policy_Id__c = '12456';
            asset.LAN__c = '12456'; 
            
            List<Asset> lstAsset = new List<Asset>();
            lstAsset.add(asset);
            
            insert lstAsset;
            
            Opportunity objOpportunity = RNWL_TestDataFactory.createOpportunityRecords(acc.Id, lstAsset[0].Id);
            String strBody = '{ "error": [ { "ErrorCode": "00", "ErrorMessage": "Success" },{ "ErrorCode": "10", "ErrorMessage": "Success" } ], "Renew_Info": [ { "Renewed_Policy_Expiry_Date": "", "Renewed_Policy_Number": "", "Renewed_Policy_Proposal_Number": "240000621404", "Renewed_Policy_Start_Date": "" } ], "response": { "policyData": [ {"Policy_number":"12456", "Policy_renewal_date": "09/01/2025", "Upsell_Flag": "No", "Renewable_Flag": "Yes", "Renewed_Flag": "No", "Sum_insured_type": "Individual", "SumInsured": "2000000", "sumInsuredtype": "IND", "Members": [ { "CB": "3000000", "Chronic": "Yes", "DoB": "03/30/1974", "Email": "rahul.ghimire@qualitykiosk.com", "Gender": "M", "healthReturn": ".00", "Name": "Vishwas Varma", "Mobile_Number": "9012737473","MemberproductComponents":[{"SumInsured": "2000000","SumInsuredPerUnit": "2000000","Upsell_SumInsured": "","Relation": "Mother"}]}], "Nominee_Details": { "Nominee_Address": "test", "Nominee_Contact_No": "8707868534", "nominee_dob": "", "nominee_first_name": "Mona", "nominee_last_name": "Mona", "Nominee_Name": "Mona", "nominee_relationship_code": "Mother", "Relationship": "Mother" }, "premium": { "Renewal_Gross_Premium": "55774.0", "Renewal_Net_Premium": "47266.49", "Upsell_Gross_Premium": "0", "Upsell_Net_Premium": "0" } } ] } }';     
        	ContentVersion content = new ContentVersion();
        	content.PathOnClient = 'Response.txt';
        	content.Title = 'Response';
        	content.VersionData = Blob.valueof(strBody);
            content.Content_Source_API__c = 'Renewal Check';
            insert content;
        
        	//Link document to Case Integration
        	ContentVersion conVersion = [Select ContentDocumentId from ContentVersion where id =: content.Id];
        	ContentDocumentLink docLink = new ContentDocumentLink();
        	docLink.LinkedEntityId = objOpportunity.Id;
        	docLink.ContentDocumentId = conVersion.ContentDocumentId;
        	insert docLink;
            
        }
        
    }
    
    @isTest
    public static void test_MemberListForTemplate(){ 
        Opportunity objOpportunity = [Select Id,AccountId From Opportunity LIMIT 1];
        Test.startTest(); 
        RNWL_EmailTemplateVFCController controller = new RNWL_EmailTemplateVFCController();
        controller.oppId = objOpportunity.Id;
        Opportunity res = controller.objOpp;
        List<RNWL_EmailTemplateVFCController.MemberUIResponseWrapper> wrapperList = controller.lstMember;
        Integer memSize = controller.memSize;
        Test.stopTest();
    }
    
}