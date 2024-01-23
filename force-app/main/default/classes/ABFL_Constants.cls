/*********************************************************
*Name           :   ABFL_Constants
*Author         :   Aditee Churiwala
*Since          :   13 Dec 2023
*Description    :   Constant class for ABFL
*History        :
Name                Date                  Change Description
*********************************************************/
public with sharing class ABFL_Constants {
	public static final string SUCCESS = 'Success';
    public static final string BRE = 'BRE';
    public static final string ERROR = 'Error';  
    public static final string CANCELED = 'Canceled';
    public static final string PENDING = 'Pending';
    public static final string RM_NO_EMAIL = 'RM-No email';
    public static final string IVR_NO_EMAIL = 'IVR-No email';
    public static final string EVALUATION_FAILED_LAN_ERROR = 'LAN can\'t be found on Case ';
    public static final string EVALUATION_FAILED_SMT_ERROR = 'Senior Management Team is not looped';
    public static final string EVALUATION_FAILED_AUTOCLOSURE = 'Trailmail is present';
    public static final string EVALUATION_FAILED_IS_REGIS_ERROR = 'User is unregistered';
    public static final string EVALUATION_SUCCESS = 'Evaluation Success';
    public static final string WAITING_API_RESPONSE = 'Waiting for API response';
    public static final String EMAIL_ENTITY = 'Email';
    // public static final String NOT_EQUAL_TO = 'Not Equals To';
    // public static final String EQUAL_TO = 'Equals';
    public static final String BLANK_DATE_FIELD = 'Please add required date field values';
    public static final String ABFL = 'ABFL';
        
    public static final string WEALTHLOB = 'Wealth';
    public static final string API = 'API';
    public static final string RESOLVED_BY_BRE = 'Resolved by BRE';
    public static final string RESOLVED_BY_STP = 'Resolved by STP';
}