/******************************************************  
* Author           - Salesforce
* Date             - 14-Dec-2023
* Description      - Test class for ASF_CaseEditPageController
********************************************************
*/
@isTest
public class ASF_CaseEditPageController_Test {

    @testSetup
    static void setUpData(){
        ASF_TestDataFactory.createCaseRecords(1);
    }
    
    @isTest
    static void updateCaseParentTest(){
        Test.startTest();
        Id caseId = [select Id, accountId, parentId, Is_Duplicate__c from case LIMIT 1].Id;
        
        Map<String, String> result = ASF_CaseEditPageController.getfieldSetFieldsWithValues('ASF_Editable_Fields', 'Case', caseId);
        Assert.isTrue(!result.isEmpty());
        Test.stopTest();
    }
}