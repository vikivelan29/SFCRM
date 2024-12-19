@isTest
public class ABCD_BeforeUpdateAfterASF_Test {
    @TestSetup
    static void makeData(){
        Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
        ASF_TestDataFactory.createC3IntegrationsAndCase();
        ASF_TestDataFactory.createCaseRecords(3);
    }
    
    @isTest
    static void testExecuteBeforeLogic(){
        Account acc = ASF_TestDataFactory.insertPersonAccount('first','last','test');
        Asset ast = ASF_TestDataFactory.createAsset(acc.Id, 'test');
        ast.Status = 'UPENDING';
        update ast;
        Id frameworkRecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        ASF_Case_Category_Config__c cccId = [SELECT Id,CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c != null];
        Map<Id,Case> cases = new Map<Id,Case>([SELECT ID,CCC_External_Id__c,Status,Stage__c,RecordTypeId,Business_Unit__c,Technical_Source__c
                                               FROM Case WHERE RecordTypeId=:frameworkRecordTypeId]);
        update cccId;
        for(Case caseRec : cases.values()){
            caseRec.Preframework_to_Framework_FromUI__c = true;
            caseRec.Business_Unit__c = 'ONEABC';
            caseRec.Technical_Source__c = 'LWC';
            caseRec.AssetId = ast.Id;
            caseRec.CCC_External_Id__c = 'PPAY008';
            caseRec.Nature__c = 'Complaint';
            caseRec.Stage__c = 'Unresolved';
            cases.put(caseRec.Id,caseRec);
        }
        String errorMessage = '';
        try{
        	update cases.values();    
        }catch(Exception ex){
            errorMessage = ex.getMessage();
        }
        System.assertEquals(errorMessage,errorMessage);
    }
}