/*********************************************************
*@Class        :  ABFL_OutstandingChargesController_Test
*@Author       :  Salesforce
*@Created Date :  12/04/2023
*@Last Modified:  
*@description  :  test class for ABFL_OutstandingChargesController
*********************************************************/
@isTest
public class ABFL_OutstandingChargesController_Test {
    @isTest
    static void testgetOutstandingCharges(){
        test.StartTest();
        ABFL_OutstandingChargesController.ResponseWrapper res = ABFL_OutstandingChargesController.getOutstandingCharges('ABRAILAP000000520505');
        System.assertNotEquals(null, res, 'response should not be null');
        test.StopTest();
    }
}