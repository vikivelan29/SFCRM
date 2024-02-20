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
}