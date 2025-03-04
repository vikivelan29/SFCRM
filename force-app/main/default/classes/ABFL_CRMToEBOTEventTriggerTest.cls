/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 05-13-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   05-11-2024   rsinghnagar@salesforce.com   Initial Version
**/
@isTest
public class ABFL_CRMToEBOTEventTriggerTest {
    
    @testSetup static void basicDataSetup() {
        // Create common test CaseIntegration records
        ASF_Case_Integration__c ci1 = new ASF_Case_Integration__c(Type__c='eBOT',Status__c='Failure',Integration_Ext_Id__c='ASF_IN_System1');    
        insert ci1;
        ASF_Case_Integration__c ci2 = new ASF_Case_Integration__c(Type__c='eBOT',Status__c='Failure',Integration_Ext_Id__c='ASF_IN_System2');    
        insert ci2;
    }
    
    @IsTest(seeAllData = false)
    static void afterInsertMethod() {
        // Bulkifying test records
        List<CRM_to_EBOT_Event__e> eventsList = new List<CRM_to_EBOT_Event__e>();
        CRM_to_EBOT_Event__e efw = new CRM_to_EBOT_Event__e();
        efw.Additional_Emails__c = 'rsinghnagar@salesforce.com,rajendra.mitu06@gmail.com';
        efw.Business_Unit__c = 'ABFL';
        efw.Case_Number__c = '00002986';
        efw.Description__c = 'Details for case here';
        efw.File_Names__c = '00P9I000001TSUz,00P9I000001TSRl';
        efw.From_Address__c = 'rajendra.mitu06@abc.com';
        String ci1Name = [Select Id,Name, Request__c from ASF_Case_Integration__c where Integration_Ext_Id__c='ASF_IN_System1' limit 1].Name;
        efw.Integration_Name__c = ci1Name;
        efw.Case_Integration_ID__c = ci1Name;
        efw.Subject__c = 'Amount Refund';
        efw.To_Address__c = 'Kumar.m.birla@abc.com';
        eventsList.add(efw);
        
        CRM_to_EBOT_Event__e efw1 = new CRM_to_EBOT_Event__e();
        efw1.Additional_Emails__c = 'rsinghnagar1@salesforce.com,rajendra.mitu061@gmail.com';
        efw1.Business_Unit__c = 'ABFL';
        efw1.Case_Number__c = '00002987';
        efw1.Description__c = 'Details for case here';
        efw1.File_Names__c = '00P9I000001TSUz,00P9I000001TSRl';
        efw1.From_Address__c = 'rajendra.mitu061@abc.com';
        String ci2Name = [Select Id,Name, Request__c from ASF_Case_Integration__c where Integration_Ext_Id__c='ASF_IN_System2' limit 1].Name;
        efw1.Integration_Name__c = ci2Name;
        efw1.Case_Integration_ID__c = ci2Name;
        efw1.Subject__c = 'Amount Refund';
        efw1.To_Address__c = 'Kumar.m.birla1@abc.com';
        eventsList.add(efw1);
        
        System.runAs(new User (Id = UserInfo.getUserId())) {
            Test.StartTest();
        	EventBus.publish(eventsList);
            Test.StopTest();   
        }
        String requestGot = [Select Id,Name, Request__c from ASF_Case_Integration__c where Integration_Ext_Id__c='ASF_IN_System1' limit 1].Request__c;
        CRM_to_EBOT_Event__e requestReceived = (CRM_to_EBOT_Event__e) JSON.deserialize(requestGot, CRM_to_EBOT_Event__e.class);
        System.assertEquals(requestReceived.Case_Integration_ID__c,ci1Name, 'Case Integration Id doesn\'t match');
    }
}