@Istest
public class ABSLI_IntegrationQueryHelperTest {
	@TestSetup
    static void createTestData(){        
        List<Case> caseRec = ASF_TestDataFactory.createCaseRecords(1);
        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_TestDataFactory.createCaseIntegration(caseRec[0].Id,'Test');
        ASF_TestDataFactory.createC3WithPrePopulateIntegrations();
    }
    @IsTest
    static void testQueryHelper(){
        Case caseRec = [Select id from Case limit 1];
        ASF_Case_Category_Config__c caseCatConfig = [Select CCC_External_Id__c from ASF_Case_Category_Config__c limit 1];
        ASF_Integration__c integ= [Select id,Processing_Class__c from ASF_Integration__c limit 1];
        List<Case> mobileUpdateCases = ABSLI_IntegrationQueryHelper.getCaseForMobileUpdateIntegration(caseRec.Id);
        System.assertEquals(1,mobileUpdateCases.size(),'PASS');
        Case caseInfo = ABSLI_IntegrationQueryHelper.getCaseInfo(caseRec.Id);
        System.assert(caseInfo!=null,'PASS');
        List<ASF_Case_Category_Config__c> categConfig = ABSLI_IntegrationQueryHelper.getCaseCategoryConfigs(caseCatConfig.CCC_External_Id__c);
        System.assertEquals(2,categConfig.size(),'PASS');        
        List<ASF_Case_Integration__c> caseInt = ABSLI_IntegrationQueryHelper.getCaseIntegrations(new List<Case>{caseRec},new Set<String>{'Test'});
        System.assertEquals(1,caseInt.size(),'PASS');  
        List<ASF_Case_Integration__c> caseIntById = ABSLI_IntegrationQueryHelper.getCaseIntegrations(caseInt);
        System.assertEquals(1,caseIntById.size(),'PASS'); 
        Map<String, ASF_Integration__c> asfIntMap = ABSLI_IntegrationQueryHelper.getIntegrationInfo(new Set<String>{integ.Processing_Class__c});
        System.assert(asfIntMap.get(integ.Processing_Class__c) != null,'PASS'); 
        Map<Id, Case> caseIdMap = ABSLI_IntegrationQueryHelper.getCases(new Set<Id>{caseRec.Id});
        System.assert(caseIdMap.get(caseRec.Id) != null,'PASS');
        Map<String, ASF_Case_Category_Config__c> categConfigMap = ABSLI_IntegrationQueryHelper.getCccIdToRecordMap(new Set<String>{caseCatConfig.CCC_External_Id__c});
        System.assert(categConfigMap.get(caseCatConfig.CCC_External_Id__c) != null,'PASS');      
        Map<Id, ASF_Case_Integration__c> caseIntMap = ABSLI_IntegrationQueryHelper.getCaseIdsToIntegrationRecordsMap(new Set<Id>{caseRec.Id},null);
        System.assert(caseIntMap.keySet().size() > 0,'PASS');    
        
    }

    
}