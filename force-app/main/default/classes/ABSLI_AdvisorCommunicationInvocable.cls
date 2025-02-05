public with sharing class ABSLI_AdvisorCommunicationInvocable {
    @InvocableMethod(label='ABSLI Advisor Communication' description='Returns Recipient for Communication')
    public static List<EmailOutputWrapper> getRecipients(List<EmailInputWrapper> records) {
        List<EmailOutputWrapper> result = new List<EmailOutputWrapper>();
        
        Set<String> partnerBrCd = new Set<String>();
        Map<String,List<Account>> mCodeVsAccount = new Map<String,List<Account>>();
        Map<String,recipientDetails> mCodeVsSupervisorEmail = new Map<String,recipientDetails>();
        Map<String,recipientDetails> mCodeVsadvisorEmail = new Map<String,recipientDetails>();
        
        
        
        for(EmailInputWrapper wrap: records){
            partnerBrCd.add(wrap.partnerBranchCode);
        }
        
        Map<Id,Account> mAdvisors = new Map<Id,Account>([SELECT ID,Partner_Branch_Code__c,PersonEmail,PersonMobilePhone,Supervisor_Email__c,Supervisor_Mobile_Number__c 
                                                         FROM Account WHERE Partner_Branch_Code__c =: partnerBrCd
                                                         AND RecordType.DeveloperName = 'ABSLI_Advisor' ORDER BY LastModifiedDate DESC]);
        for(Account advisor : mAdvisors.values()){
            if(advisor.Partner_Branch_Code__c != null){
                if(!mCodeVsAccount.containsKey(advisor.Partner_Branch_Code__c)){
                    mCodeVsAccount.put(advisor.Partner_Branch_Code__c, new List<Account>());
                }
                mCodeVsAccount.get(advisor.Partner_Branch_Code__c).add(advisor);
                
                if(!mCodeVsSupervisorEmail.containsKey(advisor.Partner_Branch_Code__c) && 
                   advisor.Supervisor_Email__c != null){
                       recipientDetails cls = new recipientDetails(advisor.Supervisor_Email__c, advisor.Supervisor_Mobile_Number__c);
                       mCodeVsSupervisorEmail.put(advisor.Partner_Branch_Code__c,cls);
                   }
                if(!mCodeVsadvisorEmail.containsKey(advisor.Partner_Branch_Code__c) && 
                   advisor.PersonEmail != null){
                       recipientDetails cls = new recipientDetails(advisor.PersonEmail, advisor.PersonMobilePhone);
                       mCodeVsadvisorEmail.put(advisor.Partner_Branch_Code__c,cls);
                   }
            }
        }
        
        if(mCodeVsAccount.keySet().size()>0){
            for(EmailInputWrapper wrap: records){
                if(mCodeVsAccount.containsKey(wrap.partnerBranchCode)){
                    // WHEN MORE THAN 1 ADVISORS FOR GIVEN PARTNER BRANCH.
                    EmailOutputWrapper cls = new EmailOutputWrapper();
                    if(mCodeVsAccount.get(wrap.partnerBranchCode).size()>1){
                        cls.toEmailAddresses = mCodeVsSupervisorEmail.get(wrap.partnerBranchCode).email;
                        cls.supervisorMobileNumber = mCodeVsSupervisorEmail.get(wrap.partnerBranchCode).mobile;
                        cls.outcome = 2;
                    }
                    else if(mCodeVsAccount.get(wrap.partnerBranchCode).size() == 1){
                        if(mCodeVsadvisorEmail.get(wrap.partnerBranchCode) != null){
                            cls.toEmailAddresses = mCodeVsadvisorEmail.get(wrap.partnerBranchCode).email;
                            cls.roMobileNumber = mCodeVsadvisorEmail.get(wrap.partnerBranchCode).mobile; 
                            cls.outcome = 1;
                        }
                        if(mCodeVsSupervisorEmail.get(wrap.partnerBranchCode) != null){
                            cls.ccEmailAddresses = mCodeVsSupervisorEmail.get(wrap.partnerBranchCode).email;
                            cls.supervisorMobileNumber = mCodeVsSupervisorEmail.get(wrap.partnerBranchCode).mobile; 
                            cls.outcome = 1;
                        }
                        
                    }
                    else{
                        cls.outcome = 0;
                    }
                    result.add(cls);
                }
            }
        }
        return result;
    }
    
    public class recipientDetails{
        public string email{get;set;}
        public string mobile{get;set;}
        recipientDetails(string em,String mob){
            this.email = em;
            this.mobile = mob;
        }
    }
    /**
* @description - Input wrapper where the values comes from the flow
*/
    public class EmailInputWrapper {
        @InvocableVariable(label='Partner Branch Code' description='Partner Branch Code' required=false)
        public String partnerBranchCode;
        @InvocableVariable(label='Case Id' description='Case Id' required=false)
        public Id caseId;
    }
    /**
* @description - output wrapper that is sent back to flow
*/
    public class EmailOutputWrapper {
        @InvocableVariable(label='ToEmailAddresses' description='Email Recipient Email Address' required=false)
        public string toEmailAddresses;
        @InvocableVariable(label='CcEmailAddresses' description='Email Recipient Cc Email Address' required=false)
        public String ccEmailAddresses;
        @InvocableVariable(label='Recipient Mobile Number' description='RO Mobile Number' required=false)
        public String roMobileNumber;
        @InvocableVariable(label='Supervisor Mobile Number' description='Supervisor Mobile Number' required=false)
        public String supervisorMobileNumber; 
        @InvocableVariable(label='Outcome' description='1 for Single RO, 2 for More than one RO, 0 for no RO' required=false)
        public integer outcome; 
    }
    
}