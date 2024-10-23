public class RNWL_UbonaCalloutWrapper {
    
    public String payloadId = '';
    public Boolean payloadEncrypted;
    public Cls_payload payload;
    public class Cls_payload {
        public String requestId = '';
        public String msisdn = '';
        public String scheduledTime = '';
        public String agentId = '';
        public String campaign = '';
        public String customerInfo = '';
        public Cls_context context;
    }
    public class Cls_context {
        public String CRMURL = '';
        public String customerName = '';
        public String intermediary = ''; 
        public String newChannel = '';
        public Date nextPremiumDate; 
        public Date policyDueDate;
        public String policyNumber = '';
        public String productName = ''; 
        public String renewalGrossPremiumFrom = '';
        public String rnNumber = '';
        public String state = '';
        public String stp_NSTP = '';
        public String sumInsured = ''; 
    }
}