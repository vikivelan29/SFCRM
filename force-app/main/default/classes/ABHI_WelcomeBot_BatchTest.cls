/*********************************************************
*Class        :  ABHI_WelcomeBot_BatchTest
*Author       :  Aditee Churiwala
*Created Date :  04/11/2024
*Last Modified:  04/11/2024
*@description  :  Test Class for ABHI_WelcomeBot_Batch and ABHI_WelcomeBot_Queuable
*********************************************************/
@isTest
public class ABHI_WelcomeBot_BatchTest {
    static void setUpData(){
        
        Account accRec = ASF_TestDataFactory.insertBusinessAccount('Test_Cmp','Test_1');
        accRec.Is_Chronic__c = false;
        accRec.CMP_OPD__c = false;
        accRec.Chronic_care__c = false;
        update accRec;
        
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        Datetime testingday = Datetime.now().addDays(-2);
		Test.setCreatedDate(astRec.Id, testingday);
        
        astRec.LAN__c = '657644354';
        astRec.Business_Unit__c = ABHI_Constants.ABHI;
        astRec.Plan_Name__c = 'Diamond';
        astRec.ProductName__c = 'Activ Assure';
        astRec.BusinessType__c = 'New Business';
        update astRec; 
        
        Dispositions__c dis = new Dispositions__c(Disposition_L1__c = 'L1', Policy_Number__c = astRec.Id,
							Status__c = 'Failure', Call_Type__c = Label.ABHI_WelcomeBot);
        insert dis;
    }   
    @isTest
    static void testBatchableMethods() {
        setUpData();
        Test.startTest();
        String strBody = '{"message": "Message sent to SQS successfully","messageId": "cbba6bb5-04d5-40cd-9fc0-e939e408353f"}';
		Test.setMock(HttpCalloutMock.class, new ABHI_MockHttpResponseGenerator(200, strBody)); 
        Database.executeBatch(new ABHI_WelcomeBot_Batch());
		Integer count = [SELECT count() FROM Dispositions__c];
        System.assertEquals(1, count, 'disposition record created');
        Test.stopTest();
    }
    @isTest
    static void testBatchableMethodsException() {
        Test.startTest();
        String strBody = '{"error": "Error sending message to SQS"}';
            Test.setMock(HttpCalloutMock.class, new ABHI_MockHttpResponseGenerator(500, strBody)); 
        	new ABHI_WelcomeBot_Queuable('\t ').execute(null);
        Test.stopTest();
    }
    
}