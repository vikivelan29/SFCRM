/****************************************************************************************************************
  * Author       - Anirudh Raturi
  * Date         - 16-July-2024
  * @description -  Test class for ABCL_CommonCLass class.
*****************************************************************************************************************/

@isTest
public with sharing class ABCL_CommonCLass_Test {
    
    /****************************************************
    * @description - To setup test data for this test class
    *****************************************************/
    @testSetup
    static void setupTestData(){

        // Insert Cases
        List<Case> caseList = new List<Case>();
        caseList.add(new Case(Business_Unit__c = 'ABFL', Stage__c = 'Open'));
        caseList.add(new Case(Business_Unit__c = 'ABWM', Stage__c = 'Open'));
        caseList.add(new Case(Business_Unit__c = 'Payments', Stage__c = 'Open'));
        caseList.add(new Case(Business_Unit__c = 'ABSLIG', Stage__c = 'Open'));
        insert caseList;
    }

    /****************************************************
     * @description - Test Method for prepopulateCaseFlds Method
    *****************************************************/
    @isTest
    static void testPrepopulateCaseFlds() {

      // Fetch Cases
      List<Case> caseList = [SELECT Id, Business_Unit__c FROM Case];

      // Test prepopulateCaseFlds method
      ABCL_CommonCLass commonClass = new ABCL_CommonCLass();
      commonClass.prepopulateCaseFlds(caseList);

      // Fetch updated Cases
      caseList = [SELECT Id, BusinessHoursId, Business_Unit__c FROM Case];

      // Validate BusinessHoursId is populated based on Business Unit
      for (Case cs : caseList) {
          if (cs.Business_Unit__c == 'ABFL' || cs.Business_Unit__c == 'ABWM') {
              System.assertNotEquals(null, cs.BusinessHoursId, 'Null');
          }
      }
    }

    @isTest
    static void testPopulateResolutionCommentOnCaseDetail() {
     
      Map<Id, Case> oldMap = new Map<Id, Case>([SELECT Id, Stage__c FROM Case]);

      // Insert Case Detail records
      ABFL_Case_Detail__c abflDetail = new ABFL_Case_Detail__c(Bank_Name__c = 'SBI');
      ABHFL_Case_Detail__c abhflDetail = new ABHFL_Case_Detail__c(Bank_IFSC_Code__c = 'BOB123');
      insert new List<SObject>{abflDetail, abhflDetail};

      // Fetch Cases
      List<Case> caseList = [SELECT Id, ABFL_Case_Detail__c, 
                              ABHFL_Case_Detail__c, Business_Unit__c FROM Case];
      for (Case cs : caseList) {
          cs.Stage__c = 'Resolved';
          if (cs.Business_Unit__c == 'ABFL') {
              cs.ABFL_Case_Detail__c = abflDetail.Id;
              cs.Resolution_Comments__c = 'Resolved ABFL Case';
          } else if (cs.Business_Unit__c == 'ABWM') {
              cs.ABHFL_Case_Detail__c = abhflDetail.Id;
              cs.Resolution_Comments__c = 'Resolved ABHFL Case';
          }
      }
      update caseList;

      // Test populateResolutionCommentOnCaseDetail method
      Test.startTest();
      ASF_BulkCaseProcessorUtility.isBulkProcessing =true;
      ABCL_CommonCLass.populateResolutionCommentOnCaseDetail(caseList, oldMap);
      Test.stopTest();

      // Fetch updated Case Details
      abflDetail = [SELECT Id, Resolution_Comments__c FROM ABFL_Case_Detail__c WHERE Id = :abflDetail.Id];
      abhflDetail = [SELECT Id, Resolution_Remarks__c FROM ABHFL_Case_Detail__c WHERE Id = :abhflDetail.Id];

      // Validate Resolution Comments/Remarks are updated
      System.assertEquals('Resolved ABFL Case', abflDetail.Resolution_Comments__c, 'Resolved ABFL Case');
      System.assertEquals('Resolved ABHFL Case', abhflDetail.Resolution_Remarks__c, 'Resolved ABHFL Case');
    }

    @isTest
    static void testBypassValidation() {
      Test.startTest();
      boolean result = ABCL_CommonCLass.bypassValidation();
      Test.stopTest();

      // Validate bypass validation logic
      System.assertEquals(false, result, 'false');
    }

    @SuppressWarnings('PMD.UnusedLocalVariable')
    @isTest
    static void testCalculateSlaOverwriteIdentifier() {

      ABCL_CommonCLass abclCommonCLassObj = new ABCL_CommonCLass();

      String result1 = abclCommonCLassObj.calculateSlaOverwriteIdentifier(945);
      
      String result2 = abclCommonCLassObj.calculateSlaOverwriteIdentifier(980);

      String result3 = abclCommonCLassObj.calculateSlaOverwriteIdentifier(1050);

      String result4 = abclCommonCLassObj.calculateSlaOverwriteIdentifier(1100);

      String result5 = abclCommonCLassObj.calculateSlaOverwriteIdentifier(1160);

      String result6 = abclCommonCLassObj.calculateSlaOverwriteIdentifier(1220);

      String result7 = abclCommonCLassObj.calculateSlaOverwriteIdentifier(1280);
      // Validate bypass validation logic
      System.assertEquals('8', result7, '8');
    }
}