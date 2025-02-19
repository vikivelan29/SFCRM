/**
 * @description       : Test Class for ABHI_KavachPolicies
 * @author            : Aditee Churiwala
 * @group             : 
 * @last modified on  : 01/11/2024
 * @last modified by  : Aditee Churiwala
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   12-22-2023   achuriwala@salesforce.com   Initial Version
**/
@isTest
public class ABHI_KavachPolicies_Test {
    /**
   * @description Test Data Setup for this Test Class
   */
    @testSetup
    static void setupTestData() {
         Account accRec = ASF_TestDataFactory.insertBusinessAccount('Test_Cmp','Test_1');
        accRec.Is_Chronic__c = true;
        accRec.CMP_OPD__c = true;
        accRec.Chronic_care__c = false;
        update accRec;
        
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        Datetime testingday = Datetime.now().addDays(-2);
		Test.setCreatedDate(astRec.Id, testingday);
        
        astRec.LAN__c = '31-24-0004016-22';
        astRec.Business_Unit__c = ABHI_Constants.ABHI;
        astRec.Plan_Name__c = 'Max+';
        astRec.ProductName__c = 'Active One';
        update astRec; 
        
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Policy_Number__c  = '31-24-0003333-00';
        caseInt.Integration_Ext_Id__c = 'Int1';
        caseInt.Status__c = 'Pending';
        caseInt.Type__c = 'Kavach';
        insert caseInt;
    }  
    /**
   * @description  getPolicyExternalData
   */
    @isTest static void testKavachPolicyCallout() {
        Test.startTest();
        ABHI_KavachPolicies.getPolicyExternalData('31-24-0003333-00','');
        ABHI_KavachPolicies.getPolicyData('31-24-0003333-00');
        ABHI_KavachPolicies.getPolicyData('31-24-0004016-22');
        ABHI_KavachPolicies.getPolicyData('31-24-22');
        Test.stopTest();
    }
    /**
   * @description Exception
   */
    @isTest static void testKavachPolicyCalloutException() {
        Test.startTest();
        ABHI_KavachPolicies.getPolicyExternalData(null,'');
        ABHI_KavachPolicies.getPolicyData(null);
        Test.stopTest();
    }
}
