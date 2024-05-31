@IsTest
public class ABCL_CaseIntegrationHelper_Test {
    @testSetup
    static void setUpData(){
        
        List<Case> caseRecords = ASF_TestDataFactory.createCaseRecords(1);
        caseRecords[0].Source__c = 'Email';
        caseRecords[0].CCC_External_Id__c = '';
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
        List<ASF_Case_Integration__c> caseIntegrations = [Select id from ASF_Case_Integration__c limit 1];
        if(caseIntegrations.size() > 0){
            caseIntegrations[0].Status__c = 'Success';
            caseIntegrations[0].Response__c = '{\"CASEID\":\"Success\",\"CASESUBTYPE\":\"AC123457\",\"COMMENT\":\"Problem\",\"OWNERFULLNAME\":\"Major\",\"CONFIDENCESCORE\":\"Major\"}';
            update caseIntegrations[0];    
        }
    }
}