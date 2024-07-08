@isTest
public class ABSLI_AfterUpdateLogic_Test {
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
        Id frameworkRecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        String cccId = [SELECT Id,CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c != null].CCC_External_Id__c;
        
        List<Case> cases = [SELECT ID,CCC_External_Id__c,Status,FTR__c,ABSLI_Case_Detail__c,Stage__c FROM Case WHERE RecordTypeId=:frameworkRecordTypeId];
        for(case c : cases){
            c.Business_Unit__c = 'ABSLI';
            c.Reject_Case__c = true;
            c.CCC_External_Id__c = cccId;
        }
        update cases;
        
        List<Case> resultcases = [SELECT ID,Status,ABSLI_Case_Detail__r.Outcome__c FROM Case WHERE RecordTypeId=:frameworkRecordTypeId];
        Assert.areEqual (resultcases[0].Status, 'Unresolved','Status should be resolved');
    }
	


}