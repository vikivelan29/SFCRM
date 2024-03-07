@isTest
public class ASF_CaseTriggerHandler2_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];

    @TestSetup
    public static void setup() {
        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
        Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
        Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
        
        User manager1 = new User(profileId = SYSTEMADMIN_PROFILE.Id, email = 'manager1@salesforce.com',
        Username = 'manager1'+String.valueOf(Integer.valueof((Math.random() * 10)))+'@mock.com',
        alias = 'manager1', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_US',
        languagelocalekey = 'en_US', timezonesidkey = 'GMT',IsActive = true);
        
        insert manager1;

        User objUser = new User(profileId = SYSTEMADMIN_PROFILE.Id, email = 'test0@salesforce.com',
                           Username = 'Test'+String.valueOf(Integer.valueof((Math.random() * 10)))+'@mock.com',
                           alias = 'uqusr', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                           languagelocalekey = 'en_US', timezonesidkey = 'GMT',IsActive = true,ManagerId=manager1.Id);
        insert objUser;
    }

    @isTest
    public static void test_Insert(){
        ASF_TestDataFactory.createCaseCategoryConfig();
        Test.startTest();
        ASF_TestDataFactory.createCaseRecords(0);
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        ASF_TestDataFactory.createInteractionCaseRecords();
        Test.stopTest();
        List<Case> frameworkCase2 = [Select Id, Subject from Case where RecordType.Name = 'Framework'];
        Assert.areEqual(1, frameworkCase2.size(), 'Expected 1, Not found');
    }

     @isTest
    public static void test_Update(){
        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_TestDataFactory.createCaseRecords(0);
        ASF_TestDataFactory.createInteractionCaseRecords();
        Test.startTest();
        Case frameworkCase = [Select Id from Case where RecordType.Name = 'Framework' LIMIT 1];
        Case interactionCase = [Select Id from Case where RecordType.Name = 'Interaction' LIMIT 1];
        frameworkCase.Subject = 'Updated subject';
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        update frameworkCase;
        ASF_TriggerSkipperUtility.resetTriggerRun('Case');
        update interactionCase;
        Test.stopTest();
        Case frameworkCase2 = [Select Id, Subject from Case where RecordType.Name = 'Framework' LIMIT 1];
        Assert.areEqual('Updated subject', frameworkCase2.Subject, 'Expected Updated subject');
    } 
}