@isTest
public with sharing class ABHFL_OtherRefundOnResolvedStage_Test {
    
    @TestSetup
    static void testData(){
       
        ASF_TestDataFactory.createCaseCategoryConfig();

        //Create Case
        Case newCase = new Case();
        newCase.CCC_External_Id__c = 'RWRORHFC';
        newCase.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        insert newCase; 
    }

    @IsTest
    static void beforeStageMovementTest(){
        ABHFL_OtherRefundOnResolvedStage otherRefundOnResolvedStageClass = new ABHFL_OtherRefundOnResolvedStage();

        List<ASF_Case_Category_Config__c> lstCaseCategory = [SELECT Additional_Email_Templates__c
                                                            FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c = 'CCC-CC-CCLTD-01'];
        lstCaseCategory[0].CCC_External_Id__c = 'RWRORHFC';
        update lstCaseCategory;   
                                                
        Case caseRecord = [SELECT Id, ABHFL_Case_Detail__r.Impact__c, Asset.Loan_Disbursement_Status__c, CCC_External_Id__c, Stage__c 
                            FROM Case];

        otherRefundOnResolvedStageClass.beforeStageMovement(new List<Case>{caseRecord});
    }

    @IsTest
    static void afterStageMovementTest(){
        
        ABHFL_OtherRefundOnResolvedStage otherRefundOnResolvedStageClass = new ABHFL_OtherRefundOnResolvedStage();

        Case caseRecord = [SELECT Id, ABHFL_Case_Detail__r.Impact__c, Asset.Loan_Disbursement_Status__c, CCC_External_Id__c, Stage__c 
                            FROM Case];

        otherRefundOnResolvedStageClass.afterStageMovement(new List<Case>{caseRecord});
    }
}