/*********************************************************
*@Class        :  ABHFL_REKYCIntegration_Test
*@Author       :  Anjali Sharma
*@description  :  Test class for ABHFL_REKYCIntegration
*********************************************************/

@IsTest
public class ABHFL_REKYCIntegration_Test {
    @TestSetup
    static void createData(){   
        Account accRec = ASF_TestDataFactory.insertPersonAccount('John', 'Smith','10110000');
        accRec.KYC_Done_Date__c = Date.today().addMonths(-2);
        accRec.Client_Code__c = '123456789';
        update accRec;
        Branch_Master__c branchMstr = new Branch_Master__c();
        branchMstr.Branch_Queue_Id__c = [Select Id from Group where Type = 'Queue' LIMIT 1].Id;
        branchMstr.UniqueKey__c = '234234';
        insert branchMstr;
        Asset astRec = ASF_TestDataFactory.createAsset(accRec.Id,'Loans');
        astRec.LAN__c = 'Test';
        astRec.Branch__c = branchMstr.Id;
        update astRec;
        ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
        caseDetail.From_Date__c = Date.newInstance(2023, 02, 04);
        caseDetail.To_Date__c = Date.newInstance(2023, 10, 15);
        insert caseDetail;
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(1);
        caseRecList[0].AssetId = astRec.Id;
        caseRecList[0].ABHFL_Case_Detail__c = caseDetail.Id;
        caseRecList[0].Case_Stage_Change_Date__c = date.today();
        caseRecList[0].AccountId = accRec.Id; 
        caseRecList[0].Business_Unit__c = 'ABHFL';
        update caseRecList[0];
        ASF_TestDataFactory.createCaseCategoryConfig();
        
        SLA_Threshold_Warning__c slaThreshold = SLA_Threshold_Warning__c.getOrgDefaults();
        slaThreshold.Stage_SLA_Threshold_1__c = .5;
        slaThreshold.Stage_SLA_Threshold_2__c = .75;
        slaThreshold.Stage_SLA_Threshold_3__c = 1;
        slaThreshold.Case_SLA_Threshold_1_Label__c = '50%';
        slaThreshold.Case_SLA_Threshold_2_Label__c = '75%';
        slaThreshold.Case_SLA_Threshold_3_Label__c = '100%';
        slaThreshold.Case_SLA_Threshold_1__c = .5;
        slaThreshold.Case_SLA_Threshold_2__c = .75;
        slaThreshold.Case_SLA_Threshold_3__c = 1;
        upsert slaThreshold SLA_Threshold_Warning__c.Id;
        
        ASF_Integration__c integ = new ASF_Integration__c();
        integ.Processing_Class__c = 'ABHFL_REKYCIntegration';
        integ.External_Id__c = 'ASF_INT_01';
        integ.Display_Name__c = 'REKYC';
        insert integ;
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Case__c = caseRecList[0].Id;
        insert caseInt;
        ContentVersion content = new ContentVersion();
        content.PathOnClient = 'Response.txt';
        content.Title = 'Response';
        content.VersionData = Blob.valueof('Test');
        insert content;
        ContentVersion conVersion = [Select ContentDocumentId from ContentVersion where id =: content.Id];
        ContentDocumentLink docLink = new ContentDocumentLink();
        docLink.LinkedEntityId = caseInt.Id;
        docLink.ContentDocumentId = conVersion.ContentDocumentId;
        docLink.ShareType = 'V';
        insert docLink;
    }

    @IsTest
    static void testEvaluate() {
        ABHFL_REKYCIntegration rk = new ABHFL_REKYCIntegration();
        Case caseRec = [SELECT id FROM case LIMIT 1];
        ASF_IntegrationsController.IntegrationWrapper result = rk.evaluate(caseRec);
        System.assertEquals('Success', result.status);
    }

    @IsTest
    static void testRun() {
        ABHFL_REKYCIntegration rk = new ABHFL_REKYCIntegration();
        ASF_Integration__c integ = [SELECT Id, External_Id__c, Display_Name__c FROM ASF_Integration__c WHERE External_Id__c = 'ASF_INT_01' LIMIT 1];
        Case caseRec = [SELECT Id FROM Case LIMIT 1];
        ASF_IntegrationsController.IntegrationWrapper result = rk.run(integ, caseRec);
        System.debug('result  -----   >    '+ result);
        System.assertEquals('Success', result.status);
    }
    @IsTest
    static void testEvaluateBulk() {
        ABHFL_REKYCIntegration rk = new ABHFL_REKYCIntegration();
        Case caseRec = [SELECT Id, Account.IsPersonAccount, Account.KYC_Done_Date__c, Account.Client_Code__c, Business_Unit__c, CCC_External_Id__c, Customer_name_formula__c, Asset.LAN__c, Asset.Last_Disbursement_Date__c, Nature__c, Account.PersonEmail,Account.PersonMobilePhone, Account.PAN__c, Account.PersonBirthdate, Account.Street_Address_1__c, Account.Street_Address_2__c, Account.Street_Address_3__c, Account.City__c, Account.State__c FROM case LIMIT 1];
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{caseRec.Id=>caseRec};
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> result = rk.evaluate(new List<Case>{caseRec});
        System.assertEquals('Success', result.get(caseRec.Id).status);
    }

    @IsTest
    static void testRunBulk() {
        ABHFL_REKYCIntegration rk = new ABHFL_REKYCIntegration();
        ASF_Integration__c integ = [SELECT Id, External_Id__c, Display_Name__c, Processing_Class__c FROM ASF_Integration__c WHERE External_Id__c = 'ASF_INT_01' LIMIT 1];
        Case caseRec = [SELECT Id, Account.IsPersonAccount, Account.KYC_Done_Date__c, Account.Client_Code__c, Business_Unit__c, CCC_External_Id__c, Customer_name_formula__c, Asset.LAN__c, Asset.Last_Disbursement_Date__c, Nature__c, Account.PersonEmail,Account.PersonMobilePhone, Account.PAN__c, Account.PersonBirthdate, Account.Street_Address_1__c, Account.Street_Address_2__c, Account.Street_Address_3__c, Account.City__c, Account.State__c FROM Case LIMIT 1];
        ASF_IntegrationsController.queriedCasesForIntegration = new Map<Id, Case>{caseRec.Id=>caseRec};
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> result = rk.run(new Map<Id, List<ASF_Integration__c>>{caseRec.Id => new List<ASF_Integration__c>{integ}}, new List<Case>{caseRec});
        System.debug('result  -----   >    '+ result);
        System.assertEquals('Success', result.get(caseRec.Id).status);
    }
}