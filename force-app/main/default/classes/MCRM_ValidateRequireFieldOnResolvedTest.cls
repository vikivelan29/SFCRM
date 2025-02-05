/*********************************************************
*Class        :  MCRM_ValidateRequireFieldOnResolvedTest
*Author       :  Zahed
*Created Date :  10/18/2024
*Last Modified:
*Description  :  Test Class for MCRM_ValidateRequireFieldOnResolvedStage
*********************************************************/ 
@isTest
public class MCRM_ValidateRequireFieldOnResolvedTest {
    @TestSetup
    static void testData(){
        
        List<ASF_Case_Category_Config__c> caseCat = ABFL_TestDataFactory.createCaseCategoryConfig(true);
        caseCat[0].LOB__c = 'Corporate';
        update caseCat;
        
        List<ASF_Case_Stage_Config__c> caseStage = ABFL_TestDataFactory.createCaseStageConfigWithTwoStages(caseCat[0].Id, true);
        
        Account acc = new Account();
        acc.recordTypeId=[select id from RecordType where sobjectType='Account' and name='Individual'].Id;
        acc.LastName = '12345';
        acc.Office_Email__c = 'testAcc@123.com';
        acc.Phone = '444-010-4444';
        acc.PAN__c = 'ADNPN4241N';
        acc.Client_Code__c = '1234';
        insert acc;
        acc.Line_of_Business__c = 'Wellness';
        update acc;
        List<ABFL_Case_Detail__c> caseDetList = ABFL_TestDataFactory.createCaseDetail('Corporate', true);
        caseDetList[0].Resolution_Comments__c = '';
        caseDetList[0].Case_Categorisation__c = 'Incorrect';
        caseDetList[0].Financial_Impact__c = 'Yes';
        Update caseDetList;
        
        Id caseDetailId = caseDetList.isEmpty() ? null : caseDetList[0].Id;
        WellnessCaseDetail__c wellnessCaseDetailRec = new WellnessCaseDetail__c();
        wellnessCaseDetailRec.Resolution_Reason__c = 'Problem Solved';
        wellnessCaseDetailRec.Resolution_Comments__c = '';
        insert wellnessCaseDetailRec;
        system.debug(wellnessCaseDetailRec.Id);
        List<Case> caseList = ABFL_TestDataFactory.createCaseRecords(2, caseDetailId, false);
        caseList[0].Technical_Source__c = 'LWC';
        caseList[0].WellnessCaseDetail__c = wellnessCaseDetailRec.Id;
        insert caseList;
    }
    
    
    @isTest
    static void testValidateOnResolvedStage(){
        List<Case> caseRecord = [SELECT Id,Nature__c,Technical_Source__c,WellnessCaseDetail__r.Resolution_Comments__c,
                                 WellnessCaseDetail__r.Resolution_Reason__c,CCC_External_Id__c
                                 FROM Case];
        
        Test.startTest();
        MCRM_ValidateRequireFieldOnResolvedStage.beforeStageMovement(caseRecord);
        MCRM_ValidateRequireFieldOnResolvedStage.afterStageMovement(caseRecord);  
        Test.stopTest();        
    }
}