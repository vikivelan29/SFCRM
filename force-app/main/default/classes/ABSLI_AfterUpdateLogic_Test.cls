@isTest
public class ABSLI_AfterUpdateLogic_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    private final static Id FRAMEWORKRECORDTYPEID = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
    @TestSetup
    static void makeData(){
        Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
        ASF_TestDataFactory.createC3IntegrationsAndCase();
        List<Case> createdCases = ASF_TestDataFactory.createCaseRecords(3);
        List<Case> cases = [SELECT ID,CCC_External_Id__c,Status,FTR__c FROM Case WHERE RecordType.Name='Framework'];
        List<ABSLI_Case_Detail__c> caseDetails =new List<ABSLI_Case_Detail__c>();
        for(integer i=0;i<cases.size();i++){
            ABSLI_Case_Detail__c caseExtn = new ABSLI_Case_Detail__c();
            caseExtn.Outcome__c = 'Resolved';
            caseExtn.Resolution__c='Email sent to Customer';
            caseDetails.add(caseExtn);
        }
        if(caseDetails.size()>0){
            insert caseDetails;
            integer i=0;
            for(Case c : cases){
                c.ABSLI_Case_Detail__c = caseDetails[i].Id;
                i++;
            }
            update cases;
        }
    }
    @isTest
    public static void ftrRegionalTest(){

        String cccId = [SELECT Id,CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c != null].CCC_External_Id__c;

        List<Case> cases = [SELECT ID,CCC_External_Id__c,Status,FTR__c,ABSLI_Case_Detail__c,Stage__c FROM Case WHERE RecordTypeId=:FRAMEWORKRECORDTYPEID];
        for(case c : cases){
            c.Business_Unit__c = 'ABSLI';
            c.Reject_Case__c = true;
            c.CCC_External_Id__c = cccId;
        }
        update cases;

        List<Case> resultcases = [SELECT ID,Status,ABSLI_Case_Detail__r.Outcome__c FROM Case WHERE RecordTypeId=:FRAMEWORKRECORDTYPEID];
        Assert.areEqual (resultcases[0].Status, 'Unresolved','Status should be resolved');
    }
    @isTest
    public static void changeOwnerOnAutoResolveTest(){
        User userRecord = new User(Alias = 'standt', Email='standarduser@testorg.com',
                                   EmailEncodingKey='UTF-8', LastName='ABCL AWS API User', LanguageLocaleKey='en_US',
                                   LocaleSidKey='en_US', ProfileId = SYSTEMADMIN_PROFILE.Id,
                                   TimeZoneSidKey='America/Los_Angeles', UserName='abcdefghijk56@gmail.com');
        insert userRecord;
        System.runAs(userRecord) {
            PermissionSet ps1 = [SELECT Id FROM PermissionSet WHERE Name = 'API_Admin_User_PS'];
            PermissionSetAssignment psa1 = new PermissionSetAssignment();
            psa1.AssigneeId = userRecord.Id;
            psa1.PermissionSetId = ps1.Id;
            insert psa1;

            PermissionSet ps2 = [SELECT Id FROM PermissionSet WHERE Name = 'Create_Case'];
            PermissionSetAssignment psa2 = new PermissionSetAssignment();
            psa2.AssigneeId = userRecord.Id;
            psa2.PermissionSetId = ps2.Id;
            insert psa2;

            String cccId = [SELECT Id,CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c != null].CCC_External_Id__c;
            Case caseRec = [SELECT Id, Stage__c, Business_Unit__c,IRDAI_Token_Number__c FROM Case WHERE RecordTypeId=:FRAMEWORKRECORDTYPEID LIMIT 1];
            caseRec.Stage__c = 'Resolved';
            caseRec.Business_Unit__c = ABSLI_Constants.BUSINESS_UNIT;
            caseRec.CCC_External_Id__c = cccId;
            Map<Id, Case> caseRec1 = new Map<Id, Case> ([SELECT Id, Stage__c, Business_Unit__c,IRDAI_Token_Number__c FROM Case WHERE RecordTypeId=:FRAMEWORKRECORDTYPEID and Stage__c != 'Resolved' LIMIT 1]);
            ABSLI_AfterUpdateLogic.changeOwnerOnAutoResolve(new List<Case> {caseRec}, caseRec1);
        }
    }
}