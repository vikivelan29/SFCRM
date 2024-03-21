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

        Datetime fromDate =  caseRecord.ABFL_Case_Detail__r.From_Date__c != null ? DateTime.newInstance(caseRecord.ABFL_Case_Detail__r.From_Date__c.year(), caseRecord.ABFL_Case_Detail__r.From_Date__c.month(), caseRecord.ABFL_Case_Detail__r.From_Date__c.day()) : null;
        Datetime toDate = caseRecord.ABFL_Case_Detail__r.To_Date__c != null ? DateTime.newInstance(caseRecord.ABFL_Case_Detail__r.To_Date__c.year(), caseRecord.ABFL_Case_Detail__r.To_Date__c.month(), caseRecord.ABFL_Case_Detail__r.To_Date__c.day()) : null;

        switch  on integRec.STP_API_Identifier__c {
            when 'GetDemandAdvice_Corp' {
                Map<String, Object> filter = new Map<String, Object>{ 'AGREEMENTNO' => caseRecord.LAN__c, 'NEXT_DUE_DATE' => new Map<String, Object>{ 'lte' => Datetime.now().format('dd-MMM-yyyy') } };
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
                Map<String, Object> filter = new Map<String, Object>{ 'AGREEMENTNO' => caseRecord.LAN__c, 'CBD' => new Map<String, Object>{ 'gte' => fromDate.format('dd-MMM-yyyy'), 'lte' => toDate.format('dd-MMM-yyyy') } };
                performCallout(integRec, caseRecord, filter);
            }
            when 'SOA_Corp'{
                Map<String, Object> filter = new Map<String, Object>{ 'AGREEMENTNO' => caseRecord.LAN__c, 'CBD' => new Map<String, Object>{ 'fromDate' => fromDate.format('dd-MMM-yyyy'), 'toDate' => toDate.format('dd-MMM-yyyy') }, 'TRANSACTIONID' => Long.valueOf(System.now().format('ddMMyyyyhhmmss'))};
                performCallout(integRec, caseRecord, filter);
            }
             
        }
    }
     public static Case_Integration_Outbound__e callout(ASF_Integration__c integRec, Case caseRecord, List<ASF_Case_Integration__c> allCaseInts){
        System.debug('In ABFL_STP_APIImplementation');
        System.debug('integRec: ' + integRec);
        System.debug('caseRecord: ' + caseRecord);

        Datetime fromDate =  caseRecord.ABFL_Case_Detail__r.From_Date__c != null ? DateTime.newInstance(caseRecord.ABFL_Case_Detail__r.From_Date__c.year(), caseRecord.ABFL_Case_Detail__r.From_Date__c.month(), caseRecord.ABFL_Case_Detail__r.From_Date__c.day()) : null;
        Datetime toDate = caseRecord.ABFL_Case_Detail__r.To_Date__c != null ? DateTime.newInstance(caseRecord.ABFL_Case_Detail__r.To_Date__c.year(), caseRecord.ABFL_Case_Detail__r.To_Date__c.month(), caseRecord.ABFL_Case_Detail__r.To_Date__c.day()) : null;

        switch  on integRec.STP_API_Identifier__c {
            when 'GetDemandAdvice_Corp' {
                Map<String, Object> filter = new Map<String, Object>{ 'AGREEMENTNO' => caseRecord.LAN__c, 'NEXT_DUE_DATE' => new Map<String, Object>{ 'lte' => Datetime.now().format('dd-MMM-yyyy') } };
                return performCallout(integRec, caseRecord, filter, allCaseInts);
            }
            when 'GetInterestResetLetter_Corp' {
                Map<String, Object> filter = new Map<String, Object>{ 'AGREEMENTNO' => caseRecord.LAN__c };
                return performCallout(integRec, caseRecord, filter, allCaseInts);
            }
            when 'GetRepaymentSchedule_Corp'{
                Map<String, Object> filter = new Map<String, Object>{ 'AGREEMENTNO' => caseRecord.LAN__c, 'DUEDATE' => new Map<String, Object>{ 'lte' => System.now().format('dd-MMM-yyyy') } };
                return performCallout(integRec, caseRecord, filter, allCaseInts);
            }
            when 'GetWelcomeLetter_Corp'{
                Map<String, Object> filter = new Map<String, Object>{ 'AGREEMENTNO' => caseRecord.LAN__c };
                return performCallout(integRec, caseRecord, filter, allCaseInts);
            }
            when 'InterestDebitNote_Corp'{
                Map<String, Object> filter = new Map<String, Object>{ 'AGREEMENTNO' => caseRecord.LAN__c, 'CBD' => new Map<String, Object>{ 'gte' => fromDate.format('dd-MMM-yyyy'), 'lte' => toDate.format('dd-MMM-yyyy') } };
                return performCallout(integRec, caseRecord, filter, allCaseInts);
            }
            when 'SOA_Corp'{
                Map<String, Object> filter = new Map<String, Object>{ 'AGREEMENTNO' => caseRecord.LAN__c, 'CBD' => new Map<String, Object>{ 'fromDate' => fromDate.format('dd-MMM-yyyy'), 'toDate' => toDate.format('dd-MMM-yyyy') }, 'TRANSACTIONID' => Long.valueOf(System.now().format('ddMMyyyyhhmmss'))};
                return performCallout(integRec, caseRecord, filter, allCaseInts);
            } 
        }
        return null;
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
     public static Case_Integration_Outbound__e performCallout(ASF_Integration__c integRec, Case caseRecord, Map<String, Object> filter, List<ASF_Case_Integration__c> allCaseInts){
        System.debug('In performCallout:' + caseRecord.ID);

        //List<ASF_Case_Integration__c> caseIntg = ABFL_SOQL_Integration.getCaseIntegrationInfo(caseRecord.Id, '');
        List<ASF_Case_Integration__c> caseIntg = new List<ASF_Case_Integration__c>();
        if(!allCaseInts.isEmpty()){
            for(ASF_Case_Integration__c caseInt : allCaseInts){
                if(caseInt.Status__c == ABFL_Constants.PENDING && caseInt.Type__c == ''){
                    caseIntg.add(caseInt);
                }
            }
        }
        ABFL_STP_Wrapper wrapper = new ABFL_STP_Wrapper(filter, caseRecord);

        //Database.SaveResult publishResult = EventBus.publish(
        return new Case_Integration_Outbound__e(
                Business_Unit__c = caseRecord.Business_Unit__c, 
                Case_Integration_ID__c = caseIntg[0]?.Name, 
                Integration_Name__c = integRec.STP_API_Identifier__c,  // STP_API_Identifier__c is the actual name of API to invoke
                Request_Payload__c = JSON.serialize(wrapper)
        //)
        );
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