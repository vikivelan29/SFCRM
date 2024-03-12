/*********************************************************
*Name           :   ABFL_Constants
*Author         :   Aditee Churiwala
*Since          :   13 Dec 2023
*Description    :   Constant class for ABFL
*History        :
Name                Date                  Change Description
*********************************************************/
@SuppressWarnings('PMD.PropertyNamingConventions')
public with sharing class ABFL_Constants {
	public static final string SUCCESS = 'Success';
    public static final string BRE = 'BRE';
    public static final string ERROR = 'Error';  
    public static final string CANCELED = 'Canceled';
    public static final string PENDING = 'Pending';
    public static final string RESOLVED = 'Resolved';
    public static final string RM_NO_EMAIL = 'RM-No email';
    public static final string IVR_NO_EMAIL = 'IVR-No email';
    public static final string EVALUATION_FAILED_LAN_ERROR = 'LAN can\'t be found on Case ';
    public static final string EVALUATION_FAILED_SMT_ERROR = 'Senior Management Team is not looped';
    public static final string EVALUATION_FAILED_AUTOCLOSURE = 'Trailmail is present';
    public static final string EVALUATION_FAILED_IS_REGIS_ERROR = 'User is unregistered';
    public static final string EVALUATION_SUCCESS = 'Evaluation Success';
    public static final string WAITING_API_RESPONSE = 'Waiting for API response';
    public static final String EMAIL_ENTITY = 'Email';
    public static final String LITMUS = 'Litmus';

    public static final String NO_SECTION = 'NO_SECTION';
    public static final String RTL_LOANDETAILS_INTEGRATION_METADATA = 'RTL_RealTime_LoanDetails';
    public static final String RTL_BASICCUSTINFO_INTEGRATION_METADATA = 'RTL_RealTime_BasicCustInfo';
    public static final String RTL_GCCPROPERTYDETAILS_INTEGRATION_METADATA = 'RTL_RealTIme_GCCPropertyDetails';
    public static final String RTL_LOANMIS_INTEGRATION_METADATA = 'RTL_RealTime_LoanMIS';
    public static final String RTL_INSTALLPMNTDTLS_INTEGRATION_METADATA = 'RTL_RealTime_InstallPmntDtls';
    public static final String RTL_GETCRMDETAILS_INTEGRATION_METADATA = 'RTL_RealTime_GetCRMDetails';
    // public static final String NOT_EQUAL_TO = 'Not Equals To';
    // public static final String EQUAL_TO = 'Equals';
    public static final String BLANK_DATE_FIELD = 'Please add required date field values';
    public static final String ABFL = 'ABFL';
    @auraEnabled public final String lob_ABFL = 'ABFL'; //for ODP alters
    public static final String CHANNEL_ID = 'CHA1002'; //Needs to check what is channel Id?
    public static final String ODP_ALERTS = 'ABFL_ODP_Alerts';
        
    public static final string WEALTHLOB = 'Wealth';
    public static final string API = 'API';
    
    public static final string NO = 'no';
    public static final string DESCRIPTION_MSG = 'Auto created Case by BRE for loan closure of digital loan';
    public static final string SOURCE = 'SystemIntegration';
    public static final List<String> ABFL_LOB_COMPLAINT_RCA = new List<String>{'Retail - Secured','Retail - Unsecured','Corporate','Digital','Not classified'};
        
    public static final string WMCHATCASEORIGIN = 'ABFL WM CHAT';
    public static final string WMEMAILTEMPLATENAME = 'ABFL_WM_BASIC_ACKNOWLEDGEMENT_EMAIL';
    public static final string WMSMSTEMPLATENAME = 'ABFL_WM_BASIC_ACKNOWLEDGEMENT_SMS_TEMPLA';

    // BRE flag values such as “SUCCESS”,” FAILURE”,”VALIDATION ERROR”,”IN_PROCESS”,” Closure In Process” will be passed in this parameter.
    public static final String BRESUCCESS {
        get{
            return 'SUCCESS';
        }
    }
    public static final String BREFAILURE {
        get{
            return 'FAILURE';
        }
    }

    @AuraEnabled(cacheable=true)
    public static ABFL_Constants getAllConstants() {
        return new ABFL_Constants();
    }
}