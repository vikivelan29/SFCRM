/*********************************************************
*Class        :  ABFL_BRE_APIImplementation
*Author       :  Aditee Churiwala
* @description    BRE API implementation class
*********************************************************/
public class ABFL_BRE_APIImplementation {
    public static String emailIdBusiness = '';
    public static String mobileBusiness = '';
    /****************************************************************************************************************
    * @LOB - ABFL
    * @Function - callout
    * @param integRec 
    * @param caseRec
    * @description  Invoked from the ABFL_InvokeBREProcess class
    *****************************************************************************************************************/
    public static void callout(ASF_Integration__c integRec, Case caseRec){
        Case caseRecord = ABFL_SOQL_Case.getCaseInfo(caseRec.Id);
        List<ASF_Case_Integration__c> caseIntg = ABFL_SOQL_Integration.getCaseIntegrationInfo(caseRec.Id,ABFL_Constants.BRE);

        if(caseRecord.AccountId != NULL && !caseRecord.Account.IsPersonAccount) {
            List<Contact> con = [SELECT Id, Email, MobilePhone FROM Contact WHERE AccountId = :caseRecord.AccountId];
			emailIdBusiness = con.size()>0 && con[0] != null && con[0].Email != null?con[0]?.Email:caseRecord.Account.Office_Email__c; 
            mobileBusiness = con.size()>0 && con[0] != null && con[0].MobilePhone != null?con[0]?.MobilePhone:caseRecord.Account.Phone; 
        }
        
        // Determine the API to invoke & generate wrapper 
     	switch on integRec.STP_API_Identifier__c {
            when 'BRE_BalanceConfirmation_Retail', 'BRE_Foreclosure_Retail', 'BRE_NDCReasonMaster_Retail',
                'BRE_RepaymentSchedule_Retail', 'BRE_WelcomeLetter_Retail', 'BRE_ClosureProcess_Retail'{
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
           when 'BRE_SanctionLetter_Retail', 'BRE_LoanAgreement_Retail'{
            fireWithoutStatus(integRec, caseRecord, caseIntg);
           }
        }    
    }
    /****************************************************************************************************************
    * @LOB - ABFL
    * @Function - callout
    * @param integRec
    * @param caseRec
    * @param allCaseInts
    * @return  Case_Integration_Outbound__e
    * @description  Invoked from the ABFL_InvokeBREProcess class
    *****************************************************************************************************************/
    public static Case_Integration_Outbound__e callout(ASF_Integration__c integRec, Case caseRec, List<ASF_Case_Integration__c> allCaseInts,
				String emailId, String mobileNo){
        //Case caseRecord = ABFL_SOQL_Case.getCaseInfo(caseRec.Id);
        Case caseRecord = caseRec;
        //List<ASF_Case_Integration__c> caseIntg = ABFL_SOQL_Integration.getCaseIntegrationInfo(caseRec.Id,ABFL_Constants.BRE);
        List<ASF_Case_Integration__c> caseIntg = new List<ASF_Case_Integration__c>();
        if(!allCaseInts.isEmpty()){
            for(ASF_Case_Integration__c caseInt : allCaseInts){
                if(caseInt.Status__c == ABFL_Constants.PENDING && caseInt.Type__c == ABFL_Constants.BRE){
                    caseIntg.add(caseInt);
                }
            }
        }
        // Determine the API to invoke & generate wrapper 
     	switch on integRec.STP_API_Identifier__c {
            when 'BRE_BalanceConfirmation_Retail', 'BRE_Foreclosure_Retail', 'BRE_NDCReasonMaster_Retail',
                'BRE_RepaymentSchedule_Retail', 'BRE_WelcomeLetter_Retail', 'BRE_ClosureProcess_Retail'{
                return fireWithoutDatesForBulk(integRec, caseRecord, caseIntg, emailId, mobileNo);
            }
            when 'BRE_SOA_Retail', 'BRE_PartPayment_Retail' {
                //BRE_SOA_Retail - fromdate - loan start date, toDate - todays date
                return fireWithDatesForBulk(integRec, caseRecord, caseIntg, new List<Date>{caseRecord.Asset.Loan_Start_Date__c, Date.today()}, emailId, mobileNo);
            }
            when 'BRE_ProInterestCert_Retail' {
                // ** from and todate is calculated for current FY - YYYY-MM-DD format.
                List<FiscalYearSettings> fi = ABFL_SOQL_Util.getFiscalYear(0,0);
                return fireWithDatesForBulk(integRec, caseRecord, caseIntg, new List<Date>{fi[0]?.StartDate, fi[0]?.EndDate}, emailId, mobileNo);
            }
           when 'BRE_InterestCert_Retail' {
                //** from and todate is calculated for previous FY YYYY-MM-DD format.
                List<FiscalYearSettings> fi = ABFL_SOQL_Util.getFiscalYear(1, 0);
                return fireWithDatesForBulk(integRec, caseRecord, caseIntg, new List<Date>{fi[0]?.StartDate, fi[0]?.EndDate}, emailId, mobileNo);
           }
           when 'BRE_MarginHolding_Corporate' {
               //** Add business Date
                return fireWithDatesForBulk(integRec, caseRecord, caseIntg, null, emailId, mobileNo);
           }
           when 'BRE_SanctionLetter_Retail', 'BRE_LoanAgreement_Retail'{
                return fireWithoutStatusForBulk(integRec, caseRecord, caseIntg, emailId, mobileNo);
           }
        }
        return null;    
    }
    /****************************************************************************************************************
    * @Function - callout
    * @param integRec
    * @param caseRecord
    * @param caseIntg
    * @description Called for Different APIs : BRE_Foreclosure_Retail,BRE_BalanceConfirmation_Retail,BRE_ClosureProcess_Retail
    *****************************************************************************************************************/
    public static void fireWithoutDates(ASF_Integration__c integRec, Case caseRecord, List<ASF_Case_Integration__c> caseIntg){
        String emailId = (caseRecord.AccountId != NULL)?(caseRecord.Account.IsPersonAccount?caseRecord.Account.PersonEmail:emailIdBusiness):NULL;
        String mobileNo = (caseRecord.AccountId != NULL)?(caseRecord.Account.IsPersonAccount?caseRecord.Account.PersonMobilePhone:mobileBusiness):NULL;
        Map<String, Object> payloadWrap = new Map<String, Object>{ 
                                                                'loanAccountNumber' => caseRecord.LAN__c, 
                                                                'ticketNo' =>  caseRecord.CaseNumber,
                                                                'source' => caseRecord.BRE_Source__c,
                                                                'email' => emailId,
                                                                'mobileNumber' => mobileNo,
                                                                'threadId' => EmailMessages.getFormattedThreadingToken(caseRecord.Id)
                                                            };

        // publish event
        EventBus.publish(
            new Case_Integration_Outbound__e (
                Business_Unit__c  = caseRecord.Business_Unit__c,
                Case_Integration_ID__c = caseIntg[0]?.Name,
                Integration_Name__c  = integRec.STP_API_Identifier__c, // STP_API_Identifier__c is the actual name of API to invoke
                Request_Payload__c  =  JSON.serialize(payloadWrap)
            )
        );
    }
    /****************************************************************************************************************
    * @Function - fireWithoutDatesForBulk
    * @param integRec
    * @param caseRecord
    * @param caseIntg
    * @return Case_Integration_Outbound__e
    * @description Called for Different APIs : BRE_Foreclosure_Retail,BRE_BalanceConfirmation_Retail,BRE_ClosureProcess_Retail
    *****************************************************************************************************************/
    public static Case_Integration_Outbound__e fireWithoutDatesForBulk(ASF_Integration__c integRec, Case caseRecord, List<ASF_Case_Integration__c> caseIntg, String emailId, String mobileNo){
        
        Map<String, Object> payloadWrap = new Map<String, Object>{ 
                                                                'loanAccountNumber' => caseRecord.LAN__c, 
                                                                'ticketNo' =>  caseRecord.CaseNumber,
                                                                'source' => caseRecord.BRE_Source__c,
                                                                'email' => emailId,
                                                                'mobileNumber' => mobileNo,
                                                                'threadId' => EmailMessages.getFormattedThreadingToken(caseRecord.Id)
                                                            };

        // publish event
        //Database.SaveResult publishResult = EventBus.publish(
            return new Case_Integration_Outbound__e (
                Business_Unit__c  = caseRecord.Business_Unit__c,
                Case_Integration_ID__c = caseIntg[0]?.Name,
                Integration_Name__c  = integRec.STP_API_Identifier__c, // STP_API_Identifier__c is the actual name of API to invoke
                Request_Payload__c  =  JSON.serialize(payloadWrap)
            );
        //);
    }

    /****************************************************************************************************************
    * @Function - fireWithoutDatesForBulk
    * @param integRec
    * @param caseRecord
    * @param caseIntg
    * @description Called for Different APIs : BRE_Foreclosure_Retail,BRE_BalanceConfirmation_Retail,BRE_ClosureProcess_Retail
    *****************************************************************************************************************/
    public static void fireWithoutStatus(ASF_Integration__c integRec, Case caseRecord, List<ASF_Case_Integration__c> caseIntg){
        String emailId = (caseRecord.AccountId != NULL)?(caseRecord.Account.IsPersonAccount?caseRecord.Account.PersonEmail:emailIdBusiness):NULL;
        String mobileNo = (caseRecord.AccountId != NULL)?(caseRecord.Account.IsPersonAccount?caseRecord.Account.PersonMobilePhone:mobileBusiness):NULL;
        Map<String, Object> payloadWrap = new Map<String, Object>{ 
                                                                'loanAccountNumber' => caseRecord.LAN__c, 
                                                                'ticketNo' =>  caseRecord.CaseNumber,
                                                                'email' => emailId,
                                                                'mobileNumber' => mobileNo,
                                                                'threadId' => EmailMessages.getFormattedThreadingToken(caseRecord.Id)
                                                            };

        // publish event
        EventBus.publish(
            new Case_Integration_Outbound__e (
                Business_Unit__c  = caseRecord.Business_Unit__c,
                Case_Integration_ID__c = caseIntg[0]?.Name,
                Integration_Name__c  = integRec.STP_API_Identifier__c, // STP_API_Identifier__c is the actual name of API to invoke
                Request_Payload__c  =  JSON.serialize(payloadWrap)
            )
        );
    }
    /****************************************************************************************************************
    * @Function - fireWithoutStatusForBulk
    * @param integRec
    * @param caseRecord
    * @param caseIntg
    * @return Case_Integration_Outbound__e
    * @description Called for Different APIs : BRE_Foreclosure_Retail,BRE_BalanceConfirmation_Retail,BRE_ClosureProcess_Retail
    *****************************************************************************************************************/
    public static Case_Integration_Outbound__e fireWithoutStatusForBulk(ASF_Integration__c integRec, Case caseRecord, List<ASF_Case_Integration__c> caseIntg,String emailId, String mobileNo){
        Map<String, Object> payloadWrap = new Map<String, Object>{ 
                                                                'loanAccountNumber' => caseRecord.LAN__c, 
                                                                'ticketNo' =>  caseRecord.CaseNumber,
                                                                'email' => emailId,
                                                                'mobileNumber' => mobileNo,
                                                                'threadId' => EmailMessages.getFormattedThreadingToken(caseRecord.Id)
                                                            };

        // publish event
        //Database.SaveResult publishResult = EventBus.publish(
            return new Case_Integration_Outbound__e (
                Business_Unit__c  = caseRecord.Business_Unit__c,
                Case_Integration_ID__c = caseIntg[0]?.Name,
                Integration_Name__c  = integRec.STP_API_Identifier__c, // STP_API_Identifier__c is the actual name of API to invoke
                Request_Payload__c  =  JSON.serialize(payloadWrap)
            );
        //);
    }
    
    /****************************************************************************************************************
    * @Function - fireWithDates
    * @param integRec
    * @param caseRecord
    * @param caseIntg
    * @description Called for Different APIs : BRE_Foreclosure_Retail,BRE_BalanceConfirmation_Retail,BRE_ClosureProcess_Retail
    *****************************************************************************************************************/
    public static void fireWithDates(ASF_Integration__c integRec, Case caseRecord, List<ASF_Case_Integration__c> caseIntg, List<Date> dts){
        Map<String, Object> payloadWrap;
        String emailId = (caseRecord.AccountId != NULL)?(caseRecord.Account.IsPersonAccount?caseRecord.Account.PersonEmail:emailIdBusiness):NULL;
        String mobileNo = (caseRecord.AccountId != NULL)?(caseRecord.Account.IsPersonAccount?caseRecord.Account.PersonMobilePhone:mobileBusiness):NULL;
        if(dts != null && !dts.isEmpty() ) {
            payloadWrap = new Map<String, Object>{ 
                                                    'loanAccountNumber' => caseRecord.LAN__c, 
                                                    'ticketNo' =>  caseRecord.CaseNumber,
                                                    'source' => caseRecord.BRE_Source__c,
                                                    'email' => emailId,
                                                    'mobileNumber' => mobileNo,
                                                    'fromDate' => dts[0],
                                                    'toDate' => dts[1],
                                                    'threadId' => EmailMessages.getFormattedThreadingToken(caseRecord.Id)
                                                };
        }
        else{
            payloadWrap = new Map<String, Object>{ 
                                                    'loanAccountNumber' => caseRecord.LAN__c, 
                                                    'ticketNo' =>  caseRecord.CaseNumber,
                                                    'source' => caseRecord.BRE_Source__c,
                                                    'email' => emailId,
                                                    'mobileNumber' => mobileNo,
                                                    'businessDate' => Date.today(),
                                                    'threadId' => EmailMessages.getFormattedThreadingToken(caseRecord.Id)
                                                };
        }

        EventBus.publish(
            new Case_Integration_Outbound__e (
                Business_Unit__c  = caseRecord.Business_Unit__c,
                Case_Integration_ID__c = caseIntg[0]?.Name,
                Integration_Name__c  = integRec.STP_API_Identifier__c, // STP_API_Identifier__c is the actual name of API to invoke
                Request_Payload__c  =  JSON.serialize(payloadWrap)
            )
        );
    }
     /****************************************************************************************************************
    * @Function - fireWithDates
    * @param integRec
    * @param caseRecord
    * @param caseIntg
    * @param dts
    * @return Case_Integration_Outbound__e
    * @description Called for Different APIs : BRE_Foreclosure_Retail,BRE_BalanceConfirmation_Retail,BRE_ClosureProcess_Retail
    *****************************************************************************************************************/
    public static Case_Integration_Outbound__e fireWithDatesForBulk(ASF_Integration__c integRec, Case caseRecord, List<ASF_Case_Integration__c> caseIntg, List<Date> dts, String emailId, String mobileNo){
        Map<String, Object> payloadWrap;
        if(dts != null && !dts.isEmpty() ) {
            payloadWrap = new Map<String, Object>{ 
                                                    'loanAccountNumber' => caseRecord.LAN__c, 
                                                    'ticketNo' =>  caseRecord.CaseNumber,
                                                    'source' => caseRecord.BRE_Source__c,
                                                    'email' => emailId,
                                                    'mobileNumber' => mobileNo,
                                                    'fromDate' => dts[0],
                                                    'toDate' => dts[1],
                                                    'threadId' => EmailMessages.getFormattedThreadingToken(caseRecord.Id)
                                                };
        }
        else{
            payloadWrap = new Map<String, Object>{ 
                                                    'loanAccountNumber' => caseRecord.LAN__c, 
                                                    'ticketNo' =>  caseRecord.CaseNumber,
                                                    'source' => caseRecord.BRE_Source__c,
                                                    'email' => emailId,
                                                    'mobileNumber' => mobileNo,
                                                    'businessDate' => Date.today(),
                                                    'threadId' => EmailMessages.getFormattedThreadingToken(caseRecord.Id)
                                                };
        }

        //Database.SaveResult publishResult = EventBus.publish(
            return new Case_Integration_Outbound__e (
                Business_Unit__c  = caseRecord.Business_Unit__c,
                Case_Integration_ID__c = caseIntg[0]?.Name,
                Integration_Name__c  = integRec.STP_API_Identifier__c, // STP_API_Identifier__c is the actual name of API to invoke
                Request_Payload__c  =  JSON.serialize(payloadWrap)
            );
        //);
    }
}