global without sharing class ASF_TimeBasedSLAAlertHandler implements Schedulable,Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        DateTime currentTime = System.now(); 
        String query = 'SELECT Id, CaseNumber, Status, OwnerId, Owner.Name,Is_Approval_Stage__c, SLA_Target_1__c, SLA_Target_2__c, SLA_Target_3__c, Stage_SLA_1__c, Stage_SLA_2__c, Stage_SLA_3__c, BusinessHoursId, LastModifiedDate,Nature__c,Type_Text__c, CreatedDate,Account.Client_Code__c,Account.Name,CreatedBy.Name  FROM  Case WHERE (Stage_SLA_2__c < :currentTime OR Stage_SLA_3__c < :currentTime) AND isClosed = false';
        return Database.getQueryLocator(query);
    }
    
    private void setCaseEmailList(List<Case> scope,
                                  list<Case> casesList,
                                  list<string> caseEmailList,
                                  list<string> userManagerGroupIdList,
                                  DateTime currentTime)
    {
        for(Case c : scope){
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
            if( ((c.Stage_SLA_2__c != null && c.Stage_SLA_2__c < currentTime) || (c.Stage_SLA_3__c != null && c.Stage_SLA_3__c < currentTime)) && String.valueOf(c.OwnerId).startsWith('005')){
                userManagerGroupIdList.add(c.OwnerId);
                
            }
        }
    }
    
    private void getUsersManagerGroupId(list<string> userManagerGroupIdList,map<Id,string> userManagerGroupIdMap){
        list<User> cecUsers = [Select Id, managerGroupId__c from User where Id IN :userManagerGroupIdList];
        if(cecUsers.size() > 0){
            for(User u: cecUsers){
                if(u.managerGroupId__c != null){
                    userManagerGroupIdMap.put(u.Id,u.managerGroupId__c);
                }
            }
        }
    }
    
    public void getManagersGroupMembers(map<Id,string> userManagerGroupIdMap,map<Id,list<string>> ManagerGroupMembersIdMap){
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
    }
    public void getUserFromSLATargetFields(list<string> caseEmailList,map<string,Id> emailUserIdMap){
        list<user> userList = [select Id, name,Email FROM User where Email IN :caseEmailList];
        if(userList.size() > 0){
            for(user u: userList){
                emailUserIdMap.put(u.Email,u.Id);
            }
        }
    }
    global void execute(Database.BatchableContext BC, List<Case> scope){
        DateTime currentTime = System.now();
        map<Id,string> caseBreachedOwnerMap = new map<Id,String>();
        map<string,Id> emailUserIdMap = new map<string,Id>();
        list<string> caseEmailList = new list<string>();
        map<Id,Boolean> emailsToBeSentForCase = new map<Id,Boolean>();
        list<string> userManagerGroupIdList = new list<string>();
        map<Id,string> userManagerGroupIdMap = new map<Id,string>();
        map<Id,list<string>> ManagerGroupMembersIdMap = new map<Id,list<string>>();
        map<Id,ASF_Case_SLA_History__c> caseIdSLAHistoryMap = new map<Id,ASF_Case_SLA_History__c>(); //Create a map of <CaseId, SLA History Record>
        list<Case> casesList = new list<Case>();
        
        
        setCaseEmailList(scope,casesList,caseEmailList,userManagerGroupIdList,currentTime);
        
        if(userManagerGroupIdList.size() > 0){
            getUsersManagerGroupId(userManagerGroupIdList,userManagerGroupIdMap);
            
            if(userManagerGroupIdMap.values().size() > 0){
                getManagersGroupMembers(userManagerGroupIdMap,ManagerGroupMembersIdMap);
                
            }
        }
        
        if(caseEmailList.size() > 0){
            getUserFromSLATargetFields(caseEmailList,emailUserIdMap);
        }
        
        system.debug('Getting the list here--->'+emailUserIdMap);
        
        //Business logic to get the breached user and send email
        // try {
        
        Map<Id,Case> caseMap = new  Map<Id,Case>();
        Map<String,String> caseIdVsSLALevel = new Map<String,String>();
        List<ASF_Case_SLA_History__c> slaHistoryList = new List<ASF_Case_SLA_History__c>();
        Map<String,Boolean> caseInBusinessHour = new Map<String,Boolean>();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        
        //Get Case Histories by Case Id and where Stage End Date is null and is Running Record is true;
        
        for(ASF_Case_SLA_History__c slaHistory : [SELECT Id, Current_Owner__c, is_Running_Record__c,Stage_End_Date__c, Stage_Start_Date__c,BusinessHoursId__c, 
                                                  Case__c, Case__r.Stage_SLA_1__c, Case__r.Stage_SLA_2__c, Case__r.Stage_SLA_3__c, Stage__c, Overdue__c, Status__c, Stage_Violation_Start_Date__c, Current_Owner_Id__c, Level__c,SLA_2_Email_Sent__c,SLA_3_Email_sent__c,Case__r.SLA_Target_1__c,Case__r.SLA_Target_2__c,Case__r.SLA_Target_3__c,Case__r.OwnerId,Breached_User_Level2__c,Breached_User_Level3__c FROM  ASF_Case_SLA_History__c 
                                                  WHERE Case__c IN: casesList AND Stage_End_Date__c = null AND is_Running_Record__c = true ])
        {
            // If SLA Violation is null, the set SLA Violation.
            if(slaHistory.Stage_Violation_Start_Date__c == null ){
                slaHistory.Stage_Violation_Start_Date__c = slaHistory.Case__r.Stage_SLA_1__c;
                slaHistory.Status__c = 'Violated';
                
            }
            
            if(slaHistory.Stage_Violation_Start_Date__c != null && slaHistory.Level__c == '2' && slaHistory.Case__r.Stage_SLA_3__c !=null &&(slaHistory.Case__r.Stage_SLA_3__c < currentTime)){
                
                system.debug('coming here2----->'+ slaHistory.Case__C);
                
                if(slaHistory.Case__r.SLA_Target_3__c != null && slaHistory.SLA_3_Email_Sent__c != slaHistory.Case__r.SLA_Target_3__c){
                    slaHistory.Level__c = '3';
                    slaHistory.Breached_User_Level3__c = slaHistory.Current_Owner__c;
                    system.debug('coming here3----->'+ slaHistory.Case__C);
                    slaHistory.SLA_3_Email_Sent__c = slaHistory.Case__r.SLA_Target_3__c;
                    caseIdSLAHistoryMap.put(slaHistory.Case__c ,slaHistory);
                    
                }else if(slaHistory.Case__r.SLA_Target_3__c == null && userManagerGroupIdMap.containsKey(slaHistory.Case__r.OwnerId) && ManagerGroupMembersIdMap.containsKey(userManagerGroupIdMap.get(slaHistory.Case__r.OwnerId)) && slaHistory.SLA_3_Email_Sent__c != userManagerGroupIdMap.get(slaHistory.Case__r.OwnerId)){
                    // emailsToBeSentForCase.put(slaHistory.case__c,true);
                    slaHistory.Level__c = '3';
                    slaHistory.Breached_User_Level3__c = slaHistory.Current_Owner__c;
                    slaHistory.SLA_3_Email_Sent__c = userManagerGroupIdMap.get(slaHistory.Case__r.OwnerId);
                    caseIdSLAHistoryMap.put(slaHistory.Case__c ,slaHistory);
                }
                
                
                // caseBreachedOwnerMap.put(slaHistory.Case__c,slaHistory.Current_Owner_Id__c);
            }else if(slaHistory.Stage_Violation_Start_Date__c != null && slaHistory.Level__c == '1' && slaHistory.Case__r.Stage_SLA_2__c != null && (slaHistory.Case__r.Stage_SLA_2__c < currentTime)){
                
                
                //Check SLA Target 2 and SLA 2 Email sent is not same
                
                if(slaHistory.Case__r.SLA_Target_2__c != null && slaHistory.SLA_2_Email_Sent__c != slaHistory.Case__r.SLA_Target_2__c){
                    slaHistory.Level__c = '2';
                    slaHistory.Breached_User_Level2__c = slaHistory.Current_Owner__c;
                    slaHistory.SLA_2_Email_Sent__c = slaHistory.Case__r.SLA_Target_2__c;
                    caseIdSLAHistoryMap.put(slaHistory.Case__c ,slaHistory);
                    
                }else if(slaHistory.Case__r.SLA_Target_2__c == null && userManagerGroupIdMap.containsKey(slaHistory.Case__r.OwnerId) && ManagerGroupMembersIdMap.containsKey(userManagerGroupIdMap.get(slaHistory.Case__r.OwnerId)) && slaHistory.SLA_2_Email_Sent__c != userManagerGroupIdMap.get(slaHistory.Case__r.OwnerId)){
                    // emailsToBeSentForCase.put(slaHistory.case__c,true);
                    slaHistory.Level__c = '2';
                    slaHistory.Breached_User_Level2__c = slaHistory.Current_Owner__c;
                    slaHistory.SLA_2_Email_Sent__c = userManagerGroupIdMap.get(slaHistory.Case__r.OwnerId);
                    caseIdSLAHistoryMap.put(slaHistory.Case__c ,slaHistory);
                }
                
                
                
                // caseBreachedOwnerMap.put(slaHistory.Case__c,slaHistory.Current_Owner_Id__c);
            }
            if(slaHistory.BusinessHoursId__c != null){
                //  slaHistory.Overdue__c = BusinessHours.diff(slaHistory.BusinessHoursId__c, slaHistory.Stage_Violation_Start_Date__c, System.now())/(1000*60*60);
                caseInBusinessHour.put(slaHistory.Case__c, BusinessHours.isWithin(slaHistory.BusinessHoursId__c, system.now()));
            }
            slaHistoryList.add(slaHistory);
            
        }
        system.debug('caseInBusinessHour == ' + caseInBusinessHour);
        
        for(Case caseObj : casesList){
            if((caseInBusinessHour.containsKey(caseObj.Id) && caseInBusinessHour.get(caseObj.Id) && caseObj.Is_Approval_Stage__c == false) || Test.isRunningTest()){
                if(caseObj.Stage_SLA_3__c != null && (caseObj.Stage_SLA_3__c < currentTime)){
                    caseMap.put(caseObj.Id, caseObj);
                    if(caseIdSLAHistoryMap.containsKey(caseObj.Id)){
                        system.debug('coming for james----'+caseObj.CaseNumber);
                        caseIdVsSLALevel.put(caseObj.Id,'Case Escalation level 3');
                    }
                    
                    
                }else if(caseObj.Stage_SLA_2__c != null && (caseObj.Stage_SLA_2__c < currentTime)){
                    caseMap.put(caseObj.Id, caseObj);
                    if(caseIdSLAHistoryMap.containsKey(caseObj.Id)){
                        caseIdVsSLALevel.put(caseObj.Id,'Case Escalation level 2');
                    }
                    
                    
                }
                
            }
        }
        
        EmailTemplate emailTemp = [Select id, Subject, Body,HtmlValue From EmailTemplate Where DeveloperName = 'Case_Owner_s_Manager_Email_when_the_SLA_is_breached'].get(0);
        Id orgWideAdressId = [SELECT Id, Address, DisplayName, Purpose, IsAllowAllProfiles, LastModifiedBy.Name FROM OrgWideEmailAddress where DisplayName=:System.Label.ASF_default_no_reply_email_address limit 1].get(0).Id;
        
        for(String caseId : caseIdVsSLALevel.keySet()){
            
            String slaLevel = caseIdVsSLALevel.get(caseId);
            Case caseObj = caseMap.get(caseId);
            String toEmailAddress ='';
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            List<String> toAddress =new List<String>();
            mail.setTemplateId(emailTemp.Id);
            mail.setOrgWideEmailAddressId(orgWideAdressId);
            
            mail.saveAsActivity = false;
            
            if(slaLevel == 'Case Escalation level 2'){
                if(caseObj.SLA_Target_2__c != null && emailUserIdMap.containsKey(caseObj.SLA_Target_2__c)){
                    mail.setTargetObjectId(emailUserIdMap.get(caseObj.SLA_Target_2__c));
                }else if(caseObj.SLA_Target_2__c != null && String.isNotBlank(caseObj.SLA_Target_2__c) ){
                    mail.setToAddresses(new list<String>{caseObj.SLA_Target_2__c});
                }else if(caseObj.SLA_Target_2__c == null && userManagerGroupIdMap.containsKey(caseObj.OwnerId) && ManagerGroupMembersIdMap.containsKey(userManagerGroupIdMap.get(caseObj.OwnerId))){
                    mail.setToAddresses(ManagerGroupMembersIdMap.get(userManagerGroupIdMap.get(caseObj.OwnerId)));
                }
                mail.setSubject('TAT Level 2 Breach for case '+ caseObj.CaseNumber);
                Messaging.SingleEmailMessage dummyEmailForHtml = Messaging.renderStoredEmailTemplate(emailTemp.Id, emailUserIdMap.get(caseObj.SLA_Target_2__c), caseObj.Id,Messaging.AttachmentRetrievalOption.NONE);
                mail.setHtmlBody(dummyEmailForHtml.getHtmlBody());
            }else if(slaLevel == 'Case Escalation level 3'){
                if(caseObj.SLA_Target_3__c != null && emailUserIdMap.containsKey(caseObj.SLA_Target_3__c)){
                    mail.setTargetObjectId(emailUserIdMap.get(caseObj.SLA_Target_3__c));
                }else if(caseObj.SLA_Target_3__c != null && String.isNotBlank( caseObj.SLA_Target_3__c)){
                    mail.setToAddresses(new list<String>{caseObj.SLA_Target_3__c});
                }else if(caseObj.SLA_Target_3__c == null && userManagerGroupIdMap.containsKey(caseObj.OwnerId) && ManagerGroupMembersIdMap.containsKey(userManagerGroupIdMap.get(caseObj.OwnerId))){
                    mail.setToAddresses(ManagerGroupMembersIdMap.get(userManagerGroupIdMap.get(caseObj.OwnerId)));
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
            system.debug('mail--->'+mail.TargetObjectId);
            
            // } 
            
            
            
        }
        
        if(!slaHistoryList.isEmpty()){
            // SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.UPDATABLE, slaHistoryList);
            // No exceptions are thrown and no rating is set
            //   update securityDecision.getRecords(); 
            UPDATE slaHistoryList;
        }
        if(!emailList.isEmpty()){
            Messaging.sendEmailResult[] sendEmailResults  = Messaging.SendEmail(emailList);
            
            if(!Test.IsRunningTest()){
                sendEmailResults =  Messaging.SendEmail(emailList);
            }
        }
    }
    
    
    global void finish(Database.BatchableContext BC){ 
        system.debug('Completed');
    }
    
    global void execute(SchedulableContext scon) {
        Database.executeBatch(new ASF_TimeBasedSLAAlertHandler(),100);
    }
}