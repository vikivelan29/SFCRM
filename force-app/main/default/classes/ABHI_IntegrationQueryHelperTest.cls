/*********************************************************
*Class        :  ABHI_IntegrationQueryHelperTest
*Author       :  Shubham Sinha
*Created Date :  12/10/2024
*Last Modified:  12/10/2024
*@description  : Test class for ABHI_IntegrationQueryHelper
***********************************************************/ 

@Istest
public class ABHI_IntegrationQueryHelperTest {
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
        Case caseInfo = ABHI_IntegrationQueryHelper.getCaseInfo(caseRec.Id);
        System.assert(caseInfo!=null,'PASS');       
        List<ASF_Case_Integration__c> caseInt = ABHI_IntegrationQueryHelper.getCaseIntegrations1(new List<Case>{caseRec},new Set<String>{'Test'});
        System.assertEquals(1,caseInt.size(),'PASS');  
        List<ASF_Case_Integration__c> caseIntById = ABHI_IntegrationQueryHelper.getCaseIntegrations(caseInt);
        Set<String> className = new Set<String>{'ABHI_ClosedIGMSComplaintIntegration'};
        ABHI_IntegrationQueryHelper.getIntegrationInfo(className);
        System.assertEquals(1,caseIntById.size(),'PASS'); 
    }    
}