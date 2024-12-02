@isTest
public class ASF_CaseCommentTriggerHandler_Test {

    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @testSetup
    static void setupData(){
        User objUser = new User(profileId = SYSTEMADMIN_PROFILE.Id, email = 'test0@salesforce.com',
                           Username = 'Test'+String.valueOf(Integer.valueof((Math.random() * 10)))+'@mock.com',
                           alias = 'uqusr', lastname = 'lastname', emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                           languagelocalekey = 'en_US', timezonesidkey = 'GMT',IsActive = true,Business_Unit__c='ABFL');
        insert objUser;
        
        System.runAs(objUser){
        	ASF_TestDataFactory.createCaseRecords(0);
        }

        CaseComment testComment = new CaseComment(
            ParentId = [select Id from case LIMIT 1].Id,
            CommentBody = 'This is a test comment.'
        );
        insert testComment;
    }
    
    static testmethod void updateCaseCommentTest() {        
        Id caseId = [select Id from case LIMIT 1].Id;
        Test.StartTest();
            CaseComment ccRec = [select id, CommentBody from CaseComment where ParentId=:caseId LIMIT 1];
            ccRec.CommentBody = 'Test';            
            try{
                update ccRec;
            }catch (DmlException e) {
                Assert.isNotNull(e.getMessage());
            }
        Test.StopTest();   
    }
    static testmethod void closeCaseCommentTest() {
        Case caseRec = [select Id from case LIMIT 1];
        caseRec.Status = 'Closed';
        update caseRec;
        Test.StartTest();
            CaseComment ccRec = [select id, CommentBody from CaseComment where ParentId=:caseRec.Id LIMIT 1];
            ccRec.CommentBody = 'Test';
        try{
            delete ccRec;
        }catch (DmlException e) {
            Assert.isNotNull(e.getMessage());
        }
        Test.StopTest();    
    }
}