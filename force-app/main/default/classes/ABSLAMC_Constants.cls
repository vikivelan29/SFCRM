/**
* @description       : Constant class to store all the resable variables at one place
* @author            : neeraj.kumar@salesforce.com
* @group             : 
* @last modified on  : 13-08-2024
* @last modified by  : Neeraj Kumar
* Description        : This will contain the strings to be used for ABSLAMC
**/
public with Sharing class ABSLAMC_Constants {
    public static final String OPEN_STAGE = 'Open';
    public static final String RESOLVED_STAGE = 'Resolved';
    public static final String UNRESOLVED_STAGE = 'Unresolved';
    public static final String REPLY_RECEIVED_FROM_APP_SUPPORT = 'Reply Received from App Support';
    public static final String ISSUE_MANAGEMENT_UNIT = 'ABSLAMC MF Issue Management Unit';   
    public static final String AWAITING_RESPONSE_FROM_APP_SUPPORT = 'Awaiting Response from App Support'; 
    public static final String ABSLAMCBU = 'ABSLAMC'; 
    public static final String ABSLAMC_CASE_ORIGIN = 'ABSLAMC Email';
    public static final String ABSLAMC_MF_PHD_QUEUE= 'ABSLAMC_MF_PHD';
    public static final String ABSLAMC_HWC_REASON_SOCIAL_MEDIA = 'Social Media';
    public static final String Y = 'Y';
    public static final String REPLYFROMCAMS = 'Reply Received from CAMS';
    public static final String CAMSCLOSEDSTATUS = 'Closed';
    public static final String CAMSOPENSTATUS = 'Open';
    public static final String CAMSPENDINGSTATUS = 'Pending with CAMS';
    public static final String ABSLAMC_CUSTOMER_STRING = 'Customer'; 
    public static final String ABSLAMC_DISTRIBUTOR_STRING= 'Distributor';
    public static final String CREATEWFINT = 'CAMS-CreateWorkflow'; 
    public static final String UPDATEWFINT = 'CAMS-UpdateWorkflow'; 
    public static final String BIRLACRM = 'BIRLACRMSF'; 
    public static final String CAMSWEB = 'CAMSWEB'; 
    public static final String CAMS = 'CAMS'; 
    public static final String CAMSCREATEWFAPI = 'ABSLAMC CAMS-CreateWF API'; 
    public static final String CAMSUPDATEWFAPI = 'ABSLAMC CAMS-UpdateWF API'; 
    public static final String REPLYTYPEFORCAMS = 'Reply Type for CAMS'; 
    public static final String ADDNTLREMARKSFORCAMS = 'Additional Remarks for CAMS';
    public static final String SATISFACTORYREPLYTYPE = 'S';
    public static final String NONSATISFACTORYREPLYTYPE = 'NS';
    public static final String CAMSAPPROVALSTAGE = 'Approval';
    public static final String APPROVEDSTATUS = 'Approved';
    public static final String RECALLEDSTATUS = 'Recalled';
    public static final String REJECTEDSTATUS = 'Rejected';
    public static final String SPRINKLRAPI = 'Sprinklr-UpdateCase API';
    public static final String SPRINKLRINT = 'Sprinklr-UpdateCase';
    public static final String SPRINKLR = 'SPRINKLR';
    public static final String RT_LEAD = Schema.sObjectType.Lead.getRecordTypeInfosByDeveloperName().get('ABSLAMC_Leads').getRecordTypeId();

    public static final String SRC_CALLCENTRE = 'Call Centre';
    public static final String SRC_BRANCH = 'Branch';
    public static final String CHNL_EMAIL = 'Email';
    public static final String CHNL_PHONE = 'Phone';
    public static final Map<String, String> LITMUS_APPID_MAP = new Map<String, String>{
        SRC_CALLCENTRE+CHNL_EMAIL => '15kk_touchpoint',
        SRC_CALLCENTRE+CHNL_PHONE => '9nu0_touchpoint',
        SRC_BRANCH => '0xzr_touchpoint'
    };
}