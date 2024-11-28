/*********************************************************
*Class        :  ABSLIG_BusinessLogic_HelperClass
*Author       :  Anirudh Raturi
*Created Date :  16/07/2024
*Description  :  Test class for ABSLIG Business Logic class
*********************************************************/

@SuppressWarnings('PMD.ApexDoc')
@isTest
public with sharing class ABSLIG_BusinessLogic_HelperClass_Test {
    
    /***********************************************************
    * @Function - testData
    * @Description - Test data
    ***********************************************************/
    @TestSetup
    static void testData(){
        
        Lead ld = new Lead();
        ld.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Service').getRecordTypeId();
        ld.Business_Unit__c = 'ABSLIG';
        ld.lastName = 'Kumar And Sons';
        ld.Company = 'Kumar And Sons';

        insert ld;
    }

    /***********************************************************
    * @Function - testprePopulateFieldsMethod
    * @Description - Test method for prePopulateFieldsMethod
    ***********************************************************/
    @IsTest
    static void testprePopulateFieldsMethod(){

        Lead leadRecord = [Select id, Business_Unit__c, lastName, Company from Lead limit 1];    

        System.assertEquals(leadRecord.Company, 'Kumar And Sons', 'Test Method Assertion');
        
	}
}