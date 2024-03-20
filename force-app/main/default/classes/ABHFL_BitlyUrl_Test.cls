/*********************************************************
*@Class        :  ABHFL_BitlyUrl_Test
*@Author       :  Anjali Sharma
*@description  :  Test class for ABHFL_BitlyUrl
*********************************************************/

@IsTest
public class ABHFL_BitlyUrl_Test {
    @TestSetup
    static void setup() {
        ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
        caseDetail.From_Date__c = Date.newInstance(2023, 02, 04);
        caseDetail.To_Date__c = Date.newInstance(2023, 10, 15);
        insert caseDetail;
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(1);
        caseRecList[0].ABHFL_Case_Detail__c = caseDetail.Id;       
        update caseRecList[0];
        
        ASF_Integration__c integ = new ASF_Integration__c();
        integ.Processing_Class__c = 'ABHFL_BitlyUrl';
        integ.External_Id__c = 'CCC-CC-CCLTD-01';
        integ.Display_Name__c = 'BitlyURL';
        insert integ;
        
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Response__c = '{"urlReturned": "Short URL","returnMessage": "Success","ReturnCode": "2"}';
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Case__c = caseRecList[0].Id;
        insert caseInt;
        
        ASF_TestDataFactory.createCaseCategoryConfig();
        ASF_Case_Category_Config__c ccc = [SELECT Id, New_Case_Email_Template__c FROM ASF_Case_Category_Config__c LIMIT 1];
        ccc.New_Case_Email_Template__c = 'Query Case Creation with Link, Query Case Creation w/o Link';
        ccc.New_Case_SMS_Metadata__c = 'Query Case Creation with Link, Query Case Creation w/o Link';
        update ccc;
    }

    @IsTest
    static void testEvaluate() {
        ABHFL_BitlyUrl bit = new ABHFL_BitlyUrl();
        Case caseRec = [SELECT id FROM case LIMIT 1];
        ASF_IntegrationsController.IntegrationWrapper result = bit.evaluate(caseRec);
        System.assertEquals('Success', result.status);
    }

    @IsTest
    static void testRun() {
        ABHFL_BitlyUrl bit = new ABHFL_BitlyUrl();
        ASF_Integration__c integ = [SELECT Id, Display_Name__c, External_Id__c FROM ASF_Integration__c WHERE External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1];
        Case caseRec = [SELECT Id FROM Case LIMIT 1];
        ASF_IntegrationsController.IntegrationWrapper result = bit.run(integ, caseRec);
        System.assertEquals('Success', result.status);
    }

    @IsTest
    static void testProcessResponse() {
        ABHFL_BitlyUrl bit = new ABHFL_BitlyUrl();
        ASF_Case_Integration__c caseInteg = [Select id,Case__c, Status__c, Response__c, Integration_Ext_Id__c from ASF_Case_Integration__c limit 1];
        bit.processResponse(caseInteg);
        
        caseInteg.status__c = 'Success';
        update caseInteg;
        bit.processResponse(caseInteg);
        Case caseRec = [SELECT Id,  Short_URL__c FROM Case WHERE Id = :caseInteg.Case__c];
        System.assertEquals('Short URL', caseRec.Short_URL__c);
    }

    @IsTest
    static void testEvaluateBulk() {
        ABHFL_BitlyUrl bit = new ABHFL_BitlyUrl();
        Case caseRecord = [SELECT Id, CCC_External_Id__c, Source__c, CaseNumber, Business_Unit__c FROM case LIMIT 1];
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{caseRecord.Id=>caseRecord};
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> result = bit.evaluate(new List<Case>{caseRecord});
        System.assertEquals('Success', result.get(caseRecord.Id).status);
    }

    @IsTest
    static void testRunBulk() {
        ABHFL_BitlyUrl bit = new ABHFL_BitlyUrl();
        ASF_Integration__c integ = [SELECT Id, Display_Name__c, External_Id__c, Processing_Class__c FROM ASF_Integration__c WHERE External_Id__c = 'CCC-CC-CCLTD-01' LIMIT 1];
        Case caseRecord = [SELECT Id, CCC_External_Id__c, Source__c, CaseNumber, Business_Unit__c FROM Case LIMIT 1];
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{caseRecord.Id=>caseRecord};
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> result = bit.run(new Map<Id, List<ASF_Integration__c>>{caseRecord.Id => new List<ASF_Integration__c>{integ}}, new List<Case>{caseRecord});
        System.assertEquals('Success', result.get(caseRecord.Id).status);
    }
}