public with sharing class RNWL_WhatsappCommunicationController {

    public static String accId;
    
    /****************************************************************************************************************
    * @Function - getData
    * @return ReportResponseWrapper
    * @param recordId - Id of the parent record
    * @description This method will return the API data for the recordId passed.
    *****************************************************************************************************************/
    @AuraEnabled
    public static ReportResponseWrapper getData(String recordId) {
        try {
            String integrationName = 'RNWL_Whatsapp_Communication';
            
            String requestString = createRequest(recordId);

            ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResponse = ABCL_IntegrationCallout.executeCallout(integrationName,requestString,null);
            if(integrationResponse.StatusCode == 200){
                ReportResponseWrapper resp = (ReportResponseWrapper) JSON.deserialize(integrationResponse.responseBody, ReportResponseWrapper.class);
                resp.StatusCode = integrationResponse.StatusCode;
                system.debug('Response--'+resp);
                return resp;
            }
            else{
                try {
                    ReportResponseWrapper resp = (ReportResponseWrapper) JSON.deserialize(integrationResponse.responseBody, ReportResponseWrapper.class);
                    resp.StatusCode = integrationResponse.StatusCode;
                    return resp;
                } catch (Exception e) {
                    ReportResponseWrapper resp = new ReportResponseWrapper();
                    resp.StatusCode = integrationResponse.StatusCode;
                    resp.Message = Custom_Messages__mdt.getInstance('ABHI_PSS_Comm_Failure').Message__c;
                    return resp;
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /****************************************************************************************************************
    * @Function - createRequest
    * @return String
    * @param recordId - Id of the parent record
    * @description This method will create the request body needed to be passed to the API.
    *****************************************************************************************************************/
    public static String createRequest(String recordId){
        List<Opportunity> oppList = [SELECT Id,Policy_Number__c, Premium_Amount__c,
                                                Proposal_Number__c
                                         FROM Opportunity 
                                         WHERE Id=:recordId 
                                         LIMIT 1];
            
        String policyNumber = oppList[0].Policy_Number__c;

        POLICY_INFO pi = new POLICY_INFO();
        
        pi.POLICY_NO = policyNumber;
        pi.CLAIM_NO = '';
        pi.APPLICATION_NO = '';
        pi.EMAIL_ID = '';
        pi.MOBILE_NO = '';
        pi.SEARCH_OPERATION = 'or';
        

        ReportRequestWrapper rrw = new ReportRequestWrapper();
        rrw.POLICY_INFO = pi;
        return JSON.serialize(rrw);
    }

    /*********************************************************
    *Class        :  ReportRequestWrapper
    *Author       :  Gaurav Sharma
    *Created Date :  07/11/2024
    *@description  : This is the wrapper class for the request that we'll send for the API call
    *********************************************************/
    public class ReportRequestWrapper{
        public POLICY_INFO POLICY_INFO;
    }

    /*********************************************************
    *Class        :  POLICY_INFO
    *Author       :  Gaurav Sharma
    *Created Date :  07/11/2024
    *@description  : This is the internal wrapper class to hold the request details
    *********************************************************/
    public class POLICY_INFO{
        public String POLICY_NO;
        public String APPLICATION_NO;
        public String CLAIM_NO;
        public String EMAIL_ID;
        public String MOBILE_NO;
        public String SEARCH_OPERATION;
    }

    /*********************************************************
    *Class        :  ReportResponseWrapper
    *Author       :  Gaurav Sharma
    *Created Date :  07/11/2024
    *@description  : This is the wrapper class to hold the response to send to the client side
    *********************************************************/
    public class ReportResponseWrapper {

        @AuraEnabled public List<PolicyInfo> PolicyInfo;
        @AuraEnabled public Integer StatusCode;
        @AuraEnabled public String Message;
    }
    
    /*********************************************************
    *Class        :  PolicyInfo
    *Author       :  Gaurav Sharma
    *Created Date :  07/11/2024
    *@description  : This is the wrapper class to hold the response from API
    *********************************************************/
        public class PolicyInfo {
            @AuraEnabled public String DOCUMENT_DESCRIPTION;
            @AuraEnabled public String DOCUMENT_ID;
            @AuraEnabled public String EMAIL_ID;
            @AuraEnabled public String MOBILE_NO;
            @AuraEnabled public String SNO;
            @AuraEnabled public String APPLICATION_NO;
            @AuraEnabled public String RECORD_PROCESS_DATE;
            
            // @AuraEnabled public String POLICY_NO;
            // @AuraEnabled public String CLAIM_NO;
            // @AuraEnabled public String SOURCE_SYSTEM;
            // @AuraEnabled public String IMPACT_MODULES;
            // @AuraEnabled public String MODE_OF_COMMUNICATION;
            // @AuraEnabled public String CC_EMAIL_ID;
            // @AuraEnabled public String BCC_EMAIL_ID;
            // @AuraEnabled public String EMAIL_STATUS;
            // @AuraEnabled public String EMAIL_CONTENT;
            // @AuraEnabled public String EMAIL_REQUEST_TIME;
            // @AuraEnabled public String EMAIL_RESPONSE_TIME;
            // @AuraEnabled public String SMS_STATUS;
            // @AuraEnabled public String SMS_CONTENT;
            // @AuraEnabled public String SMS_REQUEST_TIME;
            // @AuraEnabled public String SMS_RESPONSE_TIME;
            // @AuraEnabled public String MEMBER_ID;
            // @AuraEnabled public String NOTIFICATION_STATUS;
            // @AuraEnabled public String NOTIFICATION_CONTENT;
            // @AuraEnabled public String NOTIFICATION_REQUEST_TIME;
            // @AuraEnabled public String NOTIFICATION_RESPONSE_TIME;
            // @AuraEnabled public String DOCID;
            // @AuraEnabled public String TRIGGER_MODE;
            // @AuraEnabled public String OMNI_UPLOAD_DATETIME;
        }
}