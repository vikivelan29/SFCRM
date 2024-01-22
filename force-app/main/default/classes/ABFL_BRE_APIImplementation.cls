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
            when 'BRE_BalanceConfirmation_Retail', 'BRE_Foreclosure_Retail', 'BRE_NDCReasonMaster_Retail',
                'BRE_RepaymentSchedule_Retail', 'BRE_WelcomeLetter_Retail', 'BRE_LoanAgreement_Retail', 'BRE_ClosureProcess_Retail',
           	    'BRE_SanctionLetter_Retail'{
                fireWithoutDates(integRec, caseRecord, caseIntg);
            }
            when 'BRE_SOA_Retail', 'BRE_PartPayment_Retail' {
                //BRE_SOA_Retail - fromdate - loan start date, toDate - todays date
                fireWithDates(integRec, caseRecord, caseIntg, new List<Date>{caseRecord.Asset.Loan_Start_Date__c, Date.today()});
            }
            when 'BRE_ProInterestCert_Retail' {
                // ** from and todate is calculated for current FY - YYYY-MM-DD format.
                List<FiscalYearSettings> fi = ABFL_SOQL_Util.getFiscalYear(0,0);
                 fireWithDates(integRec, caseRecord, caseIntg, new List<Date>{fi[0]?.StartDate, fi[0]?.EndDate});
            }
           when 'BRE_InterestCert_Retail' {
               //** from and todate is calculated for previous FY YYYY-MM-DD format.
               List<FiscalYearSettings> fi = ABFL_SOQL_Util.getFiscalYear(1, 0);
               fireWithDates(integRec, caseRecord, caseIntg, new List<Date>{fi[0]?.StartDate, fi[0]?.EndDate});
           }
           when 'BRE_MarginHolding_Corporate' {
               //** Add business Date
                fireWithDates(integRec, caseRecord, caseIntg, null);
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
        System.debug('In callout:'+caseRecord.AccountId);     
        ABFL_BRE_Wrapper wrapper = new ABFL_BRE_Wrapper(caseRecord);

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
    public static void fireWithDates(ASF_Integration__c integRec, Case caseRecord, List<ASF_Case_Integration__c> caseIntg, List<Date> dts){
		String wrapper;
        if(dts != null && !dts.isEmpty() ) {
           wrapper = JSON.serialize(new ABFL_BRE_Wrapper_Dates(caseRecord, dts));
        }
        else{
            wrapper = JSON.serialize(new ABFL_BRE_Wrapper_BusinessDates(caseRecord));
        }

        Database.SaveResult publishResult = EventBus.publish(
            new Case_Integration_Outbound__e (
                Business_Unit__c  = caseRecord.Business_Unit__c,
                Case_Integration_ID__c = caseIntg[0]?.Name,
                Integration_Name__c  = integRec.STP_API_Identifier__c, // STP_API_Identifier__c is the actual name of API to invoke
                Request_Payload__c  =  wrapper
            )
        );
    }

    // Wrapper without dates
    Public class ABFL_BRE_Wrapper {
        public string loanAccountNumber ;
        public string ticketNo;
        public string source;
        public string email;
        public string mobileNumber;
        public string threadId;
        /****************************************************************************************************************
        * @LOB - ABFL
        * @Function - constructor
        * @param 
        * @return 
        * @Description - Invoked from the 
        *****************************************************************************************************************/
        public ABFL_BRE_Wrapper(Case caseRec){
            loanAccountNumber = caseRec.LAN__c;
            ticketNo = caseRec.CaseNumber;
            source = caseRec.BRE_Source__c;
            // email = caseRec.Origin == 'Email'?caseRec.SuppliedEmail:cont[0]?.Email;
            /** 
			* We are not using Contact records, so ContactEmail can't be used 
			* If Account exists, then if PersonAccount Use PersonEmail, else use Office_Email__c 
            * 
			**/
            email = (caseRec.AccountId != NULL)?(caseRec.Account.IsPersonAccount?caseRec.Account.PersonEmail:caseRec.Account.Office_Email__c):NULL;
            mobileNumber = (caseRec.AccountId != NULL)?(caseRec.Account.IsPersonAccount?caseRec.Account.PersonMobilePhone:caseRec.Account.Phone):NULL;
            threadId = EmailMessages.getFormattedThreadingToken(caseRec.Id);
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
        public string threadId;
        /****************************************************************************************************************
        * @LOB - ABFL
        * @Function - constructor
        * @param 
        * @return 
        * @Description - Invoked from the fireWithDates
        *****************************************************************************************************************/
        public ABFL_BRE_Wrapper_Dates(Case caseRec, List<Date> dts) {
            loanAccountNumber = caseRec.LAN__c;
            ticketNo = caseRec.CaseNumber;
            source = caseRec.BRE_Source__c;
            email = (caseRec.AccountId != NULL)?(caseRec.Account.IsPersonAccount?caseRec.Account.PersonEmail:caseRec.Account.Office_Email__c):NULL;
            mobileNumber = (caseRec.AccountId != NULL)?(caseRec.Account.IsPersonAccount?caseRec.Account.PersonMobilePhone:caseRec.Account.Phone):NULL;
            fromDate = dts[0];
            toDate = dts[1];
			threadId = EmailMessages.getFormattedThreadingToken(caseRec.Id);
        }
    }
    // Wrapper with dates
    Public class ABFL_BRE_Wrapper_BusinessDates {
        public string loanAccountNumber ;
        public string ticketNo;
        public string source;
        public string email;
        public string mobileNumber;
        // From and to dates will be dynamically populated by the caller
        public Date businessDate;
        public string threadId;
        /****************************************************************************************************************
        * @LOB - ABFL
        * @Function - constructor
        * @param 
        * @return 
        * @Description - Invoked from the fireWithDates
        *****************************************************************************************************************/
        public ABFL_BRE_Wrapper_BusinessDates(Case caseRec) {
            loanAccountNumber = caseRec.LAN__c;
            ticketNo = caseRec.CaseNumber;
            source = caseRec.BRE_Source__c;
            email = (caseRec.AccountId != NULL)?(caseRec.Account.IsPersonAccount?caseRec.Account.PersonEmail:caseRec.Account.Office_Email__c):NULL;
            mobileNumber = (caseRec.AccountId != NULL)?(caseRec.Account.IsPersonAccount?caseRec.Account.PersonMobilePhone:caseRec.Account.Phone):NULL;
            businessDate = Date.today();
			threadId = EmailMessages.getFormattedThreadingToken(caseRec.Id);
        }
    }
}