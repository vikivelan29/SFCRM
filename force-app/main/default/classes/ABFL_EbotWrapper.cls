/*********************************************************
*Class        :  ABFL_EbotWrapper
*Author       :  Shubham Sinha 
*Created Date :  19/12/2023
*Last Modified:  19/12/2023
*Description  :  Wrapper Class for ABFL EbotIntegration
*********************************************************/
    public class ABFL_EbotWrapper {
      public class EbotResponseWrapper{
        public String AUTOCLOSURE_IN_RR;        //Trail Mail Flag of the Email
        public String CASEID;       //Case Id
        public String CASESUBTYPE;  //Subtype Code of the Case
        public String COMMENT;      //Description of the Case
        public String CONFIDENCESCORE;      //Confidence Score of the EBOT
        public String CUSTOMERNO;       //Common Client Code of the Customer
        public String ISATTACHMENTFLAG;     //Is attachment available against the email.
        public String ISMULTIPLELAN;        //LAN Number of the Customer
        public String ISREGISTEREDCUSTOMER;     //Is Registered Customer flag of the Case
        public String ISSMT;        //Is Senior Management flag
        public String LAN;      //LAN Number of the Customer
        public String LOB;      //LOB of the Case
        public String MOODSTAMP; //Mood stamp of the customer.
        public String OWNERFULLNAME; // Owner of the Case
        public String PAYTMINTERACTIONID; //PAYTM Interaction ID available in the Email
        public String PRIORITY;  //Priority of the Email
        public String AUTORESPONSEFLAG;
        public String DISPOSITION;

      }
    }