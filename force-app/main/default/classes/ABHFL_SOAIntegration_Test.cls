/*********************************************************
*@Class        :  ABHFL_SOAIntegration_Test
*@Author       :  Anjali Sharma
*@description  :  Test class for ABHFL_SOAIntegration
*********************************************************/
@IsTest
public with sharing class ABHFL_SOAIntegration_Test {
    @TestSetup
    static void createData(){
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];  
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String uid = h.SubString(0,8); 
        User u = new User(Alias = uid, Email= uid + '@testdomain.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_IN', ProfileId = p.Id, 
                          TimeZoneSidKey='Asia/Kolkata', UserName= uid + '@testdomain.com'); 
        insert u;
        PermissionSetGroup psg = [select Id, Status from PermissionSetGroup where DeveloperName='Super_Admin'];
        
        
        if(psg.Status != 'Updated'){
            Test.calculatePermissionSetGroup(psg.Id);
            insert new PermissionSetAssignment(PermissionSetGroupId = psg.Id, AssigneeId = u.Id);
        }


        System.runAs(u){
            Account accRec = ASF_TestDataFactory.insertBusinessAccount('Test_Cmp','Test_1');
            Branch_Master__c branchMstr = new Branch_Master__c();
            branchMstr.Branch_Queue_Id__c = [Select Id from Group where Type = 'Queue' LIMIT 1].Id;
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
            integ.Processing_Class__c = 'ABHFL_SOAIntegration';
            integ.External_Id__c = 'ASF_INT_01';
            integ.Display_Name__c = 'SOA';
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
    }


    @IsTest
    static void testEvaluate() {
        ABHFL_SOAIntegration soa = new ABHFL_SOAIntegration();
        Case caseRec = [SELECT id FROM case LIMIT 1];
        ASF_IntegrationsController.IntegrationWrapper result = soa.evaluate(caseRec);
        System.assertEquals('Success', result.status);
    }

    @IsTest
    static void testRun() {
        ABHFL_SOAIntegration soa = new ABHFL_SOAIntegration();
        ASF_Integration__c integ = [SELECT Id, Display_Name__c, External_Id__c FROM ASF_Integration__c WHERE External_Id__c = 'ASF_INT_01' LIMIT 1];
        Case caseRec = [SELECT Id FROM Case LIMIT 1];
        ASF_IntegrationsController.IntegrationWrapper result = soa.run(integ, caseRec);
        System.assertEquals('Success', result.status);
    }

    @IsTest
    static void testProcessResponse() {
        ABHFL_SOAIntegration soa = new ABHFL_SOAIntegration();
        ASF_Case_Integration__c caseInteg = [Select id, Status__c ,Case__c from ASF_Case_Integration__c limit 1];
        caseInteg.Status__c = 'Success';
        update caseInteg;
        Case caseRec = [SELECT Id, ABHFL_Case_Detail__r.STP_Failure__c, MoveToNext__c, status FROM Case WHERE Id=:caseInteg.Case__c];
        System.assertEquals(false, caseRec.ABHFL_Case_Detail__r.STP_Failure__c);
        Test.startTest();
        ContentDocumentLink conDoc = [Select id from ContentDocumentLink where LinkedEntityId =: caseInteg.Id limit 1];
        DELETE conDoc;
        soa.processResponse(caseInteg);
        caseRec = [Select id,OwnerId from Case where id =: caseInteg.Case__c ];
        Group csQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Customer_Service_Team' Limit 1];
        System.assertEquals(csQueue.Id,caseRec.OwnerId);
        Test.stopTest();
    }
}
