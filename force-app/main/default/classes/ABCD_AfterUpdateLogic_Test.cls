@IsTest
public class ABCD_AfterUpdateLogic_Test {
	@TestSetup
    static void makeData(){
        Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
        ASF_TestDataFactory.createC3IntegrationsAndCase();
        ASF_Case_Category_Config__c caseCatConfig = [Select id from ASF_Case_Category_Config__c limit 1];
        Account accRec = ASF_TestDataFactory.insertPersonAccount('First','Last','CMP');
        accRec.PersonMobilePhone = '9999999999';
        update accRec;
        caseCatConfig.Litmus_Trigger__c = true;
        update caseCatConfig;
        List<Case> createdCases = ASF_TestDataFactory.createCaseRecords(3);
        List<Case> cases = [SELECT ID,CCC_External_Id__c,Status,FTR__c FROM Case WHERE RecordType.Name='Framework'];
        List<ABCD_Case_Detail__c> caseDetails =new List<ABCD_Case_Detail__c>();
        for(integer i=0;i<cases.size();i++){
            ABCD_Case_Detail__c caseExtn = new ABCD_Case_Detail__c();
            caseDetails.add(caseExtn);
        }
        if(caseDetails.size()>0){
            insert caseDetails;
            integer i=0;
            for(Case c : cases){
                c.ABCD_Case_Detail__c = caseDetails[i].Id;
                c.AccountId = accRec.Id;
                i++;
            }
            update cases;
        }
    }
    
    @IsTest
    static void testLitmus(){
        Case caseRec = [SELECT Id, Stage__c, Business_Unit__c,IRDAI_Token_Number__c,IsClosed,CCC_External_Id__c,AccountId FROM Case LIMIT 1];
        caseRec.Stage__c = 'Resolved';
        caseRec.Business_Unit__c = 'ABCD';
        Map<Id,Case> caseMap = new Map<Id,Case>();
        caseMap.put(caseRec.Id,caseRec);
        ABCD_AfterUpdateLogic.executeAfterInsertLogic(new List<Case>{caseRec},caseMap);
    }
}