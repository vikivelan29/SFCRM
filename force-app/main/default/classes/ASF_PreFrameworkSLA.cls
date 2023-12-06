public with sharing class ASF_PreFrameworkSLA {

    @AuraEnabled
    public static TimerWrapperClass getDataOnLoad(String caseId){
        TimerWrapperClass wrpcls = new TimerWrapperClass();
        try {
            
            wrpcls.businessHourWorking = false;
            List<User> user = new List<User>();
            if(caseId!=null){
                Case caseObj =  new Case();
                
                caseObj = [SELECT Id, Pre_framework_SLA__c ,CreatedDate,Stage__c, OwnerId, Owner.Name, Stage_SLA_1__c, Stage_SLA_2__c, Stage_SLA_3__c, BusinessHoursId, LastModifiedDate
                            FROM  Case
                            WHERE Id =:caseId AND isClosed = False AND Stage__c = 'New'
                            LIMIT 1];
                
                DateTime currentTime = caseObj.CreatedDate;
                Integer hours = Integer.valueOf(system.label.ASF_Preframework_sla_timer);
                DateTime SLATime = caseObj.Pre_framework_SLA__c; 
				
                if(SLATime != null && (system.now() < SLATime)){
                    wrpcls.leftTotalSec = BusinessHours.diff(caseObj.BusinessHoursId, system.now(), SLATime);
                }else if(SLATime != null && (system.now() > SLATime)){
                    wrpcls.overdueTotalSec = BusinessHours.diff(caseObj.BusinessHoursId, SLATime,system.now());
                }
                
                wrpcls.businessHourWorking = BusinessHours.isWithin(caseObj.BusinessHoursId, system.now());
                wrpcls.caseObj = caseObj;
                
            }
           

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return wrpcls;
    }
    
        
    @InvocableMethod(label='Send sla Email' description='Send email to case owners manager' category='Case')
    public static void sendEmailSLA(List<id> caseIdList){
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();        
		
        EmailTemplate emailTemp = [Select id, Subject, Body,HtmlValue From EmailTemplate Where DeveloperName = 'Case_Owner_s_Manager_Email_when_the_SLA_is_breached'].get(0);
		Id orgWideAdressId = [select Id from OrgWideEmailAddress where DisplayName=:System.Label.ASF_default_no_reply_email_address limit 1].Id;        

        Case caseObj = [SELECT Id, CaseNumber, Status, OwnerId, Owner.Name,BusinessHoursId, LastModifiedDate,Nature__c,Type_Text__c, CreatedDate,
            			CreatedBy.Name
            			FROM  Case WHERE   Id =:caseIdList[0]];
        
            String toEmailAddress ='';
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            List<String> toAddress =new List<String>();
            mail.setTemplateId(emailTemp.Id);
            mail.setOrgWideEmailAddressId(orgWideAdressId);
            
            mail.saveAsActivity = false;
            String ownerId = caseObj.OwnerId;
            if(ownerId.startsWith('005')){
                User ud= [SELECT Id, ManagerId FROM User WHERE Id = :caseObj.OwnerId];
                if(ud.ManagerId == null)
                    return;
                mail.setTargetObjectId(ud.ManagerId);
            }else if(ownerId.startsWith('00G')){
                Group g = [select id,email from Group where id =: ownerId];
                if(String.isBlank(g.email))
                    return;
                mail.setToAddresses(new String[]{g.email});
            }
            
            mail.setSubject('TAT Level 1 Breach for case '+ caseObj.CaseNumber);
            Messaging.SingleEmailMessage dummyEmailForHtml = Messaging.renderStoredEmailTemplate(emailTemp.Id, 
                                                                                                 null, 
                                                                                                 caseObj.Id,Messaging.AttachmentRetrievalOption.NONE);
            mail.setHtmlBody(dummyEmailForHtml.getHtmlBody());
            
            
            mail.setTreatBodiesAsTemplate(true);
            mail.setUseSignature(false);
            
            if( mail.TargetObjectId != null || mail.toAddresses!=null){
                emailList.add(mail);
            }
       
        if(!emailList.isEmpty()){
            Messaging.sendEmailResult[] sendEmailResults  = Messaging.SendEmail(emailList);
            for(Messaging.SendEmailResult sendEmailResult: sendEmailResults){
                for (Messaging.Sendemailerror sendEmailError : sendEmailResult.getErrors()){
                }
            }    
            
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
        public Long todaysMilisec                                       {get;set;}
        @auraEnabled 
        public Boolean businessHourWorking                                      {get;set;}
    }
}