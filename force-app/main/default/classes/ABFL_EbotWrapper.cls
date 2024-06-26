/*********************************************************
*Class        :  ABFL_EbotWrapper
*Author       :  Shubham Sinha 
*Created Date :  19/12/2023
*Last Modified:  19/12/2023
*Description  :  Wrapper Class for ABFL EbotIntegration
*********************************************************/
    public class ABFL_EbotWrapper {
      public class EbotResponseWrapper{
        public String AUTOCLOSURE_IN_RR {get; set;}       //Trail Mail Flag of the Email
        public String CASEID {get; set;}       //Case Id
        public String CASESUBTYPE {get; set;}  //Subtype Code of the Case
        public String COMMENT {get; set;}     //Description of the Case
        public String CONFIDENCESCORE {get; set;}     //Confidence Score of the EBOT
        public String CUSTOMERNO {get; set;}     //Common Client Code of the Customer
        public String ISATTACHMENTFLAG {get; set;}    //Is attachment available against the email.
        public String ISMULTIPLELAN {get; set;}        //LAN Number of the Customer
        public String ISREGISTEREDCUSTOMER {get; set;}     //Is Registered Customer flag of the Case
        public String ISSMT {get; set;}       //Is Senior Management flag
        public String LAN {get; set;}      //LAN Number of the Customer
        public String LOB {get; set;}     //LOB of the Case
        public String MOODSTAMP {get; set;} //Mood stamp of the customer.
        public String OWNERFULLNAME {get; set;} // Owner of the Case
        public String PAYTMINTERACTIONID {get; set;} //PAYTM Interaction ID available in the Email
        public String PRIORITY {get; set;}  //Priority of the Email
        public String AUTORESPONSEFLAG {get; set;}
        public String DISPOSITION {get; set;}

      }
    }