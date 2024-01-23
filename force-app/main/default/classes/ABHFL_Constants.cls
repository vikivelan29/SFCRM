/*********************************************************
*Name           :   ABHFL_Constants
*Author         :   Vishal Gangwar
*Since          :   26 Dec 2023
*Description    :   Constant class for ABHFL
*History        :
 Name                Date                  Change Description
 Vishal Gangwar      26/12/2023            Initial
 
*********************************************************/
public with sharing class ABHFL_Constants {

   //Generic Constants
    public static final String SUCCESS = 'Success';
    public static final String ERROR = 'Error';
    public static final String CANCELED = 'Canceled';
    public static final String PENDING = 'Pending';
    public static final String FAILURE = 'Failure';
    public static final String COMPLETED = 'Completed';
    public static final String RESOLVED = 'Resolved';
    public static final String QUEUE= 'Queue';
    public static final String BRANCH = 'Branch';
    public static final String CRM = 'CRM';
    public static final String EMAIL = 'Email';
    public static final String BINARY_DATA = 'BinaryData';
    public static final String BKL = 'BKL';
    public static final String SANCTION_LETTER = 'Sanction Letter';
    public static final String BALANCE_CONFIRMATION_LETTER = 'Balance Confirmation Letter';
    public static final String SANCTION_FILE = 'Sanction File';
    public static final String WELCOME_KIT = 'WelcomeKit';
    public static final String AMORTIZATION = 'Amortization Letter';
    public static final String LOD_NAME = 'List of Documents';
    public static final String ABHFL_CUSTOMER_SERVICE_TEAM = 'ABHFL_Customer_Service_Team';
    public static final String WAITING_API_RESPONSE = 'Waiting for API response';
    public static final String STP_DOC_RETRIEVAL_FAILURE = 'STP Document Retrieval Failure';
    @auraEnabled public final String ABHFL = 'ABHFL';
    
    
    //Constants for Welcome Kit STP Flow
    public static final String WK_EVALUATION_FAILED_ERROR = 'Evaluation Failed, cannot retrieve Welcome Kit.';
    public static final String WK_EVALUATION_SUCCESS_RESPONSE = 'Evaluation Success, Submit to get the Welcome Kit.';
    public static final String WK_EVALUATION_FAILED_DIGITAL_ERROR = 'Evaluation failed. Disbursal date is > 6 months.';
    public static final String WK_EVALUATION_FAILED_OFFLINE_ERROR = 'Disbursal date is > 6 months. Please inform the customer that Welcome Kit cannot be provided.'; 
    
    public static final String ACCOUNT_STATUS_CLOSED = 'Closed';
    public static final String NDC_STP_NAME = 'NDC';
    public static final String NDC_REPORT = 'NDCReport';
    public static final String LOD_REPORT = 'LODReport';
    public static final String ACCOUNT_RECORDTYPE_INDIVIDUAL = 'Individual';
    public static final String ACCOUNT_RECORDTYPE_NON_INDIVIDUAL = 'Non-Individual';
    public static final String PAYMENTLINK_INTEGRATION_METADATA = 'Payment_Link';
    public static final String PAYTMLINK_INTEGRATION_METADATA = 'Paytm_Link';
    public static final String DATASERVICE_INTEGRATION_METADATA = 'Data_Service_Details';
    public static final String PAYTM_REQUEST_TYPE = 'Coll';
    public static final String REASON_FOR_PAYMENT = 'Repricing related charges';
    public static final String REPORTING_SERVICE = 'ReportingService';
    public static final String IC_DOCUMENT_TYPE = 'ReportFilePath';
    public static final String PIC_DOCUMENT_TYPE = 'BinaryData';
    public static final String IC_REPORT_NAME = 'InterestCertificate';
    public static final String PIC_REPORT_NAME = 'ProvisionalCertificateBinary';
    public static final String ABHFL_PaymentLink = 'Payment_Link_VF';


    // Constants for REKYC 
    public static String reKycServiceName = 'Send_RKYC_API';
    public static String reKycIntegrationName = 'REKYC';
    

    // Constants for Bitly
    public static String bitlyServiceName = 'Bitly Url Integration';
    public static String bitlyIntegrationName = 'Bitly_Url';


    //Constants for Statement Of Account
    public static String soaIntegrationName = 'SOA_API';


    

    @AuraEnabled(cacheable=true)
    public static ABHFL_Constants getAllConstants() {
        return new ABHFL_Constants();
    }
}