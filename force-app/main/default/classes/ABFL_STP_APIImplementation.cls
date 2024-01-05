/*********************************************************
 *Class        :  ABFL_STP_APIImplementation
 *Author       :  Udit Singhal
 *Description  :  STP API implementation class
 *********************************************************/
public class ABFL_STP_APIImplementation{
    /****************************************************************************************************************
     * @LOB - ABFL
     * @Function - callout
     * @param integRec - ASF_Integration__c record from the framework.
     * @param caseRec - Case record from the framework.
     * @return - void
     * @Description - Invoked from the ABFL_InvokeSTPProcess class
     *****************************************************************************************************************/
    public static void callout(ASF_Integration__c integRec, Case caseRec){
        System.debug('In ABFL_STP_APIImplementation');
        System.debug('integRec: ' + integRec);
        System.debug('caseRec: ' + caseRec);

        Case caseRecord = ABFL_SOQL_Case.getCaseInfo(caseRec.Id);
		List<FiscalYearSettings> fi = ABFL_SOQL_Util.getFiscalYear();
        System.debug('@@@fis'+fi);

        switch  on integRec.STP_API_Identifier__c {
            when 'GetDemandAdvice_Corp' {
                Map<String, Object> filter = new Map<String, Object>{ 'AGREEMENTNO' => caseRecord.LAN__c, 'NEXT_DUE_DATE' => new Map<String, Object>{ 'lte' => Datetime.now().dateGMT() } };
                performCallout(integRec, caseRecord, filter);
            }
            when 'GetInterestResetLetter_Corp' {
                Map<String, Object> filter = new Map<String, Object>{ 'AGREEMENTNO' => caseRecord.LAN__c };
                performCallout(integRec, caseRecord, filter);
            }
            when 'GetRepaymentSchedule_Corp'{
                Map<String, Object> filter = new Map<String, Object>{ 'AGREEMENTNO' => caseRecord.LAN__c, 'DUEDATE' => new Map<String, Object>{ 'lte' => '' } };
                performCallout(integRec, caseRecord, filter);
            }
            when 'GetWelcomeLetter_Corp'{
                Map<String, Object> filter = new Map<String, Object>{ 'AGREEMENTNO' => caseRecord.LAN__c };
                performCallout(integRec, caseRecord, filter);
            }
            when 'InterestDebitNote_Corp'{
                Map<String, Object> filter = new Map<String, Object>{ 'AGREEMENTNO' => caseRecord.LAN__c, 'CBD' => new Map<String, Object>{ 'gte' => fi[0]?.StartDate, 'lte' => fi[0]?.EndDate } };
                performCallout(integRec, caseRecord, filter);
            }
            when 'SOA_Corp'{
                Map<String, Object> filter = new Map<String, Object>{ 'AGREEMENTNO' => caseRecord.LAN__c, 'CBD' => new Map<String, Object>{ 'fromDate' => fi[0]?.StartDate, 'toDate' => fi[0]?.EndDate },
                    												'TRANSACTIONID' => ''};
                performCallout(integRec, caseRecord, filter);
            }
             
        }
    }

    /****************************************************************************************************************
     * @LOB - ABFL
     * @Function - performCallout
     * @param integRec - ASF_Integration__c record from the framework.
     * @param caseRec - Case record from the framework.
     * @return - void
     * @Description - Invoked from the callout method of ABFL_STP_APIImplementation class
     *****************************************************************************************************************/
    public static void performCallout(ASF_Integration__c integRec, Case caseRec, Map<String, Object> filter){
        System.debug('In performCallout:' + caseRec.ID);

        List<ASF_Case_Integration__c> caseIntg = ABFL_SOQL_Integration.getCaseIntegrationInfo(caseRec.Id, '');

        ABFL_STP_Wrapper wrapper = new ABFL_STP_Wrapper(filter, caseRec);

        Database.SaveResult publishResult = EventBus.publish(new Case_Integration_Outbound__e(
            Business_Unit__c = caseRec.Business_Unit__c, 
            Case_Integration_ID__c = caseIntg[0]?.Name, 
            Integration_Name__c = integRec.STP_API_Identifier__c,  // STP_API_Identifier__c is the actual name of API to invoke
            Request_Payload__c = JSON.serialize(wrapper)
        ));
    }

    //replace hardcoded values
    public class ABFL_STP_Wrapper{
        public Map<String, Object> filter;
        public String reportType;
        public String passwordProtectPDF;
        public String pdfPassword;
        public String encryption;

        public ABFL_STP_Wrapper(Map<String, Object> filter, Case caseRec){
            this.filter = filter;
            this.reportType = 'pdf';
            this.passwordProtectPDF = 'False';
            this.pdfPassword = '';
            this.encryption = 'False';
        }
    }
}