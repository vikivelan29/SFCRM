@IsTest
public class ABHFL_CaseIntegrationHelper_Test {
    @testSetup
    static void setUpData(){
        
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('Test_Cmp','Test_1');
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec.LAN__c = '657644354';
        update astRec;
        Asset astRec1 = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec1.LAN__c = '032332232332';
        update astRec1;
        
        List<Case> caseRecords = ASF_TestDataFactory.createCaseRecords(1);
        caseRecords[0].Source__c = 'Email';
        caseRecords[0].CCC_External_Id__c = null;
        caseRecords[0].Business_Unit__c = 'ABHFL';
        caseRecords[0].AssetId = astRec1.Id;
        caseRecords[0].CCC_External_Id__c='';
        caseRecords[0].Origin='ABHFL Email';
        update caseRecords;
        
        if(caseRecords.size() > 0){
            ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();    
            caseInt.Case__c = caseRecords[0].Id;
            caseInt.Status__c = 'Pending';
            caseInt.Type__c = 'eBOT';
            insert caseInt;
            ContentVersion content = new ContentVersion();
            //content.STP_Document__c = 'No';
            content.PathOnClient = 'Response.txt';
            content.Title = 'Response';
            content.VersionData = Blob.valueof('Test');
            insert content;
            ContentVersion conVersion = [Select ContentDocumentId from ContentVersion where id =: content.Id];
            ContentDocumentLink docLink = new ContentDocumentLink();
            docLink.LinkedEntityId = caseInt.Id;
            docLink.ContentDocumentId = conVersion.ContentDocumentId;
            docLink.ShareType = 'V';
            insert docLink;
        }
        EmailMessage msg = new EmailMessage();
        msg.ToAddress = 'care.housingfinance@adityabirlacapital.com';
        msg.FromAddress = 'Mail@test.com';
        msg.ParentId = caseRecords[0].Id;
        insert msg;
        
        ASF_Checklist__c chklst = new ASF_Checklist__c();
        chklst.Status__c = 'Pending';
        chklst.Case__c = caseRecords[0].Id;
        insert chklst;
    }   
    @IsTest
    static void eBotHandler_Test(){
        List<ASF_Case_Integration__c> caseIntegrations = [Select id from ASF_Case_Integration__c limit 1];
        if(caseIntegrations.size() > 0){
            caseIntegrations[0].Status__c = 'Success';
            
           caseIntegrations[0].Response__c = '{\"ASONDATE\":\"2023-10-14\",\"CASEID\":\"CAS-53056-C0S0W7\",\"CASESUBTYPE\":\"QLOANDUSNDC\",\"COMMENT\":\"testcase\",\"CONFIDENCESCORE\":0.9,\"DISBURSTMENTTYPE\":\"FullyDisbursed\",\"FROMDATE\":\"2023-01-25\",\"FROMYEAR\":2022,\"ISCORRUPTED\":\"No\",\"ISMULTILAN\":\"Yes\",\"ISMULTIPLEDATEFORMATE\":\"Yes\",\"ISREGISTRED\":\"Yes\",\"ISREGULATOR\":\"No\",\"ISREPEAT\":\"No\",\"ISSMT\":\"No\",\"ISTRAIL\":\"Yes\",\"LANCOMMENT\":\"TestLANComment\",\"LOB\":\"HFC\",\"OWNERFULLNAME\":\"TauseefKaldane\",\"TODATE\":\"2023-01-27\",\"TOYEAR\":2023,\"Template1\":\"\",\"Template2\":\"\",\"Template3\":\"\",\"UNREGISTEREDCATEGORY\":\"\",\"EBOTLAN\":[\"657644354\",\"032332232332\",\"35677822\"]}';
            
           // caseIntegrations[0].Response__c = '{\"CASEID\":\"Success\",\"CASESUBTYPE\":\"AC123457\",\"COMMENT\":\"Problem\",\"OWNERFULLNAME\":\"Major\",\"CONFIDENCESCORE\":\"Major\"}';
            Test.startTest();
            update caseIntegrations[0];   
            Test.stopTest();
        }
    }
}