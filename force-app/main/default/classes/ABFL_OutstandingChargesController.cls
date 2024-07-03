/*********************************************************
*@Class        :  ABFL_OutstandingChargesController
*@Author       :  Salesforce
*@Created Date :  08/04/2023
*@Last Modified:  
*@description  :  Class is used for to get the outstanding charges for the LAN
*********************************************************/
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts')
public class ABFL_OutstandingChargesController {
    /**
    * @param customerLAN - LAN of Account
    * @return - ResponseWrapper 
    * @description - this method returns the Response in the form of payload & status code for outstanding charges
    */
    @auraEnabled
    public static ResponseWrapper getOutstandingCharges(String customerLAN){
        ResponseWrapper response;
        String integrationName = 'ABFL_Outstanding_Charges';
        String payload =  JSON.serialize(new OutstandingRequestBody(customerLAN));
        ABCL_IntegrationCallout.IntegrationResponseWrapper outstandingChargesRes = ABCL_IntegrationCallout.executeCallout(integrationName,payload,null);
        if(outstandingChargesRes.responseBody != null){
            response = new ResponseWrapper(outstandingChargesRes.statusCode,outstandingChargesRes.responseBody.toString());
        }
        return response;
    }

    /**
    * @description - wrapper class for the outstanding charges API.
    */
    public class OutstandingRequestBody{
        string chargeBreakupRequired = 'Y';
        string loanAccountNumber;
        string requestChannel='ATM';
        OutstandingRequestBodyHeader requestHeader = new OutstandingRequestBodyHeader();
        /**
        * @description - wrapper class for the outstanding charges API.
        * @param lan - Loan Account Number
        */
        public OutstandingRequestBody(String lan){
            this.loanAccountNumber = lan;
        }
    }
    /**
    * @description - wrapper class for the outstanding charges API.
    */
    public class OutstandingRequestBodyHeader{
        integer tenantId=505;
        OutstandingRequestUserDetails userDetail;
        /**
        * @description - wrapper class for the outstanding charges API.
        */
        public OutstandingRequestBodyHeader(){
            userDetail = new OutstandingRequestUserDetails();
        }
    }
    /**
    * @description - wrapper class for the outstanding charges API.
    */
    public class OutstandingRequestUserDetails{
        integer branchId = 5;
        string userCode = 'SYSTEM';
    }

    /**
    * @description - wrapper class for the outstanding charges API.
    */
    public Class ResponseWrapper{
        @auraEnabled
        public Integer statusCode;
        @auraEnabled
        public String payload;
        /**
        * @description - wrapper class for the outstanding charges API.
        * @param statusCode - Holds the status code of integration 
        * @param res - hold the response of integration
        */
        public ResponseWrapper(Integer statusCode, String res){
            this.statusCode = statusCode;
            this.payload = res;
        }
    }
}