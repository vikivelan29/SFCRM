public without sharing class ASF_CaseStageSLATimeBasedAction {
   
    @InvocableMethod(label='Send Stage 1 SLA Broken Email Reminders')
    public static void sendEmailSLABroke(List<String> casesList) {
        List<String> caseEmailList = new List<String>();   
        List<Case> casesNewList = new List<Case>(); 
        List<ASF_Case_SLA_History__c> slaHistoryList = new List<ASF_Case_SLA_History__c>();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        Map<String,Id> emailUserIdMap = new Map<String,Id>();
        List<String> userManagerGroupIdList = new List<String>();
        Map<String, List<Id>> managerGroupIdToOwners = new Map<String, List<Id>>();
        map<Id,List<String>> caseOwnerToManagerEmails = new map<Id,List<String>>();
        List<Id> managerUserIds = new List<Id>();
        List<GroupMember> groupMembers = new List<GroupMember>();

        for(Case caseRec : [SELECT Id,CaseNumber,SLA_Target_1__c,SLA_Target_2__c,SLA_Target_3__c,OwnerId FROM Case WHERE Id IN: casesList]){
            casesNewList.add(caseRec);
            if(caseRec.SLA_Target_1__c!=null){
                caseEmailList.add(caseRec.SLA_Target_1__c);
            }
            if((caseRec.SLA_Target_2__c == null && caseRec.SLA_Target_3__c == null) && String.valueOf(caseRec.OwnerId).startsWith('005')){
                userManagerGroupIdList.add(caseRec.OwnerId);
            }
        }
        //Sending mail to all members of the managerGroupId__c FROM owner's user record - 
        //Use case - if SLA 2 AND SLA 3 targets are empty AND SLA 1 target is inactive user, 
        //potentially the case can get away without any escalation emails, 
        //to mitigate, sending single email to all queue members of managerGroupId__c.
        if(userManagerGroupIdList.size() > 0){
            for(User u: [SELECT Id, managerGroupId__c FROM User where Id IN :userManagerGroupIdList AND isActive=true]){
                List<Id> managergroupIds = new List<Id>();
                if(u.managerGroupId__c != null){
                    managergroupIds = u.managerGroupId__c.split(',');
                }
                for(Id managergroupId : managergroupIds){
                    if(!managerGroupIdToOwners.containsKey(managergroupId)){
                        managerGroupIdToOwners.put(managergroupId, new List<Id>());
                    }
                    managerGroupIdToOwners.get(managergroupId).add(u.Id);
                }  
            }
        }

        if(!managerGroupIdToOwners.isEmpty()){
            for(GroupMember gm: [SELECT id, UserOrGroupId, Group.Type,Group.Id FROM GroupMember WHERE Group.Id IN :managerGroupIdToOwners.keySet() AND Group.Type = 'Queue']){
                if(gm.UserOrGroupId.getSObjectType() == User.getSObjectType()){
                    managerUserIds.add(gm.UserOrGroupId);
                    groupMembers.add(gm);
                }
            }
        }

        if(!caseEmailList.isEmpty() || !managerUserIds.isEmpty()){
            Map<Id, String> managerUserIdToEmails = new Map<Id, String>();
            for(user u: [SELECT Id, name,Email FROM User WHERE IsActive = true AND (Email IN :caseEmailList OR Id IN :managerUserIds)]){
                if(caseEmailList.contains(u.Email)){
                    emailUserIdMap.put(u.Email,u.Id);
                }
                if(managerUserIds.contains(u.Id)){
                    managerUserIdToEmails.put(u.Id, u.Email);
                }
            }
            for(GroupMember gm : groupMembers){
                if(managerUserIdToEmails.containsKey(gm.UserOrGroupId)){
                    for(Id ownerId : managerGroupIdToOwners.get(gm.Group.Id)){
                        if(!caseOwnerToManagerEmails.containsKey(ownerId)){
                            caseOwnerToManagerEmails.put(ownerId, new List<String>());
                        }
                        caseOwnerToManagerEmails.get(ownerId).add(managerUserIdToEmails.get(gm.UserOrGroupId));
                    }
                }
            }
        }
 
        EmailTemplate emailTemp = [SELECT Id, Subject,Body,HtmlValue From EmailTemplate WHERE DeveloperName = :Label.ASF_TAT_1_Breach_Email_Template].get(0);
         
        Id orgWideAdressId = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName=:System.Label.ASF_default_no_reply_email_address limit 1].Id;                
 
 
        for(ASF_Case_SLA_History__c slaHistory:[SELECT Id,Breached_User_Level1__c,Case__c,Case__r.Stage_SLA_1__c,Case__r.OwnerId,Case__r.CaseNumber,Case__r.SLA_Target_1__c,Stage__c,Stage_Violation_Start_Date__c,Current_Owner_Id__c,Current_Owner__c,Level__c,is_Running_Record__c FROM ASF_Case_SLA_History__c WHERE Case__c IN: casesNewList AND is_Running_Record__c = true AND Level__c = null AND Stage_Violation_Start_Date__c = null FOR UPDATE]){

            slaHistory.Breached_User_Level1__c = slaHistory.Current_Owner__c;
            slaHistory.Stage_Violation_Start_Date__c = slaHistory.Case__r.Stage_SLA_1__c;
            slaHistory.Level__c = '1';
            slaHistory.Status__c = 'Violated';
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(emailTemp.Id);
            mail.saveAsActivity = false;
            mail.setSubject('TAT Level 1 Breach for case '+ slaHistory.Case__r.CaseNumber);
            if(emailUserIdMap.containsKey(slaHistory.Case__r.SLA_Target_1__c)){
                mail.setTargetObjectId(emailUserIdMap.get(slaHistory.Case__r.SLA_Target_1__c));

            }else if(caseOwnerToManagerEmails.containsKey(slaHistory.Case__r.OwnerId)){
                mail.setToAddresses(caseOwnerToManagerEmails.get(slaHistory.Case__r.OwnerId));
            }

            Messaging.SingleEmailMessage dummyEmailForHtml = Messaging.renderStoredEmailTemplate(emailTemp.Id, emailUserIdMap.get(slaHistory.Case__r.SLA_Target_1__c), slaHistory.Case__c,Messaging.AttachmentRetrievalOption.NONE);
            mail.setHtmlBody(dummyEmailForHtml.getHtmlBody());
            mail.setOrgWideEmailAddressId(orgWideAdressId);        
            mail.setTreatBodiesAsTemplate(true);
            mail.setUseSignature(false);
            if( mail.TargetObjectId != null || mail.toAddresses!=null){
                emailList.add(mail);
            }
            slaHistoryList.add(slaHistory);
        }

        if(!slaHistoryList.isEmpty()){
            system.debug(slaHistoryList);
            try{
                UPDATE slaHistoryList;
            }catch(Exception e){
                System.debug(e.getMessage());
            }
             
        }
        if(!emailList.isEmpty()){
            Messaging.sendEmailResult[] sendEmailResults  = Messaging.SendEmail(emailList);
            for(Messaging.SendEmailResult sendEmailResult: sendEmailResults){
                //TBD throw exception
            }    
        }
    } 
}