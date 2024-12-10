/**
 * @description       : PR1030924-219
 * @author            : rkosandal@salesforce.com
 * @group             : 
 * @last modified on  : 11-19-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   10-29-2024   rkosandal@salesforce.com   Initial Version
**/
public without sharing class MCRM_CaseHelper {
    /****************************************************************************************************************
    * @Function - calculateBillableTimeOnCaseClose
    * @param newMap - map of cases from trigger.newMap.
    * @param oldMap -  map of cases from trigger.oldMap.
    * @description - calculate Billable Time in days hrs mins secs format and store it in Wellness Case Details
    */
    public static void calculateBillableTimeOnCaseClose(Map<Id, Case> newMap, Map<Id, Case> oldMap){
        List<WellnessCaseDetail__c> details = new List<WellnessCaseDetail__c>();
        Map<Id, Case> caseFinalDMLMap = ASF_CaseTriggerModularHelper.getCaseFinalDMLMap();
        for(Case c : newMap.values()){
            if((oldMap.get(c.Id).Stage__c != c.Stage__c && ASF_Constants.CASECLOSEREJECTEDSTATUSES.contains(c.Stage__c)) ||
            (caseFinalDMLMap != null && caseFinalDMLMap.containsKey(c.Id) &&  oldMap.get(c.Id).Stage__c != caseFinalDMLMap.get(c.Id)?.Stage__c
             && ASF_Constants.CASECLOSEREJECTEDSTATUSES.contains(caseFinalDMLMap.get(c.Id)?.Stage__c))){
                
                WellnessCaseDetail__c detail = new WellnessCaseDetail__c(Id = c.WellnessCaseDetail__c);
                Long milliseconds = (BusinessHours.diff(c.BusinessHoursId, c.CreatedDate, System.now()));
                detail.BillableTimeActual__c = milliseconds;
                long seconds = milliseconds / 1000;
                long minutes = seconds / 60;
                long hours = minutes / 60;
                long days = hours / 24;
                if(days < 1){
                    detail.BillableTimeText__c = ( Math.mod(hours, 24) + 'hr ' +  Math.mod(minutes, 60)  + 'min ' + Math.mod(seconds, 60)  )+'s';   
                }else{
                    detail.BillableTimeText__c = (days + 'days ' + Math.mod(hours, 24) + 'hr ' +  Math.mod(minutes, 60)  + 'min ' + Math.mod(seconds, 60) + 's '  ); 
                }
                details.add(detail);
            }
        }
        update details;
    }
}