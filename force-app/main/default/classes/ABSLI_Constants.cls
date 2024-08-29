/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 08-29-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class ABSLI_Constants {

    public static final String RESOLVED_TEAM_RES_STATUS = 'Resolved';
    public static final String UNRESOLVED_TEAM_RES_STATUS = 'Unresolved';
    public static final String SUCCESS = 'Success';
    public static final String ERROR = 'Error';
    public static final String CANCELED = 'Canceled';
    public static final String PENDING = 'Pending';
    public static final String FAILURE = 'Failure';
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
    public static final List<String> CHECKLIST_FAILURE_STATUS = new List<String>{'Signature Mismatched', 'No'};
	public static final List<String> CHECKLIST_SIGNATURECROPSIGNATUREMISMATCHANDNO_STATUS = new List<String>{'Signature Mismatched', 'No','Signature Not Cropped'};
    public static final List<String> NOMINEE_UPDATE_POLICY_IDENTIFICATION_VALIDATION = new List<String>{'Married Women Property Act','Hindu Undivided Family Act','Key Man Act'};
    public static final String ASSIGNMENT_ISSUE_TYPE_VALIDATION = 'Married Women Property Act';
    public static final String SARAL_HEALTH_PLAN_NAME = 'BSLI Saral Health'; 
    public static final Map<String,String> FIELD_AND_TYPE_FOR_CUSTOMER_PORTAL_REDIRECTION = new Map<String,String>
    {'Reinstatement_Amount__c'=>'Decimal',
     'COI_Covid_Quest__c' => 'String',
     'Medicals__c'=> 'String',
     'Remarks__c' => 'String',
     'COI_Signed_Date__c' => 'Date'};
    public static final Map<String,String> CCC_AND_FUNCTION_CODE = new Map<String,String>
     {
         'PREI001' => 'STPRI',
         'PNFT042' => 'STPFS',
         'PPCT027' => 'STPMC'
     };
     public static final List<String> SURRENDER_WITHDRAWAL_CCC_IDs = new List<String>{'PPAY008', 'PPAY001'};
     public static final String RQ_REDIRECT_COVID_QUE = 'COVID_QUE';
     public static final String CUSTOMER_PORTAL = 'Customer Portal';

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
    public static final String WHATSAPPOPTOUT_OPTIN_NAME = 'WhatappOptoutUpdateApi';
    public static final String InstaIssuranceAPI = 'InstaIssuance_Shared_API';
    public static final String PanUpdateSrvName = 'PanUpdateApi';
    public static final String BankEsbSrvName = 'BankESBService';
    public static final String AddressUpdateSrvName = 'Address Update';
    public static final String ModeChangeSrvName = 'ModeChangeApi';
    public static final String SurvivalUpdateSrvName = 'survivalUpdateApi';
    public static final String RQApiSrvName = 'RQServiceApi';

    /* BITLY INTEGRATION **/
    public static final String BITLY_LOB_VAL = '';
    public static final Integer EXPIRY_DAY = 0;
    public static final String BITLY_CLIENT_IP = '';


    public static final String ESB_SOURCE_ID = Label.ABSLI_ESB_SOURCE_VAL;
    public static final String UIN_API_SOURCE = '4170703233';
    public static final String GEN_FUND_SOURCE = '4170703531';

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
    public static final String TAXCERTIFICATE_SERVICE_NAME = 'TaxCertificateApi';
    public static final String TAXCERTIFICATE_OUTPUT_FORMAT = 'ePDF';
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
    public static final String PURPOSEISSUANCE_SERVICE_NAME = 'PurposeOfInsuanceApi';
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

    /* FETCH NEFT REF NUMBER INTEGRATION ERROR **/
    public static final String FETCHNEFTREF_SERVICE_NAME = 'fetchNEFTRefNum';
    public static final String FETCHNEFTREF_EXTERNALID = 'PNFT021';
    public static final Integer FETCHNEFTREF_BATCH_SIZE = 10;
    public static final String FETCHNEFTREF_SCHEDULDE_JOB = 'Loan NEFT Ref Num Schedulde Job';
    public static final String FETCHNEFTREF_EVALUATION_ERROR = 'ABSLI_FETCHNEFTREF_EVALUATION_ERROR';
    public static final String FETCHNEFTREF_SUCCESS_MESSAGE = 'ABSLI_FETCHNEFTREF_SUCCESS_MESSAGE';
    public static final String FETCHNEFTREF_FAILURE_MESSAGE = 'ABSLI_FETCHNEFTREF_FAILURE_MESSAGE';

    /* LOAN ASSIGNMENT INTEGRATION **/
    public static final String LOANASSIGNMENT_SERVICE_NAME = 'LoanAssignment';
    public static final String LOANASSIGNMENT_CLI_ID = 'BSLILOAN';
    public static final String LOANASSIGNMENT_SUB_CD = 'B';
    public static final String LOANASSIGNMENT_ADDR_CD = 'PR';
    public static final String LOANASSIGNMENT_CREATE_ASSIGNEE = 'N';
    public static final String LOANASSIGNMENT_EVALUATION_ERROR = 'ABSLI_LOANASSIGNMENT_EVALUATION_ERROR';
    public static final String LOANASSIGNMENT_SUCCESS_MESSAGE = 'ABSLI_LOANASSIGNMENT_SUCCESS_MESSAGE';
    public static final String LOANASSIGNMENT_FAILURE_MESSAGE = 'ABSLI_LOANASSIGNMENT_FAILURE_MESSAGE';

    /* LOAN REGISTER INTEGRATION **/
    public static final String LOANREGISTER_SERVICE_NAME = 'registerLoan';
    public static final String LOANREGISTER_STATE_CD = '1';
    public static final String LOANREGISTER_EVALUATION_ERROR = 'ABSLI_LOANREGISTER_EVALUATION_ERROR';
    public static final String LOANREGISTER_SUCCESS_MESSAGE = 'ABSLI_LOANREGISTER_SUCCESS_MESSAGE';
    public static final String LOANREGISTER_FAILURE_MESSAGE = 'ABSLI_LOANREGISTER_FAILURE_MESSAGE';

    /* LOAN APPROVAL INTEGRATION **/
    public static final String LOANAPPROVAL_SERVICE_NAME = 'ApproveVoucherUpdate';
    public static final String LOANAPPROVAL_USER_ID = 'MMSING1';
    public static final String LOANAPPROVAL_ACTION = 'A';
    public static final String LOANAPPROVAL_EVALUATION_ERROR = 'ABSLI_LOANAPPROVAL_EVALUATION_ERROR';
    public static final String LOANAPPROVAL_SUCCESS_MESSAGE = 'ABSLI_LOANAPPROVAL_SUCCESS_MESSAGE';
    public static final String LOANAPPROVAL_FAILURE_MESSAGE = 'ABSLI_LOANAPPROVAL_FAILURE_MESSAGE';
    public static final String LOANAPPROVAL_DEFAULTCOMMENT_NONSTP = 'Case received as Non STP';
    public static final String LOANAPPROVAL_DEFAULTCOMMENT_STP = 'Voucher not approved as amount is more than Rs. 1,00,000';
    public static final Decimal LOANAPPROVAL_CUTOFFAMOUNT = 100000;

    /* LOAN ASSIGNMENT INTEGRATION **/
    public static final String LOANVOUCHERPROCESS_SCHEDULDE_JOB = 'Loan Voucher Process Schedulde Job';
    public static final Integer LOANVOUCHERPROCESS_BATCH_SIZE = 10;
    public static final String LOANVOUCHERPROCESS_SUBTYPE = 'Loan Payout';

    /* MODE CHANGE INTEGRATION **/
    public static final String MODECHANGE_SCHEDULDE_JOB = 'Mode Change Schedulde Job';
    public static final Integer MODECHANGE_BATCH_SIZE = 10;
    public static final String MODECHANGE_CASECATEGORYCONFIG = 'PPCT027';
    public static final String MODECHANGE_DEFAULTSTAGE = 'Soft Resolve';

    /* NOMINEE UPDATE INTEGRATION */
    public static final String DELETENOMINEE_SRV_NAME = 'DeleteNominee';
    public static final String DELETENOMINEE_EVALUATION_ERROR = 'ABSLI_DELETENOMINEE_EVALUTION_ERROR';
    public static final String UPDATENOMINEE_SRV_NAME = 'UpdateNominee';
    public static final String UPDATENOMINEE_EVALUATION_ERROR = 'ABSLI_UPDATENOMINEE_EVALUTION_ERROR';
    public static final String CREATENOMINEE_SRV_NAME = 'CreateNominee';
    public static final String CREATENOMINEE_EVALUATION_ERROR = 'ABSLI_CREATENOMINEE_EVALUTION_ERROR';

	/* REAL TIME INTEGRATION METADATA NAME */
    public static final String PAN_VERIFICATION_INTEGRATION_METADATA = 'ABSLI_PAN_Verification';
    public static final String BANK_ESB_INTEGRATION_METADATA = 'ABSLI_Bank_ESB_Integration';
    public static final String FETCHPOLICY_ESB_INTEGRATION_METADATA = 'ABSLI_FETCH_POLICY_ESB';
    public static final String POLICY_GEN_FUND_INTEGRATION_METADATA = 'ABSLI_Gen_Fund_Integration';
    public static final String UIN_API_INTEGRATION_METADATA = 'UIN_Integration';
    public static final String FETCH_INGENIUM_CURRENTDATE_INTEGRATION_METADATA = 'ABSLI_Fetch_Ingenium_CurrentDate';

    /* IGMS OUTBOUND API */
    public static final List<String> IGMS_COMPLAINT_CATEGORIES = new List<String>{'Complaint'};
        public static final List<String> validGenders = new List<String>{'Male','Female','M','F'};
            public static final Map<String,String> mapOfGender= new Map<String,String>{'Male' =>'M', 'Female'=>'F'};
            public static final List<String> RECEIPT_NO_REQ_COMP_TYPE_CD = new List<String>{'1','7'};
    public static final String IGMS_REGCOMPLAINT_EVAL_ERROR = 'ABSLI_IGMSREGCOMPLAINT_EVAL_ERROR';
    public static final String IGMS_ATTCOMPLAINT_EVAL_ERROR = 'ABSLI_IGMSATTCOMPLAINT_EVAL_ERROR';
    public static final String IGMS_ATTESCCOMPLAINT_EVAL_ERROR = 'ABSLI_IGMSATTESCCOMPLAINT_EVAL_ERROR';
    public static final String IGMS_REOPENEDCOMPLAINT_EVAL_ERROR = 'ABSLI_IGMSREOPCOMPLAINT_EVAL_ERROR';
    public static final String IGMS_ESCALATECOMPLAINT_EVAL_ERROR = 'ABSLI_IGMSESCCOMPLAINT_EVAL_ERROR';
    public static final String IGMS_REGCOMLPAINT_NEXT_INT  = 'ABSLI_AckIGMSComplaintIntegration';
    public static final String IGMS_ACKCOMLPAINT_NEXT_INT  = 'ABSLI_PendingIGMSComplaintIntegration';
    public static final String IGMS_REOPENEDCOMLPAINT_NEXT_INT  = 'ABSLI_ReopenedIGMSComplaintIntegration';
    public static final String IGMS_REGCOMPLAINT_SRV_NAME = 'RegisterComplaints';
    public static final String IGMS_UPDATECOMPLAINT_SRV_NAME = 'UpdateComplaints';
    public static final String IGMS_UPDATECOMPLAINT_DOWNLOAD_SRV_NAME = 'UpdateComplaintsDownload';
    public static final String IGMS_UPDATECOMPLAINT_UPLOAD_SRV_NAME = 'UpdateComplaintsUpload';
    public static final String IGMS_REGCOMPLAINT_SUCCESS_RET_CD = '1';
    public static final String IGMS_ACKCOMPLAINT_SUCCESS_RET_CD = '1';
    public static final String IGMS_PENDCOMPLAINT_SUCCESS_RET_CD = '1';
    public static final String IGMS_ESCALATEDCOMPLAINT_SUCCESS_RET_CD = '1';
    public static final String IGMS_REOPENEDCOMPLAINT_SUCCESS_RET_CD = '1';
    public static final String IGMS_CLOSEDCOMPLAINT_SUCCESS_RET_CD = '1';
    public static final String IGMS_ATTENDEDCOMPLAINT_SUCCESS_RET_CD = '1';
    public static final String IGMS_ATTENDEDESCCOMPLAINT_SUCCESS_RET_CD = '1';
    public static final String[] IGMS_REGACKPEN_STATUS_CDS = new List<String>{'1','2','3'};
    public static final String CLOSED_COMPLAINT_SCHEDULE_JOB = 'IGMS Closed Complaints Outbound Schedulde Job';
    public static final String ABSLI_IGMSSYNC_SUCCESS_MESSAGE = 'ABSLI_IGMSSYNC_SUCCESS_MESSAGE';
    public static final String ABSLI_IGMSSYNC_FAILURE_MESSAGE = 'ABSLI_IGMSSYNC_FAILURE_MESSAGE';
    public static final String ABSLI_IGMS_TRANS_LOGIN_ID = 'bslicadmin';
    public static final String ABSLI_IGMS_ADDRESS_TO_INSURER_Y = 'Y';
    public static final String ABSLI_IGMS_OPTION = '1';
    public static final String ABSLI_IGMS_MODE_REGISTER = '1';
    public static final String ABSLI_IGMS_MODE_UPDATE = '2';
    public static final Integer IGMS_MAX_FILE_SIZE = 10;
    /* LOAN REPAYMENTS INTEGRATION */
    public static final String LOAN_REPAYMENT_EVAL_ERROR = 'ABSLI_LOAN_REPAYMENT_EVAL_ERROR';
    public static final String LOAN_REPAYMENT_SERVICE_NAME = 'LoanRepaymentApi';


    /* LITMUS API */
    public static final String LITMUS_SOURCE_REQ_BY = 'Customer';
    public static final String LITMUS = 'Litmus';
    public static final String COMPLAINT_NATURE = 'Complaint';

    /* REINSTATEMENT API */
    public static final String REINSTATEMENT_EVAL_ERROR = 'ABSLI_REINSTATEMENT_EVAL_ERROR';
    public static final String KARVY_QUEUE_DEVELOPER_NAME = 'ABSLI_Auto_Processing_Queue';//ABSLI_KARVY_TEAM';
    public static final String COVID_19_QUE_STRING = 'COVID 19 Questionnaire';
    public static final String REINSTATEMENT_SERVICE_NAME = 'reinstatementApi';

    /* SURVIVAL API */
    public static final String SURVIVALCTST = 'PCPT017';

    /* LSQLeadIntegration */
    public static final List<String> leadLSQTypeArr = new List<String>{'Branch walk in'};
    public static final List<String> leadD2CTypeArr = new List<String>{'Contact Centre'};
    public static final List<String> leadOneABCLeadArr = new List<String>{'Employee Referral'};

    /*Surrender & Withdrawal API */
    public static final String ABSLI_PANUPDATE_NOT_REQUIRED_ERROR = 'ABSLI_PANUPDATE_NOT_REQUIRED_ERROR';
    public static final String CHECKLIST_SIGNATURE_MATCHED = 'Signature Matched';
    public static final String ABSLI_SIGNATURE_NOT_MATCHING_ERROR = 'ABSLI_SIGNATURE_NOT_MATCHING_ERROR';
    public static final String SURRENDER_POLICY_SRV_NAME = 'policySurrender';//SurrenderUpdateApi';
    public static final String WITHDRAWAL_POLICY_SRV_NAME = 'fundWithdrawl';//WithdrawalUpdateApi';
    public static final String ACTION_SURRENDER = 'Surrender';
    public static final String ACTION_WITHDRAWAL = 'Withdrawal';
    public static final String TRANSACTION_TYPE_NEFT = 'NEFT';
    public static final List<String> SURRENDER_WITHDRAWAL_CASE_TYPES = new List<String>{'PPAY001','PPAY008'};
    public static final String SURRENDER_WITHDRAWAL_USER_BRANCH_NAME = 'User Branch';
    public static final String SURRENDER_WITHDRAWAL_USER_BRANCH_CODE = 'User123';
}