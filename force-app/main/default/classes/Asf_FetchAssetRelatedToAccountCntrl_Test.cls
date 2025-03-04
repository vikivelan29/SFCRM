/****************************************************************************************************************
  * Author           - Salesforce
  * Date             - 01-November-2023
  * @LOB - ABHFL
  * @Description -  Test class for Asf_FetchAssetRelatedToAccountController class.
  *****************************************************************************************************************/
@SuppressWarnings('PMD.MethodNamingConventions')
@isTest
public with sharing class Asf_FetchAssetRelatedToAccountCntrl_Test {

    @testSetup
    static void setupTestData(){

       Id recordTypeId =Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
       Account objAccount = new Account();
       objAccount.FirstName = 'TestFirstName';
       objAccount.LastName  = 'TestFirstName';
       objAccount.Line_of_Business__c = 'ABHFL';
       objAccount.RecordTypeId = recordTypeId;
       insert objAccount;
        
       Asset asst = new Asset();
       asst.accountId = objAccount.Id;
       asst.Loan_Amount__c = 130000000;
       asst.Scheme__c = 'Test Scheme ';
       asst.Last_Disbursement_Date__c = Date.Today().addDays(1);
       asst.Aggrement_Date__c = Date.Today().addDays(-1);
       asst.Application_Number__c = '12345';
       asst.Approved_Date__c = Date.Today();
       asst.Approved_Limit__c = 1344455444;
       asst.Branch_Code__c = '0033';
       asst.Name = 'Test Asset';

       insert asst;
        
       LAN_Mapping__c lnMapp = new LAN_Mapping__c();
       lnMapp.LAN__c = asst.Id;
       lnMapp.Customer__c = objAccount.Id;
       
       insert lnMapp;
    }
    /****************************************************
     * @Description - Test Method to test the fetchAssets Method
    *****************************************************/
    @isTest 
    static void fetchAssets_Test_Method() {

        Account acct = [Select Line_of_Business__c FROM Account WHERE FirstName = 'TestFirstName'];
        
        Test.startTest();
			Asf_FetchAssetRelatedToAccountController.Asf_FetchAssetRelatedToAccountControllerWrapper obj = Asf_FetchAssetRelatedToAccountController.fetchAssets(acct.Id);
        	System.assertEquals(1, obj.assetRecords.size());
        Test.stopTest();
    }

}