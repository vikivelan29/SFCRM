/*
*********************************************************
Apex Class Name    : ASF_CustomerEmailInvocable_Test
Created Date       : 16 Jan 2024
@description       : This class is used for Supression Logic Test Classes. Covered Classes - 
				   : ASF_CustomerEmailInvocable, ABFL_SuppressEmailHelper
@author            : Virendra Patil
Modification Log:
Ver   Date         Author                               Modification
1.0   16 Jan 2024   Virendra Patil                      Initial Version
*********************************************************
*/
@SuppressWarnings('PMD.MethodNamingConventions')
@isTest
public class ASF_CustomerEmailInvocable_Test {
    @TestSetup
    static void makeData(){
        Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
        ASF_TestDataFactory.createC3IntegrationsAndCase();
        ASF_TestDataFactory.createCaseRecords(3);
    }
    @isTest
    public static void getEmailTemplateNameTest(){
        Id frameworkRecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        
        List<Case> cases = [SELECT ID,CCC_External_Id__c FROM Case WHERE RecordTypeId=:frameworkRecordTypeId];
        if(cases.size()>0){
            List<ASF_Case_Category_Config__c> cccRecords = [SELECT ID,Business_Unit__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c =:cases[0].CCC_External_Id__c];
            List<ASF_CustomerEmailInvocable.EmailInputWrapper> wrappers = new List<ASF_CustomerEmailInvocable.EmailInputWrapper>();
            ASF_CustomerEmailInvocable.EmailInputWrapper wrapper = new ASF_CustomerEmailInvocable.EmailInputWrapper();
            wrapper.caseId = cases[0].Id;
            wrapper.caseStatus = 'Resolved';
            wrapper.cccRecord = cccRecords[0];
            wrapper.templateName = 'Generic_SR_Created';
            wrappers.add(wrapper);
            
            ASF_CustomerEmailInvocable.getEmailTemplateName(wrappers);
        }
    }
    
    @isTest
    public static void ABFL_SuppressEmailHelperTest(){
        Id frameworkRecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        
        List<Case> cases = [SELECT ID,CCC_External_Id__c FROM Case WHERE RecordTypeId=:frameworkRecordTypeId];
        for(case c : cases){
            c.Business_Unit__c = 'ABFL';
            c.Source__c = 'RM-No Email';
        }
        ASF_TriggerSkipperUtility.markTriggerRun('Case');
        update cases;
        
        if(cases.size()>0){
            List<ASF_Case_Category_Config__c> cccRecords = [SELECT ID,Business_Unit__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c =:cases[0].CCC_External_Id__c];
            for(ASF_Case_Category_Config__c ccc : cccRecords){
                ccc.Business_Unit__c = 'ABFL';
            }
            List<ASF_CustomerEmailInvocable.EmailInputWrapper> wrappers = new List<ASF_CustomerEmailInvocable.EmailInputWrapper>();
            ASF_CustomerEmailInvocable.EmailInputWrapper wrapper = new ASF_CustomerEmailInvocable.EmailInputWrapper();
            wrapper.caseId = cases[0].Id;
            wrapper.caseStatus = 'Resolved';
            wrapper.cccRecord = cccRecords[0];
            wrapper.templateName = 'Generic_SR_Created';
            wrappers.add(wrapper);
            
            List<ASF_CustomerEmailInvocable.EmailOutputWrapper> outputWrappers = ASF_CustomerEmailInvocable.getEmailTemplateName(wrappers);
            System.assertEquals(outputWrappers[0].supressEmail,true,'Supression Logic working as expected');
            
            
        }
    }
    @isTest
    public static void ABSLI_FtrRegionalTest(){
        Id frameworkRecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        
        List<Case> cases = [SELECT ID,CCC_External_Id__c FROM Case WHERE RecordTypeId=:frameworkRecordTypeId];
        for(case c : cases){
            c.Business_Unit__c = 'ABSLI';
            c.FTR__c = false;
        }
        ASF_TriggerSkipperUtility.markTriggerRun('Case');
        update cases;
        
        if(cases.size()>0){
            List<ASF_Case_Category_Config__c> cccRecords = [SELECT ID,Business_Unit__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c =:cases[0].CCC_External_Id__c];
            for(ASF_Case_Category_Config__c ccc : cccRecords){
                ccc.Business_Unit__c = 'ABSLI';
            }
            List<ASF_CustomerEmailInvocable.EmailInputWrapper> wrappers = new List<ASF_CustomerEmailInvocable.EmailInputWrapper>();
            ASF_CustomerEmailInvocable.EmailInputWrapper wrapper = new ASF_CustomerEmailInvocable.EmailInputWrapper();
            wrapper.caseId = cases[0].Id;
            wrapper.caseRecord = cases[0];
            wrapper.caseStatus = 'New';
            wrapper.cccRecord = cccRecords[0];
            wrapper.templateName = 'Email_Template_Sample';
            wrapper.LanguagePreference = 'Hindi';
            wrapper.SmsTemplateName = 'SMS_Template_Sample';
            wrapper.emailFieldName = 'New_Case_Email_Template__c';
            wrapper.SmsFieldName = 'New_Case_SMS_Metadata__c';
            wrappers.add(wrapper);
            
            List<ASF_CustomerEmailInvocable.EmailOutputWrapper> outputWrappers = ASF_CustomerEmailInvocable.getEmailTemplateName(wrappers);      
        }
    }

    
}