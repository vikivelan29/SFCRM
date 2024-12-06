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
        
        List<Case> caseRecords = ASF_TestDataFactory.createCaseRecords(3);
        caseRecords[0].Source__c = 'Email';
        caseRecords[0].CCC_External_Id__c = null;
        caseRecords[0].Business_Unit__c = 'ABHFL';
        caseRecords[0].AssetId = astRec1.Id;
        caseRecords[0].CCC_External_Id__c='';
        caseRecords[0].Origin='ABHFL Email';
        
        caseRecords[1].Source__c = 'Email';
        caseRecords[1].CCC_External_Id__c = null;
        caseRecords[1].Business_Unit__c = 'ABHFL';
        caseRecords[1].AssetId = astRec1.Id;
        caseRecords[1].CCC_External_Id__c='';
        caseRecords[1].Origin='ABHFL Email';
        
        caseRecords[2].Source__c = 'Email';
        caseRecords[2].CCC_External_Id__c = null;
        caseRecords[2].Business_Unit__c = 'ABHFL';
        caseRecords[2].AssetId = astRec1.Id;
        caseRecords[2].CCC_External_Id__c='';
        caseRecords[2].Origin='ABHFL Email';
        update caseRecords;
        
        if(caseRecords.size() > 0){
            ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();    
            caseInt.Case__c = caseRecords[0].Id;
            caseInt.Status__c = 'Pending';
            caseInt.Type__c = 'eBOT';
            insert caseInt;
            
            ASF_Case_Integration__c caseInt1 = new ASF_Case_Integration__c();    
            caseInt1.Case__c = caseRecords[1].Id;
            caseInt1.Status__c = 'Pending';
            caseInt1.Type__c = 'eBOT';
            insert caseInt1;
            
            ASF_Case_Integration__c caseInt2 = new ASF_Case_Integration__c();    
            caseInt2.Case__c = caseRecords[2].Id;
            caseInt2.Status__c = 'Pending';
            caseInt2.Type__c = 'eBOT';
            insert caseInt2;
            
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
            
            ContentVersion content1 = new ContentVersion();
            //content.STP_Document__c = 'No';
            content1.PathOnClient = 'Response.txt';
            content1.Title = 'Response';
            content1.VersionData = Blob.valueof('Test');
            insert content1;
            ContentVersion conVersion1 = [Select ContentDocumentId from ContentVersion where id =: content1.Id];
            ContentDocumentLink docLink1 = new ContentDocumentLink();
            docLink1.LinkedEntityId = caseInt1.Id;
            docLink1.ContentDocumentId = conVersion1.ContentDocumentId;
            docLink1.ShareType = 'V';
            insert docLink1;
            
            ContentVersion content2 = new ContentVersion();
            //content.STP_Document__c = 'No';
            content2.PathOnClient = 'Response.txt';
            content2.Title = 'Response';
            content2.VersionData = Blob.valueof('Test');
            insert content2;
            ContentVersion conVersion2 = [Select ContentDocumentId from ContentVersion where id =: content2.Id];
            ContentDocumentLink docLink2 = new ContentDocumentLink();
            docLink2.LinkedEntityId = caseInt2.Id;
            docLink2.ContentDocumentId = conVersion2.ContentDocumentId;
            docLink2.ShareType = 'V';
            insert docLink2;
        }
        EmailMessage msg = new EmailMessage();
        msg.ToAddress = 'care.housingfinance@adityabirlacapital.com';
        msg.FromAddress = 'Mail@test.com';
        msg.ParentId = caseRecords[0].Id;
        insert msg;
        
        EmailMessage msg1 = new EmailMessage();
        msg1.ToAddress = 'care.housingfinance@adityabirlacapital.com';
        msg1.FromAddress = 'Mail@test.com';
        msg1.ParentId = caseRecords[1].Id;
        insert msg1;
        
        EmailMessage msg2 = new EmailMessage();
        msg2.ToAddress = 'care.housingfinance@adityabirlacapital.com';
        msg2.FromAddress = 'Mail@test.com';
        msg2.ParentId = caseRecords[2].Id;
        insert msg2;
        
        ASF_Checklist__c chklst = new ASF_Checklist__c();
        chklst.Status__c = 'Pending';
        chklst.Case__c = caseRecords[0].Id;
        insert chklst;
        
        ASF_Checklist__c chklst1 = new ASF_Checklist__c();
        chklst1.Status__c = 'Pending';
        chklst1.Case__c = caseRecords[1].Id;
        insert chklst1;
        
        ASF_Checklist__c chklst2 = new ASF_Checklist__c();
        chklst2.Status__c = 'Pending';
        chklst2.Case__c = caseRecords[2].Id;
        insert chklst2;
    }   
    @IsTest
    static void eBotHandler_Test(){
        List<ASF_Case_Integration__c> caseIntegrations = [Select id from ASF_Case_Integration__c limit 3];
        if(caseIntegrations.size() > 0){
            caseIntegrations[0].Status__c = 'Success';
            
           caseIntegrations[0].Response__c = '{\"ASONDATE\":\"2023-10-14\",\"CASEID\":\"CAS-53056-C0S0W7\",\"CASESUBTYPE\":\"QLOANDUSNDC\",\"COMMENT\":\"testcase\",\"CONFIDENCESCORE\":0.9,\"DISBURSTMENTTYPE\":\"FullyDisbursed\",\"FROMDATE\":\"2023-01-25\",\"FROMYEAR\":2022,\"ISCORRUPTED\":\"No\",\"ISMULTILAN\":\"Yes\",\"ISMULTIPLEDATEFORMATE\":\"Yes\",\"ISREGISTRED\":\"Yes\",\"ISREGULATOR\":\"No\",\"ISREPEAT\":\"No\",\"ISSMT\":\"No\",\"ISATTACHMENTFLAG\":\"No\",\"ISTRAIL\":\"Yes\",\"LANCOMMENT\":\"TestLANComment\",\"LOB\":\"HFC\",\"OWNERFULLNAME\":\"TauseefKaldane\",\"TODATE\":\"2023-01-27\",\"TOYEAR\":2023,\"Template1\":\"\",\"Template2\":\"\",\"Template3\":\"\",\"UNREGISTEREDCATEGORY\":\"\",\"EBOTLAN\":[\"657644354\",\"032332232332\",\"35677822\"]}';
            
            caseIntegrations[1].Status__c = 'Success';
            
           caseIntegrations[1].Response__c = '{\"ASONDATE\":\"2023-10-14\",\"CASEID\":\"CAS-53056-C0S0W7\",\"CASESUBTYPE\":\"QLOANDUSNDC\",\"COMMENT\":\"testcase\",\"CONFIDENCESCORE\":0.9,\"DISBURSTMENTTYPE\":\"FullyDisbursed\",\"FROMDATE\":\"2023-01-25\",\"FROMYEAR\":2022,\"ISCORRUPTED\":\"No\",\"ISMULTILAN\":\"Yes\",\"ISMULTIPLEDATEFORMATE\":\"Yes\",\"ISREGISTRED\":\"No\",\"ISREGULATOR\":\"No\",\"ISREPEAT\":\"Yes\",\"ISSMT\":\"No\",\"ISATTACHMENTFLAG\":\"No\",\"ISTRAIL\":\"Yes\",\"LANCOMMENT\":\"TestLANComment\",\"LOB\":\"HFC\",\"OWNERFULLNAME\":\"TauseefKaldane\",\"TODATE\":\"2023-01-27\",\"TOYEAR\":2023,\"Template1\":\"\",\"Template2\":\"\",\"Template3\":\"\",\"UNREGISTEREDCATEGORY\":\"\",\"EBOTLAN\":[\"657644354\",\"032332232332\",\"35677822\"]}';
            caseIntegrations[2].Status__c = 'Success';
            
           caseIntegrations[2].Response__c = '{\"ASONDATE\":\"2023-10-14\",\"CASEID\":\"CAS-53056-C0S0W7\",\"CASESUBTYPE\":\"QLOANDUSNDC\",\"COMMENT\":\"testcase\",\"CONFIDENCESCORE\":0.9,\"DISBURSTMENTTYPE\":\"FullyDisbursed\",\"FROMDATE\":\"2023-01-25\",\"FROMYEAR\":2022,\"ISCORRUPTED\":\"No\",\"ISMULTILAN\":\"Yes\",\"ISMULTIPLEDATEFORMATE\":\"Yes\",\"ISREGISTRED\":\"Yes\",\"ISREGULATOR\":\"No\",\"ISREPEAT\":\"No\",\"ISSMT\":\"Yes\",\"ISATTACHMENTFLAG\":\"Yes\",\"ISTRAIL\":\"Yes\",\"LANCOMMENT\":\"TestLANComment\",\"LOB\":\"HFC\",\"OWNERFULLNAME\":\"TauseefKaldane\",\"TODATE\":\"2023-01-27\",\"TOYEAR\":2023,\"Template1\":\"\",\"Template2\":\"\",\"Template3\":\"\",\"UNREGISTEREDCATEGORY\":\"\",\"EBOTLAN\":[\"657644354\",\"032332232332\",\"35677822\"]}';
            
           // caseIntegrations[0].Response__c = '{\"CASEID\":\"Success\",\"CASESUBTYPE\":\"AC123457\",\"COMMENT\":\"Problem\",\"OWNERFULLNAME\":\"Major\",\"CONFIDENCESCORE\":\"Major\"}';
            Test.startTest();
            update caseIntegrations[0];   
            Test.stopTest();
            
             Test.startTest();
            update caseIntegrations[1];   
            Test.stopTest();
            
             Test.startTest();
            update caseIntegrations[2];   
            Test.stopTest();
        }
    }
}