/*********************************************************
*@Class        :  ABHFL_BitlyUrl_Test
*@Author       :  Anjali Sharma
*@description  :  Test class for ABHFL_BitlyUrl
*********************************************************/

@IsTest
public class ABHFL_BitlyUrl_Test {
    @TestSetup
    static void setup() {
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
        ASF_Integration__c integ = [SELECT Id, Display_Name__c, External_Id__c FROM ASF_Integration__c WHERE External_Id__c = 'ASF_INT_01' LIMIT 1];
        Case caseRec = [SELECT Id FROM Case LIMIT 1];
        ASF_IntegrationsController.IntegrationWrapper result = bit.run(integ, caseRec);
        System.assertEquals('Success', result.status);
    }

    @IsTest
    static void testProcessResponse() {
        ABHFL_BitlyUrl bit = new ABHFL_BitlyUrl();
        ASF_Case_Integration__c caseInteg = [Select id,Case__c, Status__c, Response__c from ASF_Case_Integration__c limit 1];
        bit.processResponse(caseInteg);
        
        caseInteg.status__c = 'Success';
        update caseInteg;
        bit.processResponse(caseInteg);
        Case caseRec = [SELECT Id,  Short_URL__c FROM Case WHERE Id = :caseInteg.Case__c];
        System.assertEquals('Short URL', caseRec.Short_URL__c);
    }
}