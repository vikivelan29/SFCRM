/**
 * @description       : 
 * @author            : Salesforce
 * @group             : 
**/
public with sharing class ASF_ClosedMilestoneTimeController {
    
    @AuraEnabled
    public static Map<String, TimerWrapperClass> getDataOnLoad(String caseId){
        try {
            Map<String, TimerWrapperClass> wrapperMap = new Map<String, TimerWrapperClass>();
            wrapperMap.put('overall', new TimerWrapperClass() );
            wrapperMap.put('stage', new TimerWrapperClass() );
            TimerWrapperClass overallwrpcls = wrapperMap.get('overall');
            TimerWrapperClass stagewrpcls = wrapperMap.get('stage');
            List<User> user = new List<User>();
            Case caseObj =  new Case();
            caseObj = [SELECT Id, Stage__c,Overall_Case_Closure_SLA__c, CreatedDate, Owner.Name, BusinessHoursId,
                        Stage_SLA_1__c, Stage_SLA_2__c, Stage_SLA_3__c,LastModifiedDate
                        FROM  Case
                        WHERE Id =:caseId AND isClosed = False
                        LIMIT 1];
            if(!ASF_Constants.CASECLOSEREJECTEDSTATUSES.contains(caseObj.Stage__c)){
                
                if(caseObj.Overall_Case_Closure_SLA__c != null && (system.now() < caseObj.Overall_Case_Closure_SLA__c)){
                     overallwrpcls.leftTotalSec = BusinessHours.diff(caseObj.BusinessHoursId,system.now(),caseObj.Overall_Case_Closure_SLA__c);
                }else if(caseObj.Overall_Case_Closure_SLA__c != null && (system.now() > caseObj.Overall_Case_Closure_SLA__c)){
                     overallwrpcls.overdueTotalSec = system.now().getTime() - caseObj.Overall_Case_Closure_SLA__c.getTime();
                }
                if(caseObj.Stage_SLA_1__c != null && (system.now() < caseObj.Stage_SLA_1__c)){
                    stagewrpcls.leftTotalSec = BusinessHours.diff(caseObj.BusinessHoursId, system.now(), caseObj.Stage_SLA_1__c);
                }else if(caseObj.Stage_SLA_1__c != null && (system.now() > caseObj.Stage_SLA_1__c)){
                    stagewrpcls.overdueTotalSec = BusinessHours.diff(caseObj.BusinessHoursId, caseObj.Stage_SLA_1__c,system.now());
                }
                stagewrpcls.businessHourWorking = BusinessHours.isWithin(caseObj.BusinessHoursId, system.now());
                overallwrpcls.businessHourWorking = BusinessHours.isWithin(caseObj.BusinessHoursId, system.now());
                overallwrpcls.caseObj = caseObj;
                stagewrpcls.caseObj = caseObj;
                wrapperMap.put('overall', overallwrpcls );
                wrapperMap.put('stage', stagewrpcls );
            }
            return wrapperMap;

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