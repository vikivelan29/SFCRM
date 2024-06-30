/**
 * Test class: ASF_CaseStageSLA3TimeBasedActionTest
 */
public without sharing class ASF_CaseStageSLA3TimeBasedAction {
    @InvocableMethod(label='Handle Stage SLA 3 Breach')
    public static void handleSLA3Broke(List<String> scope){

        DateTime currentTime = System.now();
        Map<Id,ASF_Case_SLA_History__c> caseIdSLAHistoryMap = new Map<Id,ASF_Case_SLA_History__c>();
        
        for(ASF_Case_SLA_History__c slaHistory : [SELECT Id,Current_Owner__c,is_Running_Record__c,Stage_End_Date__c,Stage_Start_Date__c,BusinessHoursId__c,Case__c,Case__r.Stage_SLA_1__c,Case__r.Stage_SLA_2__c,Case__r.Stage_SLA_3__c,Stage__c,Overdue__c,Status__c,Stage_Violation_Start_Date__c,Current_Owner_Id__c,Level__c,SLA_2_Email_Sent__c,SLA_3_Email_sent__c,Case__r.SLA_Target_1__c,Case__r.SLA_Target_2__c,Case__r.SLA_Target_3__c,Case__r.OwnerId,Breached_User_Level2__c,Breached_User_Level3__c FROM  ASF_Case_SLA_History__c WHERE Case__c IN: scope AND Stage_End_Date__c = null AND is_Running_Record__c = true FOR UPDATE]){
            Boolean isUpdated = false;
            if(slaHistory.Stage_Violation_Start_Date__c == null ){
                slaHistory.Stage_Violation_Start_Date__c = slaHistory.Case__r.Stage_SLA_1__c;
                slaHistory.Status__c = 'Violated';
                isUpdated = true;
            }

            if(slaHistory.Stage_Violation_Start_Date__c != null && slaHistory.Case__r.Stage_SLA_3__c !=null && slaHistory.Case__r.Stage_SLA_3__c < currentTime){
                slaHistory.Level__c = '3';
                slaHistory.Breached_User_Level3__c = slaHistory.Current_Owner__c;
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
    
    /*
    OLD method which updates the SLA history as well as sends the email to managers.
    public static void sendEmailSLA3Broke(List<String> scope){

        DateTime currentTime = System.now();
        Map<String,Id> emailUserIdMap = new Map<String,Id>();
        list<String> caseEmailList = new list<String>();
        Map<Id,ASF_Case_SLA_History__c> caseIdSLAHistoryMap = new Map<Id,ASF_Case_SLA_History__c>();
        list<Case> casesList = new list<Case>();
        Map<Id,Case> caseMap = new  Map<Id,Case>();
        Map<String,String> caseIdVsSLALevel = new Map<String,String>();
        Map<String,Boolean> caseInBusinessHour = new Map<String,Boolean>();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
       
        for(Case caseRec : [SELECT Id,CaseNumber,SLA_Target_1__c,SLA_Target_2__c,SLA_Target_3__c,Stage_SLA_2__c, Stage_SLA_3__c,OwnerId , Is_Approval_Stage__c FROM Case WHERE Id IN: scope]){
            casesList.add(caseRec);
            if(caseRec.SLA_Target_3__c!=null){
                caseEmailList.add(caseRec.SLA_Target_3__c);
            }    
        }

        if(!caseEmailList.isEmpty()){
            for(user u: [SELECT Id,name,Email FROM User WHERE IsActive = true AND Email IN :caseEmailList]){
                emailUserIdMap.put(u.Email,u.Id);
            }
        }

        for(ASF_Case_SLA_History__c slaHistory : [SELECT Id,Current_Owner__c,is_Running_Record__c,Stage_End_Date__c,Stage_Start_Date__c,BusinessHoursId__c,Case__c,Case__r.Stage_SLA_1__c,Case__r.Stage_SLA_2__c,Case__r.Stage_SLA_3__c,Stage__c,Overdue__c,Status__c,Stage_Violation_Start_Date__c,Current_Owner_Id__c,Level__c,SLA_2_Email_Sent__c,SLA_3_Email_sent__c,Case__r.SLA_Target_1__c,Case__r.SLA_Target_2__c,Case__r.SLA_Target_3__c,Case__r.OwnerId,Breached_User_Level2__c,Breached_User_Level3__c FROM  ASF_Case_SLA_History__c WHERE Case__c IN: casesList AND Stage_End_Date__c = null AND is_Running_Record__c = true FOR UPDATE]){
            Boolean isUpdated = false;
            if(slaHistory.Stage_Violation_Start_Date__c == null ){
                slaHistory.Stage_Violation_Start_Date__c = slaHistory.Case__r.Stage_SLA_1__c;
                slaHistory.Status__c = 'Violated';
                isUpdated = true;
            }

            if(slaHistory.Stage_Violation_Start_Date__c != null && slaHistory.Case__r.Stage_SLA_3__c !=null && slaHistory.Case__r.Stage_SLA_3__c < currentTime){
                if(slaHistory.SLA_3_Email_Sent__c != slaHistory.Case__r.SLA_Target_3__c){
                    slaHistory.Level__c = '3';
                    slaHistory.Breached_User_Level3__c = slaHistory.Current_Owner__c;
                    isUpdated = true;
                }
            }

            if(slaHistory.BusinessHoursId__c != null){
                caseInBusinessHour.put(slaHistory.Case__c, BusinessHours.isWithin(slaHistory.BusinessHoursId__c, system.now()));
            }
            if(isUpdated){
                caseIdSLAHistoryMap.put(slaHistory.Case__c ,slaHistory);
            }
        }

        for(Case caseObj : casesList){
            if(caseInBusinessHour.containsKey(caseObj.Id) && caseInBusinessHour.get(caseObj.Id)){
                if(caseIdSLAHistoryMap.containsKey(caseObj.Id) && caseIdSLAHistoryMap.get(caseObj.Id).Level__c == '3'){
                    caseMap.put(caseObj.Id, caseObj);
                    caseIdVsSLALevel.put(caseObj.Id,'Case Escalation level 3');
                }
            }
        }

        EmailTemplate emailTemp = [SELECT id, Subject, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName = :Label.ASF_TAT_3_Breach_Email_Template].get(0);
        Id orgWideAdressId = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName=:System.Label.ASF_default_no_reply_email_address LIMIT 1].get(0).Id;

        for(String caseId : caseIdVsSLALevel.keySet()){

            String slaLevel = caseIdVsSLALevel.get(caseId);
            Case caseObj = caseMap.get(caseId);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(emailTemp.Id);
            mail.setOrgWideEmailAddressId(orgWideAdressId);
            mail.saveAsActivity = false;
            
            if(slaLevel == 'Case Escalation level 3'){
                if(caseObj.SLA_Target_3__c != null && emailUserIdMap.containsKey(caseObj.SLA_Target_3__c)){
                    mail.setTargetObjectId(emailUserIdMap.get(caseObj.SLA_Target_3__c));
                    caseIdSLAHistoryMap.get(caseId).SLA_3_Email_Sent__c = caseObj.SLA_Target_3__c;
                }
                mail.setSubject('TAT Level 3 Breach  for case '+ caseObj.CaseNumber);
                Messaging.SingleEmailMessage dummyEmailForHtml = Messaging.renderStoredEmailTemplate(emailTemp.Id, emailUserIdMap.get(caseObj.SLA_Target_3__c), caseObj.Id,Messaging.AttachmentRetrievalOption.NONE);
                mail.setHtmlBody(dummyEmailForHtml.getHtmlBody());
            }

            mail.setTreatBodiesAsTemplate(true);
            mail.setUseSignature(false);
            if( mail.TargetObjectId != null || mail.toAddresses!=null){
                emailList.add(mail);
            }
    
        }

        if(!caseIdSLAHistoryMap.isEmpty()){
            try{
                UPDATE caseIdSLAHistoryMap.values();
            } catch(DmlException dmle){
                
            }
            
        }
        if(!emailList.isEmpty()){
            Messaging.sendEmailResult[] sendEmailResults  = Messaging.sendEmail(emailList);
            for(Messaging.SendEmailResult sendEmailResult: sendEmailResults){
                for (Messaging.Sendemailerror sendEmailError : sendEmailResult.getErrors()){
                    //TBD throw error
                }
            }    

        }
    }
    */
}