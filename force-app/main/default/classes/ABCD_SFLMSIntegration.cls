public with sharing class ABCD_SFLMSIntegration {
    public static void invokeIntegration(List<Lead> newleads){
        Set<Id> leadIds = new Set<Id>();
        List<ABCL_Integration_Event__e> sfLMSEvents = new List<ABCL_Integration_Event__e>();
        for(Lead ld : newleads){
            leadIds.add(ld.Id);
        }
        List<Lead> leads = [SELECT ID,FirstName,LastName,External_Lead_ID__c,Rating,Name,MobilePhone,Email,Product_Category__c,
                            City__c,PIN_Code__c,Product_LK__c,Product_LK__r.Name,Business_Unit__c,LeadSource,Sub_Source__c,
                            Function__c,ONEABC_Lead_Source__c,
                            Remarks__c,OwnerId, Owner.Name,ABSLI_Lead_Type__c FROM Lead WHERE Id =: leadIds];
        for(Lead ld : leads){
            ABCL_Integration_Event__e evt = new ABCL_Integration_Event__e ();
            evt.Record_Id__c = ld.Id;
            evt.Business_Unit__c = 'ABCD';
            evt.ServiceName__c ='PushLeadToSFLMS';
            evt.ObjectApiName__c ='Lead';
            sfLMSWrapper retCls = new sfLMSWrapper(ld.FirstName,ld.LastName,ld.Email,
                                                  ld.Function__c,ld.MobilePhone,ld.PIN_Code__c,ld.Product_Category__c ,
                                                  ld.ONEABC_Lead_Source__c,ld.Sub_Source__c,ld.City__c,ld.Remarks__c);
            String responseText = JSON.serialize(retCls);
            responseText = responseText.replace('Address_PostalCode', 'Address__PostalCode__s');
            responseText = responseText.replace('Product_Category', 'Product_Category__c');
            responseText = responseText.replace('Address_City', 'Address__City__s');
            responseText = responseText.replace('central_team_remarks', 'central_team_remarks__c'); 
            responseText = responseText.replace('Sub_Source', 'Sub_Source__c');   
            responseText = responseText.replace('LOB', 'LOB__c');               
            evt.Request__c = responseText;
            sfLMSEvents.add(evt);
            
            ASF_Case_Integration__c cInte = new ASF_Case_Integration__c();
            cInte.Request__c = JSON.serialize(evt);
            
            insert cInte;
            System.debug('Check here --> '+cInte.Id);

        }
        if(sfLMSEvents.size()>0){
            List<Database.SaveResult> publishResults = EventBus.publish(sfLMSEvents);
        }
    }
    
    public class sfLMSWrapper{
        public string FirstName{get;set;}
        public string LastName{get;set;}
        public string Email{get;set;}
        public string LOB{get;set;}
        public string MobilePhone{get;set;}
        public string Address_PostalCode{get;set;}
        public string Product_Category{get;set;}
        public string LeadSource{get;set;}
        public string Sub_Source{get;set;}
        public string Address_City{get;set;}
        public string central_team_remarks{get;set;}
        
        public sfLMSWrapper(String fName, String lName, String email,
                           String lob, String mobile, String postalCode, String prodCategory, String ldSource,
                           String subSource, String addrCity, String remarks)
        {
            this.FirstName = fName;
            this.LastName = lName;
            this.Email = email;
            this.LOB = lob;
            this.MobilePhone = mobile;
            this.Address_PostalCode = postalCode;
            this.Product_Category = prodCategory;
            this.LeadSource = ldSource;
            this.Sub_Source = '';
            this.Address_City = addrCity;
            this.central_team_remarks = remarks;
        }
    }
    

}