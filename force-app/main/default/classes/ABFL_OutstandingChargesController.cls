/*********************************************************
*@Class        :  ABFL_OutstandingChargesController
*@Author       :  Salesforce
*@Created Date :  08/04/2023
*@Last Modified:  
*@description  :  Class is used for to get the outstanding charges for the LAN
*********************************************************/
public class ABFL_OutstandingChargesController {
    @auraEnabled
    public static ResponseWrapper getOutstandingCharges(String customerLAN){
        ResponseWrapper response;
        String integrationName = 'ABFL_Outstanding_Charges';
        ABCL_Integrations__mdt enachStatusIntegrationRec = ABCL_Integrations__mdt.getInstance(integrationName);
        String payload =  JSON.serialize(new outstandingRequestBody(customerLAN));
        System.debug('Payload ==> '+payload);
        ABCL_IntegrationCallout.IntegrationResponseWrapper outstandingChargesRes = ABCL_IntegrationCallout.executeCallout(integrationName,payload,null);
        if(outstandingChargesRes.responseBody != null){
            response = new ResponseWrapper(outstandingChargesRes.statusCode,outstandingChargesRes.responseBody.toString());
        }
        System.debug('response==> '+response);
        return response;
    }

    public class outstandingRequestBody{
        string chargeBreakupRequired = 'Y';
        string loanAccountNumber;
        string requestChannel='CRM';
        outstandingRequestBodyHeader requestHeader = new outstandingRequestBodyHeader();
        public outstandingRequestBody(String lan){
            this.loanAccountNumber = lan;
        }
    }
    public class outstandingRequestBodyHeader{
        integer tenantId=505;
        outstandingRequestUserDetails userDetail;
        public outstandingRequestBodyHeader(){
            userDetail = new outstandingRequestUserDetails();
        }
    }
    public class outstandingRequestUserDetails{
        integer branchId = 5000000;
        string userCode = 'SYSTEM';
    }

    public Class ResponseWrapper{
        @auraEnabled
        public Integer statusCode;
        @auraEnabled
        public String payload;
        public ResponseWrapper(Integer statusCode, String res){
            this.statusCode = statusCode;
            this.payload = res;
        }
    }
}