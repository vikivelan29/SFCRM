/******************************************************  
* Author           - Dinoy Pauly
* Date             - 08-November-2024
* Description      - Batch class for sending reports to external customers
********************************************************
*/
global with sharing class ABML_ScheduleReportsBatch implements Schedulable, Database.Batchable<sObject>, Database.Stateful {
    
//        List<Messaging.EmailFileAttachment> listOfAttachment = new List<Messaging.EmailFileAttachment>();
    
            String firstCsvBody = '';
        String secondCsvBody = '';
        String thirdCsvBody = '';
        String fourthCsvBody = '';
        
      
    
    global Database.QueryLocator start(DataBase.BatchableContext context){         
        String strLob = System.Label.ABML_BU;
        String closeCaseStatus = 'Closed';
        String resolveCaseStatus = 'Resolved';
        String query = 'SELECT createdBy.Name, Assigned_Team__c, Status, Ageing_Number_Of_Days__c, Source__c,Sub_Source__c, Categorization_Date__c, Stage_SLA_1__c, Type_Text__c, Sub_Type_Text__c, Owner.Name, Account.Name, Subject, CreatedDate, CaseNumber, Client_Code__c, ABML_Case_Detail__c, ';
        query +=  'Description, Account.PersonDepartment, Account.Type, Nature__c, ABML_Case_Detail__r.Name, ABML_Case_Detail__r.TAT_Deadline_Date__c, Pending_Clarification__c, ';
        query += 'Account.Client_Code__c, Account.ABML_Broker_Code__pc, Account.ABML_Agent_Code__pc, Account.ABML_Branch_Code__c, Account.ABML_Franchisee_Code__c, Recategorisation_Date__c,Account.ABML_Contact_Type__c, ';
        query += 'ABML_Case_Detail__r.TAT_Days__c, ABML_Case_Detail__r.Assigned_User__r.Name , Ageing_Business_Days__c, Overall_Case_Closure_SLA__c FROM Case Where Business_Unit__c =: strLob AND (Status !=: closeCaseStatus OR Status !=: resolveCaseStatus)';
        return Database.getQueryLocator(query);
    }
    
    global void execute(DataBase.BatchableContext context,List<Case> scope){
                
        Map<String, Integer> mapOfStageTatHours = new Map<String, Integer>();
        Set<String> setOfCaseType = new Set<String>();
        Set<String> setOfCaseSubType = new Set<String>();
        
        for (Case objCase : scope) {
            setOfCaseType.add(objCase.Type_Text__c);
            setOfCaseSubType.add(objCase.Sub_Type_Text__c);
        }
        for(ASF_Case_Stage_Config__c objStageConfig : [Select Id, Stage_SLA_1__c, Case_Category_Config__r.Type__c, Case_Category_Config__r.Sub_Type__c, Order__c from ASF_Case_Stage_Config__c where Case_Category_Config__r.Business_Unit__c = 'ABML' AND Case_Category_Config__r.Type__c IN: setOfCaseType AND Case_Category_Config__r.Sub_Type__c IN: setOfCaseSubType AND Order__c = 1]){
            String uniqueIdentifier = objStageConfig.Case_Category_Config__r.Type__c + '#+' + objStageConfig.Case_Category_Config__r.Sub_Type__c;
            mapOfStageTatHours.put(uniqueIdentifier, (Integer)objStageConfig.Stage_SLA_1__c);
        }
        
        for (Case objCase : scope) {
            
            String uniqueStr = objCase.Type_Text__c + '#+' +  objCase.Sub_Type_Text__c;
            Integer tatHours;
            
            if(mapOfStageTatHours.containsKey(uniqueStr)){
                tatHours = mapOfStageTatHours.get(uniqueStr);
            }
            //department pendency
            firstCsvBody += '"' + (objCase.CaseNumber != null ? objCase.CaseNumber : '') + '","' 
                + (objCase.Account.Client_Code__c != null ? objCase.Account.Client_Code__c : '') + '","'
                + (objCase.Account.Name != null ? objCase.Account.Name : '') + '","'
                + (objCase.Account.ABML_Branch_Code__c != null ? objCase.Account.ABML_Branch_Code__c : '') + (objCase.Account.ABML_Franchisee_Code__c != null ? objCase.Account.ABML_Franchisee_Code__c : '') + '","'
                + (objCase.Account.Name != null ? objCase.Account.Name : '') + '","'
                + (objCase.Account.ABML_Contact_Type__c != null ? objCase.Account.ABML_Contact_Type__c : '') + '","'
                + objCase.createddate + '","' 
                + (objCase.Categorization_Date__c != null ? String.valueOf(objCase.Categorization_Date__c) : '') + '","'
                + objCase.createdBy.Name + '","'
                + (objCase.Source__c != null ? String.valueOf(objCase.Source__c) : '') + '","'
                + (objCase.Sub_Source__c != null ? String.valueOf(objCase.Sub_Source__c) : '') + '","'
                + (objCase.Nature__c != null ? objCase.Nature__c : '') + '","'
                + (objCase.Subject != null ? objCase.Subject : '') + '","' 
                + (objCase.Type_Text__c != null ? objCase.Type_Text__c : '') + '","'
                + (objCase.Sub_Type_Text__c != null ? String.valueOf(objCase.Sub_Type_Text__c) : '') + '","'
                + (objCase.Status != null ? objCase.Status : '') + '","'
                + (tatHours != null ? String.valueOf(tatHours) : '') + '","'
                + (objCase.Stage_SLA_1__c != null ? String.valueOf(objCase.Stage_SLA_1__c) : '') + '","'
                + (objCase.OwnerId != null ? objCase.Owner.Name : '') + '","'
                + (objCase.Assigned_Team__c != null ? objCase.Assigned_Team__c : '') + '","'
                 + (objCase.Ageing_Number_Of_Days__c != null ? String.valueOf(objCase.Ageing_Number_Of_Days__c) : '') + '"\n';            
            Date tatDate = Date.valueOf(objCase.Stage_SLA_1__c);
            
            //today tat
            if(tatDate == System.Today()){
                secondCsvBody += '"' + (objCase.CaseNumber != null ? objCase.CaseNumber : '') + '","' 
                + (objCase.Account.Client_Code__c != null ? objCase.Account.Client_Code__c : '') + '","'
                + (objCase.Account.Name != null ? objCase.Account.Name : '') + '","'
                + (objCase.Account.ABML_Branch_Code__c != null ? objCase.Account.ABML_Branch_Code__c : '') + (objCase.Account.ABML_Franchisee_Code__c != null ? objCase.Account.ABML_Franchisee_Code__c : '') + '","'
                + (objCase.Account.Name != null ? objCase.Account.Name : '') + '","'
                + (objCase.Account.ABML_Contact_Type__c != null ? objCase.Account.ABML_Contact_Type__c : '') + '","'
                + objCase.createddate + '","' 
                + (objCase.Categorization_Date__c != null ? String.valueOf(objCase.Categorization_Date__c) : '') + '","'
                + objCase.createdBy.Name + '","'
                + (objCase.Source__c != null ? String.valueOf(objCase.Source__c) : '') + '","'
                + (objCase.Sub_Source__c != null ? String.valueOf(objCase.Sub_Source__c) : '') + '","'
                + (objCase.Nature__c != null ? objCase.Nature__c : '') + '","'
                + (objCase.Subject != null ? objCase.Subject : '') + '","' 
                + (objCase.Type_Text__c != null ? objCase.Type_Text__c : '') + '","'
                + (objCase.Sub_Type_Text__c != null ? String.valueOf(objCase.Sub_Type_Text__c) : '') + '","'
                + (objCase.Status != null ? objCase.Status : '') + '","'
                + (tatHours != null ? String.valueOf(tatHours) : '') + '","'
                + (objCase.Stage_SLA_1__c != null ? String.valueOf(objCase.Stage_SLA_1__c) : '') + '","'
                + (objCase.OwnerId != null ? objCase.Owner.Name : '') + '","'
                + (objCase.Assigned_Team__c != null ? objCase.Assigned_Team__c : '') + '","'
                 + (objCase.Ageing_Number_Of_Days__c != null ? String.valueOf(objCase.Ageing_Number_Of_Days__c) : '') + '"\n';
            }
            
          //missed tat
            if(objCase.Stage_SLA_1__c < System.Now()){
                thirdCsvBody += '"' + (objCase.CaseNumber != null ? objCase.CaseNumber : '') + '","' 
                + (objCase.Account.Client_Code__c != null ? objCase.Account.Client_Code__c : '') + '","'
                + (objCase.Account.Name != null ? objCase.Account.Name : '') + '","'
                + (objCase.Account.ABML_Branch_Code__c != null ? objCase.Account.ABML_Branch_Code__c : '') + (objCase.Account.ABML_Franchisee_Code__c != null ? objCase.Account.ABML_Franchisee_Code__c : '') + '","'
                + (objCase.Account.Name != null ? objCase.Account.Name : '') + '","'
                + (objCase.Account.ABML_Contact_Type__c != null ? objCase.Account.ABML_Contact_Type__c : '') + '","'
                + objCase.createddate + '","' 
                + (objCase.Categorization_Date__c != null ? String.valueOf(objCase.Categorization_Date__c) : '') + '","'
                + objCase.createdBy.Name + '","'
                + (objCase.Source__c != null ? String.valueOf(objCase.Source__c) : '') + '","'
                + (objCase.Sub_Source__c != null ? String.valueOf(objCase.Sub_Source__c) : '') + '","'
                + (objCase.Nature__c != null ? objCase.Nature__c : '') + '","'
                + (objCase.Subject != null ? objCase.Subject : '') + '","' 
                + (objCase.Type_Text__c != null ? objCase.Type_Text__c : '') + '","'
                + (objCase.Sub_Type_Text__c != null ? String.valueOf(objCase.Sub_Type_Text__c) : '') + '","'
                + (objCase.Status != null ? objCase.Status : '') + '","'
                + (tatHours != null ? String.valueOf(tatHours) : '') + '","'
                + (objCase.Stage_SLA_1__c != null ? String.valueOf(objCase.Stage_SLA_1__c) : '') + '","'
                + (objCase.OwnerId != null ? objCase.Owner.Name : '') + '","'
                + (objCase.Assigned_Team__c != null ? objCase.Assigned_Team__c : '') + '","'
                 + (objCase.Ageing_Number_Of_Days__c != null ? String.valueOf(objCase.Ageing_Number_Of_Days__c) : '') + '"\n';
            }
            
            //ageing
            fourthCsvBody += '"' + (objCase.CaseNumber != null ? objCase.CaseNumber : '') + '","' 
                + (objCase.Account.Client_Code__c != null ? objCase.Account.Client_Code__c : '') + '","'
                + (objCase.Account.Name != null ? objCase.Account.Name : '') + '","'
                + (objCase.Account.ABML_Branch_Code__c != null ? objCase.Account.ABML_Branch_Code__c : '') + (objCase.Account.ABML_Franchisee_Code__c != null ? objCase.Account.ABML_Franchisee_Code__c : '') + '","'
                + (objCase.Account.Name != null ? objCase.Account.Name : '') + '","'
                + (objCase.Account.ABML_Contact_Type__c != null ? objCase.Account.ABML_Contact_Type__c : '') + '","'
                + objCase.createddate + '","' 
                + (objCase.Categorization_Date__c != null ? String.valueOf(objCase.Categorization_Date__c) : '') + '","'
                + objCase.createdBy.Name + '","'
                + (objCase.Source__c != null ? String.valueOf(objCase.Source__c) : '') + '","'
                + (objCase.Sub_Source__c != null ? String.valueOf(objCase.Sub_Source__c) : '') + '","'
                + (objCase.Nature__c != null ? objCase.Nature__c : '') + '","'
                + (objCase.Subject != null ? objCase.Subject : '') + '","' 
                + (objCase.Type_Text__c != null ? objCase.Type_Text__c : '') + '","'
                + (objCase.Sub_Type_Text__c != null ? String.valueOf(objCase.Sub_Type_Text__c) : '') + '","'
                + (objCase.Status != null ? objCase.Status : '') + '","'
                + (tatHours != null ? String.valueOf(tatHours) : '') + '","'
                + (objCase.Stage_SLA_1__c != null ? String.valueOf(objCase.Stage_SLA_1__c) : '') + '","'
                + (objCase.OwnerId != null ? objCase.Owner.Name : '') + '","'
                + (objCase.Assigned_Team__c != null ? objCase.Assigned_Team__c : '') + '","'
                 + (objCase.Ageing_Number_Of_Days__c != null ? String.valueOf(objCase.Ageing_Number_Of_Days__c) : '') + '"\n';
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
        
        String departmentPendency = 'ABML Department Pendency.csv';
        String totalTat = 'ABML Cases With Todays TAT Deadline.csv';
        String missedTat = 'ABML Missed TAT.csv';
        String agingCases = 'ABML Aging Cases of the Day Per Agent.csv';
        List<Messaging.EmailFileAttachment> listOfAttachment = new List<Messaging.EmailFileAttachment>();   
        String csvHeader = 'Case Number,Client Code,Client Name,Branch/Franchisee code,Branch/Franchisee Name,Contact Type,Created on,Categorized on,Created By,Source,Sub-Source,Nature,Subject,Case Type,Sub Type,Status,TAT HRS SLA 1,TAT Date SLA 1,Case Owner,Assigned Team,Ageing(No of Days)\n';
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        List<String> listOfToAddress = new List<String>();
        for(ABML_Daily_Report_Sender__c objReportSender : [Select Email__c from ABML_Daily_Report_Sender__c where Name!='ordWideAddress'])
        {
            listOfToAddress.add(objReportSender.Email__c);
        }   
        ABML_Daily_Report_Sender__c objReportSender = [SELECT Email__c from ABML_Daily_Report_Sender__c WHERE Name = 'ordWideAddress' LIMIT 1];
        OrgWideEmailAddress orgWideEmail = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address =:objReportSender.Email__c  LIMIT 1];
        String firstCsvContent = csvHeader + firstCsvBody;
        String secondCsvContent = csvHeader + secondCsvBody;
        String thirdCsvContent = csvHeader + thirdCsvBody;        
        String fourthCsvContent = csvHeader + fourthCsvBody;
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
        if (emailList != null && emailList.size() > 0) 
        {
            res = Messaging.sendEmail(emailList);
        }  
        System.debug('Sent=========');
    }
    
    global void execute(SchedulableContext sc){
        DataBase.executeBatch(new ABML_ScheduleReportsBatch());
    }

}