/*********************************************************
*Class        :  ABHFL_Auto_Closure_Test
*Author       :  Anirudh Raturi
*Created Date :  18/11/2024
*Last Modified:  18/11/2024
*Description  :  Test Class for ABHFL_Auto_Closure
*********************************************************/

@isTest
public with sharing class ABHFL_Auto_Closure_Test {
   
    /****************************************************
     * @description - To setup test data for this test class
    *****************************************************/
    @testSetup
    static void setupTestData(){ 

        String inpputString1 = '2024-01-05T01:44:00.000Z';
        DateTime resultDateTime1 = DateTime.ValueofGmt(inpputString1.replace('T', ' '));

        ABHFL_Case_Detail__c caseDet1 = new ABHFL_Case_Detail__c();
        caseDet1.Payment_Link_Trigger_Time__c = resultDateTime1;

        insert caseDet1;

        Case case1 = new Case();
        case1.CCC_External_Id__c = 'hfl069';
        case1.ABHFL_Case_Detail__c = caseDet1.Id;

        insert case1;
    }

    @isTest
    static void ABHFL_Auto_Closure_Class(){

        Test.startTest();
            ABHFL_Auto_Closure ba = new ABHFL_Auto_Closure();
            Id jobid= Database.executeBatch(ba,5);
        Test.stopTest();

        List<Case> caseList = [SELECT id, ABHFL_Case_Detail__r.Payment_Link_Trigger_Time__c, Stage__c, Rejection_Reason__c FROM Case];

        for(Case cs : caseList) {
            String paymentLinkTriggerTime = String.valueOf(cs.ABHFL_Case_Detail__r.Payment_Link_Trigger_Time__c);
            if(paymentLinkTriggerTime == '2024-01-05T01:44:00.000Z') {
                system.assertEquals('Unresolved', cs.Stage__c);
                system.assertEquals('Closed as Exception', cs.Rejection_Reason__c);
            }
        }
    }
}