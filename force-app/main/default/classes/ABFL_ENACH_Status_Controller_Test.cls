@isTest
public class ABFL_ENACH_Status_Controller_Test {
    @isTest
    static void testgetENACHStatus(){
        test.StartTest();
        ABFL_ENACH_Status_Controller.ResponseWrapper res = ABFL_ENACH_Status_Controller.getENACHStatus('19531');
        System.assertNotEquals(null, res, 'response should not be null');
    }
}