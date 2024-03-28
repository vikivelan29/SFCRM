/*********************************************************
*@Class        :  ABFL_ENACH_Status_Controller
*@Author       :  Salesforce
*@Created Date :  19/03/2024
*@Last Modified:  
*@description  :  Class is used for to get the ENACH Status
*********************************************************/
public class ABFL_ENACH_Status_Controller {
    @auraEnabled
    public static ResponseWrapper getENACHStatus(String customerId){
        try{
            ResponseWrapper response;
            String integrationName = 'ABFL_ENACH_Status';
            ABCL_Integrations__mdt enachStatusIntegrationRec = ABCL_Integrations__mdt.getInstance(integrationName);
            String merchantId = enachStatusIntegrationRec.Merchant_Id__c;
            String payload =  ABCL_Encryption.encrypt(JSON.serialize(new EnachStatusReqest(merchantId, customerId)));
            String conPayload = JSON.serialize(new Map<String, Object>{'content' => payload});
            ABCL_IntegrationCallout.IntegrationResponseWrapper enachResponse = ABCL_IntegrationCallout.executeCallout(integrationName,conPayload,null);
            if(enachResponse.responseBody != null){
                System.debug(' response Body ==> '+enachResponse.responseBody);
                String res = ABCL_Encryption.decrypt(enachResponse.responseBody.remove('"'));
                response = new ResponseWrapper(enachResponse.statusCode,res);
            }
            System.debug('response==> '+response);
            return response;
        }catch(exception e){
            throw new AuraHandledException('Error : '+e.getMessage());
        }
    }

    public class EnachStatusReqest{
        String pl_merchant_id;
        String customer_Id;
        EnachStatusReqest(String mId, String customer_Id){
            this.pl_merchant_id = mId;
            this.customer_Id = customer_Id;
        }
    }

    public Class ResponseWrapper{
        @AuraEnabled
        public Integer statusCode;
        @AuraEnabled
        public String payload;
        public ResponseWrapper(Integer statusCode, String res){
            this.statusCode = statusCode;
            this.payload = res;
        }
    }
}