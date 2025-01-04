@isTest
public class RNWL_WhatsappCommunicationControllerTest {
    
    private final static Profile SYSTEMADMIN_PROFILE = [SELECT Id FROM Profile WHERE name='System Administrator' LIMIT 1];
    private static final String FAKE_RESPONSE_JSON = '{"StatusCode":"","Message":"","PolicyInfo":[{"SNO":"17002561","DOCUMENT_ID":"A5348","POLICY_NO":"382939464318072024","APPLICATION_NO":"240000605647","CLAIM_NO":"","SOURCE_SYSTEM":"BaNCS","IMPACT_MODULES":"Mission Transformation - NB Triggers R1D1","DOCUMENT_DESCRIPTION":"Mission Transformation-Policy Issuance - e-welcome kit - Customer","MODE_OF_COMMUNICATION":"Sms","RECORD_PROCESS_DATE":"2024-07-18 00:00:00.0","EMAIL_ID":"zulekha.patel@qualitykiosk.com","CC_EMAIL_ID":" ","BCC_EMAIL_ID":" ","EMAIL_STATUS":"NA","EMAIL_CONTENT":"NA","EMAIL_REQUEST_TIME":"","EMAIL_RESPONSE_TIME":"","MOBILE_NO":"7738909402","SMS_STATUS":"Y","SMS_CONTENT":"https://cpssprod.adityabirlahealth.com/ContentViewerService/resources/ContentViewer/getContent?clickID=17002561_PXSM","SMS_REQUEST_TIME":"2024-07-18 17:02:11.0","SMS_RESPONSE_TIME":"2024-07-18 17:02:11.0","MEMBER_ID":" ","NOTIFICATION_STATUS":"NA","NOTIFICATION_CONTENT":"NA","NOTIFICATION_REQUEST_TIME":"","NOTIFICATION_RESPONSE_TIME":"","DOCID":"NA","TRIGGER_MODE":"Real Time","OMNI_UPLOAD_DATETIME":"NA For alerts"}]}';
    private static final String FAKE_RESPONSE_JSON_NEGATIVE = '{"StatusCode":"400","Message":"","PolicyInfo":[{"SNO":"17002561","DOCUMENT_ID":"A5348","POLICY_NO":"382939464318072024","APPLICATION_NO":"240000605647","CLAIM_NO":"","SOURCE_SYSTEM":"BaNCS","IMPACT_MODULES":"Mission Transformation - NB Triggers R1D1","DOCUMENT_DESCRIPTION":"Mission Transformation-Policy Issuance - e-welcome kit - Customer","MODE_OF_COMMUNICATION":"Sms","RECORD_PROCESS_DATE":"2024-07-18 00:00:00.0","EMAIL_ID":"zulekha.patel@qualitykiosk.com","CC_EMAIL_ID":" ","BCC_EMAIL_ID":" ","EMAIL_STATUS":"NA","EMAIL_CONTENT":"NA","EMAIL_REQUEST_TIME":"","EMAIL_RESPONSE_TIME":"","MOBILE_NO":"7738909402","SMS_STATUS":"Y","SMS_CONTENT":"https://cpssprod.adityabirlahealth.com/ContentViewerService/resources/ContentViewer/getContent?clickID=17002561_PXSM","SMS_REQUEST_TIME":"2024-07-18 17:02:11.0","SMS_RESPONSE_TIME":"2024-07-18 17:02:11.0","MEMBER_ID":" ","NOTIFICATION_STATUS":"NA","NOTIFICATION_CONTENT":"NA","NOTIFICATION_REQUEST_TIME":"","NOTIFICATION_RESPONSE_TIME":"","DOCID":"NA","TRIGGER_MODE":"Real Time","OMNI_UPLOAD_DATETIME":"NA For alerts"}]}';
    
    
    private class Mock implements HttpCalloutMock { 
        public HTTPResponse respond(HTTPRequest req) { 
            HTTPResponse res = new HTTPResponse();
            res.setBody(FAKE_RESPONSE_JSON);
            res.setStatusCode(200);
            return res;
        }
    }
    
    private class Mock2 implements HttpCalloutMock { 
        public HTTPResponse respond(HTTPRequest req) { 
            HTTPResponse res = new HTTPResponse();
            res.setBody(FAKE_RESPONSE_JSON_NEGATIVE);
            res.setStatusCode(400);
            return res;
        }
    }
    
    @TestSetup
    public static void setup(){
        Account acc=  new Account(name='Test Account' ,Client_Code__c = 'PT87552250');
        insert acc;
        
        Asset objAsset =  new Asset(name='71-20-00040-01-02', ABHI_Policy_Id__c='21-24-0000759-01', LAN__c = '21-24-0000759-01');
        insert objAsset;
        
        Opportunity oppRec = new Opportunity();
        oppRec.Name = 'Testabc' ;
        oppRec.AccountId = acc.Id;
        oppRec.CloseDate = Date.today();
        oppRec.Policy__c = objAsset.Id;
        oppRec.StageName = 'In Progress';
        oppRec.Policy_Number__c = 'GFB-HB-22-2024165-004';
        insert oppRec;
    }
    
    @IsTest
    static void testExecuteCallout(){  
        
        Opportunity objOpportunity = [Select Id From Opportunity LIMIT 1];
        Test.startTest();
        try{
            Test.setMock(HttpCalloutMock.class, new Mock());
            RNWL_WhatsappCommunicationController.getData(objOpportunity.Id);
        }catch(Exception e){}
        
        Test.stopTest();
    }
    
    
    @IsTest
    static void testExecuteCalloutNegative(){ 
        Opportunity objOpportunity = [Select Id From Opportunity LIMIT 1];
        String strBody = null;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new Mock2());
        RNWL_WhatsappCommunicationController.getData(objOpportunity.Id);
        Test.stopTest();
    }
}