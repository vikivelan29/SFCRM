/*********************************************************
*Class        :  RNWL_Constants
*LOB          :  Renewal
*Author       :  Raj Raghuwanshi 
*Created Date :  21/10/2024
*Last Modified:  21/10/2024
*@description  :  This class is used for keep all the constant variables for Renewal classes*/

public class RNWL_Constants {
    public static final Map<Integer, String> MONTH_MAP;
    Static{ 
        	MONTH_MAP = new Map<Integer, String>
        	{
           		1 => 'January',
                2 => 'February',
                3 => 'March',
                4 => 'April',
                5 => 'May',
                6 => 'June',
                7 => 'July',
                8 => 'August',
                9 => 'September',
                10 => 'October',
                11 => 'November',
                12 => 'December' 
             };
        } 
    public static final Map<String, String> API_TO_META_DATA_MAP = new Map<String, String>
    {RNWL_Constants.RENEWAL_API_NAME => 'RNWL_RenewalDetail', RNWL_Constants.RENEWAL_GROUP_API_NAME => 'RNWL_Non_Ind_Account'};
        
    // API Name to store Response
    public static final String HEALTH_API_NAME = 'Health Return'; 
    public static final String FITNESS_API_NAME = 'Fitness Assessment'; 
    public static final String RENEWAL_API_NAME = 'Renewal Check'; 
    public static final String RENEWAL_GROUP_API_NAME = 'Renewal Group Check'; 
    public static final String APP_REG_API_NAME = 'AppRegDetails'; 
   
    // Policy Number key in API
    public static final String RENEWAL_POLICY_NUM_KEY = 'Policy_number'; 
    public static final String RENEWAL_GRP_POLICY_NUM_KEY = 'Certificate_number';
    
}