/*********************************************************
*name           :   ABFL_Constants
*author         :   Aditee Churiwala
*since          :   13 Dec 2023
*@description   :   Constant class for ABFL
*history        :
name                Date                  Change Description
*********************************************************/
@SuppressWarnings('PMD.PropertyNamingConventions')
public with sharing class ABFL_Constants {
	public static final string SUCCESS = 'Success';
    public static final string BRE = 'BRE';
    public static final string ERROR = 'Error';  
    public static final string CANCELED = 'Canceled';
    public static final string PENDING = 'Pending';
    public static final string RESOLVED = 'Resolved';
    public static final string RM_NO_EMAIL = 'RM-no email';
    public static final string IVR_NO_EMAIL = 'IVR-No email';
    public static final string EVALUATION_FAILED_LAN_ERROR = 'LAN can\'t be found on Case ';
    public static final string EVALUATION_FAILED_SMT_ERROR = 'Senior Management Team is not looped';
    public static final string EVALUATION_FAILED_AUTOCLOSURE = 'Trailmail is present';
    public static final string EVALUATION_FAILED_IS_REGIS_ERROR = 'User is unregistered';
    public static final string EVALUATION_FAILED_AMOUNT_ERROR = 'Amount can\'t be blank ';
    public static final string EVALUATION_FAILED_FREQUENCY_ERROR = 'Frequency can\'t be blank ';
    public static final string EVALUATION_FAILED_TO_DATE_ERROR = 'To Date can\'t be blank ';
    public static final string EVALUATION_FAILED_DATE_VALIDATION = 'From Date and To Date should be in future';
    public static final string EVALUATION_FAILED_FROM_TO_DATE_VALIDATION = 'From Date and To Date shouldn\'t be same';
    public static final string EVALUATION_FAILED_FROM_DATE_ERROR = 'From Date can\'t be blank ';
    public static final string EVALUATION_FAILED_BANK_ACCOUNT_ERROR = 'Bank Account No can\'t be blank ';
    public static final string EVALUATION_FAILED_IFSC_CODE_ERROR = 'Ifsc Code can\'t be blank ';
    public static final string EVALUATION_SUCCESS = 'Evaluation Success';
    public static final string WAITING_API_RESPONSE = 'Waiting for API response';
    public static final String EMAIL_ENTITY = 'Email';
    public static final String LITMUS = 'Litmus';
    public static final String ENACH_INTEGRATION_METADATA = 'ABFL_Enach';
    
    public static final String DMS_METADATA = 'Asf_DMS_File_Datatable';
    public static final String DMS_GENERIC_ERROR = System.Label.ASF_ErrorMessage;
    public static final String DMS_SYNC_FILE_SIZE_ERROR = 'The syncing process was stopped because the file size surpassed 5 MB';
    public static final String INVALID_DMS_RECORD_ERROR = 'Selected DMS record is invalid';
    public static final Integer NEXT_DMS_RETRY = 15;

    public static final String NO_SECTION = 'NO_SECTION';
    public static final String RTL_LOANDETAILS_INTEGRATION_METADATA = 'RTL_RealTime_LoanDetails';
    public static final String RTL_BASICCUSTINFO_INTEGRATION_METADATA = 'RTL_RealTime_BasicCustInfo';
    public static final String RTL_GCCPROPERTYDETAILS_INTEGRATION_METADATA = 'RTL_RealTIme_GCCPropertyDetails';
    public static final String RTL_LOANMIS_INTEGRATION_METADATA = 'RTL_RealTime_LoanMIS';
    public static final String RTL_INSTALLPMNTDTLS_INTEGRATION_METADATA = 'RTL_RealTime_InstallPmntDtls';
    public static final String RTL_GETCRMDETAILS_INTEGRATION_METADATA = 'RTL_RealTime_GetCRMDetails';
    public static final String DMS_ENCRYPT_DOC_ID = 'DMS_ENCRYPT_DOC_ID';
    
    //EOD APIs
    public static final String EOD_ACCOUNT_BALANCE_INTEGRATION_METADATA = 'EOD_Account_Balance';
    public static final String EOD_APPLICATION_DETAILS_INTEGRATION_METADATA = 'EOD_Application_Details';
    public static final String EOD_REPAYMENT_DETAILS_INTEGRATION_METADATA = 'EOD_Repayment_Details';
    public static final String EOD_DISBURSEMENT_DETAILS_INTEGRATION_METADATA = 'EOD_Disbursement_Details';
    // public static final String NOT_EQUAL_TO = 'Not Equals To';
    // public static final String EQUAL_TO = 'Equals';
    public static final String BLANK_DATE_FIELD = 'Please add required date field values';
    public static final String ABFL = 'ABFL';
    @auraEnabled public final String lobABFL = 'ABFL'; //for ODP alters
    public static final String CHANNEL_ID = 'CHA1002'; //Needs to check what is channel Id?
    public static final String ODP_ALERTS = 'ABFL_ODP_Alerts';
        
    public static final string WEALTHLOB = 'Wealth';
    public static final string API = 'API';
    
    public static final string NO = 'no';
    public static final string DESCRIPTION_MSG = 'Auto created Case by BRE for loan closure of digital loan';
    public static final string SOURCE = 'SystemIntegration';
    public static final List<String> ABFL_LOB_COMPLAINT_RCA = new List<String>{'Retail - Secured','Retail - Unsecured','Corporate','Digital','Not classified'};

    public static final List<String> ABFL_ABWM_BUSINESSUNIT = new List<String>{'ABFL','ABWM'};
    public static final string WMCHATCASEORIGIN = 'ABFL WM CHAT';
    public static final string WMEMAILTEMPLATENAME = 'ABFL_WM_BASIC_ACKNOWLEDGEMENT_EMAIL';
    public static final string WMSMSTEMPLATENAME = 'ABFL_WM_BASIC_ACKNOWLEDGEMENT_SMS_TEMPLA';
    public static final String ABWMEMAIL = 'ABWM Email';
    
    public static final String ABWM = 'ABWM';

    public static final List<String> ABFL_ALLEMAILORIGIN = new List<String>{'ABFL Email','ABFL WM CHAT','ABWM Email'};

    /* Map to Store Asset LOB with Default Queue Names */
    public static final Map<String,String> MASSETLOBSVSDEFAULTQUEUE= new Map<String,String>{'Corporate'=> 'ABFL_Institutional_Service_Desk', 'Digital'=>'ABFL_Digital_CS', 'Retail - Secured' => 'ABFL_Mortgage_CS', 'Retail - Unsecured' => 'ABFL_Unsecured_CS' };
    
    public static final Set<String> GRIEVANCE_TEAM_ASGNMENT_CTSTS = new Set<String>{'CARCBUNP','CB61219','CFCST052','CFCST053','CPREDEDCUN',
    'CPREDEERMOR','CPREDEERUN','CPREDEREUN','CPREDERSMOR','CRENONDCI','CSERNONDMOR','DIAC61219','DIGICOMPAYTM003','DNRFCL61219',
    'DNRN61219','DTURP61219','DTURP61219CORP','DTURP61219MOR','DTURP61219UN','NRR61219','qnotni01','RBC61217','RBC61218','RBC61219',
    'TPF61219','CSERLIEDMOR','CSTCUEDCI','APNR61219','NMSFMNP61219','CEXDENGCI','EP61216','EP61217','EP61218','CEXDENGDI','CEXDENGMOR',
    'CEXDENGUN','CFCST065','CFCST078','CFCST089','CFFOFLUN','NMSFMNP61218','NMSFMNP61217','FFIP61219','EP61219','CFRAFOCTMOR','CFRFOCTCI',
    'BPW61219','CACINIDCI','CACINSSCI','qecser01','CPANACRCI','CPEMNTDI','CPOOEMNTMOR','CPRBOUPWRMOR','CPRBOUPWRUN','CPRCONMOR','CPRCONUN',
    'btr13','CACINCLMAONCI','CACINONCI','CACINRYCI','CCDENTCORP','CCDENTDI','CCDENTMOR','CCDENTUN','CCOLIEDCI','CCOLIEDCIMOR','CECDENTCI',
    'CECDENTMOR','CECDENTUN','CEMIMOESDI','CEMIMOESUN','CEMIMORATMOR','CFCST057','CFCST059','CFCST060','CFCST085','CFCST091','CFCST093',
    'cffmms01','CMISMICTDIG','CMISMICTMOR','CMSMLUN','CPOERERCI','CPOREREGUN','CPORERERMOR','CPREINEDMOR','CPRELECECORP','CPRELECEMOR',
    'CSDLRREJDL','CSDLRREJMOR','CSDLRREJUN','CSERDEONDIG','CSERDEONMOR','CSERDETEDIG','CSERDETEMOR','CSERDETSDIG','CSERDETSMOR',
    'CSERINNDIG','CSERINNDMOR','CSERNAEDMOR','CSEROTRSDIG','CSEROTRSMOR','IIAR61216','IIAR61217','IIAR61218','IIAR61219','IPCLCI61219',
    'IPDR61217','IPDR61218','IPDR61219','LN61219','NAD61219','NMNR61219','PPEIP61216','PPEIP61217','PPEIP61218','PPEIP61219','qaccdq01',
    'qaccin01','qagedr01','qothic01','qothot01','qprodr01','qregln01','rcgrncl01','TPF61217','TPF61218','UDSD61219'};
    /**
    * @description Static string to return 'SUCCESS'
    */
    public static final String BRESUCCESS {
        get{
            return 'SUCCESS';
        }
    }
    /**
    * @description Static string to return 'FAILURE'
    */
    public static final String BREFAILURE {
        get{
            return 'FAILURE';
        }
    }

    /**
    * @description Static Integer to return 5242880
    */
    public static final Integer FIVE_MB_FILE_SIZE_BYTES {
        get{
            return 5242880;
        }
    }

    /**
    * @description  : function to return all constant values to lightning component
    * @return       : ABFL_Constants
    */
    @AuraEnabled(cacheable=true)
    public static ABFL_Constants getAllConstants() {
        return new ABFL_Constants();
    }
}