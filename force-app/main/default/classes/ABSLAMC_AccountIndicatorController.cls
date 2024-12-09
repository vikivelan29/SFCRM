/*********************************************************
*Class        :  ABSLAMC_AccountIndicatorController
*Author       :  Neeraj Kumar
*Created Date :  24/10/2024
*@description  : This class returns Case data/ NPS data for Account
*********************************************************/
public class ABSLAMC_AccountIndicatorController {
    
    /*********************************************************
*method       :  getCasesForAccount
*description  :  returns map of String,List of Cases
*params       :  accId
*********************************************************/
    @AuraEnabled(Cacheable = true)
    public static Map<String, List<Case>> getCasesForAccount(String accId) {
        
        Map<String, List<Case>> stageToCaseMap = new Map<String, List<Case>>();
        Map<String, ASF_ClosedMilestoneTimeController.TimerWrapperClass> slaBreachMap = new Map<String, ASF_ClosedMilestoneTimeController.TimerWrapperClass>();
        List<Case> caseList = new List<Case>();
        decimal slaBreachRange = 20;
        
        caseList = [SELECT Id,CaseNumber,Stage__c,Nature__c,Escalated_Date_Time__c,SLA_Broken__c,Case_SLA_Threshold_2__c
                    FROM Case 
                    WHERE AccountId = :accId AND Stage__c NOT IN ('Resolved', 'Unresolved')];
        
        for (Case c : caseList) {
            if (!stageToCaseMap.containsKey('Open Cases')) {
                stageToCaseMap.put('Open Cases', new List<Case>());
            }
            stageToCaseMap.get('Open Cases').add(c);
            
            
            if (c.Nature__c == 'Complaint') {
                if (!stageToCaseMap.containsKey('Open Complaints')) {
                    stageToCaseMap.put('Open Complaints', new List<Case>());
                }
                stageToCaseMap.get('Open Complaints').add(c);
            }
            
            if (c.Escalated_Date_Time__c != null) {
                if (!stageToCaseMap.containsKey('Escalated Cases')) {
                    stageToCaseMap.put('Escalated Cases', new List<Case>());
                }
                stageToCaseMap.get('Escalated Cases').add(c);
            }
            
            if (c.SLA_Broken__c == true) {
                if (!stageToCaseMap.containsKey('Open Cases Breached SLA')) {
                    stageToCaseMap.put('Open Cases Breached SLA', new List<Case>());
                }
                stageToCaseMap.get('Open Cases Breached SLA').add(c);
            }
            
            if (c.Case_SLA_Threshold_2__c > DateTime.now()) {
                if (!stageToCaseMap.containsKey('Open Cases Nearing SLA Breach')) {
                    stageToCaseMap.put('Open Cases Nearing SLA Breach', new List<Case>());
                }
                stageToCaseMap.get('Open Cases Nearing SLA Breach').add(c);
                
            }
        }
        
        System.debug('CaseMap: '+stageToCaseMap);
        return stageToCaseMap.isEmpty() ? new Map<String, List<Case>>() : stageToCaseMap;
    }
    
        
    /*********************************************************
*method       :  getLatestNPSData
*description  :  returns map of String,String having nps data
*params       :  accId
*********************************************************/
    @AuraEnabled(Cacheable = true) 
    public static Map<String, String> getLatestNPSData(String accId) {
        Map<String, String> resultMap = new Map<String, String>();
        
        List<Survey_Response__c> surveyResp = [SELECT Id, Primary_Question_NPS__c, Responded_on__c, Journey__c
                                         FROM Survey_Response__c 
                                         WHERE Client_Code__c = :accId 
                                         ORDER BY Responded_on__c DESC LIMIT 1];
        
        if (!surveyResp.isEmpty()) {
            if (surveyResp[0].Responded_on__c != null) {
                resultMap.put('Latest Response', String.valueOf(Date.valueOf(surveyResp[0].Responded_on__c)));
            }
            
            if (surveyResp[0].Primary_Question_NPS__c != null) {
                resultMap.put('Score', String.valueOf(surveyResp[0].Primary_Question_NPS__c));
            }
            
            if (surveyResp[0].Journey__c != null && surveyResp[0].Journey__c != '') {
                resultMap.put('Journey', String.valueOf(surveyResp[0].Journey__c));
            }
        }
        
        return resultMap.isEmpty() ? new Map<String, String>() : resultMap;
    }
    
}