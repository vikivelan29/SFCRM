/*********************************************************
*Class        :  ASF_CaseSLABroken
*Description  :  Class to notify Emails based on Case SLA violations
*********************************************************/

public without sharing class ASF_CaseSLABroken {
    
   @InvocableMethod(label='Send Email SLA Broke1')
   public static void sendEmailSLABroke(List<String> casesList) {

        List<ASF_Case_SLA_History__c> slaHistoryList = new List<ASF_Case_SLA_History__c>();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
       
        List<Case> oldCaseList = [Select Id,CaseNumber,SLA_Target_1__c,OwnerId from Case where Id IN: casesList];
        map<Id,Id> caseOwnerIdMap = new map<Id,Id>();
        map<Id,list<string>> userIdEmailListMap = new map<Id,list<string>>();
        list<string> userManagerGroupIdList = new list<string>();
        map<string,string> userManagerGroupIdMap = new map<string,string>();
        map<string,list<string>> ManagerGroupMembersIdMap = new map<string,list<string>>();
        map<string,string> userIdEmailMap = new map<string,string>();
        

        List<string> caseEmailList = new List<string>();
        List<Case> casesNewList = new List<Case>();
         
        Map<string,Id> emailUserIdMap = new Map<string,Id>();
        for(Case c : oldCaseList){
             casesNewList.add(c);
             if(c.SLA_Target_1__c!=null){
                caseEmailList.add(c.SLA_Target_1__c);
            }
            if(c.SLA_Target_1__c == null && String.valueOf(c.OwnerId).startsWith('005')){
                userManagerGroupIdList.add(c.OwnerId);

            }

            caseOwnerIdMap.put(c.Id,C.OwnerId);
        }


        if(userManagerGroupIdList.size() > 0){
            list<User> cecUsers = [Select Id, managerGroupId__c from User where Id IN :userManagerGroupIdList];
            
            if(cecUsers.size() > 0){
                for(User u: cecUsers){
                    //Map  of user -> GroupId
                    userManagerGroupIdMap.put(u.Id,u.managerGroupId__c);
                }
            }

            if(userManagerGroupIdMap.values().size() > 0){
                list<Id> userIdList = new list<Id>();
                list<GroupMember> managerPublicGroups = [SELECT id, UserOrGroupId, Group.Type,Group.Id FROM GroupMember WHERE Group.Id IN :userManagerGroupIdMap.values()];
                if(managerPublicGroups.size() > 0){
                    for(GroupMember gm: managerPublicGroups){
                        userIdList.add(gm.UserOrGroupId);
                        if(ManagerGroupMembersIdMap.containsKey(gm.Group.Id)){
                            //map of Group -> list<Group Members>
                            ManagerGroupMembersIdMap.get(gm.Group.Id).add(gm.UserOrGroupId);
                        }else{
                            list<string> temp = new list<string>();
                            temp.add(gm.UserOrGroupId);
                            ManagerGroupMembersIdMap.put(gm.Group.Id,temp);
                        }
                    }
                }

                if(userIdList.size() > 0){
                    list<User> userEmailList = [Select Id, Email from User where Id IN :userIdList];
                    if(userEmailList.size() > 0){
                        for(User u: userEmailList){
                            userIdEmailMap.put(u.Id,u.Email);
                        }
                    }


                }
            }
            

         
           

        }

        //Loop through userManagerGroupIdMap <u.id,managerGroupId>
        //loop through ManagerGroupMembersIdMap.keyset() and check if managerGroupId exists
        //for each value get the userEmail from userIdEmailMap and add it final list of ownerId -> userIdEmail

        if(userManagerGroupIdMap.values().size() > 0){
            for(string s: userManagerGroupIdMap.keySet()){
                Id mangerGroupIdString = userManagerGroupIdMap.get(s);
                if(ManagerGroupMembersIdMap.containsKey(mangerGroupIdString) && ManagerGroupMembersIdMap.get(mangerGroupIdString).size() > 0){
                    for(String managerGroupIdKeyString: ManagerGroupMembersIdMap.keySet()){
                        list<string> userOrGroupIdList = ManagerGroupMembersIdMap.get(managerGroupIdKeyString);
                        for(Id userIdString: userOrGroupIdList){
                            system.debug('Email---->'+userIdEmailMap.get(userIdString));
                            if(userIdEmailListMap.containsKey(s) ){
                                system.debug('UserId debug2---->'+s);
                                userIdEmailListMap.get(s).add(userIdEmailMap.get(userIdString));
                            }else{
                                list<string> temp = new list<string>();
                                temp.add(userIdEmailMap.get(userIdString));
                                system.debug('UserId debug1---->'+s);
                                userIdEmailListMap.put(s,temp);
                            }
                        }
                        

                    }
                }
            }
        }

        



        

        if(caseEmailList.size() > 0){
            list<user> userList = [select Id, name,Email FROM User where Email IN :caseEmailList];
            if(userList.size() > 0){
                for(user u: userList){
                    emailUserIdMap.put(u.Email,u.Id);
                }
            }
        }

        EmailTemplate emailTemp = [Select Id, 
                                  Subject,
                                  Body,
                                  HtmlValue
                                  From 
                                  EmailTemplate 
                                  Where 
                                  DeveloperName = 'Case_Owner_s_Manager_Email_when_the_SLA_is_breached'].get(0);
        
        Id orgWideAdressId = [SELECT Id, Address, DisplayName, Purpose, IsAllowAllProfiles, LastModifiedBy.Name FROM OrgWideEmailAddress WHERE DisplayName=:System.Label.ASF_default_no_reply_email_address].get(0).Id;                                  


        for(ASF_Case_SLA_History__c slaHistory:[SELECT Id, 
                          Breached_User_Level1__c,
                          Case__c,
                          Case__r.Stage_SLA_1__c,
                          Case__r.OwnerId,
                          Case__r.CaseNumber,
                          Case__r.SLA_Target_1__c,
                          Stage__c,
                          Stage_Violation_Start_Date__c,
                          Current_Owner_Id__c,
                          Current_Owner__c,
                          Level__c,
                          is_Running_Record__c
                          FROM
                          ASF_Case_SLA_History__c 
                          WHERE
                          Case__c IN: casesNewList
                          AND is_Running_Record__c = true and Level__c = null and Stage_Violation_Start_Date__c = null]){

                    slaHistory.Breached_User_Level1__c = slaHistory.Current_Owner__c;
                    slaHistory.Stage_Violation_Start_Date__c = slaHistory.Case__r.Stage_SLA_1__c;
                    slaHistory.Level__c = '1';

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    
                    mail.setTemplateId(emailTemp.Id);
                    mail.saveAsActivity = false;
                    mail.setSubject('TAT Level 1 Breach for case '+ slaHistory.Case__r.CaseNumber);
                    mail.setTargetObjectId(emailUserIdMap.get(slaHistory.Case__r.SLA_Target_1__c));
                    if(emailUserIdMap.containsKey(slaHistory.Case__r.SLA_Target_1__c)){
                        mail.setTargetObjectId(emailUserIdMap.get(slaHistory.Case__r.SLA_Target_1__c));
                    }else if(String.isNotBlank(slaHistory.Case__r.SLA_Target_1__c)){
                        mail.setToAddresses(new list<String>{slaHistory.Case__r.SLA_Target_1__c});
                    }else if(userIdEmailListMap.containsKey(slaHistory.Case__r.OwnerId)){
                        mail.setToAddresses(userIdEmailListMap.get(slaHistory.Case__r.OwnerId));
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
            //SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.UPDATABLE, slaHistoryList);
			// No exceptions are thrown and no rating is set
		  //update securityDecision.getRecords(); 
            UPDATE slaHistoryList;
        }
        if(!emailList.isEmpty()){
            //EmailMessageTriggerHandler.SystemModeForSendingEmails= true;
            if(!test.isRunningTest()){
            	Messaging.sendEmailResult[] sendEmailResults  = Messaging.SendEmail(emailList);
            	for(Messaging.SendEmailResult sendEmailResult: sendEmailResults){
                //
            	}
            }
            
   		}
   } 
}