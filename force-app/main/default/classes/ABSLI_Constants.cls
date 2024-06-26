public class ABSLI_Constants {

    public static final String SUCCESS = 'Success';
    public static final String ERROR = 'Error';
    public static final String CANCELED = 'Canceled';
    public static final String PENDING = 'Pending';
    public static final String WAITING_API_RESPONSE = 'Waiting for API response';
    public static final String QUERY = 'Query';
    public static final string REQUEST = 'Request';
    public static final string BUSINESS_UNIT = 'ABSLI';
    public static final string EVALUATION_SUCCESS = 'Evaluation Success';
    public static final String COMPLETED = 'Completed';
    public static final String strResidence = 'Thane';
    public static final String BANK_ESB_FAILURE_RESPONSE = 'Unable to fetch Bank details. Please try again later.';
    public static final String COMM_LOG_DEFAULT_STATUS = 'In Progress';
    public static final String CHECKLIST_PASS_STATUS = 'Signature Matched,Yes';

    /* Bitly Link REAL TIME API
     */
    public static final String BITLYLINK_INTEGRATION_METADATA = 'ABSLI_Bitly_Link';
    /* Fund Value REAL TIME API
     */
    public static final String FUND_VALUE_API_METADATA = 'ABSLI_Fund_Value';

    /* POLICY NOMINEE REAL TIME FETCH API
     */
    public static final String FETCH_POLICY_NOMINEE_METADATA = 'ABSLI_Policy_Nominee';

    /* BANK BRANCH DETAIL REAL TIME FETCH API - THIS IS CALLED FROM ABSLI_FetchBankDetailsController.
     */
    public static final String FETCH_BANK_DETAIL_METADATA = 'ABSLI_Bank_Branch_Detail';

    /** SERVICES NAME BELOW **/
    public static final String MobileUpdateSrvName = 'ContactUpdateApi';
    public static final String WHATSAPPOPTOUT_OPTIN_NAME = 'WHATSAPPOPTOUT_OPTINApi';
    public static final String PanUpdateSrvName = 'PanUpdateApi';
    public static final String BankEsbSrvName = 'BankESBService';
    public static final String AddressUpdateSrvName = 'Address Update';
    public static final String ModeChangeSrvName = 'ModeChangeApi';
    public static final String SurvivalUpdateSrvName = 'survivalUpdateApi';

    /* BITLY INTEGRATION **/
    public static final String BITLY_LOB_VAL = '';
    public static final Integer EXPIRY_DAY = 0;
    public static final String BITLY_CLIENT_IP = '';


    public static final String ESB_SOURCE_ID = Label.ABSLI_ESB_SOURCE_VAL;

    /* POLICY ACCOUNT STATEMENT INTEGRATION **/
    public static final String POLICYSTATEMENT_SERVICE_NAME = 'PasApi';
    public static final String POLICYSTATEMENT_STATEMENT_OPTION = 'unit';
    public static final String POLICYSTATEMENT_OUTPUT_FORMAT = 'EPDF';
    public static final String POLICYSTATEMENT_STATEMENT_FORMAT = 'IRDA';
    public static final String POLICYSTATEMENT_AGENT_CODE = 'a2p9i9';
    public static final String POLICYSTATEMENT_EVALUATION_ERROR = 'ABSLI_POLICYSTATEMENT_EVALUATION_ERROR';
    public static final String POLICYSTATEMENT_SUCCESS_MESSAGE = 'ABSLI_POLICYSTATEMENT_SUCCESS_MESSAGE';
    public static final String POLICYSTATEMENT_FAILURE_MESSAGE = 'ABSLI_POLICYSTATEMENT_FAILURE_MESSAGE';

    /* TAX CERTIFICATE DOWNLOAD INTEGRATION **/
    public static final String TAXCERTIFICATE_SERVICE_NAME = 'PPCApi';
    public static final String TAXCERTIFICATE_OUTPUT_FORMAT = 'EPDF';
    public static final String TAXCERTIFICATE_AGENT_CODE = 'a2p9i9';
    public static final String TAXCERTIFICATE_EVALUATION_ERROR = 'ABSLI_TAXCERTIFICATE_EVALUATION_ERROR';
    public static final String TAXCERTIFICATE_SUCCESS_MESSAGE = 'ABSLI_TAXCERTIFICATE_SUCCESS_MESSAGE';
    public static final String TAXCERTIFICATE_FAILURE_MESSAGE = 'ABSLI_TAXCERTIFICATE_FAILURE_MESSAGE';

    /* BANK ACCOUNT UPDATE INTEGRATION **/
    public static final String BANKACCOUNTUPDATE_SERVICE_NAME = 'BankAccountUpdateApi';
    public static final String BANKACCOUNTUPDATE_MICR_CODE = '000000000';
    public static final String BANKACCOUNTUPDATE_TRANSTYPE = 'NEFT';
    public static final String BANKACCOUNTUPDATE_IMPSFLAG = 'Success';
    public static final String BANKACCOUNTUPDATE_IMPS_STATUSCODE = '0';
    public static final String BANKACCOUNTUPDATE_IMPS_STATUSDESC = '0';
    public static final String BANKACCOUNTUPDATE_EVALUATION_ERROR = 'ABSLI_BANKACCOUNTUPDATE_EVALUATION_ERROR';
    public static final String BANKACCOUNTUPDATE_SUCCESS_MESSAGE = 'ABSLI_BANKACCOUNTUPDATE_SUCCESS_MESSAGE';
    public static final String BANKACCOUNTUPDATE_FAILURE_MESSAGE = 'ABSLI_BANKACCOUNTUPDATE_FAILURE_MESSAGE';

    /* PURPOSE OF ISSUANCE INTEGRATION **/
    public static final String PURPOSEISSUANCE_SERVICE_NAME = 'poiUpdate';
    public static final String PURPOSEISSUANCE_EVALUATION_ERROR = 'ABSLI_PURPOSEISSUANCE_EVALUATION_ERROR';
    public static final String PURPOSEISSUANCE_SUCCESS_MESSAGE = 'ABSLI_PURPOSEISSUANCE_SUCCESS_MESSAGE';
    public static final String PURPOSEISSUANCE_FAILURE_MESSAGE = 'ABSLI_PURPOSEISSUANCE_FAILURE_MESSAGE';
    public static final String PURPOSEISSUANCE_SUCCESS_RESPONSE = 'POI update success';

    /* CONTACT DETAIL UPDATE INTEGRATION ERROR **/
    public static final String CONTACTUPDATE_SERVICE_NAME = 'ContactUpdateApi';
    public static final Map<String,String> CONTACTUPDATE_EVALUATE_ERROR = new Map<String,String>{'PNFT008'=>'ABSLI_MOBILEUPDATE_EVALUATION_ERROR',
        'PNFT007' => 'ABSLI_EMAILEUPDATE_EVALUATION_ERROR'};
    public static final String CONTACTUPDATE_SUCCESS_MESSAGE = 'ABSLI_CONTACTUPDATE_SUCCESS_MESSAGE';
    public static final String CONTACTUPDATE_FAILURE_MESSAGE = 'ABSLI_CONTACTUPDATE_FAILURE_MESSAGE';

	  /* REAL TIME INTEGRATION METADATA NAME */

    public static final String PAN_VERIFICATION_INTEGRATION_METADATA = 'ABSLI_PAN_Verification';
    public static final String BANK_ESB_INTEGRATION_METADATA = 'ABSLI_Bank_ESB_Integration';
    public static final String FETCHPOLICY_ESB_INTEGRATION_METADATA = 'ABSLI_FETCH_POLICY_ESB';


}
