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
    * @Function - callout
    * @param caseRec - Case record from the framework.
    * @return - void
    * @Description - Called for Different APIs : BRE_Foreclosure_Retail,BRE_BalanceConfirmation_Retail,BRE_ClosureProcess_Retail
    * BRE_Foreclosure_Retail,BRE_NDCReasonMaster_Retail, BRE_RepaymentSchedule_Retail, BRE_WelcomeLetter_Retail
    *****************************************************************************************************************/
    public static void fireWithoutDates(ASF_Integration__c integRec, Case caseRecord, List<ASF_Case_Integration__c> caseIntg){
        System.debug('In callout:'+caseRecord.AccountId);     
        String emailId = (caseRecord.AccountId != NULL)?(caseRecord.Account.IsPersonAccount?caseRecord.Account.PersonEmail:caseRecord.Account.Office_Email__c):NULL;
        String mobileNo = (caseRecord.AccountId != NULL)?(caseRecord.Account.IsPersonAccount?caseRecord.Account.PersonMobilePhone:caseRecord.Account.Phone):NULL;
        Map<String, Object> payloadWrap = new Map<String, Object>{ 
                                                                'loanAccountNumber' => caseRecord.LAN__c, 
                                                                'ticketNo' =>  caseRecord.CaseNumber,
                                                                'source' => caseRecord.BRE_Source__c,
                                                                'email' => emailId,
                                                                'mobileNumber' => mobileNo,
                                                                'threadId' => EmailMessages.getFormattedThreadingToken(caseRecord.Id)
                                                            };

        // publish event
        Database.SaveResult publishResult = EventBus.publish(
            new Case_Integration_Outbound__e (
                Business_Unit__c  = caseRecord.Business_Unit__c,
                Case_Integration_ID__c = caseIntg[0]?.Name,
                Integration_Name__c  = integRec.STP_API_Identifier__c, // STP_API_Identifier__c is the actual name of API to invoke
                Request_Payload__c  =  JSON.serialize(payloadWrap)
            )
        );
    }

    /****************************************************************************************************************
    * @Function - callout
    * @param caseRec - Case record from the framework.
    * @return - void
    * @Description - Called for Different APIs : 'BRE_SanctionLetter_Retail', 'BRE_LoanAgreement_Retail'
    *****************************************************************************************************************/
    public static void fireWithoutStatus(ASF_Integration__c integRec, Case caseRecord, List<ASF_Case_Integration__c> caseIntg){
        System.debug('In callout:'+caseRecord.AccountId);     
        String emailId = (caseRecord.AccountId != NULL)?(caseRecord.Account.IsPersonAccount?caseRecord.Account.PersonEmail:caseRecord.Account.Office_Email__c):NULL;
        String mobileNo = (caseRecord.AccountId != NULL)?(caseRecord.Account.IsPersonAccount?caseRecord.Account.PersonMobilePhone:caseRecord.Account.Phone):NULL;
        Map<String, Object> payloadWrap = new Map<String, Object>{ 
                                                                'loanAccountNumber' => caseRecord.LAN__c, 
                                                                'ticketNo' =>  caseRecord.CaseNumber,
                                                                'email' => emailId,
                                                                'mobileNumber' => mobileNo,
                                                                'threadId' => EmailMessages.getFormattedThreadingToken(caseRecord.Id)
                                                            };

        // publish event
        Database.SaveResult publishResult = EventBus.publish(
            new Case_Integration_Outbound__e (
                Business_Unit__c  = caseRecord.Business_Unit__c,
                Case_Integration_ID__c = caseIntg[0]?.Name,
                Integration_Name__c  = integRec.STP_API_Identifier__c, // STP_API_Identifier__c is the actual name of API to invoke
                Request_Payload__c  =  JSON.serialize(payloadWrap)
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
        Map<String, Object> payloadWrap;
        String emailId = (caseRecord.AccountId != NULL)?(caseRecord.Account.IsPersonAccount?caseRecord.Account.PersonEmail:caseRecord.Account.Office_Email__c):NULL;
        String mobileNo = (caseRecord.AccountId != NULL)?(caseRecord.Account.IsPersonAccount?caseRecord.Account.PersonMobilePhone:caseRecord.Account.Phone):NULL;
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

        Database.SaveResult publishResult = EventBus.publish(
            new Case_Integration_Outbound__e (
                Business_Unit__c  = caseRecord.Business_Unit__c,
                Case_Integration_ID__c = caseIntg[0]?.Name,
                Integration_Name__c  = integRec.STP_API_Identifier__c, // STP_API_Identifier__c is the actual name of API to invoke
                Request_Payload__c  =  JSON.serialize(payloadWrap)
            )
        );
    }
}