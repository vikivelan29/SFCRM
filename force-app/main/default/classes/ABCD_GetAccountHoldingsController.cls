/**
* @description       ABCD Customer Info 
* @author            : dhinesh.t@salesforce.com
* @group             : 
* @last modified on  : 02-12-2024
* @last modified by  : dhinesh.t@salesforce.com
* Modifications Log
* Ver   Date         Author                       Modification
* 1.0   02-12-2024   dhinesh.ta@salesforce.com   Initial Version
**/
public class ABCD_GetAccountHoldingsController {
	@AuraEnabled
    public static GetAccountHoldingsResult getAccountHoldings(String customerId, String lob) {
        List<String> holdingIDs = new List<String>();
        Boolean isSuccess = false;
        String errorMessage = null;
    
        try {
            HoldingIdsRequest payload = new HoldingIdsRequest();
            payload.customerId = customerId;
            payload.lob = lob;
    
            String integrationName = 'ABCD_Get_Customer_Holdings';
            String serializedPayload = JSON.serialize(payload);
            ABCL_IntegrationCallout.IntegrationResponseWrapper responseWrapper = ABCL_IntegrationCallout.executeCallout(
                integrationName,
                serializedPayload,
                null
            );
    
            if (responseWrapper != null && responseWrapper.statusCode == 200 && String.isNotBlank(responseWrapper.responseBody)) {
                HoldingIdsResponse response = (HoldingIdsResponse) JSON.deserialize(responseWrapper.responseBody, HoldingIdsResponse.class);
    			system.debug(response);
                if (response != null && response.status == 'Success' && response.holdingIdsInfo != null) {
                    holdingIDs = response.holdingIdsInfo.holdingIDs;
                    isSuccess = true;
                } else {
                    errorMessage = response != null ? response.message : 'Unexpected response structure';
                }
            } else {
                errorMessage = 'Invalid response from the external service';
            }
        } catch (Exception e) {
            System.debug('Error in getAccountHoldings: ' + e.getMessage());
            errorMessage = 'Error retrieving account holdings: ' + e.getMessage();
        }
    
        return new GetAccountHoldingsResult(isSuccess, holdingIDs, errorMessage);
        
    }

    
    @AuraEnabled(cacheable=true)
    public static String getClientCode(Id caseId) {
        return [SELECT Account.Client_Code__c FROM Case WHERE Id = :caseId].Account.Client_Code__c;
    }
    
    public class HoldingIdsRequest {
        public String customerId;
        public String lob;
    }
	public class HoldingIdsInfo {
        public String LOB;
        public List<String> holdingIDs;
    }

    public class HoldingIdsResponse {
        public Integer code;
        public HoldingIdsInfo holdingIdsInfo;
        public String message;
        public String status;
    }
    
    public class GetAccountHoldingsResult {
        @AuraEnabled
        public Boolean isSuccess;
        @AuraEnabled
        public List<String> holdingIDs;
        @AuraEnabled
        public String errorMessage;
    
        public GetAccountHoldingsResult(Boolean isSuccess, List<String> holdingIDs, String errorMessage) {
            this.isSuccess = isSuccess;
            this.holdingIDs = holdingIDs;
            this.errorMessage = errorMessage;
        }
    }
    
}