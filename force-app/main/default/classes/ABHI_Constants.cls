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
    public static final String INDIVIDUAL = 'Individual';
    public static final String NON_INDIVIDUAL = 'Non-Individual';
    
    
    public static final String BUSINESS_UNIT_API = 'Business_Unit__c';
    
    public static final List<String> POLICY_ALL_OBJECT = new List<String>{'Account','Asset','Customer_Member_Mapping', 'Nominee'};

}