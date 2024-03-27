/*********************************************************
*Class        :  ABHFL_Auto_Closure
*Author       :  Anirudh Raturi
*Created Date :  18/11/2024
*Last Modified:  18/11/2024
*Description  :  Class for Auto Closure of Cases
*********************************************************/

global with sharing class ABHFL_Auto_Closure implements Database.Batchable<sObject>, Schedulable {

    public Map<String, ABHFL_Auto_Closure__mdt> cccExtIdToAutoClosureRecMap = new Map<String, ABHFL_Auto_Closure__mdt>();

    public ABHFL_Auto_Closure() {
        mapOfCccExtenalIdToAutoClosureRec();
    }

    public void mapOfCccExtenalIdToAutoClosureRec(){
        
        List<ABHFL_Auto_Closure__mdt> autoClosRecList = ABHFL_Auto_Closure__mdt.getAll().values();

        for(ABHFL_Auto_Closure__mdt autoClosRec : autoClosRecList) {
            cccExtIdToAutoClosureRecMap.put(autoClosRec.CCC_External_Id__c, autoClosRec);
        }
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
         
        Set<String> cccExternalIdList = cccExtIdToAutoClosureRecMap.keyset();

        String query = 'SELECT Id, AccountId, ContactId, ABHFL_Case_Detail__r.Realization_status__c, ABHFL_Case_Detail__r.Payment_Link_Trigger_Time__c, Stage__c,' +
                        ' CCC_External_Id__c, No_Auto_Communication__c FROM Case where CCC_External_Id__c in: cccExternalIdList';
        return Database.getQueryLocator(query);
    }
     
    global void execute(Database.BatchableContext BC, List<Case> caseList) {
        
        autoClosureOfCase(caseList);       
    }
     
    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations like sending email
    }

    public void autoClosureOfCase(List<Case> caseLst) {

        List<Case> updateCaseList = new List<Case>();
        Map<Id, String> caseIdToEmailTemplateMap = new Map<Id, String>();
        Map<Id, String> caseIdToSmsMetadataMap = new Map<Id, String>();
        Map<Id, Boolean> transferredMap = new Map<Id, Boolean>();
        List<String> stagetoInclude = new List<String>{'Resolved', 'resolved', 'Unresolved', 'unresolved', 'Duplicate', 'duplicate', 'Closed', 'closed'};

        for(Case caserec : caseLst) {
            String caseRecId = caserec.Id;
            String caseStage = caserec.Stage__c;
            String stageToBePopulated = cccExtIdToAutoClosureRecMap.get(caserec.CCC_External_Id__c).Stage__c;
            String realizationStatus  = caserec.ABHFL_Case_Detail__r.Realization_status__c;
            Decimal closureOfDuration = cccExtIdToAutoClosureRecMap.get(caserec.CCC_External_Id__c).Duration_Of_Closure__c;
            DateTime paymentLinkTriggerTIme = caserec.ABHFL_Case_Detail__r.Payment_Link_Trigger_Time__c;
            Map<String, Decimal> timeFormatsToTimeVal  = differenceBetweenTwoDateTime(DateTime.Now(), paymentLinkTriggerTIme);
            Decimal numberOfDays = timeFormatsToTimeVal.get('days');

            if(numberOfDays > closureOfDuration && String.isBlank(realizationStatus) && !stagetoInclude.contains(caseStage)) {
                caserec.Stage__c = stageToBePopulated;
                caserec.Rejection_Reason__c = 'Closed as Exception';
                updateCaseList.add(caserec); 

                String emailTemplateName = cccExtIdToAutoClosureRecMap.get(caserec.CCC_External_Id__c).Email_Template__c;
                String smsTemplateName = cccExtIdToAutoClosureRecMap.get(caserec.CCC_External_Id__c).SMS_Template__c;

                caseIdToEmailTemplateMap.put(caseRecId, emailTemplateName);
                caseIdToSmsMetadataMap.put(caseRecId, smsTemplateName);
            }
            transferredMap.put(caseRecId, false);
        }
        if(updateCaseList.size() > 0) {
            update updateCaseList;
            List<Database.SaveResult> platformEventResultList = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseLst, caseIdToEmailTemplateMap,
                                                                                                                            caseIdToSmsMetadataMap, transferredMap); 
        }
    }

    public Map<String, Decimal> differenceBetweenTwoDateTime(DateTime dt2,DateTime dt1) {

        Map<String, Decimal> timFormatsToTimeVal = new Map<String, Decimal>();

        if(dt2 != null && dt1 != null) {
            Decimal milliseconds = Decimal.valueOf(dt2.getTime() - dt1.getTime());
            Decimal seconds = milliseconds / 1000;
            Decimal minutes = seconds / 60;
            Decimal hours = minutes / 60;
            Decimal days = hours / 24;
    
            timFormatsToTimeVal = new Map<String, Decimal>{'milliseconds' => milliseconds, 'seconds' => seconds, 'minutes' => minutes, 'hours' => hours, 'days' => days};
        }

        return timFormatsToTimeVal;
    }

    public void execute(SchedulableContext SC) {
        // specify the task or method to be executed
    }
}