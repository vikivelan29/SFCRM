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
    
    public static final String SLA_Broken_Reset_CCC_List = 'CCUSADGEHFC,ABHFL_Complaint_CCC_5,CCUSMAGEHFC,CCUSMOGEHFC,'+
        'CCUSNAGEHFC,ABHFL_Complaint_CCC_9,CCVNESLHFC,ABHFL_Complaint_CCC_11,CDISLOMIHFC,ABHFL_Complaint_CCC_13,'+
        'CCNROPHFC,hfl027,CGSTGSEDHFC,CGSTGSONHFC,ABHFL_Complaint_CCC_19,CLOALOLSHFC,CLOAAPUSHFC,HFCCICND,hfl033,'+
        'hfl044,comloanphis,COVEOVSSHFC,CPMAPMNGHFC,CPMAYSS,ABHFL_Complaint_CCC_31,hfl028,hfl075,hfl077,CLOALINEDHFC,'+
        'CLOALONTHFC,CLOANOEDHFC,CLOAPRCEHFC,CLOAPRNTHFC,REFCL002,ABHFL_Complaint_CCC_42,CREPBOEDHFC,CREPEONHFC,'+
        'hfl024,hfl025,COMEMIDC,CREPEMETHFC,CREPEMEDHFC,CREPMAEDHFC,ABHFL_Complaint_CCC_51,ABHFL_Complaint_CCC_53,'+
        'CRESCHEHFC,CRESCHLHFC,hfl019,CRESPANEHFC,CRESRONTHFC,ABHFL_Complaint_CCC_59,CSTAAMLEHFC,CSTABAERHFC,'+
        'CSTACOTSHFC,HFCCDNRSC,HFCCINRID,CSTAESNTHFC,CSTAITEHFC,hfl041,CSTAPRITEHFC,CSTAPOTSHFC,CSTAPRTEHFC,'+
        'costatrepay,CSTASAERHFC,CSTASHONHFC,CSTASIONHFC,hfl076,ABHFL_Complaint_CCC_77,ABHFL_Complaint_CCC_78,'+
		'ABHFL_Complaint_CCC_79,CSTASTNTHFC,COMPBCRW,HFCCSDFNRTR,CWAIEMNDHFC,CWAIESNDHFC,cowaiforech,cowaivinter,'+
        'cowailockch,COMPPCRW,cowaivpartp,COMPPRECCW,COMPFRW,ABHFL_Complaint_CCC_92,ABHFL_Complaint_CCC_93';
    //NDC Subtype
    public static final String NDC_CCC_EXTERNALID = 'QLOANDUSNDC';
    //Amortization Subtype External Id
    public static final String Amort_CCC_EXTERNALID = 'hfl004';   
    //Generic Constants
    public static final String SUCCESS = 'Success';
    public static final String ERROR = 'Error';
    public static final String CANCELED = 'Canceled';
    public static final String PENDING = 'Pending';
    public static final String FAILURE = 'Failure';
    public static final String COMPLETED = 'Completed';
    public static final String RESOLVED = 'Resolved';
    public static final String REJECTED = 'Rejected';
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
    public static final String BUSINESS_UNIT_ABHFL = 'ABHFL';
    public static final String API = 'API';
    public static final String OPEN = 'Open';
    public static final String CHANNEL_ID = 'CHA1002';
    public static final String ODP_ALERTS = 'ODP_Alerts';
    public static final String SEND_LEAD_TO_CRM = 'Send_Lead_To_CRM';
    public static final String INTERACTION_RECORD_TYPE = 'Interaction';
    public static final String NEW_STATUS = 'New';
    public static final String EMAIL_TECHNICAL_SOURCE = 'Email';
    public static final String SUB_VARIANT = 'GENERAL PURPOSE LOAN';
    public static final String VARIANT = 'HOME CONSTRUCTION LOAN';
    public static final String SOURCE_TYPE = 'Internal';
    public static final String SOURCE_SYSTEM_API = 'SFDC';
    public static final String EXTERNAL_RECORD_TYPE = 'External';
    public static final String STP_REQUEST_TYPE_DOWNLOAD = 'Download';
    
    
    
    
    //Constants for Welcome Kit STP Flow
    public static final String WK_EVALUATION_FAILED_ERROR = 'Evaluation Failed, cannot retrieve Welcome Kit.';
    public static final String WK_EVALUATION_SUCCESS_RESPONSE = 'Evaluation Success, Submit to get the Welcome Kit.';
    public static final String WK_EVALUATION_FAILED_DIGITAL_ERROR = 'Evaluation failed. Disbursal date is > 6 months.';
    public static final String WK_EVALUATION_FAILED_OFFLINE_ERROR = 'Disbursal date is > 6 months. Please inform the customer that Welcome Kit cannot be provided.'; 
    
    public static final String ERROR_DESC_FOR_CANCELLED_DMS = 'Not processed-Missing Lead ID';
    public static final String ACCOUNT_STATUS_CLOSED = 'Closed';
    public static final String NDC_STP_NAME = 'NDC';
    public static final String NDC_REPORT = 'NDCReport';
    public static final String LOD_REPORT = 'LODReport';
    public static final String ACCOUNT_RECORDTYPE_INDIVIDUAL = 'Individual';
    public static final String ACCOUNT_RECORDTYPE_NON_INDIVIDUAL = 'Non-Individual';
    public static final String PAYMENTLINK_INTEGRATION_METADATA = 'Payment_Link';
    public static final String PAYTMLINK_INTEGRATION_METADATA = 'Paytm_Link';
    public static final String DATASERVICE_INTEGRATION_METADATA = 'Data_Service_Details';
    public static final String ROIHISTORY_INTEGRATION_METADATA = 'ROI_History_Details';
    public static final String COMPLAINT_INVESTIGATION_INTEGRATION_METADATA = 'Complaint_investigation_Details';
    public static final String PAYTM_REQUEST_TYPE = 'Coll';
    public static final String REASON_FOR_PAYMENT = 'Repricing related charges';
    public static final String REPORTING_SERVICE = 'ReportingService';
    public static final String IC_DOCUMENT_TYPE = 'ReportFilePath';
    public static final String PIC_DOCUMENT_TYPE = 'BinaryData';
    public static final String IC_REPORT_NAME = 'InterestCertificate';
    public static final String PIC_REPORT_NAME = 'ProvisionalCertificateBinary';
    public static final String ABHFL_PaymentLink = 'Payment_Link_VF';
    public static final String PAYMENT_BOUNCE_TEMPLATE = 'Payment_Bounced_1705034284521';
    public static final String PAYMENT_NOTRECEIVED_TEMPLATE = 'Payment_Unable_to_trace_payment_details_1705034679464';
    public static final String PAYMENT_BOUNCE_SMS = 'ABHFL_Payment_Bounce';
    public static final String PAYMENT_NOTRECEIVED_SMS = 'ABHFL_Payment_Unable_to_trace_payment';
    public static final String SHORTFALL_TEMPLATE = 'Shortfall_Amount_VF';
    public static final String SHORTFALL_SMS = 'ABHFL_Shortfall_Amount_Part_Payment';
    public static final String PAYMENT_RECEIVED_TEMPLATE = 'Payment_Received_Successfully_1705035361551';
    public static final String PAYMENT_RECEIVED_SMS = 'ABHFL_Payment_Received_Successfully';
    public static final String TRACKING_LINK_SMS = 'ABHFL_Stage_Mvmnt_Tracking_Link';
    public static final String MULTIPLELAN_PAYMENT_RECEIVED_SMS = 'ABHFL_MultiLAN_Payment_Received';
    public static final String MULTIPLELAN_PAYMENT_RECEIVED_EMAIL = 'Payment_acceptance_email_MultiLAN_VF';
    public static final String MULTIPLELAN_AMORT_PARTIAL_EMAIL ='Informing_customer_that_ROI_is_revised_Partailly_disbursed_loan_1706087796320';
    public static final String MULTIPLELAN_AMORT_PARTIAL_SMS ='ABHFL_ROI_revision_partially_disbursed';
    public static final String MULTIPLELAN_AMORT_FULL_EMAIL ='Informing_customer_that_ROI_is_revised_Fully_disbursed_loan_1706090167218';
    public static final String MULTIPLELAN_AMORT_FULL_SMS ='ABHFL_ROI_revision_fully_disbursed';
    public static final String MULTIPLELAN_PRCLS_STATEMENT_CLOSUREEMAIL ='Foreclosure_letter_MultiLAN';
    public static final String MULTIPLELAN_PRCLS_STATEMENT_CLOSURESMS ='ABHFL_FCL_issued_to_customer';
    public static final String PRECLS_LOANCLOSED_EMAIL ='Loan_Closed_share_property_papers_VF';
    public static final String PRECLS_LOANCLOSED_SMS ='ABHFL_Loan_Closed_return_property_papers';
    


    // Constants for REKYC 
    public static String REKYC_SERVICE_NAME = 'Send_RKYC_API';
    public static final String REKYC_SYS_NAME = 'A3S';

    // Constants for Bitly
    public static String BITLY_SERVICE_NAME = 'ShortUrl';
    public static String BITLTY_INTEGRATION_NAME = 'Bitly_Url';


    //Constants for Statement Of Account
    public static String SOA_INTEGRATION_NAME = 'SOA_API';
    public static final String SOA_SOURCE = 'CRM';
    public static final String SOA_REQUEST_TYPE = 'View';
    public static final String SOA_REPORT_NAME = 'SOABinary';
    public static final String SOA_DOCUMENT_TYPE = 'BinaryData';

    //Constants for EmailTemplates.
    public static String ROI_OFFERSHARED_WITH_PAYABLE_CHARGES_EMAIL = 'ROI_offer_shared_with_payment_Link';
    public static String ROI_OFFERSHARED_WITHOUT_PAYABLE_CHARGES_EMAIL = 'ROI_offer_shared_with_Single_Lan_VF';
    public static String GST_INVOICE_EMAIL = 'Query_Case_Closure_1701081397834';
    public static String DSRA_LIEN_EMAIL = 'Query_Case_Closure_1701081397834';
    public static String ESCROW_STATEMENT_EMAIL = 'Query_Case_Closure_1701081397834';
    public static String NOC_REQUIRED_EMAIL = 'Sharing_NOC_copy_with_customer_on_receipt_of_payment_1707970074046';
    public static String ADDRESSCHANGE_REJECTION_EMAIL = 'ABHFL_AddressChange_Status_Email_1727254483228';
    //Constants for SMS.
    public static String ROI_OFFERSHARED_WITH_PAYABLE_CHARGES_SMS = 'ABHFL_ROI_w_payment_Link_SL';
    public static String ROI_OFFERSHARED_WITHOUT_PAYABLE_CHARGES_SMS = 'ABHFL_ROI_wo_Payment_Link_SL';
    public static String GST_INVOICE_SMS = 'Query_Case_Closure_1701081397834';
    public static String DSRA_LIEN_SMS = 'ABHFL_Query_Case_Closure';
    public static String ESCROW_STATEMENT_SMS = 'ABHFL_Query_Case_Closure';
    public static String NOC_REQUIRED_SMS = 'ABHFL_NOC_Required';
    public static String ADDRESSCHANGE_REJECTION_SMS = 'ABHFL_AddressChange_SMS_1727259602449';
    
    //CCC External Id Constants
    public static String GST_INVOICE_ID = 'HFCRARGI';
    public static String DSRA_LIEN_ID = 'AC123470';
    public static String ESCROW_STATEMENT_ID = 'hfl029';
    public static String NOC_REQUIRED_ID = 'hfl050';
    public static final List<String> ALLLANCTSTs = new List<String>{'hfl045','hfl023'};

	//restrict recurssion
	public static boolean isProcessing = true;
    

    @AuraEnabled(cacheable=true)
    public static ABHFL_Constants getAllConstants() {
        return new ABHFL_Constants();
    }
}