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
     * @param caseRecord - Case record from the framework.
     * @return - void
     * @Description - Invoked from the ABFL_InvokeSTPProcess class
     *****************************************************************************************************************/
    public static void callout(ASF_Integration__c integRec, Case caseRecord){
        System.debug('In ABFL_STP_APIImplementation');
        System.debug('integRec: ' + integRec);
        System.debug('caseRecord: ' + caseRecord);

		List<FiscalYearSettings> fi = ABFL_SOQL_Util.getFiscalYear(0,0);
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
                Map<String, Object> filter = new Map<String, Object>{ 'AGREEMENTNO' => caseRecord.LAN__c, 'DUEDATE' => new Map<String, Object>{ 'lte' => System.now().format('dd-MMM-yyyy') } };
                performCallout(integRec, caseRecord, filter);
            }
            when 'GetWelcomeLetter_Corp'{
                Map<String, Object> filter = new Map<String, Object>{ 'AGREEMENTNO' => caseRecord.LAN__c };
                performCallout(integRec, caseRecord, filter);
            }
            when 'InterestDebitNote_Corp'{
                Map<String, Object> filter = new Map<String, Object>{ 'AGREEMENTNO' => caseRecord.LAN__c, 'CBD' => new Map<String, Object>{ 'gte' => caseRecord.ABFL_Case_Detail__r.From_Date__c, 'lte' => caseRecord.ABFL_Case_Detail__r.To_Date__c } };
                performCallout(integRec, caseRecord, filter);
            }
            when 'SOA_Corp'{
                Map<String, Object> filter = new Map<String, Object>{ 'AGREEMENTNO' => caseRecord.LAN__c, 'CBD' => new Map<String, Object>{ 'fromDate' => caseRecord.ABFL_Case_Detail__r.From_Date__c, 'toDate' => caseRecord.ABFL_Case_Detail__r.To_Date__c }, 'TRANSACTIONID' => System.now().format('ddMMyyyyhhmmss')};
                performCallout(integRec, caseRecord, filter);
            }
             
        }
    }

    /****************************************************************************************************************
     * @LOB - ABFL
     * @Function - performCallout
     * @param integRec - ASF_Integration__c record from the framework.
     * @param caseRecord - Case record from the framework.
     * @return - void
     * @Description - Invoked from the callout method of ABFL_STP_APIImplementation class
     *****************************************************************************************************************/
    public static void performCallout(ASF_Integration__c integRec, Case caseRecord, Map<String, Object> filter){
        System.debug('In performCallout:' + caseRecord.ID);

        List<ASF_Case_Integration__c> caseIntg = ABFL_SOQL_Integration.getCaseIntegrationInfo(caseRecord.Id, '');

        ABFL_STP_Wrapper wrapper = new ABFL_STP_Wrapper(filter, caseRecord);

        Database.SaveResult publishResult = EventBus.publish(new Case_Integration_Outbound__e(
            Business_Unit__c = caseRecord.Business_Unit__c, 
            Case_Integration_ID__c = caseIntg[0]?.Name, 
            Integration_Name__c = integRec.STP_API_Identifier__c,  // STP_API_Identifier__c is the actual name of API to invoke
            Request_Payload__c = JSON.serialize(wrapper)
        ));
    }

    // Wrapper to send data
    public class ABFL_STP_Wrapper{
        public Map<String, Object> filter;
        public String reportType;
        public String passwordProtectPDF;
        public String pdfPassword;
        public String encryption;

        public ABFL_STP_Wrapper(Map<String, Object> filter, Case caseRecord){
            this.filter = filter;
            this.reportType = 'pdf';
            this.passwordProtectPDF = 'false';
            this.pdfPassword = '';
            this.encryption = 'false';
        }
    }
}