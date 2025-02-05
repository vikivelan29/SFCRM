@isTest
public class RNWL_RelatedListHelperTest {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];

    @TestSetup
    public static void setup(){
        User objUser = new User(profileId = SYSTEMADMIN_PROFILE.Id, email = 'test1@salesforce.com',
                                Username = 'Test1'+String.valueOf(Integer.valueof((Math.random() * 10)))+'@mock.com',
                                alias = 'test', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                                languagelocalekey = 'en_US', timezonesidkey = 'GMT',IsActive = true);

        
        insert objUser;

        Account acc = ASF_TestDataFactory.insertBusinessAccount('test', 'strCRN');
        
        Asset asset = ASF_TestDataFactory.createAsset(acc.Id,'');  
        Opportunity oppRec = RNWL_TestDataFactory.createOpportunityRecords(acc.Id, asset.Id);
        PE_Logger__c peLogger = new PE_Logger__c();
        peLogger.Email_Template_Name__c = 'ABSLI_Request_Complaint_Creation';
        peLogger.Opportunity_ID__c = oppRec.Id;
        peLogger.LOB__c = 'ABHI';
        peLogger.PE_Name__c = 'Test Log';
        insert peLogger;
        
        EmailMessage emailMsg = new EmailMessage();
        emailMsg.RelatedToId = oppRec.Id;
        emailMsg.Subject = 'blah blah blah';
        emailMsg.ToAddress = 'test@sf.com';
        //emailMsg.Status = 'Sent';
        insert emailMsg;
    }
    
    @IsTest
    private static void test_EmailMessageMode(){
        Opportunity oppRec = [Select Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
            RNWL_RelatedListHelper.getRelatedRecords('Email Message', oppRec.Id, false);
        Test.stopTest();
    }

    @IsTest
    private static void test_EmailMessageModeViewAll(){
        Opportunity oppRec = [Select Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
            RNWL_RelatedListHelper.getRelatedRecords('Email Message', oppRec.Id, true);
        Test.stopTest();
    }
    
    @IsTest
    private static void test_BestDispositionMode(){
        Opportunity oppRec = [Select Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
            RNWL_RelatedListHelper.getRelatedRecords('Best Disposition', oppRec.Id, false);
        Test.stopTest(); 
    }
    
    @IsTest
    private static void test_LastDispositionMode(){
        Opportunity oppRec = [Select Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
            RNWL_RelatedListHelper.getRelatedRecords('Last Disposition', oppRec.Id, false);
        Test.stopTest(); 
    }

    @IsTest
    private static void test_UpdateRazorPay(){
        Opportunity oppRec = [Select Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
            RNWL_RelatedListHelper.updateOpportunityFields(oppRec.Id, 'https://www.google.co.in', 1000);
        Test.stopTest(); 
    }
}