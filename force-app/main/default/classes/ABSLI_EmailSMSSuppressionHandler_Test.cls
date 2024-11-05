/**
 * @description       : Test class for ABSLI_EmailSMSSuppressionHandler
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 19-Sep-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@IsTest
public class ABSLI_EmailSMSSuppressionHandler_Test {

    @TestSetup
    static void makeData(){
        ASF_TestDataFactory.createC3IntegrationsAndCase();
        ASF_TestDataFactory.createCaseRecords(3);
    }
    @isTest
    public static void handleSuppressionLogicTest(){
        Id frameworkRecordTypeId = Schema.sObjectType.Case.getRecordTypeInfosByDeveloperName().get('Framework').getRecordTypeId();
        
        List<Case> cases = [SELECT ID,CCC_External_Id__c,Auto_Rejected__c,Status FROM Case WHERE RecordTypeId=:frameworkRecordTypeId];
        
        if(cases.size()>0){
            cases[0].Auto_Rejected__c = false;
			cases[0].Status = 'Unresolved'; 
   
            List<ASF_Case_Category_Config__c> cccRecords = [SELECT ID,Business_Unit__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c =:cases[0].CCC_External_Id__c];
            
            List<ASF_CustomerEmailInvocable.EmailInputWrapper> wrappers = new List<ASF_CustomerEmailInvocable.EmailInputWrapper>();
            ASF_CustomerEmailInvocable.EmailInputWrapper wrapper = new ASF_CustomerEmailInvocable.EmailInputWrapper();
            wrapper.caseId = cases[0].Id;
            wrapper.caseStatus = 'Unresolved';
            wrapper.cccRecord = cccRecords[0];
            wrapper.templateName = 'Generic_SR_Created';
            wrapper.caseRecord = cases[0];
            wrappers.add(wrapper);
            Map<Id, ASF_CustomerEmailInvocable.EmailOutputWrapper> allOutputs = new Map<Id, ASF_CustomerEmailInvocable.EmailOutputWrapper>(); 
            
            Test.startTest();
            ABSLI_EmailSMSSuppressionHandler.handleSuppressionLogic(wrappers,allOutputs);
            Test.stopTest();
            
            Assert.areEqual('ABSLI_Request_Complaint_Un_Resolved_VF',allOutputs.get(cases[0].Id).templateName,'templateName should be as expected');
        }
    }
}