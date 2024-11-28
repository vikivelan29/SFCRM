/*********************************************************
*Class        :  ASF_CaseE2CHelper_Test
*Author       :  Dhineshkumar Teekaraman
*Description  :  Test class for ASF_CaseE2CHelper
*********************************************************/
@isTest
public class ASF_CaseE2CHelper_Test {
    @isTest
    static void testBlockCases() {
        //with subject which has exclusion subject keyword.
        List<Configuration__c> testConfigs = new List<Configuration__c>();
        Id Blockerid = Schema.SObjectType.Configuration__c.getRecordTypeInfosByName().get('Exclusion Subject').getRecordTypeId();
        testConfigs.add(new Configuration__c(ExclusionSubjectKeyword__c = 'Test1', Active__c = true,RecordTypeId=Blockerid));
        insert testConfigs;
        String errorMessage = 'Email having subject keyword';

        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                           Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                           Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
        
        try{
        List<Case> testCases = new List<Case>();
        Id interactionId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Interaction').getRecordTypeId();
        testCases.add(new Case(Subject = 'Test1', Origin = 'Email',RecordTypeId = interactionId));
        ASF_CaseE2CHelper.setBusinessUnitValue(testCases);
        //ASF_CaseE2CHelper.blockOOOCases(testCases);
        insert testCases;
        
	
        }
        catch(Exception e)
        {
            String message = e.getMessage();
            system.debug(message);
            system.assert(message.contains('Email having subject keyword'),'message=' + message);
        }
    }

        
        
     @isTest
    static void testBlockCases2() {
        //without subject
        List<Configuration__c> testConfigs = new List<Configuration__c>();
        Id Blockerid = Schema.SObjectType.Configuration__c.getRecordTypeInfosByName().get('Exclusion Subject').getRecordTypeId();
        testConfigs.add(new Configuration__c(ExclusionSubjectKeyword__c = 'Test1', Active__c = true,RecordTypeId=Blockerid));
        insert testConfigs;

        insert new SLA_Threshold_Warning__c(Case_SLA_Threshold_1__c = 0.5, Case_SLA_Threshold_2__c = 0.7,
                                           Case_SLA_Threshold_3__c = 0.8, Stage_SLA_Threshold_1__c = 0.5,
                                           Stage_SLA_Threshold_2__c = 0.7, Stage_SLA_Threshold_3__c = 0.6);
        
        try{
        Test.startTest();
        List<Case> testCases = new List<Case>();
        Id interactionId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Interaction').getRecordTypeId();
        testCases.add(new Case(Subject = '', Origin = 'Email',RecordTypeId = interactionId));
        insert testCases;
        List<Case> insertedCases = [SELECT Id, Subject, Origin FROM Case WHERE RecordTypeId = :interactionId];
        System.assertNotEquals(0, insertedCases.size(), 'Case record not inserted successfully');
        System.assertEquals(null, insertedCases[0].Subject, 'Subject should be empty');    
        Test.stopTest();
        }
        catch(Exception e){
            
        }
        
              
    }


}