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
        query += 'ABML_Case_Detail__r.TAT_Days__c, ABML_Case_Detail__r.Assigned_User__r.Name , Ageing_Business_Days__c, Overall_Case_Closure_SLA__c FROM Case Where Business_Unit__c =: strLob';
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
        
        for(ABML_Daily_Report_Sender__c objReportSender : [Select Email__c from ABML_Daily_Report_Sender__c where Name!='ordWideAddress'])
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
            + objCase.Overall_Case_Closure_SLA__c + '","'
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
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>(); 
        
        ABML_Daily_Report_Sender__c objReportSender = [SELECT Email__c from ABML_Daily_Report_Sender__c WHERE Name = 'ordWideAddress' LIMIT 1];
        OrgWideEmailAddress orgWideEmail = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address =:objReportSender.Email__c  LIMIT 1];     
       
        emailList.add(message);
     
        //message.setToAddresses( new String[] { 'dinoypauly8@gmail.com' } );
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