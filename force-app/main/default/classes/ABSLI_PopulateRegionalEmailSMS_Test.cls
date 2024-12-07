@isTest
public class ABSLI_PopulateRegionalEmailSMS_Test {

    @TestSetup
    static void makeData(){
        Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
        ASF_TestDataFactory.createC3IntegrationsAndCase();
        ASF_TestDataFactory.createCaseRecords(3);
    }
    
    @isTest
    public static void absliFtrRegionalTest(){
        Id frameworkRecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        
        List<Case> cases = [SELECT ID,CCC_External_Id__c,Status,FTR__c FROM Case WHERE RecordTypeId=:frameworkRecordTypeId];
        for(case c : cases){
            c.Business_Unit__c = 'ABSLI';
            c.Status = 'New';
            c.FTR__c = true;
        }
        ASF_TriggerSkipperUtility.markTriggerRun('Case');
        update cases;
        
        
        if(cases.size()>0){
            List<ASF_Case_Category_Config__c> cccRecords = [SELECT ID,Business_Unit__c,Send_FTR_communications__c,FTR_SMS_Metadata__c,FTR_Email_Template__c
                                                            FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c =:cases[0].CCC_External_Id__c];
            for(ASF_Case_Category_Config__c ccc : cccRecords){
                ccc.Business_Unit__c = 'ABSLI';
                ccc.Send_FTR_communications__c = true;
            }
            ASF_Case_Email_Config__c  regRec = new ASF_Case_Email_Config__c(Type__c = 'Regional Template',Language__c = 'Hindi', Case_Category_Config__c = cccRecords[0].Id,
                                                                                       FTR_Email_Template__c = 'Hindi_Template', Regional_Template_External_ID__c = 'REG-HINDI-TEST');
            insert regRec;
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
            for(case c : cases){
                c.Business_Unit__c = 'ABSLI';
                c.FTR__c = true;
                c.Status = 'Resolved';
            }
            ASF_TriggerSkipperUtility.markTriggerRun('Case');
            update cases;
            wrappers[0].caseStatus = 'Resolved';
            List<ASF_CustomerEmailInvocable.EmailOutputWrapper> outputWrappers2 = ASF_CustomerEmailInvocable.getEmailTemplateName(wrappers);
            Assert.areEqual(outputWrappers2[0].supressEmail, false,'Emails should not be supressed');
        }
    }
}