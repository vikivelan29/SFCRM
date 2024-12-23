/******************************************************  
* Author           - Dinoy Pauly
* Date             - 08-November-2024
* Description      - Batch class for sending reports to external customers
********************************************************
*/
global with sharing class ABML_ScheduleReportsBatch implements Schedulable, Database.Batchable<sObject> {
    global Database.QueryLocator start(DataBase.BatchableContext context){
         
        String abml=System.Label.ABML_BU;//'ABML';
        String query = 'SELECT Type_Text__c,Sub_Type_Text__c,Assigned_Team__c, Owner.Name, Account.Name, Subject, CreatedDate,CaseNumber, Client_Code__c,ABML_Case_Detail__c,Description,Account.PersonDepartment, Account.Type,Nature__c,ABML_Case_Detail__r.Name,ABML_Case_Detail__r.TAT_Deadline_Date__c,ABML_Case_Detail__r.TAT_Days__c,Pending_Clarification__c,ABML_Case_Detail__r.Assigned_User__r.Name,Ageing_Business_Days__c FROM case where Business_Unit__c =:abml';
        return Database.getQueryLocator(query);
    }
    
    global void execute(DataBase.BatchableContext context,List<Case> scope){
        List<id> caseDetailsId = new List<id>();
        
        String csvHeader = 'Type,Sub Type,Assigned Team,Contact Type,Description,Nature,Case Number,Account Name,Case Owner\n';
        String csvBody = '';
        String csvBodyTwo = '';
        String csvHeaderTwo ='Case Owner, Account Name, Subject, Date/Time Opened,Case Number,Description,Type,Sub Type_Text,ABML Case Detail Name\n';
        String csvHeaderThree ='Case Number,Type,Sub Type,Case Owner,Description,Contact Type,TAT Deadline,TAT Days\n';
        String csvBodyThree = '';
        String csvHeaderFour ='ABML Case Detail Name,Assigned User,Pending Clarification,Type,Sub Type,Ageing(Business Days),Case Number,Description,Case Owner\n';
        String csvBodyFour = '';

        for (case cs : scope) {
            //csvBody += '"' + cs.Type_Text__c + '","' + cs.Sub_Type_Text__c + '","' + cs.Assigned_Team__c + '","' + cs.Account.Type + '","' + cs.Description + '","' + cs.Nature__c + '","' + String.valueOf(cs.CaseNumber) + '","' + cs.Account.Name + '","' + cs.Owner.Name + '"\n';
   
            csvBody += '"' + (cs.Type_Text__c != null ? cs.Type_Text__c : '') + '","' 
            + (cs.Sub_Type_Text__c != null ? cs.Sub_Type_Text__c : '') + '","'
            + (cs.Assigned_Team__c != null ? cs.Assigned_Team__c : '') + '","'
            + (cs.Account.Type != null ? cs.Account.Type : '') + '","'
            + (cs.Description != null ? cs.Description : '') + '","' 
            + (cs.Nature__c != null ? cs.Nature__c : '') + '","'
            + (cs.CaseNumber != null ? String.valueOf(cs.CaseNumber) : '') + '","'
            + (cs.Account.Name != null ? cs.Account.Name : '') + '","'
            + (cs.Owner.Name != null ? cs.Owner.Name : '') + '"\n';
            
            //csvBodyTwo += '"' + cs.Owner.Name + '","' + cs.Account.Name + '","' + cs.Subject + '","' + cs.CreatedDate + '","' + String.valueOf(cs.CaseNumber) + '","' + cs.Description + '","' + cs.Type_Text__c + '","' + cs.Sub_Type_Text__c + '","' + cs.ABML_Case_Detail__r.Name + '"\n';
            csvBodyTwo += '"' + (cs.Owner != null && cs.Owner.Name != null ? cs.Owner.Name : '') + '","'
            + (cs.Account.Name != null ? cs.Account.Name : '') + '","'
            + (cs.Subject != null ? cs.Subject : '') + '","'
            + cs.CreatedDate + '","'
            + (cs.CaseNumber != null ? String.valueOf(cs.CaseNumber) : '') + '","'
            + (cs.Description != null ? cs.Description : '') + '","'
            + (cs.Type_Text__c != null ? cs.Type_Text__c : '') + '","'
            + (cs.Sub_Type_Text__c != null ? cs.Sub_Type_Text__c : '') + '","'
            + (cs.ABML_Case_Detail__r.Name != null ? cs.ABML_Case_Detail__r.Name : '') + '"\n';
            
            //csvBodyThree += '"' + String.valueOf(cs.CaseNumber) + '","' + cs.Type_Text__c + '","' + cs.Sub_Type_Text__c + '","' + cs.Owner.Name + '","' + cs.Description + '","' + cs.Account.Type + '","' + cs.ABML_Case_Detail__r.TAT_Deadline_Date__c + '","' + cs.ABML_Case_Detail__r.TAT_Days__c + '"\n';
            csvBodyThree += '"' + (cs.CaseNumber != null ? String.valueOf(cs.CaseNumber) : '') + '","'
            + (cs.Type_Text__c != null ? cs.Type_Text__c : '') + '","'
            + (cs.Sub_Type_Text__c != null ? cs.Sub_Type_Text__c : '') + '","'
            + (cs.Owner.Name != null ? cs.Owner.Name : '') + '","'
            + (cs.Description != null ? cs.Description : '') + '","'
            + (cs.Account.Type != null ? cs.Account.Type : '') + '","'
            + (cs.ABML_Case_Detail__r.TAT_Deadline_Date__c != null ? cs.ABML_Case_Detail__r.TAT_Deadline_Date__c : '') + '","'
            + (cs.ABML_Case_Detail__r.TAT_Days__c != null ? cs.ABML_Case_Detail__r.TAT_Days__c : '') + '"\n';
            
            //csvBodyFour += '"' + cs.Name + '","' + cs.Assigned_User__c + '","' + cs.Case__r.Pending_Clarification__c + '","' + cs.Case__r.Type_Text__c + '","' + cs.Case__r.Sub_Type_Text__c + '","' + String.valueOf(cs.Case__r.Ageing_Business_Days__c) + '","' + String.valueOf(cs.Case__r.CaseNumber) + '","' + cs.Case__r.Description + '","' + cs.Case__r.Owner.Name + '"\n';
            csvBodyFour += '"' + (cs.ABML_Case_Detail__r.Name != null ? cs.ABML_Case_Detail__r.Name : '') + '","'
            + (cs.ABML_Case_Detail__r.Assigned_User__r.Name != null ? cs.ABML_Case_Detail__r.Assigned_User__r.Name : '') + '","'
            + cs.Pending_Clarification__c + '","'
            + (cs.Type_Text__c != null ? cs.Type_Text__c : '') + '","'
            + (cs.Sub_Type_Text__c != null ? cs.Sub_Type_Text__c : '') + '","'
            + (cs.Ageing_Business_Days__c != null ? String.valueOf(cs.Ageing_Business_Days__c) : '') + '","' 
            + (cs.CaseNumber != null ? String.valueOf(cs.CaseNumber) : '') + '","'
            + (cs.Description != null ? cs.Description : '') + '","'
            + (cs.Owner.Name != null ? cs.Owner.Name : '') + '"\n';
        }
        
        String csvContent = csvHeader + csvBody;
        String csvContentTwo = csvHeaderTwo + csvBodyTwo;
        String csvContentThree = csvHeaderThree + csvBodyThree;
        
        String csvContentFour = csvHeaderFour + csvBodyFour;
        
        //BUSpecificAutoEmailMapping__mdt mdt = [Select Business_Unit__c,Default_Automated_Email_From_Address__c from BUSpecificAutoEmailMapping__mdt where Business_Unit__c=:System.Label.ABML_BU LIMIT 1];
        OrgWideEmailAddress orgWideEmail =[SELECT id, Address,DisplayName FROM OrgWideEmailAddress where DisplayName =:System.Label.ASF_default_no_reply_email_address LIMIT 1];//    where Address =:mdt.Default_Automated_Email_From_Address__c
        List<Messaging.EmailFileAttachment> attach=new List<Messaging.EmailFileAttachment>();
        
        String deptPendant='ABML Department Pendency.csv';
        String totalTat = 'ABML Total TAT cases for User.csv';
        String missedTat = 'ABML Missed TAT.csv';
        String agingCases = 'ABML Aging Cases of the Day Per Agent.csv';
        
        Messaging.EmailFileAttachment csvAttachment1 = attachFile(deptPendant,csvContent);
        Messaging.EmailFileAttachment csvAttachment2 = attachFile(totalTat,csvContentTwo);
        Messaging.EmailFileAttachment csvAttachment3 = attachFile(missedTat,csvContentThree);
        Messaging.EmailFileAttachment csvAttachment4 = attachFile(agingCases,csvContentFour);
        attach.add(csvAttachment1);
        attach.add(csvAttachment2);
        attach.add(csvAttachment3);
        attach.add(csvAttachment4);
        
        List<string> toAddress = new List<string>();
        List<ABML_Daily_Report_Sender__c> mailSetting = [select Email__c from ABML_Daily_Report_Sender__c];
        for(ABML_Daily_Report_Sender__c sets:mailSetting){
             toAddress.add(sets.Email__c);
        }
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>(); 
        
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setFileAttachments(attach);  
        message.setSubject('Daily Status Report -'+system.today());
        message.setorgWideEmailAddressId(orgWideEmail.Id);
        message.setPlainTextBody('Please find the reports attached.');    
        message.setToAddresses(toAddress);
       
        Messaging.EmailFileAttachment firstAttachment = createAttachment(departmentPendency, firstCsvContent);
        Messaging.EmailFileAttachment secondAttachment = createAttachment(totalTat, secondCsvContent);
        Messaging.EmailFileAttachment thirdAttachment = createAttachment(missedTat, thirdCsvContent);
        Messaging.EmailFileAttachment fourthAttachment = createAttachment(agingCases, fourthCsvContent);
        listOfAttachment.add(firstAttachment);
        listOfAttachment.add(secondAttachment);
        listOfAttachment.add(thirdAttachment);
        listOfAttachment.add(fourthAttachment);
        
        Id templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'ABML_Daily_Reports_Template_1734689602486' LIMIT 1].Id;
        
        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
        emailMessage.setTemplateId(templateId);
        emailMessage.setFileAttachments(listOfAttachment);  
        emailMessage.setSubject('Daily Status Report - ' + System.Today());
        emailMessage.setorgWideEmailAddressId(orgWideEmail.Id);
        emailMessage.setPlainTextBody('Please find the reports attached.');    
        emailMessage.setToAddresses(listOfToAddress);
       
        emailList.add(emailMessage);
        
        Messaging.SendEmailResult[] res;
        if (!emailList.isEmpty()) {
            res = Messaging.sendEmail(emailList);
            system.debug('Done'+res);
        }
        //Messaging.SendEmailResult[] res = Messaging.sendEmail( new Messaging.SingleEmailMessage[] { message } );
        
    }
    
    public Messaging.EmailFileAttachment attachFile(String fileName,String csvContent){
        //Messaging.EmailFileAttachment attach=new Messaging.EmailFileAttachment();
        Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
        csvAttachment.setFileName(fileName);
        csvAttachment.setBody(Blob.valueOf(csvContent));
        csvAttachment.setContentType('text/csv');
        //attach.add(csvAttachment);
        return csvAttachment;
        
    }
    
    global void finish(DataBase.BatchableContext context){
        system.debug('Completed');
    }
    
    global void execute(SchedulableContext sc){
        DataBase.executeBatch(new ABML_ScheduleReportsBatch());
    }

}