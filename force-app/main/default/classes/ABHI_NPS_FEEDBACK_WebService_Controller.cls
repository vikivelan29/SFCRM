/*********************************************************
*Class        :  ABHI_NPS_FEEDBACK_WebService_Controller
*Author       :  Anirudh Raturi
*Created Date :  26/08/2024
*@description  :  Class for NPS FEEDBACK INBOUND API 
*********************************************************/

@SuppressWarnings('PMD.ExcessivePublicCount,PMD.ApexDoc')
/******************************************
    Endpoint - services/apexrest/ABHI_NPS_FEEDBACK_API/V1

    Our Response for Status Code & Message:   
    Success Code & Message:
    1000: ‘Success’ 
    1001: ‘Failure’ 
*******************************************/
@RestResource(urlMapping='/ABHI_NPS_FEEDBACK_API/V1/*')
global with sharing class ABHI_NPS_FEEDBACK_WebService_Controller {

    @HttpPost
    global static NPS_FEEDBACK_RESPONSE_WRAPPER createSurveyResponse() {

        NPS_FEEDBACK_RESPONSE_WRAPPER respWrapper = new NPS_FEEDBACK_RESPONSE_WRAPPER();
        ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResponse = new ABCL_IntegrationCallout.IntegrationResponseWrapper();
        ASF_Case_Integration__c caseIntg = new ASF_Case_Integration__c(Type__c = 'NPSFEEDBACK');
        ABCL_Integrations__mdt integrationMdt = ABCL_IntegrationCallout.getIntegrationMetadata('ABHI_NPS_FEEDBACK_INBOUND');
        ABHI_NPS_FEEDBACK_WebService_Controller npsFeedbackObj = new ABHI_NPS_FEEDBACK_WebService_Controller();
        String sucessMessage = Custom_Messages__mdt.getInstance('ABHI_NPS_FEEDBACK_SUCCESS_MESSAGE').Message__c;
        integrationResponse.requestBody = RestContext.request.requestBody.toString();
        Boolean hasError = false;
        String tagPrivateCustomerId = '';

        try {
            NPS_FEEDBACK_REQUEST_WRAPPER npsReqWrapper = (NPS_FEEDBACK_REQUEST_WRAPPER)JSON.deserialize(integrationResponse.requestBody, NPS_FEEDBACK_REQUEST_WRAPPER.class);
            try {
                respWrapper = npsFeedbackObj.createSurveyResponse(npsReqWrapper);
                ABHI_ResponseWrapper resp = new ABHI_ResponseWrapper('1000',ABHI_Constants.SUCCESS, sucessMessage);
                integrationResponse.responseBody = JSON.serialize(resp, true);
                respWrapper.StatusCode = '1000';
                respWrapper.StatusMessage = ABHI_Constants.SUCCESS;
                respWrapper.StatusRemarks = sucessMessage;
            }
            catch(Exception e) {
                integrationResponse.responseBody = JSON.serialize(new ABHI_ResponseWrapper('1001', ABHI_Constants.FAILURE, e.getMessage()), true);
                respWrapper.StatusCode = '1001';
                respWrapper.StatusMessage = ABHI_Constants.FAILURE;
                respWrapper.StatusRemarks = e.getMessage();
                hasError = true;
            }
            tagPrivateCustomerId = npsReqWrapper?.tag_private_customer_id;
        }
        catch(Exception e) {
            integrationResponse.responseBody = JSON.serialize(new ABHI_ResponseWrapper('1001', ABHI_Constants.FAILURE, e.getMessage()), true);
            respWrapper.tag_private_customer_id = tagPrivateCustomerId;
            respWrapper.StatusCode = '1001';
            respWrapper.StatusMessage = ABHI_Constants.FAILURE;
            respWrapper.StatusRemarks = Custom_Messages__mdt.getInstance('ABHI_InvalidJson').Message__c;
        }
        finally {
            respWrapper.tag_private_customer_id = tagPrivateCustomerId;
            ABHI_ResponseWrapper.createLog(caseIntg, integrationMdt, integrationResponse, hasError);
        }

        return respWrapper;
    }

    /**
    * @param       - reqBody 
    * @return      - String 
    * @description - This method create the the Survey_Response__c Record.
    */
    public NPS_FEEDBACK_RESPONSE_WRAPPER createSurveyResponse(NPS_FEEDBACK_REQUEST_WRAPPER npsReqWrapper) {

        NPS_FEEDBACK_RESPONSE_WRAPPER respWrapperObj = new NPS_FEEDBACK_RESPONSE_WRAPPER();

        Account acc = new Account(LOB_Client_Code__c = npsReqWrapper?.tag_private_customer_id);

        Survey_Response__c createSurveyResponse   = new Survey_Response__c();
        createSurveyResponse.Business_Unit__c     = ABHI_Constants.ABHI;
        createSurveyResponse.Client_Code__r       = acc;
        createSurveyResponse.Customer_Comments__c = npsReqWrapper?.comment ?? '';
        createSurveyResponse.Date_of_Feedback__c  = Datetime.valueOf(npsReqWrapper?.responded_date);
        createSurveyResponse.Trigger_Name__c      = npsReqWrapper?.project_name ?? '';

        Map<String,Integer> ratings                  = logicToPopulateRating(npsReqWrapper);
        createSurveyResponse.Primary_Question_NPS__c = ratings?.get('actualRating');
        createSurveyResponse.L1_Driver__c            = ratings?.get('L1 Drivers');
        createSurveyResponse.L2_Driver__c            = ratings?.get('L2 Drivers');
        createSurveyResponse.L3_Driver__c            = ratings?.get('L3 Drivers');
    
        if(createSurveyResponse != null && Schema.sObjectType.Survey_Response__c.isCreateable()) {
            insert createSurveyResponse;
        }
        return respWrapperObj;
    }

    /**
    * @param       - npsReqWrapper 
    * @return      - String 
    * @description - This method calculates the logic for population of the field value in Survey_Response__c Record.
    */
    public  Map<String,Integer> logicToPopulateRating(NPS_FEEDBACK_REQUEST_WRAPPER npsReqWrapper) {
        
        Map<String,Integer> mapOfFldToRating = new Map<String, Integer>();
        List<ratings> ratingList = npsReqWrapper?.ratings;

        if(ratingList.size() > 0) {
            for(ratings rt : ratingList) {
                if(rt.field_id == 'primary_rating' && (npsReqWrapper.tag_claim_status == 'repudiation' || npsReqWrapper.tag_earner_type == 'non-earner')) {
                    mapOfFldToRating.put('actualRating', rt.actual_rating);
                }
                if(rt.question == 'L1 Drivers' || rt.question == 'L2 Drivers' || rt.question == 'L3 Drivers') {
                    mapOfFldToRating.put(rt.question, rt.actual_rating);
                }
            }
        }
        else {
            mapOfFldToRating.put('actualRating', Integer.valueOf(npsReqWrapper?.primary_rating));
        }
        return mapOfFldToRating;
    }

    @SuppressWarnings('PMD.PropertyNamingConventions,PMD.ClassNamingConventions')
    global class NPS_FEEDBACK_REQUEST_WRAPPER{

		public String comment{get;set;}
		public String project_name{get;set;}
		public String utmMedium{get;set;}
		public String tag_earner_type{get;set;}
		public String responded_date{get;set;}
		public String tag_claim_status{get;set;}
		public String primary_rating{get;set;}
		public String tag_private_customer_id{get;set;}
		public list<ratings> ratings{get;set;}
		public String feed_id{get;set;}
    }

    @SuppressWarnings('PMD.PropertyNamingConventions,PMD.ClassNamingConventions')
    global class ratings{
        public String question{get;set;}
        public String rating{get;set;}
        public String field_id{get;set;}
        public Integer seq_no{get;set;}
        public Integer actual_rating{get;set;}
    }

    @SuppressWarnings('PMD.PropertyNamingConventions,PMD.ClassNamingConventions')
    global class NPS_FEEDBACK_RESPONSE_WRAPPER {
        public String tag_private_customer_id{get;set;}
        public String StatusCode{get;set;}
        public String StatusMessage{get;set;}
        public String StatusRemarks{get;set;}
    }       
}