@isTest
public class ASF_CustomerEmailInvocable_Test {
    @TestSetup
    static void makeData(){
        List<sObject> ls = Test.loadData(SLA_Threshold_Warning__c.sObjectType, 'testSLAThreshold');
        ASF_TestDataFactory.createC3IntegrationsAndCase();
        List<Case> cases = ASF_TestDataFactory.createCaseRecords(3);
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
            
            List<ASF_CustomerEmailInvocable.EmailOutputWrapper> outputWrappers = ASF_CustomerEmailInvocable.getEmailTemplateName(wrappers);
            for(ASF_CustomerEmailInvocable.EmailOutputWrapper outputWrapper : outputWrappers){
                
            }
            
        }
        
        
        
    }
    
}