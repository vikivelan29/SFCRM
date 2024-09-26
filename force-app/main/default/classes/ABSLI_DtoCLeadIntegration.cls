public with sharing class ABSLI_DtoCLeadIntegration {
    public static void invokeIntegration(List<Lead> newleads){
        Set<Id> leadIds = new Set<Id>();
        List<ABCL_Integration_Event__e> d2cEvents = new List<ABCL_Integration_Event__e>();
        for(Lead ld : newleads){
            leadIds.add(ld.Id);
        }
        List<Lead> leads = [SELECT ID,FirstName,LastName,External_Lead_ID__c,Rating,Name,MobilePhone,Email,Asset__c,Asset__r.Policy_No__c,
                            City__c,PIN_Code__c,
                            OwnerId, Owner.Name,ABSLI_Lead_Type__c FROM Lead WHERE Id =: leadIds];
        for(Lead ld : leads){
            ABCL_Integration_Event__e evt = new ABCL_Integration_Event__e ();
            evt.Record_Id__c = ld.Id;
            evt.Business_Unit__c = 'ABSLI';
            evt.ServiceName__c ='PushLeadsToD2C';
            evt.ObjectApiName__c ='Lead';
            returnWrapper retCls = new returnWrapper();
            retCls.Lead = new List<d2cWrapper>();
            
            d2cWrapper cls = new d2cWrapper();
            cls.LeadId = ld.External_Lead_ID__c;
            cls.ExistingCustomerFlag = 'N';
            cls.ExistingCustomerName = '';//ld.Asset__c != null ? ld.Asset__r.Policy_No__c : '';
            cls.FirstName = ld.FirstName;
            cls.MiddleName = '';
            cls.LastName = ld.LastName;
            cls.Gender = '';
            cls.DOB = '';
            cls.Mobile = ld.MobilePhone;
            cls.Email = ld.Email;
            cls.AnnualPremium = '';
            cls.SumAssured = '';
            cls.Product = 'Nishchit Aayush Plan';
            cls.ClickToCall = '';
            cls.Source = 'Service Contact Centre-DM';
            cls.SubSource = 'SSCCDM0135';
            cls.Stage = 'Get Quote';
            cls.SubStage = 'Pre quote';
            cls.LeadDropped = '';
            cls.LeadDroppedPage = 'ABFSGEXTmxvdrins727092';
            cls.StatusOfAadhar = '';
            cls.AadharNumber = '';
            cls.StatusOfPan ='';
            cls.PanNumber = '';
            cls.DropOfUrl = '';
            cls.DropUrlClicked = '';
            cls.DropDateTime = '';
            cls.LeadQualified = '';
            cls.JunkLead = '';
            cls.CId = ld.External_Lead_ID__c+','+ld.Rating;
            cls.Gclid = ld.City__c != null ? ld.City__c : 'NA';
            cls.ApplicationNumber = ld.PIN_Code__c;
            cls.SmokerNonSmoker = '';
            cls.Nationality = '';
            cls.Browser ='';
            cls.Device = '';
            cls.RefDetails = '';
            cls.Member = new List<memberDetail>();
            cls.Member.add(new memberDetail(ld.FirstName,ld.LastName,ld.MobilePhone,ld.Email,ld.PIN_Code__c,ld.City__c));
            
            retCls.Lead.add(cls);
            evt.Request__c = JSON.serialize(retCls);
            d2cEvents.add(evt);
        }
        if(d2cEvents.size()>0){
            List<Database.SaveResult> publishResults = EventBus.publish(d2cEvents);
        }
        
    }
    public class returnWrapper{
        public List<d2cWrapper> Lead{get;set;}
    }
    public class d2cWrapper{
        public string LeadId{get;set;}
        public String ExistingCustomerFlag{get;set;}
        public String ExistingCustomerName{get;set;}
        public String FirstName{get;set;}
        public String MiddleName{get;set;}
        public String LastName{get;set;}
        public String Gender{get;set;}
        public String DOB{get;set;}
        public String Mobile{get;set;}
        public String Email{get;set;}
        public String AnnualPremium{get;set;}
        public String SumAssured{get;set;}
        public String Product{get;set;}
        public String ClickToCall{get;set;}
        public String Source{get;set;}
        public String SubSource{get;set;}
        public String Stage{get;set;}
        public String SubStage{get;set;}
        public String LeadDropped{get;set;}
        public String LeadDroppedPage{get;set;}
        public String StatusOfAadhar{get;set;}
        public String AadharNumber{get;set;}
        public String StatusOfPan{get;set;}
        public String PanNumber{get;set;}
        public String DropOfUrl{get;set;}
        public String DropUrlClicked{get;set;}
        public String DropDateTime{get;set;}
        public String LeadQualified{get;set;}
        public String JunkLead{get;set;}
        public String CId{get;set;}
        public String Gclid{get;set;}
        public String ApplicationNumber{get;set;}
        public String SmokerNonSmoker{get;set;}
        public String Nationality{get;set;}
        public String Browser{get;set;}
        public String Device{get;set;}
        public String RefDetails{get;set;}
        public List<memberDetail> Member{get;set;}
	        
    }
    public class memberDetail{
        public String MemberId{get;set;}
        public String FirstName{get;set;}
        public String MiddleName{get;set;}
        public String LastName{get;set;}
        public String Address{get;set;}
        public String Gender{get;set;}
        public String MobileNumber{get;set;}
        public String EmailId{get;set;}
        public String Pincode{get;set;}
        public String State{get;set;}
        public String City{get;set;}
        public String DOB{get;set;}
        public String Nationality{get;set;}
        public String TypeOfAddress{get;set;}
        public String Proposer{get;set;}
        public List<medicalDetail> Medical{get;set;}
        public List<documentDetail> Document{get;set;}
        
        public memberDetail(){
            
        }
        public memberDetail(String fName,String lName,String mobile,String email,String postalCode,
                           String city)
        {
            this.MemberId = '';
            this.FirstName = fName;
            this.MiddleName = '';
            this.LastName = lName;
            this.Address = '';
            this.Gender = '';
            this.MobileNumber =mobile;
            this.EmailId = email;
            this.Pincode = postalCode;
            this.State = '';
            this.City = city;
            this.DOB = ''; 
            this.Nationality = '';
            this.TypeOfAddress = '';
            this.Proposer ='';
            this.Medical = new List<medicalDetail>();
            this.Medical.add(new medicalDetail());
            this.Document = new List<documentDetail>();
            this.Document.add(new documentDetail());

            
        }
        
        
    }
    public class documentDetail{
        public String DocumentNumber{get;set;}
        public String DocumentType{get;set;}
        public String Source{get;set;}
        public String DocumentName{get;set;}  
        public String DocumentStatus{get;set;}
        
        public documentDetail(){
            this.DocumentNumber = '';
            this.DocumentType = '';
            this.Source = '';
            this.DocumentName = '';
            this.DocumentStatus = '';
        }
        
    }
    public class medicalDetail{
        public String MedicalNumber{get;set;}
        public String RequirementType{get;set;}
        public String Source{get;set;}
        public String MedicalName{get;set;}
        public String MedicalStatus{get;set;}
        public String MedicalTestDate{get;set;}
        public String MedicalUniqueNumber{get;set;}
        
        public medicalDetail(){
            this.MedicalNumber = '';
            this.RequirementType = '';
            this.Source = '';
            this.MedicalName = '';
            this.MedicalStatus = '';
            this.MedicalTestDate = '';
            this.MedicalUniqueNumber = '';
        }
    }

}