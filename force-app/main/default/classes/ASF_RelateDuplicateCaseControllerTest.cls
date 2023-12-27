/******************************************************  
* Author           - Salesforce
* Date             - 01-Dec-2023
* Description      - Test class for ASF_RelateDuplicateCaseController
********************************************************
*/

@isTest
public class ASF_RelateDuplicateCaseControllerTest {

    @testSetup
    static void setUpData(){
        ASF_TestDataFactory.createCaseRecords(1);
        ASF_TestDataFactory.insertBusinessAccount('Test Relate','');
    }
    
    @isTest
    static void updateCaseParentTest(){
        Test.startTest();
        Id accountId = [select Id FROM account LIMIT 1].Id;
        List<case> caseList = new List<case>();
        for(Case caseRec : [select Id, accountId, parentId, Is_Duplicate__c from case]){
            caseRec.accountId = accountId;
            caseList.add(caseRec);
        }
        
        String result = ASF_RelateDuplicateCaseController.updateCaseParent(caseList[0].Id, caseList[0].parentId, true);
        Assert.areEqual(result, 'Success');
        Test.stopTest();
    }
}