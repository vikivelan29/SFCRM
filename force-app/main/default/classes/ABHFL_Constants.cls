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
    public static final String ABHFL_CUSTOMER_SERVICE_TEAM = 'ABHFL_Customer_Service_Team';
    public static final String WAITING_API_RESPONSE = 'Waiting for API response';
    
    
   //Constants for Balance Confirmation Letter STP Flow
    public static final String BCL_EVALUATION_FAILED_LAN_EMAIL_ERROR = 'Evaluation Failed, LAN or STP Request Type is Empty, Can not retrieve Balance Confirmation Letter.';
    public static final String BCL_EVALUATION_SUCCESS_RESPONSE = 'Evaluation Success, Submit to get the Balance Confirmation Letter.';
    public static final String BCL_EVALUATION_FAILED_AS_ON_DATE_ERROR = 'Evaluation failed. As on Date is Empty.';
    public static final String BCL_RUN_SUCCESS = 'Run Success, Submitted to get the Balance Confirmation Letter.';
    
    
   //Constants for Sanction Letter STP Flow 
    public static final String SL_EVALUATION_FAILED_LAN_ERROR = 'Evaluation Failed, Loan Account Number is blank, Can not retrieve Sanction Letter.';
    public static final String SL_EVALUATION_SUCCESS_RESPONSE = 'Evaluation Success, Submitted to get the Sanction Letter.';
    public static final String SL_RUN_SUCCESS = 'Run Success, Submitted to get the Sanction Letter.';
    
    //Constants for Welcome Kit STP Flow
    public static final String WK_EVALUATION_FAILED_ERROR = 'Evaluation Failed, cannot retrieve Welcome Kit.';
	public static final String WK_EVALUATION_SUCCESS_RESPONSE = 'Evaluation Success, Submit to get the Welcome Kit.';
	public static final String WK_EVALUATION_FAILED_DIGITAL_ERROR = 'Evaluation failed. Disbursal date is > 6 months.';
	public static final String WK_EVALUATION_FAILED_OFFLINE_ERROR = 'Disbursal date is > 6 months. Please inform the customer that Welcome Kit cannot be provided.'; 
    
    // Constants for Statement Of Account STP Flow
    public static final String SOA_EVALUATION_FAILED_DATE_ERROR = 'Evaluation Failed, From_Date or To_Date cannot be blank.';
    public static final String SOA_EVALUATION_SUCCESS_RESPONSE = 'Evaluation Success, Submit to get statement Of Account.';
    public static final String SOA_RUN_SUCCESS = 'Run Success, Submitted to get the Statement Of Account.';
    
    public static final String ACCOUNT_STATUS_CLOSED = 'Closed';
    public static final String NDC_STP_NAME = 'NDC';
    public static final String NDC_REPORT = 'NDCReport';
    public static final String ACCOUNT_RECORDTYPE_INDIVIDUAL = 'Individual';
    public static final String ACCOUNT_RECORDTYPE_NON_INDIVIDUAL = 'Non-Individual';
    public static final String PAYMENTLINK_INTEGRATION_METADATA = 'Payment_Link';
    public static final String PAYTMLINK_INTEGRATION_METADATA = 'Paytm_Link';
    public static final String PAYTM_REQUEST_TYPE = 'Coll';
    public static final String REASON_FOR_PAYMENT = 'Repricing related charges';
}