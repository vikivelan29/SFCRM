/**
 * @description       : Constant class to store all the resable variables at one place
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 09-03-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   05-13-2024   rsinghnagar@salesforce.com   Initial Version
**/
public with sharing class ASF_Constants {

    public static final String GENERIC_ERROR_MESSAGE = 'An error occurred during processing, please contact system administrator';
    
    //Skipper flags - keep it sync with Feature_Skipper_Flag__c field options from Case
    public static final String SKIP_ASSIGNMENT = 'SKIP_ASSIGNMENT';
    public static final String SKIP_VALIDATE_RECAT_PARAM = 'SKIP_VALIDATE_RECAT_PARAM';
    public static final String SKIP_STAGE_ENTRY_CHECKS = 'SKIP_STAGE_ENTRY_CHECKS';
    public static final String SKIP_PERI_GENERATE = 'SKIP_PERI_GENERATE';
    public static final String SKIP_CLOSE_CASE_CHECK = 'SKIP_CLOSE_CASE_CHECK';
    public static final String SKIP_OWNER_CHECK = 'SKIP_OWNER_CHECK';
    public static final String SKIP_STAGE_EXIT_CHECKS = 'SKIP_STAGE_EXIT_CHECKS';
    public static final String SKIP_VALIDATE_CHECKLISTS = 'SKIP_VALIDATE_CHECKLISTS';
    public static final String SKIP_VALIDATE_TASKS = 'SKIP_VALIDATE_TASKS';
    public static final String SKIP_APPROVAL_CHECKS = 'SKIP_APPROVAL_CHECKS';
    public static final String SKIP_VALIDATION_CHECKS = 'SKIP_VALIDATION_CHECKS';
    public static final String SKIP_INTEGRATION_CHECKS = 'SKIP_INTEGRATION_CHECKS';


    public static final String STRING_BLANK ='';
    public static final String STRING_SPACE = ' ';
    public static final String STRING_HYPHEN = '-';
    public static final Boolean BOOL_TRUE = true;
    public static final Boolean BOOL_FALSE = false;
    
    public static final string STRING_DEBIT_CARDS = 'DebitCard';
    public static final string STRING_CREDIT_CARDS = 'CreditCard';
    public static final string STRING_COLON = ':';
    public static final string STRING_FORWARD_SLASH = '/';

    /**Added by Shreya */
    public static final String STRING_ACCOUNTS = 'Accounts';
    public static final String STRING_ACCOUNTS_BRCKT ='Accounts (';
    public static final String STRING_CARDS= 'Cards';
    public static final String STRING_CARDS_BRCKT= 'Cards (';
    public static final String STRING_CLS_BRCKT= ')';
    public static final String STRING_OPEN_BRCKT= '(';
    public static final String STRING_ACCOUNT= 'Account';
    public static final String STRING_OD= 'OD';
    public static final String STRING_ACTION='action';
    public static final String STRING_COMPANY_PAN ='company_pan__c';
    public static final String STR_DATE_FORMAT_2 = 'dd-MM-yyyy';
    public static final String STRING_MASKED = 'MASKED';
    public static final String STRING_NOACCESS = 'NOACCESS';
    public static final String STRING_CUSTOM_1 = 'Custom-1';
    public static final String STRING_ASTERISK = '*';
    public static final String STRING_NULL_LOWERCASED = 'null';
    /**Ended by Shreya */
    
    /* Added for ksc_AccountsSearchParser Class ~Neeti */
    public static final String NO_DATA_MESSAGE  = 'Sync Complete. No new data found';
    public static final String ERROR_MESSAGE = 'An unexpected error Occured. Please connect with System Administrator.';
    public static final String ERR_MESSAGE = 'For further assistance please contact system admin.';
    /*END - Added for ksc_AccountsSearchParser Class ~Neeti */

    
    public static final String C360_PERM_SET_APINAME = 'Create_Case';
    public static final String MOCK_ERROR_RESPONSE_BODY = '{"code":400,"status":"FAILURE","transactionId":"MockTxIdError","error":{"errorMessage":"BAD_REQUEST","errorDetails":"ForBidden"},"data":null}';
    public static final String MOCK_DEFAULT_RESPONSE_BODY = '{"example":"test"}';
    public static final String MOCK_ENCRYPTION_KEY = 'OkSqBEB++kdiZmwmigEtCHMW8MXUgO02wGhVlA0+3JQ=';
    public static final String MOCK_ENCRYPTION_RESPONSE = 'ji+U/tVFevfj3LZQFHdIPyd9Q5MkYl7w1t0akDSgKPOYSX+b5F5EbgwnRe/YvMfkJH+sU4xuycbJCdt0a2YS9yTtGmwBPNy36m7vZiTnO1MLjSd0JhJYoSA6t1U5hVEy0o399b+8J6iC0ayjNq4cdtg7aoULEqZDq7P6IeaXlrpb2r3Ehf3zYDcBnVl9Z45PdPPmWnsR2R+8YAVVVCjUOw==';
    
	public static final String STRING_AMOUNT_VALUE = 'amountValue';
	public static final String STRING_CURRENCY_CODE = 'currencyCode';

    public static final String STRING_DEBIT_CARD = 'Debit';
    public static final String STRING_D = 'd';
    public static final String STRING_CREDIT_CARD = 'Credit';
    public static final String STRING_C = 'c';
    public static final String STRING_PRODUCT_LISTING = 'Product_Listing';
    public static final String STRING_SEMI_COLON =';';

    public static final string TIMEZONE_ASIA_KOLKATA = 'Asia/Kolkata';

    public static final String HRD_RESPONSE_ENCRYPTED = 'x-enc-flag';
    public static final String STRING_DAY = ' Day';
    public static final String STRING_DAYS = ' Days';
    public static final String STRING_MONTHS = ' Months ';
    public static final String STRING_MONTH = ' Month ';
    public static final String STRING_YEAR = ' Year ';
    public static final String STRING_YEARS = ' Years ';
    public static final String STRING_DOT = '.';
    
    /*JWT Auth Params*/    
    public static final String STRING_PERSONBIRTHDATE = 'PersonBirthdate';
    public static final string STRING_COMMA = ', ';

    /*Mask Controller*/ 
    public static final String RT_FRAMEWORK = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Framework').getRecordTypeId();
    public static final String RT_INTERACTION = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Interaction').getRecordTypeId();
    public static final List<String> LIST_ADDRESS_NAME = new List<String>{'PersonMailingStreet', 'PersonMailingCity', 'PersonMailingState', 'PersonMailingPostalCode', 'PersonMailingCountry',
    'BillingStreet', 'BillingCity', 'BillingState', 'BillingCountry', 'BillingPostalCode'};
   

    /* Added For Asset Filters */
    public static final String STRING_PRESENT_HOLDINGS = 'Present_Holdings';
    public static final String STRING_PAST_HOLDINGS = 'Past_Holdings';
    public static final String STRING_CC_ASSET_GROUP = 'CC_Asset_Group';
    public static final String STRING_ASSET_SLT_GROUP = 'Asset_SLT';
    public static final String STRING_CC_ACC_STATUS = 'CC_account_status';
    public static final String STRING_CC_ACC_BC1 = 'CC_account_bc1';
    public static final String STRING_CC_ACC_BC2 = 'CC_account_bc2';
    public static final String STRING_CC_CARD_STATUS = 'CC_status';
    public static final String STRING_CC_CARD_BC = 'CC_card_block_code';
    public static final String STRING_CORP_LOANS = 'Corporate Loans';
    /* END - Added For Asset Filters */    

    /* Added For Loans Search API BU Logic */
    public static final String STRING_IS_API_LOAD = 'API_LOANS';
    
    public static final List<String> BU_SHOWCHECKLISTS_ONREJECTION = new List<String>{'ABSLI'};
    public static final String REJECTIONSTATUS = 'Unresolved';
    public static final String DUPLICATESTATUS = 'Closed Duplicate';
    public static final String DUPLICATESTAGE = 'Duplicate';
    public static final List<String> REJECTIONSTATUSES = new List<String>{'Unresolved','Rejected','Duplicate'};
    public static final List<String> CASECLOSEREJECTEDSTATUSES = new List<String>{'Closed','Resolved','Rejected','Unresolved','Duplicate'};
    public static final String ONCREATECLOSESTAGE = 'Resolved';
    public static final String ONCREATECLOSESTATUS = 'Resolved';
    public static final List<String> RESOLVEDSTAGES = new List<String>{'Resolved','Closed'};
    public static final String ABFL_BU = 'ABFL';
    public static final String ABSLI_BU = 'ABSLI';
    public static final String ABSLIG_BU = 'ABSLIG';
    public static final List<String> RESOLUTIONCOMMENT_REQ_TECHSRC = new List<String>{'LWC','API'};

    public static final List<String> ABFL_LOB_COMPLAINT_RCA = new List<String>{'Retail - Secured','Retail - Unsecured','Corporate','Digital','Not classified'};    
        
    /* Map to Store Case Origin Vs Business Unit */
    public static final Map<String,String> mCaseOriginVsBusinessUnit= new Map<String,String>{'Payments Email' => 'Payments', 'ABFL Email' => 'ABFL', 'ABHFL Email' => 'ABHFL','ABFL WM CHAT' =>'ABWM', 'ABWM Email' => 'ABWM', 'ABSLI Email' => 'ABSLI','ABSLIG Email' => 'ABSLIG', 'ABSLAMC Email' => 'ABSLAMC'};
    
    /* Map to Store Case Origin Vs Source */
    public static final Map<String,String> mCaseOriginVsSource= new Map<String,String>{'ABFL WM CHAT' =>'Chatbot'};
        
        
    /* RETRY MECHANISM RELATED CONSTANTS. */
    public static final String RETRY_PROCESSTYPEINTEG = 'Process';
    public static final String RETRY_PREPOPULATEDTYPEINTEG = 'Pre Populate';
    public static final String RETRY_PROCESS_SEQUENTIALTYPEINTEG = 'Process Sequential';
    public static final List<String> RETRY_ENABLEDSTATUESES = new List<String>{'Pending','Failure'};
    
    public static final List<String> VALIDATION_BYPASS_PROFILES = new List<String>{'System Administrator','Salesforce API Only System Integrations'};
    public static final String DMS_FILE_TRANSFER_SOURCE = 'SFDC';
    public static Boolean bypassOwnerChangeValidation = false;
    public static final List<String> BU_WITHOUT_LOB = new List<String>{'ABHFL','ABSLI','ABSLIG','ABHI'};
        
    /* Asset ExternalId fields per Business Unit */
    public static final List<String> BUSpecificLANKey = new List<String>{'ABSLI','ABSLIG'};
    public static final List<String> completeChecklistStatus = new List<String>{'Completed','Rejected','Yes','Signature Matched','No','Cancelled','Signature Mismatched','Signature Not Cropped'};
    
    public static final String ABSLI_CASE_EXTENSION_OBJ_NAME = 'ABSLI_Case_Detail__c';
    public static final String ABSLI_CASE_ORIGIN_EMAIL = 'ABSLI Email';
    //Add all the Case Detail fields here in lowercase. It's used for the skipper functionality in case the field is not present in Case Stage Config for query
    public static final Set<String> CASE_EXTENSION_FIELDSET = new Set<String>{'pay_payment_detail__c','abhfl_case_detail__c','abfl_case_detail__c','absli_case_detail__c','abslig_case_detail__c'};

}
