@IsTest
public class EbotBatchClass_Test {
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
    }   
    @IsTest
    static void eBotHandler_Test(){
        List<Case> caseList = [Select id from Case limit 1];
		            EmailMessage eMsg = new EmailMessage();
            eMsg.ParentId = caseList[0].Id;
            eMsg.ToAddress = 'abfl.grievancehead@adityabirlacapital.com';
            eMsg.FromAddress = 'abfl.crmuat01@adityabirlacapital.com';
            eMsg.CCAddress = 'abfl.instics@adityabirlacapital.com';
            eMsg.BCCAddress = 'test@test.com';
            eMsg.MessageIdentifier = 'ABC';
            eMsg.Incoming = true;
            eMsg.Send_to_EBOT__c = true;
            eMsg.Headers ='In-Reply-To:';
            insert eMsg;
        Database.executebatch(new EbotbatchClass(new List<String>{emsg.Id}));
    }
}