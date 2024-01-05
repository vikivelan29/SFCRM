/*********************************************************
*Class        :  ABFL_BRE_APIImplementation
*Author       :  Aditee Churiwala
*Description  :  BRE API implementation class
*********************************************************/
public class ABFL_BRE_APIImplementation {
    /****************************************************************************************************************
    * @LOB - ABFL
    * @Function - callout
    * @param caseRec - Case record from the framework.
    * @return - ABFL_InvokeBREProcess.IntegrationResponseWrapper
    * @Description - Invoked from the ABFL_InvokeBREProcess class
    *****************************************************************************************************************/
    public static void callout(ASF_Integration__c integRec, Case caseRec){
        System.debug('In callout:'+caseRec.ID+' '+integRec.STP_API_Identifier__c);
        Case caseRecord = ABFL_SOQL_Case.getCaseInfo(caseRec.Id);
        List<ASF_Case_Integration__c> caseIntg = ABFL_SOQL_Integration.getCaseIntegrationInfo(caseRec.Id,ABFL_Constants.BRE);
        // Determine the API to invoke & generate wrapper 
     	switch on integRec.STP_API_Identifier__c {
           when 'BRE_BalanceConfirmation_Retail', 'BRE_Foreclosure_Retail', 'BRE_NDCReasonMaster_Retail', 'BRE_ProInterestCert_Retail',
               'BRE_RepaymentSchedule_Retail', 'BRE_WelcomeLetter_Retail' {
               fireWithoutDates(integRec, caseRecord, caseIntg);
           }
           when 'BRE_InterestCert_Retail', 'BRE_SOA_Retail' {
               fireWithDates(integRec, caseRecord, caseIntg);
           }
        }    
    }
    /****************************************************************************************************************
    * @Function - callout
    * @param caseRec - Case record from the framework.
    * @return - void
    * @Description - Called for Different APIs : BRE_Foreclosure_Retail,BRE_BalanceConfirmation_Retail,BRE_ClosureProcess_Retail
    * BRE_Foreclosure_Retail,BRE_NDCReasonMaster_Retail, BRE_RepaymentSchedule_Retail, BRE_WelcomeLetter_Retail
    *****************************************************************************************************************/
    public static void fireWithoutDates(ASF_Integration__c integRec, Case caseRecord, List<ASF_Case_Integration__c> caseIntg){
        System.debug('In callout:'+caseRecord.ID);     
        List<Contact> cont = ABFL_SOQL_Case.getContact(caseRecord.AccountId);
        ABFL_BRE_Wrapper wrapper = new ABFL_BRE_Wrapper(caseRecord, cont);

        // publish event
        Database.SaveResult publishResult = EventBus.publish(
            new Case_Integration_Outbound__e (
                Business_Unit__c  = caseRecord.Business_Unit__c,
                Case_Integration_ID__c = caseIntg[0]?.Name,
                Integration_Name__c  = integRec.STP_API_Identifier__c, // STP_API_Identifier__c is the actual name of API to invoke
                Request_Payload__c  =  JSON.serialize(wrapper)
            )
        );
    }
    
    /****************************************************************************************************************
    * @LOB - ABFL
    * @Function - callout
    * @param caseRec - Case record from the framework.
    * @return - void
    * @Description - Invoked from the ABFL_InvokeBREProcess class
    *****************************************************************************************************************/
    public static void fireWithDates(ASF_Integration__c integRec, Case caseRecord, List<ASF_Case_Integration__c> caseIntg){
        List<FiscalYearSettings> fi = ABFL_SOQL_Util.getFiscalYear();
        System.debug('@@@fis'+fi);

        List<Contact> cont = ABFL_SOQL_Case.getContact(caseRecord.AccountId);

        ABFL_BRE_Wrapper_Dates wrapper = new ABFL_BRE_Wrapper_Dates(caseRecord, fi, cont);
        
        Database.SaveResult publishResult = EventBus.publish(
            new Case_Integration_Outbound__e (
                Business_Unit__c  = caseRecord.Business_Unit__c,
                Case_Integration_ID__c = caseIntg[0]?.Name,
                Integration_Name__c  = integRec.STP_API_Identifier__c, // STP_API_Identifier__c is the actual name of API to invoke
                Request_Payload__c  =  JSON.serialize(wrapper)
            )
        );
    }

    // Wrapper with dates
    Public class ABFL_BRE_Wrapper {
        public string loanAccountNumber ;
        public string ticketNo;
        public string source;
        public string email;
        public string mobileNumber;
        
        /****************************************************************************************************************
        * @LOB - ABFL
        * @Function - constructor
        * @param 
        * @return 
        * @Description - Invoked from the 
        *****************************************************************************************************************/
        public ABFL_BRE_Wrapper(Case caseRec, List<Contact> cont){
            loanAccountNumber = caseRec.LAN__c;
            ticketNo = caseRec.CaseNumber;
            source = caseRec.BRE_Source__c;
            email = caseRec.Origin == 'Email'?caseRec.SuppliedEmail:cont[0]?.Email;
            mobileNumber = cont[0]?.MobilePhone != null?cont[0]?.MobilePhone:cont[0]?.Phone;
        }
    }
    // Wrapper with dates
    Public class ABFL_BRE_Wrapper_Dates {
        public string loanAccountNumber ;
        public string ticketNo;
        public string source;
        public string email;
        public string mobileNumber;
        // From and to dates will be dynamically populated by the caller
        public Date fromDate;
        public Date toDate;
        
        /****************************************************************************************************************
        * @LOB - ABFL
        * @Function - constructor
        * @param 
        * @return 
        * @Description - Invoked from the 
        *****************************************************************************************************************/
        public ABFL_BRE_Wrapper_Dates(Case caseRec, List<FiscalYearSettings> fi, List<Contact> cont) {
            loanAccountNumber = caseRec.LAN__c;
            ticketNo = caseRec.CaseNumber;
            source = caseRec.BRE_Source__c;
            email = caseRec.Origin == 'Email'?caseRec.SuppliedEmail:cont[0]?.Email;
            mobileNumber = cont[0]?.MobilePhone != null?cont[0]?.MobilePhone:cont[0]?.Phone;
            fromDate = fi[0]?.StartDate;
            toDate = fi[0]?.EndDate;
        }
    }
}