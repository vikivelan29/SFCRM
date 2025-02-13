public class ABCD_DGTransactionHistoryController {
    
    @AuraEnabled
    public static TransactionHistoryResult getTransactions(String mobileNumber, String customerID, String emailID, Date startDate, Date toDate) {
        List<TransactionRecord> transactionRecords = new List<TransactionRecord>();
        Boolean isSuccess = false;
        String errorMessage = null;
    
        try {
            TransactionHistoryRequest payload = new TransactionHistoryRequest();
            payload.mobileNumber = mobileNumber;
            payload.emailID = emailID;
            payload.startDate = startDate;
            payload.customerID = customerID;
            payload.toDate = toDate;
    
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
                errorMessage = 'Invalid response from the external service';
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
        public String emailID;
        public String customerID;
        public Date startDate;
        public Date toDate;
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