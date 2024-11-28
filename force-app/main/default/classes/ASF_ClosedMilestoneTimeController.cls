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
            wrapperMap.put('sla1', new TimerWrapperClass() );
            wrapperMap.put('sla2', new TimerWrapperClass() );
            wrapperMap.put('sla3', new TimerWrapperClass() );
            TimerWrapperClass overallwrpcls = wrapperMap.get('overall');
            TimerWrapperClass sla1wrpcls = wrapperMap.get('sla1');
            List<User> user = new List<User>();
            Case caseObj =  new Case();
            caseObj = [SELECT Id, Stage__c,Overall_Case_Closure_SLA__c, CreatedDate, Owner.Name, BusinessHoursId,
                        Stage_SLA_1__c, Stage_SLA_2__c, Stage_SLA_3__c,LastModifiedDate,ClosedDate
                        FROM  Case
                        WHERE Id =:caseId
                        LIMIT 1];
            //if(!ASF_Constants.CASECLOSEREJECTEDSTATUSES.contains(caseObj.Stage__c)){
                
                if(caseObj.Overall_Case_Closure_SLA__c != null && (system.now() < caseObj.Overall_Case_Closure_SLA__c)){
                     overallwrpcls.leftTotalSec = BusinessHours.diff(caseObj.BusinessHoursId,system.now(),caseObj.Overall_Case_Closure_SLA__c);
                }else if(caseObj.Overall_Case_Closure_SLA__c != null && (system.now() > caseObj.Overall_Case_Closure_SLA__c)){
                     overallwrpcls.overdueTotalSec = system.now().getTime() - caseObj.Overall_Case_Closure_SLA__c.getTime();
                }
                if(caseObj.Stage_SLA_1__c != null && (system.now() < caseObj.Stage_SLA_1__c)){
                    sla1wrpcls.leftTotalSec = BusinessHours.diff(caseObj.BusinessHoursId, system.now(), caseObj.Stage_SLA_1__c);
                }else if(caseObj.Stage_SLA_1__c != null && (system.now() > caseObj.Stage_SLA_1__c)){
                    sla1wrpcls.overdueTotalSec = BusinessHours.diff(caseObj.BusinessHoursId, caseObj.Stage_SLA_1__c,system.now());
                }
                sla1wrpcls.businessHourWorking = BusinessHours.isWithin(caseObj.BusinessHoursId, system.now());
                overallwrpcls.businessHourWorking = BusinessHours.isWithin(caseObj.BusinessHoursId, system.now());
                overallwrpcls.caseObj = caseObj;
                sla1wrpcls.caseObj = caseObj;
                overallwrpcls.isClosed = ASF_Constants.CASECLOSEREJECTEDSTATUSES.contains(caseObj.Stage__c);
                
                //Overall
                if(!overallwrpcls.isClosed && caseObj.Overall_Case_Closure_SLA__c != null){
                    overallwrpcls.isBreached = true;
                    if(system.now() < caseObj.Overall_Case_Closure_SLA__c){
                        overallwrpcls.isBreached = false;
                    }
                }
                if(overallwrpcls.isClosed && caseObj.Overall_Case_Closure_SLA__c != null){
                    overallwrpcls.isBreached = true;
                    if(caseObj.ClosedDate < caseObj.Overall_Case_Closure_SLA__c){
                        overallwrpcls.isBreached = false;
                    }
                }
                overallwrpcls.slaMilliseconds = caseObj.Overall_Case_Closure_SLA__c!=null?caseObj.Overall_Case_Closure_SLA__c.getTime():0;
                wrapperMap.put('overall', overallwrpcls );

                //SLA 1
                sla1wrpcls.isClosed = overallwrpcls.isClosed;
                if(!sla1wrpcls.isClosed && caseObj.Stage_SLA_1__c != null){
                    sla1wrpcls.isBreached = true;
                    if(system.now() < caseObj.Stage_SLA_1__c){
                        sla1wrpcls.isBreached = false;
                    }
                }
                if(sla1wrpcls.isClosed && caseObj.Stage_SLA_1__c != null){
                    sla1wrpcls.isBreached = true;
                    if(caseObj.ClosedDate < caseObj.Stage_SLA_1__c){
                        sla1wrpcls.isBreached = false;
                    }
                }
                sla1wrpcls.slaMilliseconds = caseObj.Stage_SLA_1__c!=null?caseObj.Stage_SLA_1__c.getTime():0;
                wrapperMap.put('sla1', sla1wrpcls );

                //SLA 2 and SLA 3
                TimerWrapperClass sla2wrpcls = wrapperMap.get('sla2');
                sla2wrpcls.isClosed = overallwrpcls.isClosed;
                if(!sla2wrpcls.isClosed && caseObj.Stage_SLA_2__c != null){
                    sla2wrpcls.isBreached = true;
                    if(system.now() < caseObj.Stage_SLA_2__c){
                        sla2wrpcls.isBreached = false;
                    }
                }
                if(sla2wrpcls.isClosed && caseObj.Stage_SLA_2__c != null){
                    sla2wrpcls.isBreached = true;
                    if(caseObj.ClosedDate < caseObj.Stage_SLA_2__c){
                        sla2wrpcls.isBreached = false;
                    }
                }
                sla2wrpcls.slaMilliseconds = caseObj.Stage_SLA_2__c!=null?caseObj.Stage_SLA_2__c.getTime():0;
                wrapperMap.put('sla2', sla2wrpcls );

                TimerWrapperClass sla3wrpcls = wrapperMap.get('sla3');
                sla3wrpcls.isClosed = overallwrpcls.isClosed;
                if(!sla3wrpcls.isClosed && caseObj.Stage_SLA_3__c != null){
                    sla3wrpcls.isBreached = true;
                    if(system.now() < caseObj.Stage_SLA_3__c){
                        sla3wrpcls.isBreached = false;
                    }
                }
                if(sla3wrpcls.isClosed && caseObj.Stage_SLA_3__c != null){
                    sla3wrpcls.isBreached = true;
                    if(caseObj.ClosedDate < caseObj.Stage_SLA_3__c){
                        sla3wrpcls.isBreached = false;
                    }
                }
                sla3wrpcls.slaMilliseconds = caseObj.Stage_SLA_3__c!=null?caseObj.Stage_SLA_3__c.getTime():0;
                wrapperMap.put('sla3', sla3wrpcls );
            //}
            return wrapperMap;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class TimerWrapperClass{
        @auraEnabled
        public Case caseObj {get;set;}
        @auraEnabled 
        public Long overdueTotalSec {get;set;}
        @auraEnabled 
        public Long leftTotalSec {get;set;}
        @auraEnabled 
        public Boolean businessHourWorking {get;set;}
        @auraEnabled 
        public Boolean isClosed {get;set;}
        @auraEnabled 
        public Boolean isBreached {get;set;}
        @AuraEnabled
        public Long slaMilliseconds{get;set;}
    
    }
}