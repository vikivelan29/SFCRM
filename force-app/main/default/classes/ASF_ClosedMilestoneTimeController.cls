/**
 * @description       : 
 * @author            : Salesforce
 * @group             : 
**/
public with sharing class ASF_ClosedMilestoneTimeController {
    
    @AuraEnabled(cacheable = true)
    public static TimerWrapperClass getDataOnLoad(String caseId, String caseStage){
        try {
            TimerWrapperClass wrpcls = new TimerWrapperClass();
            List<User> user = new List<User>();
            if((caseId != null) && (caseStage != 'Closed') && (caseStage != 'Rejected')){
                Case caseObj =  new Case();

                caseObj = [SELECT Id, Stage__c,Overall_Case_Closure_SLA__c, CreatedDate, Owner.Name, BusinessHoursId
                            FROM  Case
                            WHERE Id =:caseId AND isClosed = False
                            LIMIT 1];
                if(caseObj.Overall_Case_Closure_SLA__c != null && (system.now() < caseObj.Overall_Case_Closure_SLA__c)){
                     wrpcls.leftTotalSec = BusinessHours.diff(caseObj.BusinessHoursId,system.now(),caseObj.Overall_Case_Closure_SLA__c);
                }else if(caseObj.Overall_Case_Closure_SLA__c != null && (system.now() > caseObj.Overall_Case_Closure_SLA__c)){
                     wrpcls.overdueTotalSec = system.now().getTime() - caseObj.Overall_Case_Closure_SLA__c.getTime();
                }
               wrpcls.businessHourWorking = BusinessHours.isWithin(caseObj.BusinessHoursId, system.now());
                wrpcls.caseObj = caseObj;
                
            }
            return wrpcls;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class TimerWrapperClass{
        @auraEnabled
        public Case caseObj                                             {get;set;}
        @auraEnabled 
        public Long overdueTotalSec                                     {get;set;}
        @auraEnabled 
        public Long leftTotalSec                                        {get;set;}
        @auraEnabled 
        public Boolean businessHourWorking                              {get;set;}
    
    }
}