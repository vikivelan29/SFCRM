/**
 * Test class: ASF_CaseStageSLA2TimeBasedActionTest
 */
public without sharing class ASF_CaseStageSLA2TimeBasedAction {
    @InvocableMethod(label='Handle Stage SLA 2 Breach')
    public static void handleSLA2Broke(List<String> scope){

        DateTime currentTime = System.now();
        Map<Id,ASF_Case_SLA_History__c> caseIdSLAHistoryMap = new Map<Id,ASF_Case_SLA_History__c>();
       
        for(ASF_Case_SLA_History__c slaHistory : [SELECT Id,Current_Owner__c,is_Running_Record__c,Stage_End_Date__c,Stage_Start_Date__c,BusinessHoursId__c,Case__c,Case__r.Stage_SLA_1__c,Case__r.Stage_SLA_2__c,Case__r.Stage_SLA_3__c,Stage__c,Overdue__c,Status__c,Stage_Violation_Start_Date__c,Current_Owner_Id__c,Level__c,SLA_2_Email_Sent__c,SLA_3_Email_sent__c,Case__r.SLA_Target_1__c,Case__r.SLA_Target_2__c,Case__r.SLA_Target_3__c,Case__r.OwnerId,Breached_User_Level2__c,Breached_User_Level3__c FROM  ASF_Case_SLA_History__c WHERE Case__c IN: scope AND Stage_End_Date__c = null AND is_Running_Record__c = true FOR UPDATE]){
            Boolean isUpdated = false;
            if(slaHistory.Stage_Violation_Start_Date__c == null ){
                slaHistory.Stage_Violation_Start_Date__c = slaHistory.Case__r.Stage_SLA_1__c;
                slaHistory.Status__c = 'Violated';
                isUpdated = true;
            }

            if(slaHistory.Stage_Violation_Start_Date__c != null && slaHistory.Case__r.Stage_SLA_2__c != null && slaHistory.Case__r.Stage_SLA_2__c < currentTime){
                slaHistory.Level__c = '2';
                slaHistory.Breached_User_Level2__c = slaHistory.Current_Owner__c;
                isUpdated = true;
            }
            if(isUpdated){
                caseIdSLAHistoryMap.put(slaHistory.Case__c ,slaHistory);
            }
        }

        if(!caseIdSLAHistoryMap.isEmpty()){ 
            try{
                UPDATE caseIdSLAHistoryMap.values();
            } catch(DmlException dmle){
                
            }
        }
    }
}