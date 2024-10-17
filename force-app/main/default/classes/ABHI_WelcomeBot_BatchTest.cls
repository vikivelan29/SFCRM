/*********************************************************
*Class        :  ABHI_ViewPolicyInformation_Cntrl_Test
*Author       :  Anirudh Raturi
*Created Date :  02/00/2024
*Last Modified:  02/00/2024
*@description  :  Test Class for ABHI_ViewPolicyInformation_Controller
*********************************************************/
@isTest
public class ABHI_WelcomeBot_BatchTest {
	 @testSetup
    static void setUpData(){
        
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('Test_Cmp','Test_1');
        accRec.Is_Chronic__c = true;
        accRec.CMP_OPD__c = true;
        accRec.Chronic_care__c = false;
        update accRec;
        
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        Datetime testingday = Datetime.now().addDays(-2);
		Test.setCreatedDate(astRec.Id, testingday);
        
        astRec.LAN__c = '657644354';
        astRec.Business_Unit__c = ABHI_Constants.ABHI;
        astRec.Plan_Name__c = 'Max+';
        astRec.ProductName__c = 'Active One';
        update astRec; 
        
        
        Dispositions__c dis = new Dispositions__c(Disposition_L1__c = 'L1', Policy_Number__c = astRec.Id,
							Status__c = 'Failure');
        insert dis;
    }   
      @isTest
    static void testBatchableMethods() {

        Test.startTest();
        
        Database.executeBatch(new ABHI_WelcomeBot_Batch());
		Integer count = [SELECT count() FROM Dispositions__c];
        System.assertEquals(1, count, 'disposition record created');
        Test.stopTest();
    }
    
}
