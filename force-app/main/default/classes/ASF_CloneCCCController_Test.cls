@isTest(seeAllData=false)
public class ASF_CloneCCCController_Test {

    @TestSetup
    public static void setupData(){
    	 ASF_TestDataFactory.createCaseCategoryConfig();   
        ASF_Case_Rule__c caseRuleRec = [select id from ASF_Case_Rule__c where Type__c='Work' LIMIT 1];
        Id cccId = [select Id from ASF_Case_Category_Config__c LIMIT 1].Id;
        ASF_Work_Item__c stage2_Work_WorkItem = new ASF_Work_Item__c();
        stage2_Work_WorkItem.Task_Title__c = 'Service Request - Clarification from DEBIT';
        stage2_Work_WorkItem.Task_Description__c = 'Check the accuracy of the Credit report submitted to bureau for Ownership Dispute';
        stage2_Work_WorkItem.Completion_Time__c = 3;
        stage2_Work_WorkItem.Case_Rule__c= caseRuleRec.Id;
        stage2_Work_WorkItem.Work_Item_External_ID__c='Workitem-CIBIL-OD-W012';
        
        insert stage2_Work_WorkItem;
        
        List<ASF_Case_Field_Config__c> fieldConfigs = new List<ASF_Case_Field_Config__c>();
        ASF_Case_Field_Config__c field1 = new ASF_Case_Field_Config__c();
        field1.Case_Main_Config__c = cccId;
        field1.ObjectAPIName__c = 'Case';
        field1.FieldAPIName__c = 'Description';
        field1.Display_Order__c = 1;
        fieldConfigs.add(field1);
        ASF_Case_Field_Config__c field2 = new ASF_Case_Field_Config__c();
        field2.Case_Main_Config__c = cccId;
        field2.ObjectAPIName__c = 'PAY_Payment_Detail__c';
        field2.FieldAPIName__c = 'Payment_mode__c';
        field2.Display_Order__c = 2;
        fieldConfigs.add(field2);
        insert fieldConfigs;
    }
    
    @isTest
    private static void searchConfigTest() {
        Test.startTest();
        String result = ASF_CloneCCCController.searchConfig('Typetest','Subtype');
        Assert.areEqual('Success', result, 'result should be Success'); 
        Test.stopTest();     
    }
    @isTest
    private static void cloneConfigDataTest() {
        Test.startTest();
        ASF_Case_Category_Config__c caseCatConfig = [select Id from ASF_Case_Category_Config__c LIMIT 1];
        ASF_CloneCCCController_Mocktest mock = new ASF_CloneCCCController_Mocktest();
        Test.setMock(HttpCalloutMock.class, mock);
        Map<String,String> result = ASF_CloneCCCController.cloneConfigData(caseCatConfig.Id,'Typetest','Subtype');
        Test.stopTest();     
    }
    @isTest
    private static void graphResponseTest() {
        Test.startTest();
        String jsonString = '{ "graphs": [ { "graphId": "1", "graphResponse": { "compositeResponse": [ { "body": [ { "errorCode": "PROCESSING_HALTED", "message": "The transaction was rolled back since another operation in the same transaction failed." } ], "httpHeaders": {}, "httpStatusCode": 400, "referenceId": "refCategoryConfig" } ] }, "isSuccessful": true } ] }';
        ASF_GraphResponse result = ASF_GraphResponse.parse(jsonString);       
        // Assert that the result is not null
        System.assertNotEquals(null, result);
        Test.stopTest();     
    }
}