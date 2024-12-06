/*********************************************************
*Class        :  ABSLAMC_LitmusSurveyApi_Test
*Author       :  Santosh V
*Created Date :  03/11/2024
*Last Modified:  03/11/2024
*Description  :  test Class for ABSLAMC_LitmusSurveyApi
*********************************************************/

@SuppressWarnings('PMD.MethodNamingConventions')
@isTest
public class ABSLAMC_LitmusSurveyApi_Test {
    @testSetup
    public static void setUpTestData(){
        
        list<ASF_Case_Category_Config__c> ccclist = ABFL_TestDataFactory.createCaseCategoryConfig(false);
        ccclist[0].CCC_External_Id__c = 'MF01';
        
        insert ccclist[0];
        
        List<ASF_Case_Stage_Config__c> csclist =  ABFL_TestDataFactory.createCaseStageConfigWithTwoStages(ccclist[0].Id, true);
        
        List<ASF_Integration__c> asfInte_list = ABFL_TestDataFactory.createIntegration(csclist[1].Id, false, 'ABSLAMC_LitmusSurveyApi' , '');
        asfInte_list[0].Query_Fields__c = 'Stage__c,AccountId,Source__c,Status,CCC_External_Id__c,ABSLAMC_Case_Detail__r.Caller_Type__c';
        asfInte_list[0].Display_Name__c = 'Litmus';
        asfInte_list[0].Run_Integration_From_LWC__c = true;
        insert asfInte_list[0];
        
        Account acc = ABFL_TestDataFactory.createAccount();
        
        ABSLAMC_Case_Detail__c casedetailObj = new ABSLAMC_Case_Detail__c(caller_type__c = 'Investor');
        insert casedetailObj;
        
        list<Case>  caselist = ABFL_TestDataFactory.createCaseRecords(1, null, false);
        caselist[0].ccc_external_Id__c = 'MF01';
        caselist[0].Stage__c = 'Resolved';
        caselist[0].ABSLAMC_Case_Detail__c = casedetailObj.Id;
        caselist[0].Technical_Source__c = 'LWC';
        caselist[0].accountId = acc.Id;
        caselist[0].source__c = 'Email - Branch';
        insert caselist[0];
        
        insert new ASF_Case_Integration__c(case__c = caselist[0].Id, 
                                           Integration_Ext_Id__c = 'ABSLAMC Litmus Api',
                                           Type__c = 'Litmus',
                                           Status__c = 'Pending');
        
        
    }
    @isTest
    public static void testLitmusEvaluateAndRunMethodBulk(){
        
        ABSLAMC_LitmusSurveyApi litmusApiObj = new ABSLAMC_LitmusSurveyApi();
        
        list<case> caseRecs = [SELECT id, AccountId  from Case where ccc_external_Id__c='MF01'];
        list<ASF_Integration__c> intList = [SELECT id,External_Id__c,Type__c,Processing_Class__c,Display_Name__c,Query_Fields__c from ASF_Integration__c];
        
        Map<Id, List<ASF_Integration__c>> integs = new Map<Id, List<ASF_Integration__c>>();
        integs.put(caseRecs[0].Id,intList);
        
        
        Test.StartTest();
        
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> intwrapper = litmusApiObj.evaluate(caseRecs);
        for(ASF_IntegrationsController.IntegrationWrapper wrappeobj : intwrapper.values()){
            if(wrappeobj.status == 'Success'){
                Map<Id, ASF_IntegrationsController.IntegrationWrapper> res = litmusApiObj.run(integs, caseRecs);
            }
        }
        list<ASF_Case_Integration__c> caseIntList = [SELECT id from ASF_Case_Integration__c where Case__c=:caseRecs[0].Id];
        Test.StopTest();
        System.assertEquals(false, caseIntList.isEmpty()); 
        
    }
}