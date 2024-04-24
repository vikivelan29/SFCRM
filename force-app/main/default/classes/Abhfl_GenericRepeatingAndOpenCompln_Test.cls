/****************************************************************************************************************
  * Author       - Anirudh Raturi
  * Date         - 08-Feb-2024
  * @LOB         - ABHFL
  * @description -  Test class for Abhfl_GenericRepeatingAndOpenComplntClas class.
*****************************************************************************************************************/

@isTest
public with sharing class Abhfl_GenericRepeatingAndOpenCompln_Test {

    /****************************************************
       * @description - Test Method for evaluate Method
    *****************************************************/
    @isTest 
    static void genericFetchQuery_TestMethod() {

        List<Case> sobJRec = (List<Case>) Abhfl_GenericRepeatingAndOpenComplntClas.genericFetchQuery('id', 'Case', '');
        System.assertEquals(sobJRec.size(), 0);
    }
}