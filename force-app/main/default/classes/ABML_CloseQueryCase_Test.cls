/**
* @description       : Test Class for ABML_CloseQueryCase
* @author            : saravpreet.arora@in.ey.com
* @group             : 
* @last modified on  : 
* @last modified by  : 
* Modifications Log
* Ver   Date         Author                       Modification
* 1.0   25/11/2024   Saravpreet Arora             Initial Version
**/
@isTest
public class ABML_CloseQueryCase_Test {
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    @TestSetup
    static void makeData(){
        User objUser = new User(Alias = 'user'  , Email = 'standarduser@testorg.com', EmailEncodingKey = 'UTF-8', LastName = 'Test', LanguageLocaleKey = 'en_US', 
                                LocaleSidKey = 'en_US', ProfileId = SYSTEMADMIN_PROFILE.Id, TimeZoneSidKey = 'America/Los_Angeles', Username = 'testUserAbml@gmail.com',
                                Business_Unit__c = 'ABML', IsActive = true);
        insert objUser;
        Id CaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Framework').getRecordTypeId();
        System.runAs(objUser) {
            List<Case> listOfCases = new List<Case> ();
            for(Integer caseCount = 0 ; caseCount <= 5 ; caseCount++)
            {
                Case caseRecord = new Case(Business_Unit__c = 'ABML', Nature__c = 'Query', Channel__c = 'Inbound Call', RecordTypeId = CaseRecordTypeId);
                listOfCases.add(caseRecord);
            } 
            Test.startTest();
            insert listOfCases;
			Test.stopTest();            
        }
        
    }
    @isTest
    static void prepopulateCaseFldsTest() {
        
        User objUser = [SELECT Id, Name FROM User WHERE Business_Unit__c = 'ABML' LIMIT 1];
        System.runAs(objUser){            
            
            List<Case> caseList = [SELECT Id, Business_Unit__c, Nature__c, Channel__c  FROM Case LIMIT 6];   
            Case updatedCase = [SELECT Stage__c, Status FROM Case LIMIT 1];
            System.assertEquals('Resolved', updatedCase.Stage__c, 'Stage should be resolved');
            System.assertEquals('Resolved', updatedCase.Status, 'Status should be resolved');
        }
    }
}