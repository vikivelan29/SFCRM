/******************************************************  
* Author           - Dinoy Pauly
* Date             - 08-November-2024
* Description      - Batch class for sending reports to external customers
********************************************************
*/
global with sharing class ABML_ScheduleReportsBatch implements Schedulable, Database.Batchable<sObject> {
    
    global Database.QueryLocator start(DataBase.BatchableContext context){         
        String strLob = System.Label.ABML_BU;
        String query = 'SELECT Type_Text__c, Sub_Type_Text__c, Assigned_Team__c, Owner.Name, Account.Name, Subject, CreatedDate, CaseNumber, Client_Code__c, ABML_Case_Detail__c, ';
        query +=  'Description, Account.PersonDepartment, Account.Type, Nature__c, ABML_Case_Detail__r.Name, ABML_Case_Detail__r.TAT_Deadline_Date__c, Pending_Clarification__c, ';
        query += 'Account.Client_Code__c, Account.ABML_Broker_Code__pc, Account.ABML_Agent_Code__pc, Account.ABML_Branch_Code__c, Account.ABML_Franchisee_Code__c, Recategorisation_Date__c,Account.ABML_Contact_Type__c,Ageing_Number_Of_Days__c, ';
        query += 'ABML_Case_Detail__r.TAT_Days__c, ABML_Case_Detail__r.Assigned_User__r.Name , Ageing_Business_Days__c FROM Case Where Business_Unit__c =: strLob';
        return Database.getQueryLocator(query);
    }
    
    global void execute(DataBase.BatchableContext context,List<Case> scope){
        
        String firstCsvHeader = 'Client Code,Broker Code,Agent Code,Branch Code,Franchisee Code,Type,Sub Type,Assigned Team,Contact Type,Description,Nature,Case Number,Account Name,Case Owner\n';
        String secondCsvHeader ='Client Code,Broker Code,Agent Code,Branch Code,Franchisee Code,Nature,Case Owner, Account Name, Subject, Date/Time Opened,Case Number,Description,Type,Sub Type,ABML Case Detail Name\n';
        String thirdCsvHeader ='Case Number,Type,Sub Type,Case Owner,Description,Contact Type,TAT Deadline,TAT Days,Nature,Recategorisation Date,Created Date\n';
        String fourthCsvHeader ='Client Code,Broker Code,Agent Code,Branch Code,Franchisee Code,ABML Case Detail Name,Contact Type,Nature,Type,Sub Type,Ageing(No of Days),Case Number,Description,Case Owner,Created Date\n';        
        
        String firstCsvBody = '';
        String secondCsvBody = '';
        String thirdCsvBody = '';
        String fourthCsvBody = '';
        
        String departmentPendency = 'ABML Department Pendency.csv';
        String totalTat = 'ABML Cases With Todays TAT Deadline.csv';
        String missedTat = 'ABML Missed TAT.csv';
        String agingCases = 'ABML Aging Cases of the Day Per Agent.csv';
        
        List<String> listOfToAddress = new List<String>();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        List<Messaging.EmailFileAttachment> listOfAttachment = new List<Messaging.EmailFileAttachment>();
        
        for(ABML_Daily_Report_Sender__c objReportSender : [Select Email__c from ABML_Daily_Report_Sender__c])
        {
             listOfToAddress.add(objReportSender.Email__c);
        }        
      
        for (Case objCase : scope) {
            firstCsvBody += '"' + (objCase.Account.Client_Code__c != null ? objCase.Account.Client_Code__c : '') + '","' 
            + (objCase.Account.ABML_Broker_Code__pc != null ? objCase.Account.ABML_Broker_Code__pc : '') + '","'
            + (objCase.Account.ABML_Agent_Code__pc != null ? objCase.Account.ABML_Agent_Code__pc : '') + '","'
            + (objCase.Account.ABML_Branch_Code__c != null ? objCase.Account.ABML_Branch_Code__c : '') + '","'
            + (objCase.Account.ABML_Franchisee_Code__c != null ? objCase.Account.ABML_Franchisee_Code__c : '') + '","'
            + (objCase.Type_Text__c != null ? objCase.Type_Text__c : '') + '","' 
            + (objCase.Sub_Type_Text__c != null ? objCase.Sub_Type_Text__c : '') + '","'
            + (objCase.Assigned_Team__c != null ? objCase.Assigned_Team__c : '') + '","'
            + (objCase.Account.ABML_Contact_Type__c != null ? objCase.Account.ABML_Contact_Type__c : '') + '","'
            + (objCase.Description != null ? objCase.Description : '') + '","' 
            + (objCase.Nature__c != null ? objCase.Nature__c : '') + '","'
            + (objCase.CaseNumber != null ? String.valueOf(objCase.CaseNumber) : '') + '","'
            + (objCase.Account.Name != null ? objCase.Account.Name : '') + '","'
            + (objCase.Owner.Name != null ? objCase.Owner.Name : '') + '"\n';
            
            secondCsvBody += '"' + (objCase.Owner != null && objCase.Owner.Name != null ? objCase.Owner.Name : '') + '","'
            + (objCase.Account.Client_Code__c != null ? objCase.Account.Client_Code__c : '') + '","' 
            + (objCase.Account.ABML_Broker_Code__pc != null ? objCase.Account.ABML_Broker_Code__pc : '') + '","'
            + (objCase.Account.ABML_Agent_Code__pc != null ? objCase.Account.ABML_Agent_Code__pc : '') + '","'
            + (objCase.Account.ABML_Branch_Code__c != null ? objCase.Account.ABML_Branch_Code__c : '') + '","'
            + (objCase.Account.ABML_Franchisee_Code__c != null ? objCase.Account.ABML_Franchisee_Code__c : '') + '","'
            + (objCase.Account.Name != null ? objCase.Account.Name : '') + '","'
            + (objCase.Subject != null ? objCase.Subject : '') + '","'
            + objCase.CreatedDate + '","'
            + (objCase.CaseNumber != null ? String.valueOf(objCase.CaseNumber) : '') + '","'
            + (objCase.Description != null ? objCase.Description : '') + '","'
            + (objCase.Type_Text__c != null ? objCase.Type_Text__c : '') + '","'
            + (objCase.Sub_Type_Text__c != null ? objCase.Sub_Type_Text__c : '') + '","'
            + (objCase.ABML_Case_Detail__r.Name != null ? objCase.ABML_Case_Detail__r.Name : '') + '"\n';
            
            thirdCsvBody += '"' + (objCase.CaseNumber != null ? String.valueOf(objCase.CaseNumber) : '') + '","'
            + (objCase.Type_Text__c != null ? objCase.Type_Text__c : '') + '","'
            + (objCase.Sub_Type_Text__c != null ? objCase.Sub_Type_Text__c : '') + '","'
            + (objCase.Owner.Name != null ? objCase.Owner.Name : '') + '","'
            + (objCase.Description != null ? objCase.Description : '') + '","'
            + (objCase.Account.ABML_Contact_Type__c != null ? objCase.Account.ABML_Contact_Type__c : '') + '","'
            + (objCase.ABML_Case_Detail__r.TAT_Deadline_Date__c != null ? objCase.ABML_Case_Detail__r.TAT_Deadline_Date__c : '') + '","'
            + (objCase.ABML_Case_Detail__r.TAT_Days__c != null ? objCase.ABML_Case_Detail__r.TAT_Days__c : '') + '","'
            + (objCase.Nature__c != null ? objCase.Nature__c : '') + '","'
            + objCase.Recategorisation_Date__c + '","'
            + objCase.CreatedDate + '"\n';
            
            fourthCsvBody += '"' + (objCase.Account.Client_Code__c != null ? objCase.Account.Client_Code__c : '') + '","' 
            + (objCase.Account.ABML_Broker_Code__pc != null ? objCase.Account.ABML_Broker_Code__pc : '') + '","'
            + (objCase.Account.ABML_Agent_Code__pc != null ? objCase.Account.ABML_Agent_Code__pc : '') + '","'
            + (objCase.Account.ABML_Branch_Code__c != null ? objCase.Account.ABML_Branch_Code__c : '') + '","'
            + (objCase.Account.ABML_Franchisee_Code__c != null ? objCase.Account.ABML_Franchisee_Code__c : '') + '","'
            + (objCase.ABML_Case_Detail__r.Name != null ? objCase.ABML_Case_Detail__r.Name : '') + '","'
            + (objCase.Account.ABML_Contact_Type__c != null ? objCase.Account.ABML_Contact_Type__c : '') + '","'
            + (objCase.Nature__c != null ? objCase.Nature__c : '') + '","'
            + (objCase.Type_Text__c != null ? objCase.Type_Text__c : '') + '","'
            + (objCase.Sub_Type_Text__c != null ? objCase.Sub_Type_Text__c : '') + '","'
            + (objCase.Ageing_Number_Of_Days__c != null ? String.valueOf(objCase.Ageing_Number_Of_Days__c) : '') + '","' 
            + (objCase.CaseNumber != null ? String.valueOf(objCase.CaseNumber) : '') + '","'
            + (objCase.Description != null ? objCase.Description : '') + '","'
            + (objCase.Owner.Name != null ? objCase.Owner.Name : '') + '","'
            + objCase.CreatedDate +'"\n';
        }
        
        String firstCsvContent = firstCsvHeader + firstCsvBody;
        String secondCsvContent = secondCsvHeader + secondCsvBody;
        String thirdCsvContent = thirdCsvHeader + thirdCsvBody;        
        String fourthCsvContent = fourthCsvHeader + fourthCsvBody;
        
        //BUSpecificAutoEmailMapping__mdt mdt = [Select Business_Unit__c,Default_Automated_Email_From_Address__c from BUSpecificAutoEmailMapping__mdt where Business_Unit__c=:System.Label.ABML_BU LIMIT 1];
        OrgWideEmailAddress orgWideEmail = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress where DisplayName =: System.Label.ASF_default_no_reply_email_address LIMIT 1];//    where Address =:mdt.Default_Automated_Email_From_Address__c        
       
        Messaging.EmailFileAttachment firstAttachment = createAttachment(departmentPendency, firstCsvContent);
        Messaging.EmailFileAttachment secondAttachment = createAttachment(totalTat, secondCsvContent);
        Messaging.EmailFileAttachment thirdAttachment = createAttachment(missedTat, thirdCsvContent);
        Messaging.EmailFileAttachment fourthAttachment = createAttachment(agingCases, fourthCsvContent);
        listOfAttachment.add(firstAttachment);
        listOfAttachment.add(secondAttachment);
        listOfAttachment.add(thirdAttachment);
        listOfAttachment.add(fourthAttachment);
        
        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
        emailMessage.setFileAttachments(listOfAttachment);  
        emailMessage.setSubject('Daily Status Report - ' + System.Today());
        emailMessage.setorgWideEmailAddressId(orgWideEmail.Id);
        emailMessage.setPlainTextBody('Please find the reports attached.');    
        emailMessage.setToAddresses(listOfToAddress);
       
        emailList.add(emailMessage);
        
        Messaging.SendEmailResult[] res;
        if (emailList != null && emailList.size() > 0) 
        {
            res = Messaging.sendEmail(emailList);
        }  
    }
    
    public Messaging.EmailFileAttachment createAttachment(String fileName, String csvContent){
        Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
        csvAttachment.setFileName(fileName);
        csvAttachment.setBody(Blob.valueOf(csvContent));
        csvAttachment.setContentType('text/csv');
        return csvAttachment;
    }
    
    global void finish(DataBase.BatchableContext context){
        system.debug('Completed');
    }
    
    global void execute(SchedulableContext sc){
        DataBase.executeBatch(new ABML_ScheduleReportsBatch());
    }

}
