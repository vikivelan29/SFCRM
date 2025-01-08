@isTest
public class ABSLI_PIVCModernization_Test {
    private class ABSLI_MockIntegrationCalloutError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"Status": "400", "responseBody":{"Fault":{"FaultMessage":"Error","FaultCode":"400"}}}');
            return res;
        }
    }
    public class ABSLI_MockHttpResponseSuccess implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"Status": "200", "Message": "Success"}');
            return res;
        }
    }
    @isTest
    static void testSendCase() {
        Account acc = new Account();
        acc.FirstName='test';
        acc.LastName='test2';
        insert acc;
        
        Asset assetRec = new Asset();
        assetRec.Name = 'Test Asset';
        assetRec.AccountId =acc.Id;
        assetRec.Application_Number__c = '1234';
        insert assetRec;
        
        ABSLI_Case_Detail__c detailRec = new ABSLI_Case_Detail__c();
        detailRec.API_Request__c = 'API Request';
        detailRec.API_Name__c = 'PIVC Verisafe';
        detailRec.API_Response_Message__c = 'Success';
        detailRec.API_Error_Code__c = '200';
        
        insert detailRec;
        
        Case caseRec = new Case();
        caseRec.Source__c = 'Email';
        //caseRec.Business_Unit__c = 'ABSLI'; //added 
        caseRec.Status = 'Open';
        caseRec.AssetId = assetRec.Id;
        caseRec.ABSLI_Case_Detail__c = detailRec.Id;
        caseRec.AccountId = acc.Id;
        caseRec.CCC_External_Id__c = 'ABSLI_PAS';
        caseRec.LAN__c = '8895335596';
        caseRec.Technical_Source__c = 'API';
        insert caseRec;
        
        ABSLI_Case_Detail__c caseDetail = new ABSLI_Case_Detail__c(
            //Case__c = caseObj.Id,
            API_Request__c = 'API Request',
            API_Name__c = 'PIVC Verisafe',
            API_Response_Message__c = 'Success',
            API_Error_Code__c = '200'
        );
        insert caseDetail;
        List<case> casList = [SELECT Id,AssetId,ABSLI_Case_Detail__c FROM Case];
        // Set up mock callout response
        Test.startTest();
        
        // Mock the integration response
        Test.setMock(HttpCalloutMock.class, new ABSLI_MockHttpResponseSuccess());
        
        // Call the sendcase method
        String result = ABSLI_PIVCModernization.sendcase(caseRec.Id);
        System.assertEquals('Send Case to CRM is Successful', result);
        
        Set<Id> caseIdSet = new Set<Id>{caseRec.Id};
            set<Id>  case2Set = new Set<Id>();   
        ABSLI_PIVCModernization.executeSendCaseToCRM(caseIdSet);
        ABSLI_PIVCModernization.executeSendCaseToCRM(case2Set);
        Test.stopTest();
        
    }
    
    @isTest
    static void exceptionCover() {
        Account acc = new Account();
        acc.FirstName='test';
        acc.LastName='test2';
        insert acc;
        
        Asset assetRec = new Asset();
        assetRec.Name = 'Test Asset';
        assetRec.AccountId =acc.Id;
        assetRec.Application_Number__c = '1234';
        insert assetRec;
        
        ABSLI_Case_Detail__c detailRec = new ABSLI_Case_Detail__c();
        detailRec.API_Request__c = 'API Request';
        detailRec.API_Name__c = 'PIVC Verisafe';
        detailRec.API_Response_Message__c = 'Success';
        detailRec.API_Error_Code__c = '200';
        
        insert detailRec;
        
        Case caseRec = new Case();
        caseRec.Source__c = 'Email';
        //caseRec.Business_Unit__c = 'ABSLI';
        caseRec.Status = 'Open';
        caseRec.AssetId = assetRec.Id;
        caseRec.ABSLI_Case_Detail__c = detailRec.Id;
        caseRec.AccountId = acc.Id;
        caseRec.CCC_External_Id__c = 'ABSLI_PAS';
        caseRec.LAN__c = '8895335596';
        caseRec.Technical_Source__c = 'API';
        insert caseRec;
        
        ABSLI_Case_Detail__c caseDetail = new ABSLI_Case_Detail__c(
            //Case__c = caseObj.Id,
            API_Request__c = 'API Request',
            API_Name__c = 'PIVC Verisafe',
            API_Response_Message__c = 'Success',
            API_Error_Code__c = '200'
        );
        insert caseDetail;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ABSLI_MockIntegrationCalloutError());
        //Set<Id> caseIdSet = new Set<Id>{caseRec.Id};
        set<Id>  case2Set = new Set<Id>();   
        //ABSLI_PIVCModernization.executeSendCaseToCRM(caseIdSet);
        ABSLI_PIVCModernization.executeSendCaseToCRM(case2Set);
        ABSLI_PIVCModernization.sendcase(caseRec.Id);
        Test.stopTest();
    }    
}