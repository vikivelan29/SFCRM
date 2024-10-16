/*********************************************************
*Class        :  ABHI_Constants
*Author       :  Anirudh Raturi
*Created Date :  31/07/2023
*Last Modified:  31/07/2023
*@description  :  Class for ABHI Constants
*********************************************************/

public with sharing class ABHI_Constants {
    
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
    public static final String BUSINESS_UNIT_ABHFL = 'ABHFL';
    public static final String API = 'API';
    public static final String OPEN = 'Open';
    public static final String NEW_STATUS = 'New';
    public static final String ABHI = 'ABHI';
    public static final String JARVIS = 'JARVIS';
    public static final String PERMANENT = 'Permanent';
    public static final String OTHER = 'other';
    public static final String INDIVIDUAL = 'Individual';
    public static final String NON_INDIVIDUAL = 'Non-Individual';
    public static final String POLICY_IS_MANDATORY_ON_Customer = 'Policy is mandatory on customer.';
    public static final String BUSINESS_UNIT_API = 'Business_Unit__c';
    public static final List<String> POLICY_ALL_OBJECT = new List<String>{'Account','Asset','Customer_Member_Mapping', 'Nominee', 'Previous_Policy_Details'};

    //omnidocs
    public static final String EMAIL_TEMPLATE_DEVELOPER_NAME = 'OMNI_DOC_SEND_EMAIL_1724913452870';
    public static final String OMNI_INT_TYPE = 'OmniDoc';
    public static final String TASK_ID = 'Attachments';
    public static final String LOGICAL_ID = 'SFCRM';
    public static final String SEARCH_OPERATOR = 'OR';
    public static final String PARAM_ID = '2';
    public static final String CATEGORY_ID = '1009';
    public static final String OMNIDOC_INTEGRATION_NAME = 'ABHI_OmniDocSearchRequest';
    public static final Integer STATUS_OK = 200;
    public static final String FROM_ADDRESS_DISPLAY_NAME = 'abcl.co.in';
    public static final String DT_LABEL = 'label';
    public static final String DT_FIELDNAME = 'fieldName';
    public static final String DT_TYPE = 'type';
    public static final String DT_TYPEATTRIBUTES = 'typeAttributes';
    public static final String ERROR_CIO_PUBLISH = 'Error in publishing CIO event ';
    public static final String ERROR_CIO_ZEROINTREC = 'Query returned no ASF case integration records';
    public static final String ERROR_NULLPARAM = 'Null parameters recieved';
    public static final String ERROR_ASFINSERT = 'Error in inserting ASF record ';
    public static final String ERROR_OMNIRESFAIL = 'Integration Failed. Try again or contact your Salesforce admin for help';
    public static final String ERROR_OMNIRESPENDINGLONG = 'File downlad process took too long to execute. Try again or contact your Salesforce admin for help';
    public static final String ERROR_OMNISUCCESSLONG = 'File download process failed. Try again or contact your Salesforce admin for help';
    public static final String ERROR_DT_NORECORDS = 'Dynamic datatable child has no records';
    public static final String OMNIPAYLOAD_OMNIDOCINDEX = 'OmniDocIndex';
    public static final String OMNIPAYLOAD_VID = 'VID';
    public static final String OMNIPAYLOAD_UPLOADEDDATE = 'UploadedDate';
    public static final String OMNIPAYLOAD_FILENAME = 'FileName';
    public static final String OMNIPAYLOAD_OMNIDOCIMAGEINDEX = 'OmniDocImageIndex';
    public static final String OMNIRES_SUCCESS = 'Success';
    public static final String OMNIRES_FAILURE = 'Failure';
    public static final String OMNIRES_PENDING = 'Pending';
    public static final String ERROR_MISSING_LEAD_FOR_CANCELLED = 'Not processed-Missing Lead ID';
    public static final String OMNIDOC_FILE_TRANSFER_SOURCE = 'SFDC';
    public static final String OMNIDOC_FILE_TRANSFER_CATEGORYID = '1007';
    public static final String OMNIDOC_FILE_TRANSFER_DOCSEARCHPARAMID_CASE = '17';
    public static final String OMNIDOC_FILE_TRANSFER_LOGICALID = 'CRM';
    public static final String OMNIDOC_FILE_TRANSFER_TASKID = 'Attachments';
 public static final String MASTER_POLICY_ERROR = 'Master policy doesn\'t exist';
}
