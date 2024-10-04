@isTest
public class ABSLI_DownloadIGMSComplaint_Test {
    @testSetup
    static void testSetup(){
        
        Id recordTypeId =Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
        Account objAccount = new Account();
        objAccount.FirstName = 'TestFirstName';
        objAccount.LastName  = 'TestFirstName';
        objAccount.RecordTypeId = recordTypeId;
        objAccount.Client_Code__c = 'ABSLI001';
        insert objAccount;
        
        Case testCase = new Case();
        testCase.CCC_External_Id__c = 'PNFT007';
        testCase.Business_Unit__c = 'ABSLI';
        testCase.Source__c = 'Email';
        testCase.Client_Code_Text__c = 'ABSLI001';
        testCase.AccountId = objAccount.Id;
        insert testCase;
        
        ABSLI_IGMS_Document__c doc = new ABSLI_IGMS_Document__c();
        doc.Case__c = testCase.Id;
        doc.IRDA_Token_Number__c = '2';
        doc.Document_Id__c = 'DOC-1234';
        insert doc;
    }
    @isTest
    static void testDocument(){
        ABSLI_IGMS_Document__c docobj = [Select Id From ABSLI_IGMS_Document__c limit 1];
    
        Test.starttest();
        ABSLI_DownloadIGMSComplaintIntegration.downloadAttachment(docobj.Id);
        Test.stoptest();
    }
}