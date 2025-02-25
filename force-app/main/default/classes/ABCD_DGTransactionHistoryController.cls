public class ABCD_DGTransactionHistoryController {
    
    @AuraEnabled
    public static TransactionHistoryResult getTransactions(String mobileNumber, String customerID, String emailID, String startDate, String toDate) {
        List<TransactionRecord> transactionRecords = new List<TransactionRecord>();
        Boolean isSuccess = false;
        String errorMessage = null;
    
        try {
            TransactionHistoryRequest payload = new TransactionHistoryRequest();
            if (String.isNotBlank(customerID)) {
                payload.customerId = customerID;
                payload.mobileNumber = '';
                payload.emailId = '';
            } else {
                payload.customerId = '';
                payload.mobileNumber = mobileNumber;
                payload.emailId = emailID;
            }
            if(startDate == NULL){
            	payload.startDate = '';    
            }else{
                payload.startDate = startDate;    
            }
            if(toDate == NULL){
            	payload.endDate = '';    
            }else{
                payload.endDate = toDate;    
            }
            
    
            String integrationName = 'ABCD_Get_DG_Transactions';
            String serializedPayload = JSON.serialize(payload);
            system.debug(serializedPayload);
            ABCL_IntegrationCallout.IntegrationResponseWrapper responseWrapper = ABCL_IntegrationCallout.executeCallout(
                integrationName,
                serializedPayload,
                null
            );
    
            if (responseWrapper != null && responseWrapper.statusCode == 200 && String.isNotBlank(responseWrapper.responseBody)) {
                TransactionsResponse response = (TransactionsResponse) JSON.deserialize(responseWrapper.responseBody, TransactionsResponse.class);
                system.debug(response);
                if (response != null && response.status == 'Success' && response.dgTransactionInfo != null) {
                    transactionRecords = response.dgTransactionInfo.dgTransactionDetails;
                    isSuccess = true;
                } else {
                    errorMessage = response != null ? response.message : 'Unexpected response structure';
                }
            } else {
                errorMessage = 'Unexpected error, pls try again or contact your administrator';
            }
        } catch (Exception e) {
            System.debug('Error in getTransactions: ' + e.getMessage());
            errorMessage = 'Error retrieving transactions: ' + e.getMessage();
        }
        System.debug('Final Transactions being returned: ' + JSON.serialize(transactionRecords));
        TransactionHistoryResult toDebug = new TransactionHistoryResult(isSuccess, transactionRecords, errorMessage);
        System.debug('Final Transactions being returned: ' + JSON.serialize(toDebug));
        return new TransactionHistoryResult(isSuccess, transactionRecords, errorMessage);
    }
    
    public class TransactionHistoryRequest {
        public String mobileNumber;
        public String emailId;
        public String customerId;
        public String startDate;
        public String endDate;
    }

    public class TransactionInfo {
        public List<TransactionRecord> dgTransactionDetails;
    }

    public class TransactionsResponse {
        public Integer code;
        public TransactionInfo dgTransactionInfo;
        public String message;
        public String status;
    }
    
    public class TransactionRecord {
        @AuraEnabled public String transactionType;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public Decimal unit;
        @AuraEnabled public DateTime transactionDate;
        @AuraEnabled public String transactionStatus;
    }
    
    public class TransactionHistoryResult {
        @AuraEnabled
        public Boolean isSuccess;
        @AuraEnabled
        public List<TransactionRecord> dgTransactionDetails;
        @AuraEnabled
        public String errorMessage;
    
        public TransactionHistoryResult(Boolean isSuccess, List<TransactionRecord> dgTransactionDetails, String errorMessage) {
            this.isSuccess = isSuccess;
            this.dgTransactionDetails = dgTransactionDetails;
            this.errorMessage = errorMessage;
        }
    }
}