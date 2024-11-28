/**
* @description       : 
* @author            : Salesforce
* @group             : 
**/
public with sharing class ASF_StageBasedMilestoneTimerController {
    
    @AuraEnabled(cacheable = true)
    public static TimerWrapperClass getDataOnLoad(String caseId){
        TimerWrapperClass wrpcls = new TimerWrapperClass();
        try {
            
            wrpcls.businessHourWorking = false;
            List<User> user = new List<User>();
            if(caseId!=null){
                Case caseObj =  new Case();
                
                caseObj = [SELECT Id, Stage__c, OwnerId, Owner.Name, Stage_SLA_1__c, Stage_SLA_2__c, Stage_SLA_3__c, BusinessHoursId, LastModifiedDate
                           FROM  Case
                           WHERE Id =:caseId AND isClosed = False
                           LIMIT 1];
                
                if(caseObj.Stage_SLA_1__c != null && (system.now() < caseObj.Stage_SLA_1__c)){
                    wrpcls.leftTotalSec = BusinessHours.diff(caseObj.BusinessHoursId, system.now(), caseObj.Stage_SLA_1__c);
                }else if(caseObj.Stage_SLA_1__c != null && (system.now() > caseObj.Stage_SLA_1__c)){
                    wrpcls.overdueTotalSec = BusinessHours.diff(caseObj.BusinessHoursId, caseObj.Stage_SLA_1__c,system.now());
                }
                wrpcls.businessHourWorking = BusinessHours.isWithin(caseObj.BusinessHoursId, system.now());
                wrpcls.caseObj = caseObj;
                
            }
            
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return wrpcls;
    }
    
    
    
    public class TimerWrapperClass{
        @auraEnabled
        public Case caseObj                                             {get;set;}
        @auraEnabled 
        public Long overdueTotalSec                                     {get;set;}
        @auraEnabled 
        public Long leftTotalSec                                        {get;set;}
        @auraEnabled 
        public Long todaysMilisec                                       {get;set;}
        @auraEnabled 
        public Boolean businessHourWorking                                      {get;set;}
    }
}