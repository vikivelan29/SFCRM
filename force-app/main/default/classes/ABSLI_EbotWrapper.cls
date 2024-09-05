public class ABSLI_EbotWrapper {
    public class EbotResponseWrapper{
        public String ClientId;
        public String PolicyNo;
        public String CaseSubSubType;
        public String Issue_Type;
        public String CaseNo;
        public String FromDate;
        public String ToDate;
        //public String FTR;
        public String Comments;
        public Boolean FTR;
        public List<EmailDetailsWrapper> Email_Details;
    }
    
    public class EmailDetailsWrapper {
        //public String Is_Register_Customer;	
        //public String EmailCustomerFlag;
        public Boolean Is_Register_Customer;	
        public Boolean EmailCustomerFlag;
        public String EmailFrom;
        public String EmailTo;
        public String EmailSubject;
        public List<StaticAttachmentWrapper> Static_Attachment;
    }
    
    public class StaticAttachmentWrapper {
		public String AttachmentName;
		public String For_Registered_Customer;
	}

}