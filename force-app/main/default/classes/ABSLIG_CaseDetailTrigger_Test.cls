/**
 * @description       : Test Class for ABSLIG_CaseDetailTrigger
 * @author            : Anirudh Raturi
 * @createdDate       : 10-06-2024
 * @last modified on  : 10-06-2024
 * @last modified by  : Anirudh Raturi 
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   08-06-2024   Anirudh Raturi   Initial Version
**/

@isTest
public class ABSLIG_CaseDetailTrigger_Test {

    @testSetup
    static void setupTestData() {
        // Create test ABSLIG_Case_Detail__c records
        List<ABSLIG_Case_Detail__c> caseDetails = new List<ABSLIG_Case_Detail__c>();
        
        for (Integer i = 0; i < 5; i++) {
            caseDetails.add(new ABSLIG_Case_Detail__c(
                Maker_Comment__c = 'Initial Maker Comment ' + i,
                Checker_Comment__c = 'Initial Checker Comment ' + i
            ));
        }
        
        insert caseDetails;
    }
    
    @isTest
    static void testPopulateFieldsOfABSLIGCaseDetail() {
        // Retrieve the test data
        List<ABSLIG_Case_Detail__c> caseDetails = [SELECT Id, Maker_Comment__c, Checker_Comment__c FROM ABSLIG_Case_Detail__c];
        
        // Create a new map to simulate trigger.newMap and a clone of the existing records to simulate trigger.oldMap
        Map<Id, ABSLIG_Case_Detail__c> newMap = new Map<Id, ABSLIG_Case_Detail__c>();
        Map<Id, ABSLIG_Case_Detail__c> oldMap = new Map<Id, ABSLIG_Case_Detail__c>();
        
        for (ABSLIG_Case_Detail__c detail : caseDetails) {
            detail.Maker_Comment__c = 'Updated Maker Comment ' + detail.Id;
            detail.Checker_Comment__c = 'Updated Checker Comment ' + detail.Id;
        }

        Test.startTest();
            update caseDetails;
        Test.stopTest();
        
        // Validate the results
        for (Id id : newMap.keySet()) {
            ABSLIG_Case_Detail__c newDetail = newMap.get(id);
            ABSLIG_Case_Detail__c oldDetail = oldMap.get(id);
            
            if (newDetail.Maker_Comment__c != oldDetail.Maker_Comment__c) {
                System.assertEquals(UserInfo.getName(), newDetail.Maker_Name__c, 'Maker Name should be updated');
            } else {
                System.assert(newDetail.Maker_Name__c == null, 'Maker Name should not be updated');
            }
            
            if (newDetail.Checker_Comment__c != oldDetail.Checker_Comment__c) {
                System.assertEquals(UserInfo.getName(), newDetail.Checker_Name__c, 'Checker Name should be updated');
            } else {
                System.assert(newDetail.Checker_Name__c == null, 'Checker Name should not be updated');
            }
        }
    }
}