@isTest
public class ABSLI_BeforeUpdateTriggerLogic_Test {

    @TestSetup
    static void makeData(){
        Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
        ASF_TestDataFactory.createC3IntegrationsAndCase();
        ASF_TestDataFactory.createCaseRecords(3);
    }
    @isTest
    public static void ftrRegionalTest(){
        Id frameworkRecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        String cccId = [SELECT Id,CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c != null].CCC_External_Id__c;
        List<Case> cases = [SELECT ID,CCC_External_Id__c,Status,FTR__c FROM Case WHERE RecordTypeId=:frameworkRecordTypeId];
        for(case c : cases){
            ABSLI_Case_Detail__c detailRec = new ABSLI_Case_Detail__c();
			insert detailRec;
            c.Business_Unit__c = 'ABSLI';
            c.Status = 'New';
            c.FTR__c = true;
            c.MoveToNext__c = true;
            c.CCC_External_Id__c = cccId;
            c.ABSLI_Case_Detail__c = detailRec.Id;
        }
        String errorMessage = '';
        try{
        	update cases;    
        }catch(Exception ex){
        	errorMessage  = ex.getMessage();
        }
        //Assert.areNotEqual(cases[0].Status, 'New','Status should be resolved');
        System.assertEquals(true,errorMessage.contains('first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Update CBS'));
    }
}