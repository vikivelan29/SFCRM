/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-09-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@SuppressWarnings('PMD.FormalParameterNamingConventions')
/**
 * This batch class sends SLA 2 and SLA 3 breach emails at scheduled time.
 * It sends the consolidated email to managers i.e. one email for one manager, listing all escalated cases.
 String sch = '0 15 12,15,18 * * ?';
 String jobID = System.schedule('Send consolidated SLA 2 & 3 breach emails', sch, new ASF_CaseSLA2and3BrokenConsolidatedBatch());
 * 
 */
global with sharing class ASF_CaseSLA2and3BrokenConsolidatedBatch implements Schedulable,Database.Batchable<sObject>{
    global Database.QueryLocator start(Database.BatchableContext context){
        DateTime currentTime = System.now();
        String query = '';
        
        //SLA history fields
        query += 'SELECT Id,Current_Owner__c,is_Running_Record__c,Stage_End_Date__c,Stage_Start_Date__c,BusinessHoursId__c,Case__c,Stage__c,Overdue__c,Status__c,Stage_Violation_Start_Date__c,Current_Owner_Id__c,Level__c,SLA_2_Email_Sent__c,SLA_3_Email_sent__c,Breached_User_Level2__c,Breached_User_Level3__c,';
        
        //Case fields
        query += 'Case__r.Id,Case__r.CaseNumber, Case__r.Status, Case__r.OwnerId, Case__r.Owner.Name,Case__r.Is_Approval_Stage__c, Case__r.SLA_Target_1__c, Case__r.SLA_Target_2__c, Case__r.SLA_Target_3__c, Case__r.Stage_SLA_1__c, Case__r.Stage_SLA_2__c, Case__r.Stage_SLA_3__c, Case__r.BusinessHoursId, Case__r.LastModifiedDate,Case__r.Nature__c,Case__r.Type_Text__c, Case__r.CreatedDate,Case__r.CreatedBy.Name, Case__r.Last_Owner_Change_Date__c,Case__r.Sub_Type_Text__c,Case__r.Business_Unit__c,Case__r.Stage__c';
        
        query += ' FROM ASF_Case_SLA_History__c WHERE is_Running_Record__c = true AND Stage_End_Date__c = null';
        query += ' AND Case__r.Recordtype.Name = \'Framework\' AND Case__r.isClosed = false';
        query += ' AND(';
        //Cases for which SLA 2 and 3 are breached, scheduled flow has updated the records, only email needs to be sent
        query += ' ((Level__c = \'2\' AND Case__r.SLA_Target_2__c != null) OR (Level__c = \'3\' AND Case__r.SLA_Target_3__c != null))';
        
        query += ' OR';
        //Cases for which scheduled flow somehow failed to update the records, but SLA 2 and 3 actualy breached, so SLA history update and email send both are needed
        query += ' ((Case__r.Stage_SLA_2__c < :currentTime AND Case__r.SLA_Target_2__c != null) OR (Case__r.Stage_SLA_3__c < :currentTime AND Case__r.SLA_Target_3__c != null))';

        query += ') order by Case__r.SLA_Target_2__c, Case__r.SLA_Target_3__c, Case__r.CreatedDate DESC';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext context, List<ASF_Case_SLA_History__c> scope){

        DateTime currentTime = System.now();
        Map<String,User> emailUserIdMap = new Map<String,User>();
        Set<String> caseEmailList = new Set<String>();
        map<Id,ASF_Case_SLA_History__c> caseIdToUpdateSLAHistoryMap = new map<Id,ASF_Case_SLA_History__c>();
        map<Id,ASF_Case_SLA_History__c> caseIdToSLAHistoryMap = new map<Id,ASF_Case_SLA_History__c>();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        Map<String, Set<Id>> managerEmailToCasesForSLA2 = new Map<String, Set<Id>>();
        Map<String, Set<Id>> managerEmailToCasesForSLA3 = new Map<String, Set<Id>>();
        Map<Id, Case> casesMap = new Map<Id, Case>();

        for(ASF_Case_SLA_History__c slaHistory : scope){
            //This SLA 1 targets are added because its needed in the email body
            if(slaHistory.Case__r.SLA_Target_1__c!=null){
                caseEmailList.add(slaHistory.Case__r.SLA_Target_1__c);
            }
            if(slaHistory.Case__r.SLA_Target_2__c!=null){
                caseEmailList.add(slaHistory.Case__r.SLA_Target_2__c);
            }
            if(slaHistory.Case__r.SLA_Target_3__c!=null){
                caseEmailList.add(slaHistory.Case__r.SLA_Target_3__c);
            }
            casesMap.put(slaHistory.Case__c, slaHistory.Case__r);
            caseIdToSLAHistoryMap.put(slaHistory.Case__c, slaHistory);
        }

        if(caseEmailList.size() > 0){
            for(User user: [SELECT Id, name, Email FROM User WHERE Email IN :caseEmailList AND IsActive = true]){
                emailUserIdMap.put(user.Email,user);
            }
        }

        for(ASF_Case_SLA_History__c slaHistory : scope){

            Boolean isCaseWithinBusinessHours = false;
            if(slaHistory.BusinessHoursId__c != null){
                isCaseWithinBusinessHours = BusinessHours.isWithin(slaHistory.BusinessHoursId__c, system.now());
            }
            if(slaHistory.Stage_Violation_Start_Date__c == null ){
                slaHistory.Stage_Violation_Start_Date__c = slaHistory.Case__r.Stage_SLA_1__c;
                slaHistory.Status__c = 'Violated';
            }

            if(slaHistory.Case__r.Stage_SLA_3__c != null && slaHistory.Case__r.Stage_SLA_3__c < currentTime && slaHistory.Case__r.SLA_Target_3__c != null){
                if(slaHistory.Level__c != '3'){
                    slaHistory.Level__c = '3';
                    slaHistory.Breached_User_Level3__c = slaHistory.Current_Owner__c;
                    caseIdToUpdateSLAHistoryMap.put(slaHistory.Case__c ,slaHistory);
                }
                if(isCaseWithinBusinessHours || Test.isRunningTest()){
                    if(!managerEmailToCasesForSLA3.containsKey(slaHistory.Case__r.SLA_Target_3__c)){
                        managerEmailToCasesForSLA3.put(slaHistory.Case__r.SLA_Target_3__c, new Set<Id>());
                    }
                    managerEmailToCasesForSLA3.get(slaHistory.Case__r.SLA_Target_3__c).add(slaHistory.Case__c);
                }
            }
            else if(slaHistory.Case__r.Stage_SLA_2__c != null && slaHistory.Case__r.Stage_SLA_2__c < currentTime && slaHistory.Case__r.SLA_Target_2__c != null){
                if(slaHistory.Level__c != '2'){
                    slaHistory.Level__c = '2';
                    slaHistory.Breached_User_Level2__c = slaHistory.Current_Owner__c;
                    caseIdToUpdateSLAHistoryMap.put(slaHistory.Case__c ,slaHistory);
                }
                if(isCaseWithinBusinessHours || Test.isRunningTest()){
                    if(!managerEmailToCasesForSLA2.containsKey(slaHistory.Case__r.SLA_Target_2__c)){
                        managerEmailToCasesForSLA2.put(slaHistory.Case__r.SLA_Target_2__c, new Set<Id>());
                    }
                    managerEmailToCasesForSLA2.get(slaHistory.Case__r.SLA_Target_2__c).add(slaHistory.Case__c);
                }
            }
        }
        if(!managerEmailToCasesForSLA2.isEmpty() || !managerEmailToCasesForSLA3.isEmpty()){
            Map<String, EmailTemplate> emailTemplateMap = new Map<String, EmailTemplate>();
            //SLA_Breach_Email_Consolidated
            for(EmailTemplate emailTemp : [SELECT id, Subject, DeveloperName FROM EmailTemplate WHERE DeveloperName IN (:Label.ASF_TAT_3_Breach_Email_Temp_Consolidated, :Label.ASF_TAT_2_Breach_Email_Temp_Consolidated)]){
                emailTemplateMap.put(emailTemp.DeveloperName, emailTemp);
            }
            Id orgWideAdressId = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName=:System.Label.ASF_default_no_reply_email_address LIMIT 1].get(0).Id;
            if(emailTemplateMap.containsKey(Label.ASF_TAT_2_Breach_Email_Temp_Consolidated)){
                for(String email : managerEmailToCasesForSLA2.keySet()){
                    if(emailUserIdMap.containsKey(email)){
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setTemplateId(emailTemplateMap.get(Label.ASF_TAT_2_Breach_Email_Temp_Consolidated).Id);
                        mail.setOrgWideEmailAddressId(orgWideAdressId);
                        mail.saveAsActivity = false;
                        mail.setTreatBodiesAsTemplate(true);
                        mail.setUseSignature(false);
                        mail.setTargetObjectId(emailUserIdMap.get(email).Id);
                        mail.setSubject('TAT Level 2 Breach for cases');
                        String casesTable = prepareHTMLTable(managerEmailToCasesForSLA2.get(email), casesMap, emailUserIdMap, true);
                        Messaging.SingleEmailMessage dummyEmailForHtml = Messaging.renderStoredEmailTemplate(emailTemplateMap.get(Label.ASF_TAT_2_Breach_Email_Temp_Consolidated).Id, emailUserIdMap.get(email).Id, null,Messaging.AttachmentRetrievalOption.NONE);
                        String emailBody = dummyEmailForHtml.getHtmlBody();
                        emailBody = emailBody.replace('<ENTER_CASES>', casesTable);
                        emailBody = emailBody.replace('<ENTER_LEVEL>', '2');
                        mail.setHtmlBody(emailBody);
                        emailList.add(mail);
                        for(Id caseId : managerEmailToCasesForSLA2.get(email)){
                            if(!caseIdToUpdateSLAHistoryMap.containsKey(caseId)){
                                caseIdToUpdateSLAHistoryMap.put(caseId, caseIdToSLAHistoryMap.get(caseId));
                            }
                            caseIdToUpdateSLAHistoryMap.get(caseId).SLA_2_Email_Sent__c = casesMap.get(caseId).SLA_Target_2__c;
                        }
                    }
                }
            }
            if(emailTemplateMap.containsKey(Label.ASF_TAT_3_Breach_Email_Temp_Consolidated)){
                for(String email : managerEmailToCasesForSLA3.keySet()){
                    if(emailUserIdMap.containsKey(email)){
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setTemplateId(emailTemplateMap.get(Label.ASF_TAT_3_Breach_Email_Temp_Consolidated).Id);
                        mail.setOrgWideEmailAddressId(orgWideAdressId);
                        mail.saveAsActivity = false;
                        mail.setTreatBodiesAsTemplate(true);
                        mail.setUseSignature(false);
                        mail.setTargetObjectId(emailUserIdMap.get(email).Id);
                        mail.setSubject('TAT Level 3 Breach for cases');
                        String casesTable = prepareHTMLTable(managerEmailToCasesForSLA3.get(email), casesMap, emailUserIdMap, false);
                        Messaging.SingleEmailMessage dummyEmailForHtml = Messaging.renderStoredEmailTemplate(emailTemplateMap.get(Label.ASF_TAT_3_Breach_Email_Temp_Consolidated).Id, emailUserIdMap.get(email).Id, null,Messaging.AttachmentRetrievalOption.NONE);
                        String emailBody = dummyEmailForHtml.getHtmlBody();
                        emailBody = emailBody.replace('<ENTER_CASES>', casesTable);
                        emailBody = emailBody.replace('<ENTER_LEVEL>', '3');
                        mail.setHtmlBody(emailBody);
                        emailList.add(mail);
                        for(Id caseId : managerEmailToCasesForSLA3.get(email)){
                            if(!caseIdToUpdateSLAHistoryMap.containsKey(caseId)){
                                caseIdToUpdateSLAHistoryMap.put(caseId, caseIdToSLAHistoryMap.get(caseId));
                            }
                            caseIdToUpdateSLAHistoryMap.get(caseId).SLA_3_Email_Sent__c = casesMap.get(caseId).SLA_Target_3__c;
                        }
                    }
                }
            }
            if(!caseIdToUpdateSLAHistoryMap.isEmpty()){ 
                UPDATE caseIdToUpdateSLAHistoryMap.values();
            }
            if(!emailList.isEmpty()){
                Messaging.sendEmailResult[] sendEmailResults  = Messaging.SendEmail(emailList);
            }
        }
    }

    private String prepareHTMLTable(Set<Id> caseIds, Map<Id, Case> casesMap, Map<String,User> emailUserIdMap, Boolean isSLA2){
        String table = '<table style="border: 1px solid black;border-collapse: collapse;">';
        //saving some CPU time by putting entire header row together, readability compromised.
        table += '<thead><tr><th style="border: 1px solid black;border-collapse: collapse;">Case No.</th><th style="border: 1px solid black;border-collapse: collapse;">Case Creation date</th><th style="border: 1px solid black;border-collapse: collapse;">Assigned On</th><th style="border: 1px solid black;border-collapse: collapse;">Current Owner</th><th style="border: 1px solid black;border-collapse: collapse;">L1 Manager</th><th style="border: 1px solid black;border-collapse: collapse;">Breached on</th><th style="border: 1px solid black;border-collapse: collapse;">Case Type</th><th style="border: 1px solid black;border-collapse: collapse;">Case Sub-Type</th><th style="border: 1px solid black;border-collapse: collapse;">LOB</th><th style="border: 1px solid black;border-collapse: collapse;">Current stage breached</th>';
        table += isSLA2?'<th style="border: 1px solid black;border-collapse: collapse;">SLA 3 breach time</th>':'';
        table += '</tr></thead><tbody>';
        for(Id caseId : caseIds){
            Case caseRec = casesMap.get(caseId);
            table += '<tr><td style="border: 1px solid black;border-collapse: collapse;">'+caseRec.CaseNumber+'</td><td style="border: 1px solid black;border-collapse: collapse;">'+caseRec.CreatedDate.format('dd-MM-yyyy hh:mm a', 'IST')+'</td>';
            table += '<td style="border: 1px solid black;border-collapse: collapse;">'+caseRec.Last_Owner_Change_Date__c.format('dd-MM-yyyy hh:mm a', 'IST')+'</td><td style="border: 1px solid black;border-collapse: collapse;">'+caseRec.Owner.Name+'</td>';
            table += '<td style="border: 1px solid black;border-collapse: collapse;">'+(caseRec.SLA_Target_1__c!=null?String.valueOf(emailUserIdMap.get(caseRec.SLA_Target_1__c)?.Name):'')+'</td>';
            table += '<td style="border: 1px solid black;border-collapse: collapse;">'+(isSLA2?caseRec.Stage_SLA_2__c.format('dd-MM-yyyy hh:mm a', 'IST'):caseRec.Stage_SLA_3__c.format('dd-MM-yyyy hh:mm a', 'IST'))+'</td>';
            table += '<td style="border: 1px solid black;border-collapse: collapse;">'+caseRec.Type_Text__c+'</td><td style="border: 1px solid black;border-collapse: collapse;">'+caseRec.Sub_Type_Text__c+'</td><td style="border: 1px solid black;border-collapse: collapse;">'+caseRec.Business_Unit__c+'</td><td style="border: 1px solid black;border-collapse: collapse;">'+caseRec.Stage__c+'</td>';
            table += isSLA2?('<td style="border: 1px solid black;border-collapse: collapse;">'+(caseRec.Stage_SLA_3__c!=null?(caseRec.Stage_SLA_3__c.format('dd-MM-yyyy hh:mm a', 'IST')) : 'NA')+'</td></tr>'):'</tr>';
        }
        table += '</tbody></table>';
        return table;
    }
    
    global void finish(Database.BatchableContext context){ 
        system.debug('Completed');
    }

    global void execute(SchedulableContext scon) {
        Database.executeBatch(new ASF_CaseSLA2and3BrokenConsolidatedBatch(),50);
    }
}