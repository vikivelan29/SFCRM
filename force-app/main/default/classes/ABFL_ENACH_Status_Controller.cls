/*********************************************************
*@Class        :  ABFL_ENACH_Status_Controller
*@Author       :  Salesforce
*@Created Date :  19/03/2024
*@Last Modified:  
*@description  :  Class is used for to get the ENACH Status
*********************************************************/
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts,PMD.FieldNamingConventions,PMD.FormalParameterNamingConventions, PMD.VariableNamingConvenstions')
public class ABFL_ENACH_Status_Controller {
    /**
    * @param customerId - Client Code of Account
    * @return - ResponseWrapper 
    * @description - this method returns the Response in the form of payload & status code for ENACH Status
    */
    @auraEnabled
    public static ResponseWrapper getENACHStatus(String customerId){
        try{
            ResponseWrapper response;
            String integrationName = 'ABFL_ENACH_Status';
            ABCL_Integrations__mdt enachStatusIntegrationRec = ABCL_Integrations__mdt.getInstance(integrationName);
            String merchantId = enachStatusIntegrationRec.Merchant_Id__c;
            String payload =  ABCL_Encryption.encrypt(JSON.serialize(new EnachStatusReqest(merchantId, customerId)));
            String conPayload = JSON.serialize(new Map<String, Object>{'content' => payload});
            ABCL_IntegrationCallout.IntegrationResponseWrapper enachResponse = ABCL_IntegrationCallout.executeCallout(integrationName,conpayload,null);
            String res;
            if(enachResponse.responseBody != null){
                if(enachResponse.responseBody.toString().contains('content')){
                    Map<String, Object> mapResObject = (Map<String, object>) JSON.deserializeUntyped(enachResponse.responseBody);
                    res = ABCL_Encryption.decrypt(mapResObject.get('content').toString());
                }else{
                    res = ABCL_Encryption.decrypt(enachResponse.responseBody.toString().remove('"'));
                }
                response = new ResponseWrapper(enachResponse.statusCode,res);
            }
            return response;
        }catch(exception e){
            throw new AuraHandledException('Error : '+e.getMessage()+' '+e.getLineNumber());
        }
    }

    /**
    * @description - Wrapper class ENACH Status
    */
    public class EnachStatusReqest{
        String pl_merchant_id;
        String customer_Id;
        /**
        * @param mId - Marchant Id
        * @param customerId - Customer Id 
        * @description - this method returns the Response in the form of payload & status code for ENACH Status
        */
        EnachStatusReqest(String mId, String customerId){
            this.pl_merchant_id = mId;
            this.customer_Id = customerId;
        }
    }

    /**
    * @description - Wrapper class ENACH Status response 
    */
    public Class ResponseWrapper{
        @auraEnabled
        public Integer statusCode;
        @auraEnabled
        public String payload;

        /**
        * @param statusCode - 
        * @param  res
        * @description - Wrapper class ENACH Status
        */
        public ResponseWrapper(Integer statusCode, String res){
            this.statusCode = statusCode;
            this.payload = res;
        }
    }
    
   
}