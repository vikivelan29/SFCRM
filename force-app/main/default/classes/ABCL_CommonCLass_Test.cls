/****************************************************************************************************************
  * Author       - Anirudh Raturi
  * Date         - 19-Feb-2024
  * @LOB         - Common class for all LOB
  * @description -  Test class for ABCL_CommonCLass class.
*****************************************************************************************************************/

@isTest
public with sharing class ABCL_CommonCLass_Test {
    
    /****************************************************
    * @description - To setup test data for this test class
    *****************************************************/
    @testSetup
    static void setupTestData(){

        Case cs = new Case();
        cs.Business_Unit__c = 'ABHFL';
        insert cs;
    }

    /****************************************************
     * @description - Test Method for prepopulateCaseFlds Method
    *****************************************************/
    @isTest 
    static void prepopulateCaseFldsTestMethod() {
        
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