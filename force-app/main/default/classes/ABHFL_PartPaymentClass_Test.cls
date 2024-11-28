/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 06-23-2024
 * @last modified by  : rsinghnagar@salesforce.com 
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   06-23-2024   rsinghnagar@salesforce.com   Initial Version
**/
@isTest
public with sharing class ABHFL_PartPaymentClass_Test { 

    @TestSetup
    static void testData(){
        
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('ABHFLLLL','Test_1');

        //Create Asset
        Asset astRec = new Asset();
        astRec.Name = 'Test';
        astRec.Lan__c = 'LAXXXXXX01';
        astRec.Loan_Disbursement_Status__c = 'Partially';
        astRec.AccountId = accRec.Id;
        insert astRec;

        //Create Case Extension record
        ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
        caseDetail.Impact__c = 'Tenure';
        insert caseDetail;
       
        //Create Case
        Case newCase = new Case();
        newCase.CCC_External_Id__c = 'qbccdd01';
        newCase.RecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        newCase.AssetId = astRec.Id;
        newCase.ABHFL_Case_Detail__c = caseDetail.Id;
        newCase.Stage__c = 'CPU Banking';
        insert newCase;
        
    }

    @IsTest
    static void beforeStageMovementTest(){
        ABHFL_PartPaymentClass partPaymentClass = new ABHFL_PartPaymentClass();
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> returnWrapper = new Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper>();
        returnWrapper = partPaymentClass.beforeStageMovement(new List<Case>());
    }

    @IsTest
    static void afterStageMovementTest(){
        
        ABHFL_PartPaymentClass partPaymentClass = new ABHFL_PartPaymentClass();
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> returnWrapper = new Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper>();

        Case caseRecord = [SELECT Id, ABHFL_Case_Detail__r.Impact__c, Asset.Loan_Disbursement_Status__c, CCC_External_Id__c, Stage__c 
                            FROM Case];

        returnWrapper = partPaymentClass.afterStageMovement(new List<Case>{caseRecord});
        ASF_CaseMovementHelper.CaseStageValidationWrapper returnWrapperObj = returnWrapper.get(caseRecord.Id); 
        System.assertEquals(returnWrapperObj.errorMessage,System.Label.Impact_Field_Error);
    }
}