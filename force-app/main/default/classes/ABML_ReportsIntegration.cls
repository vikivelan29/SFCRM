
/*********************************************************
*@Class        :  ABML_ReportsIntegration
*@Author       :  Tanmay Metkar
*@Created Date :  25-October-2024
*@Last Modified:  25-November-2024
*@description  :  Class for ABML SOA,SOT and Contract Note Report Integration
*********************************************************/
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts')
public with sharing class ABML_ReportsIntegration{
    
    @AuraEnabled
    public static void getReports(Id caseRecId, String clientCode, String startDate, String endDate, String reportType, String financialYear){ 
        
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        Case caseRecord = new Case();
        
        if(caseRecId != null){
            caseRecord = [SELECT Id, Business_Unit__c FROM Case WHERE Id =: caseRecId LIMIT 1];
        }
        
        //String clientCode = caseRecord.Client_Code__c != null ? caseRecord.Client_Code__c : '';
         
        String firmNumber = 'ABM-000001';

        String userName = ABML_Report_Integration__mdt.getInstance('ABML_Report_Credentials').Username__c;                              
        String password = ABML_Report_Integration__mdt.getInstance('ABML_Report_Credentials').Password__c; 
        String dataString = ABML_Report_Integration__mdt.getInstance('ABML_Report_Credentials').DataString__c; 
        String waitingApiResponse  = 'Waiting for API response';
        String pending = 'Pending';
        String success = 'Success';
        String error = 'Error';
        
        String startdateSpecified = startDate != null ? 'true' : '';
        String enddateSpecified = endDate != null ? 'true' : '';
        
        
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Case__c  = caseRecId != null ? caseRecId : null;
        caseInt.Business_External_Id__c = 'ABML_Report_Integration';
        caseInt.Status__c = pending; 
        if(reportType == 'Statement Of Account'){
            caseInt.Request__c  =  JSON.serialize(new ReportRequestWrapper(clientCode,startDate,startdateSpecified,endDate,enddateSpecified,userName,password,dataString,firmNumber,financialYear,'StatementOfAccounts'));
        }
        if(reportType == 'Statement Of Transaction'){
            caseInt.Request__c  =  JSON.serialize(new ReportRequestWrapper(clientCode,startDate,startdateSpecified,endDate,enddateSpecified,userName,password,dataString,firmNumber,financialYear,'StatementOfTransaction'));
        }
        if(reportType == 'Contract Note'){
            caseInt.Request__c  =  JSON.serialize(new ReportRequestWrapper(clientCode,startDate,startdateSpecified,endDate,enddateSpecified,userName,password,dataString,firmNumber,financialYear,'ContractNote','0','false'));
        }
        
        caseInt.Response__c = waitingApiResponse;
        
        if(!Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
            return; 
        }
        
        insert caseInt;        
        
        String strAsfName = [Select Id, Name from ASF_Case_Integration__c Where Id =: caseInt.Id].Name;
        Case_Integration_Outbound__e outboundEvent = new Case_Integration_Outbound__e ();
        outboundEvent.Case_Integration_ID__c = strAsfName;        
       
        if(caseRecord.Business_Unit__c != ''){
            outboundEvent.Business_Unit__c  = caseRecord.Business_Unit__c;
        }
        
        if(reportType == 'Statement Of Account'){
            outboundEvent.Integration_Name__c  ='StatementOfAccounts';
            outboundEvent.Request_Payload__c  =  JSON.serialize(new ReportRequestWrapper(clientCode,startDate,startdateSpecified,endDate,enddateSpecified,userName,password,dataString,firmNumber,financialYear,'StatementOfAccounts'));
        }
        
        if(reportType == 'Statement Of Transaction'){
            outboundEvent.Integration_Name__c  ='StatementOfTransaction';
            outboundEvent.Request_Payload__c  =  JSON.serialize(new ReportRequestWrapper(clientCode,startDate,startdateSpecified,endDate,enddateSpecified,userName,password,dataString,firmNumber,financialYear,'StatementOfTransaction'));
        }
        
        if(reportType == 'Contract Note'){
            outboundEvent.Integration_Name__c  ='ContractNote';
            outboundEvent.Request_Payload__c  =  JSON.serialize(new ReportRequestWrapper(clientCode,startDate,startdateSpecified,endDate,enddateSpecified,userName,password,dataString,firmNumber,financialYear,'ContractNote','0','false'));
        }
        
        Database.SaveResult publishResult = EventBus.publish(outboundEvent);
        
        if(publishResult.isSuccess()){
            result.status = success;
            result.response = Custom_Messages__mdt.getInstance('SOA_RUN_SUCCESS').Message__c;
        }
        else{
            result.status = error;
        }   
    }
    
    public static void sendEmailAttachments(List<ASF_Case_Integration__c> asfCaseIntList){    
        Set<Id> caseRecordsIds = new Set<Id>();
        Set<Id> asfRecordIds = new Set<Id>();
        Set<Id> accountRecords = new Set<Id>();
        Map<Id , Case> caseRecordsMap = new Map<Id , Case>();
        Map<Id , ContentVersion> newContentMap = new Map<Id , ContentVersion>();
        Map<Id, Account> accountsMap = new Map<Id, Account>();
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        Id personAccRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('ABML Customer').getRecordTypeId();
        
        if(!asfCaseIntList.isEmpty()){
            for(ASF_Case_Integration__c objAsfCase : asfCaseIntList){
                caseRecordsIds.add(objAsfCase.Case__c);
                asfRecordIds.add(objAsfCase.Id);
            }
        }        
   
        if(!caseRecordsIds.isEmpty()){
            for(Case objCase : [Select Id, Business_Unit__c, AccountId, Customer_name_formula__c, Account.RecordTypeId from Case where ID IN : caseRecordsIds]){
                if(objCase.Business_Unit__c == 'ABML'){
                    caseRecordsMap.put(objCase.Id , objCase);
                    accountRecords.add(objCase.AccountId);
                }
            }
        }
        if(!accountRecords.isEmpty()){
            for(Account accountObj : [Select Id, PersonContactId from Account where ID IN : accountRecords]){
                //if(accountObj.PersonContactId != null){
                    accountsMap.put(accountObj.Id , accountObj);
                    system.debug('accountObj.PersonContactId >>> '+ accountObj.PersonContactId );
                //}
            }
        }        
        if(!asfRecordIds.isEmpty()){
            for(ContentVersion objContentVersion : [Select Id, FirstPublishLocationId, Title, VersionData From ContentVersion Where FirstPublishLocationId IN : asfRecordIds]){
                if(objContentVersion.FirstPublishLocationId != null && objContentVersion.Title != null){
                    newContentMap.put(objContentVersion.FirstPublishLocationId , objContentVersion);  
                }
            }
        }
        //BUSpecificAutoEmailMapping__mdt mdt = [Select Business_Unit__c,Default_Automated_Email_From_Address__c from BUSpecificAutoEmailMapping__mdt where Business_Unit__c=:System.Label.ABML_BU LIMIT 1];
        //OrgWideEmailAddress[] objOrgWideAddresses = [Select Id, DisplayName,Address from OrgWideEmailAddress where DisplayName =: System.Label.ASF_default_no_reply_email_address];//    where Address =:mdt.Default_Automated_Email_From_Address__c
        ABML_Daily_Report_Sender__c objReportSender = [SELECT Email__c from ABML_Daily_Report_Sender__c WHERE Name = 'ordWideAddress' LIMIT 1];
        OrgWideEmailAddress orgWideEmail = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address =:objReportSender.Email__c  LIMIT 1]; 
        // Added for template
        Id templateId1 = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'ABML_Report_Integration_Email_Template_1733123089274' LIMIT 1].Id;
        Id templateId2 = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'ABML_SOT_Email_Template_1733145673611' LIMIT 1].Id;
        Id templateId3 = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'ABML_Contract_Note_Email_Template_1733145822012' LIMIT 1].Id;

        Contact contactRec;
        if(!Test.isRunningtest()){
        	contactRec = [SELECT Id FROM Contact WHERE AccountId=:accountRecords LIMIT 1];
        }
        
        if(!asfCaseIntList.isEmpty()){
            for (ASF_Case_Integration__c objAsfCaseRecord : asfCaseIntList) {
                if (objAsfCaseRecord.Status__c == 'Success' && caseRecordsMap.containsKey(objAsfCaseRecord.Case__c) && newContentMap.containskey(objAsfCaseRecord.Id)){                    
                    // Get the associated case record
                    Case caseRecord = caseRecordsMap.get(objAsfCaseRecord.Case__c);                    
                    // Check if the case record and email are not null
                    if (caseRecord != null) {
                        email.setOrgWideEmailAddressId(orgWideEmail.Id);
                        if(newContentMap.get(objAsfCaseRecord.Id).Title.contains('Statement of Accounts') || newContentMap.get(objAsfCaseRecord.Id).Title.contains('SOA')){
                            email.setTemplateId(templateId1);
                        }
                        if(newContentMap.get(objAsfCaseRecord.Id).Title.contains('Statement of Transaction') || newContentMap.get(objAsfCaseRecord.Id).Title.contains('SOT')){
                            email.setTemplateId(templateId2);
                        }
                        if(newContentMap.get(objAsfCaseRecord.Id).Title.contains('Contract Note') || newContentMap.get(objAsfCaseRecord.Id).Title.contains('Contract')){
                            email.setTemplateId(templateId3);
                        }
                        if(caseRecord.Account.RecordTypeId == personAccRecordType){
                            email.setTargetObjectId(accountsMap.get(caseRecord.AccountId).PersonContactId); 
                        }
                        else{
                            if(contactRec!=null){ 
                                email.setTargetObjectId(contactRec.Id);
                            }
                        }
                        
                        email.setSaveAsActivity(false);
                        email.setWhatId(caseRecord.Id);
                        
                        // Create the attachment
                        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                        Blob emailVersionData = newContentMap.get(objAsfCaseRecord.Id).VersionData;
                        attachment.setBody(emailVersionData);
                        attachment.setFileName(newContentMap.get(objAsfCaseRecord.Id).Title);
                        attachment.setContentType('application/pdf');
                        email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
                    } 
                    else {
                        System.debug('Case record or email address is null for Case ID: ' + objAsfCaseRecord.Case__c);
                    }
                    ABCL_IntegrationCommonUtility.transferAttachments(objAsfCaseRecord);
                }
            }   
            try{    
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });                
            }
            catch (Exception e) {
                // Handle the exception and log the error
                System.debug('Error sending email: ' + e.getMessage());
            }            
        }    
    }    

/****************************************************************************************************************
    *@description - Wrapper class to get all the request parameters
*****************************************************************************************************************/

    public class ReportRequestWrapper{

        public String Clientcode;
        public String StartDate;
        public String StartdateSpecified;
        public String Enddate;
        public String EnddateSpecified;
        public String UserName;
        public String Password;
        public String DataString;
        public String FirmNumber;
        public String FinancialYear;
        public String CommodityMergedContract;
        public String CommodityMergedContractSpecified;
        public String reportName;
        
        ReportRequestWrapper(string Clientcode, String StartDate, string StartdateSpecified, String Enddate, String EnddateSpecified,string UserName, String Password, String DataString, String FirmNumber,string FinancialYear,string reportName, String CommodityMergedContract, String CommodityMergedContractSpecified){
            this.Clientcode = Clientcode;
            this.StartDate = StartDate;
            this.StartdateSpecified = StartdateSpecified;
            this.Enddate = Enddate;
            this.EnddateSpecified = EnddateSpecified;
            this.UserName = UserName;
            this.Password = Password;
            this.DataString = DataString;
            this.FirmNumber = FirmNumber;
            this.FinancialYear = FinancialYear;
            this.reportName = reportName;
            this.CommodityMergedContract = CommodityMergedContract;
            this.CommodityMergedContractSpecified = CommodityMergedContractSpecified;
        }
        ReportRequestWrapper(string Clientcode, String StartDate, string StartdateSpecified, String Enddate, String EnddateSpecified,string UserName, String Password, String DataString, String FirmNumber,string FinancialYear,string reportName){
            this.Clientcode = Clientcode;
            this.StartDate = StartDate;
            this.StartdateSpecified = StartdateSpecified;
            this.Enddate = Enddate;
            this.EnddateSpecified = EnddateSpecified;
            this.UserName = UserName;
            this.Password = Password;
            this.DataString = DataString;
            this.FirmNumber = FirmNumber;
            this.FinancialYear = FinancialYear;
            this.reportName = reportName;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static date getAccountActiveDate(String clientCode){
        Account activeDate = [Select Id,Client_Code__c, Active_Date__c from Account where Client_Code__c =:clientCode limit 1];
        if(activeDate.Active_Date__c!=null){
            return activeDate.Active_Date__c;
        }else{
            return null; 
        }
    }
}