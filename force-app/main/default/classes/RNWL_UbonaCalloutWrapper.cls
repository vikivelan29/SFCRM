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
}