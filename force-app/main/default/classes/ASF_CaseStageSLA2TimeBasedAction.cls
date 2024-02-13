public class ASF_CaseStageSLA2TimeBasedAction {
    @InvocableMethod(label='Send Stage 1 SLA 2 Broken Email Reminders')
    public static void sendEmailSLA2Broke(List<String> scope){

        List<Case> oldCaseList = [SELECT Id,
                                            CaseNumber,
                                            SLA_Target_1__c,
                                            SLA_Target_2__c,
                                            SLA_Target_3__c,
                                            Stage_SLA_2__c, Stage_SLA_3__c,
                                            OwnerId , Is_Approval_Stage__c
                                    FROM Case 
                                    WHERE Id IN: scope];

        DateTime currentTime = System.now();
       
        map<string,Id> emailUserIdMap = new map<string,Id>();
        list<string> caseEmailList = new list<string>();
       
        map<Id,ASF_Case_SLA_History__c> caseIdSLAHistoryMap = new map<Id,ASF_Case_SLA_History__c>();
        list<Case> casesList = new list<Case>();
       
        for(Case c : oldCaseList){
            casesList.add(c);
            if(c.SLA_Target_1__c!=null){
                caseEmailList.add(c.SLA_Target_1__c);
            }
            if(c.SLA_Target_2__c!=null){
                caseEmailList.add(c.SLA_Target_2__c);
            }
            if(c.SLA_Target_3__c!=null){
                caseEmailList.add(c.SLA_Target_3__c);
            }     
        }

        if(caseEmailList.size() > 0){
            list<user> userList = [SELECT Id, 
                                        name,
                                        Email 
                                    FROM User 
                                    WHERE Email IN :caseEmailList];
            if(userList.size() > 0){
                for(user u: userList){
                    emailUserIdMap.put(u.Email,u.Id);
                }
            }
        }

        Map<Id,Case> caseMap = new  Map<Id,Case>();
        Map<String,String> caseIdVsSLALevel = new Map<String,String>();
        List<ASF_Case_SLA_History__c> slaHistoryList = new List<ASF_Case_SLA_History__c>();
        Map<String,Boolean> caseInBusinessHour = new Map<String,Boolean>();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

        for(ASF_Case_SLA_History__c slaHistory : [SELECT Id, 
                                                    Current_Owner__c, 
                                                    is_Running_Record__c,
                                                    Stage_End_Date__c, 
                                                    Stage_Start_Date__c,
                                                    BusinessHoursId__c, 
                                                    Case__c, 
                                                    Case__r.Stage_SLA_1__c, 
                                                    Case__r.Stage_SLA_2__c, 
                                                    Case__r.Stage_SLA_3__c, 
                                                    Stage__c, 
                                                    Overdue__c, 
                                                    Status__c, 
                                                    Stage_Violation_Start_Date__c, 
                                                    Current_Owner_Id__c, 
                                                    Level__c,
                                                    SLA_2_Email_Sent__c,
                                                    SLA_3_Email_sent__c,
                                                    Case__r.SLA_Target_1__c,
                                                    Case__r.SLA_Target_2__c,
                                                    Case__r.SLA_Target_3__c,
                                                    Case__r.OwnerId,
                                                    Breached_User_Level2__c,
                                                    Breached_User_Level3__c 
                                                FROM  ASF_Case_SLA_History__c 
                                                WHERE Case__c IN: casesList 
                                                AND Stage_End_Date__c = null 
                                                AND is_Running_Record__c = true ]){
            if(slaHistory.Stage_Violation_Start_Date__c == null ){
                slaHistory.Stage_Violation_Start_Date__c = slaHistory.Case__r.Stage_SLA_1__c;
                slaHistory.Status__c = 'Violated';
            }


            // if(slaHistory.Stage_Violation_Start_Date__c != null && slaHistory.Level__c == '2' && slaHistory.Case__r.Stage_SLA_3__c !=null &&(slaHistory.Case__r.Stage_SLA_3__c < currentTime)){
            //     if(slaHistory.Case__r.SLA_Target_3__c != null && slaHistory.SLA_3_Email_Sent__c != slaHistory.Case__r.SLA_Target_3__c){
            //         slaHistory.Level__c = '3';
            //         slaHistory.Breached_User_Level3__c = slaHistory.Current_Owner__c;
            //         slaHistory.SLA_3_Email_Sent__c = slaHistory.Case__r.SLA_Target_3__c;
            //         caseIdSLAHistoryMap.put(slaHistory.Case__c ,slaHistory);
            //     }

            // }
            // else 
            if(slaHistory.Stage_Violation_Start_Date__c != null && slaHistory.Level__c == '1' && slaHistory.Case__r.Stage_SLA_2__c != null && (slaHistory.Case__r.Stage_SLA_2__c < currentTime)){
                if(slaHistory.Case__r.SLA_Target_2__c != null && slaHistory.SLA_2_Email_Sent__c != slaHistory.Case__r.SLA_Target_2__c){
                    slaHistory.Level__c = '2';
                    slaHistory.Breached_User_Level2__c = slaHistory.Current_Owner__c;
                    slaHistory.SLA_2_Email_Sent__c = slaHistory.Case__r.SLA_Target_2__c;
                    caseIdSLAHistoryMap.put(slaHistory.Case__c ,slaHistory);
                }
            }

            if(slaHistory.BusinessHoursId__c != null){
                caseInBusinessHour.put(slaHistory.Case__c, BusinessHours.isWithin(slaHistory.BusinessHoursId__c, system.now()));
            }
            slaHistoryList.add(slaHistory);

        }

        for(Case caseObj : casesList){
            if(caseInBusinessHour.containsKey(caseObj.Id) && caseInBusinessHour.get(caseObj.Id) && caseObj.Is_Approval_Stage__c == false){
                if(caseObj.Stage_SLA_2__c != null && caseObj.Stage_SLA_2__c < currentTime
                && caseIdSLAHistoryMap.containsKey(caseObj.Id) && caseIdSLAHistoryMap.get(caseObj.Id).Level__c == '2'){
                    caseMap.put(caseObj.Id, caseObj);
                    caseIdVsSLALevel.put(caseObj.Id,'Case Escalation level 2');
                }
                // else if(caseObj.Stage_SLA_3__c != null && caseObj.Stage_SLA_3__c < currentTime
                // && caseIdSLAHistoryMap.containsKey(caseObj.Id) && caseIdSLAHistoryMap.get(caseObj.Id).Level__c == '3'){
                //     caseMap.put(caseObj.Id, caseObj);
                //     caseIdVsSLALevel.put(caseObj.Id,'Case Escalation level 3');
                // }
            }
        }

        EmailTemplate emailTemp = [SELECT id, 
                                            Subject, 
                                            Body,
                                            HtmlValue 
                                    FROM EmailTemplate 
                                    WHERE DeveloperName = 'Case_Owner_s_Manager_Email_when_the_SLA_is_breached'].get(0);
        Id orgWideAdressId = [SELECT Id, Address, DisplayName, Purpose, IsAllowAllProfiles, LastModifiedBy.Name FROM OrgWideEmailAddress where DisplayName=:System.Label.ASF_default_no_reply_email_address limit 1].get(0).Id;
        //Id orgWideAdressId = [SELECT Id, Address, DisplayName, Purpose, IsAllowAllProfiles, LastModifiedBy.Name FROM OrgWideEmailAddress limit 1].Id;

        for(String caseId : caseIdVsSLALevel.keySet()){

            String slaLevel = caseIdVsSLALevel.get(caseId);
            Case caseObj = caseMap.get(caseId);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(emailTemp.Id);
            mail.setOrgWideEmailAddressId(orgWideAdressId);
            mail.saveAsActivity = false;

            if(slaLevel == 'Case Escalation level 2'){
                if(caseObj.SLA_Target_2__c != null && emailUserIdMap.containsKey(caseObj.SLA_Target_2__c)){
                    mail.setTargetObjectId(emailUserIdMap.get(caseObj.SLA_Target_2__c));
                }
                else if(caseObj.SLA_Target_2__c != null && String.isNotBlank(caseObj.SLA_Target_2__c) ){
                    mail.setToAddresses(new list<String>{caseObj.SLA_Target_2__c});
                }
                mail.setSubject('TAT Level 2 Breach for case '+ caseObj.CaseNumber);
                Messaging.SingleEmailMessage dummyEmailForHtml = Messaging.renderStoredEmailTemplate(emailTemp.Id, emailUserIdMap.get(caseObj.SLA_Target_2__c), caseObj.Id,Messaging.AttachmentRetrievalOption.NONE);
                mail.setHtmlBody(dummyEmailForHtml.getHtmlBody());
            }
            // else if(slaLevel == 'Case Escalation level 3'){
            //     if(caseObj.SLA_Target_3__c != null && emailUserIdMap.containsKey(caseObj.SLA_Target_3__c)){
            //         mail.setTargetObjectId(emailUserIdMap.get(caseObj.SLA_Target_3__c));
            //     }
            //     else if(caseObj.SLA_Target_3__c != null && String.isNotBlank( caseObj.SLA_Target_3__c)){
            //         mail.setToAddresses(new list<String>{caseObj.SLA_Target_3__c});
            //     }
            //     mail.setSubject('TAT Level 3 Breach  for case '+ caseObj.CaseNumber);
            //     Messaging.SingleEmailMessage dummyEmailForHtml = Messaging.renderStoredEmailTemplate(emailTemp.Id, emailUserIdMap.get(caseObj.SLA_Target_3__c), caseObj.Id,Messaging.AttachmentRetrievalOption.NONE);
            //     mail.setHtmlBody(dummyEmailForHtml.getHtmlBody());
            // }

            mail.setTreatBodiesAsTemplate(true);
            mail.setUseSignature(false);


            if( mail.TargetObjectId != null || mail.toAddresses!=null){
                emailList.add(mail);
            }
    
        }

        if(!slaHistoryList.isEmpty()){ 
            UPDATE slaHistoryList;
        }
        if(!emailList.isEmpty()){
            Messaging.sendEmailResult[] sendEmailResults  = Messaging.SendEmail(emailList);
            for(Messaging.SendEmailResult sendEmailResult: sendEmailResults){
                for (Messaging.Sendemailerror sendEmailError : sendEmailResult.getErrors()){
                    //TBD throw error
                }
            }    

        }
    }
}