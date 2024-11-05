@IsTest
public class ABSLI_NSDLPANVerificationTest {
    @TestSetup
    static void createTestData(){
        Account accRec = ASF_TestDataFactory.insertPersonAccount('First Name','Last Name','Test_1');
        Account accBussRec = ASF_TestDataFactory.insertBusinessAccount('Test_Cmp','Test_1');
        accBussRec.RecordTypeId = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Non_Individual').getRecordTypeId();
        update accBussRec;
        Contact conRec = ASF_TestDataFactory.insertContact('Test Contact','abcl@test.com');
        conRec.AccountId = accBussRec.Id;
        conRec.Primary__c = true;
        update conRec;
        ABSLI_Case_Detail__c caseDetail = new ABSLI_Case_Detail__c();
        caseDetail.PAN_Number__c = 'CYIPP8888A';
        insert caseDetail;
        List<Case> caseRecList = ASF_TestDataFactory.createCaseRecords(2);
        caseRecList[0].AccountId = accRec.Id;
        caseRecList[1].AccountId = accBussRec.Id;
        caseRecList[0].ABSLI_Case_Detail__c = caseDetail.Id;
        caseRecList[1].ABSLI_Case_Detail__c = caseDetail.Id;
        update caseRecList;
        ASF_TestDataFactory.createC3WithPrePopulateIntegrations();
        List<ASF_Integration__c> integs = [Select id from ASF_Integration__c];
        for(ASF_Integration__c integ : integs){
            integ.Processing_Class__c = 'ABSLI_PanUpdateIntegration';
            integ.Query_Fields__c = 'ABSLI_Case_Detail__r.Status_Valid_For_STP__c,CaseNumber,Account.Client_Code__c,ABSLI_Case_Detail__r.Mobile_Number__c,Business_Unit__c,Asset.Policy_No__c,Account.PAN__c';
        }
        update integs;
    }
    @IsTest
    static void getPanVerificationDetailsTest(){
        List<Case> caseList = [Select id,Account.IsPersonAccount from Case];
        for(Case caseRec : caseList){
            if(caseRec.Account.IsPersonAccount){
                ABSLI_NSDLPANVerification.PANVerificationWrapper personAccountresponse = ABSLI_NSDLPANVerification.getPanVerificationDetails(caseRec.Id);
                System.assertEquals('First Name Last Name',personAccountresponse.name);
                try{
                    ABSLI_NSDLPANVerification.PANVerificationWrapper errorResponse = ABSLI_NSDLPANVerification.getPanVerificationDetails(null);
                }catch(Exception ex){}
                Test.startTest();
                personAccountresponse.dob = system.today();
                /*StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
                mock.setStaticResource('PANVerificationMockResponse');
                mock.setStatusCode(200);
                mock.setHeader('Content-Type', 'application/json');*/
                Test.setMock(HttpCalloutMock.class, new ABSLI_NSDLPANResponseGenerator());
                ABSLI_NSDLPANVerification.PANVerificationResponseWrapper verificationResponse = ABSLI_NSDLPANVerification.verifyPAN(JSON.serialize(personAccountresponse)
                                                                                                                                    ,String.valueof(caseRec.Id)
                                                                                                                                    ,'test');
                ABSLI_NSDLPANVerification.PANVerificationResponseWrapper verificationResponse1 = ABSLI_NSDLPANVerification.verifyPANDetails(JSON.serialize(personAccountresponse)
                                                                                                                                    ,String.valueof(caseRec.Id));
                Test.stopTest();
                System.assertEquals(true,verificationResponse.isSuccess);
                ABSLI_NSDLPANVerification.PANVerificationResponseWrapper updatePanResponse = ABSLI_NSDLPANVerification.updatePAN(caseRec.Id);
                System.assertEquals(true,updatePanResponse.isSuccess);
                
            }else{
                ABSLI_NSDLPANVerification.PANVerificationWrapper bussAccountresponse = ABSLI_NSDLPANVerification.getPanVerificationDetails(caseRec.Id);
                System.assertNotEquals('Test_Cmp',bussAccountresponse.name);
            }           
        }
    }
    
    public class ABSLI_NSDLPANResponseGenerator implements HttpCalloutMock {
        /**
            * @description  Mocking failure response
            * @param req
            ** @return HTTPResponse
        */ 
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
			String s = '{}';
            res.setBody(s);
            res.setStatusCode(200);
            return res;
        }
    }
    
}