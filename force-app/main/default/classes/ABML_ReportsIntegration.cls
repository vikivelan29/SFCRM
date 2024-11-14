/*********************************************************
*@Class        :  ABML_ReportsIntegration
*@Author       :  
*@Created Date :  
*@Last Modified:  
*@description  :  Class for ABML SOA,SOT and Contract Note Report Integration
*********************************************************/
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts')
public with sharing class ABML_ReportsIntegration{
    @AuraEnabled
    public static void getReports(Id caseRecId, string startDate, string endDate, string reportType,string financialYear){ 
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        Case caseRecord = [
            SELECT Id,Business_Unit__c,SuppliedEmail,Client_Code__c FROM Case WHERE Id =: caseRecId];
        string clientCode = caseRecord.Client_Code__c;
        string firmNumber = 'ABM-000001';
        string userName = ABML_Report_Integration__mdt.getInstance('ABML_Report_Credentials').Username__c;                               // 'cllvl';
        string password = ABML_Report_Integration__mdt.getInstance('ABML_Report_Credentials').Password__c; // 'cllvl';
        string startdateSpecified;
        string enddateSpecified;
        string dataString = ABML_Report_Integration__mdt.getInstance('ABML_Report_Credentials').DataString__c; // '192.168.90.21:1822/abm2223';
        String waitingApiResponse  = 'Waiting for API response';
        String pending = 'Pending';
        String success = 'Success';
        String error = 'Error';
        
        if(startDate!=null){
            startdateSpecified = 'true';
        }
        if(endDate!=null){
            enddateSpecified = 'true';
        }
        
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Case__c  = caseRecId;
        caseInt.Business_External_Id__c = 'ABML_Report_Integration';
        caseInt.Status__c = pending; 
        if(reportType=='Statement Of Account'){
            caseInt.Request__c  =  JSON.serialize(new ReportRequestWrapper(clientCode,startDate,startdateSpecified,endDate,enddateSpecified,userName,password,dataString,firmNumber,financialYear,'StatementOfAccount'));
        }
        if(reportType=='Statement Of Transaction'){
            caseInt.Request__c  =  JSON.serialize(new ReportRequestWrapper(clientCode,startDate,startdateSpecified,endDate,enddateSpecified,userName,password,dataString,firmNumber,financialYear,'StatementOfTransaction'));
        }
        if(reportType=='Contract Note'){
            caseInt.Request__c  =  JSON.serialize(new ReportRequestWrapper(clientCode,startDate,startdateSpecified,endDate,enddateSpecified,userName,password,dataString,firmNumber,financialYear,'ContractNote','0','false'));
        }
        caseInt.Response__c = waitingApiResponse;
        if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
            insert caseInt;
        }
        
        ASF_Case_Integration__c caseInt1 = [Select id, name,Status__c from ASF_Case_Integration__c where id =: caseInt.Id ];
        
        Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
        caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
        caseIntOut.Case_Integration_ID__c = caseInt1.Name;
        if(reportType=='Statement Of Account'){
            caseIntOut.Integration_Name__c  ='StatementOfAccount';
        }
        if(reportType=='Statement Of Transaction'){
            caseIntOut.Integration_Name__c  ='StatementOfTransaction';
        }
        if(reportType=='Contract Note'){
            caseIntOut.Integration_Name__c  ='ContractNote';
        }
        if(reportType=='Statement Of Account'){
            caseIntOut.Request_Payload__c  =  JSON.serialize(new ReportRequestWrapper(clientCode,startDate,startdateSpecified,endDate,enddateSpecified,userName,password,dataString,firmNumber,financialYear,'StatementOfAccount'));
        }
        if(reportType=='Statement Of Transaction'){
            caseIntOut.Request_Payload__c  =  JSON.serialize(new ReportRequestWrapper(clientCode,startDate,startdateSpecified,endDate,enddateSpecified,userName,password,dataString,firmNumber,financialYear,'StatementOfTransaction'));
        }
        if(reportType=='Contract Note'){
            caseIntOut.Request_Payload__c  =  JSON.serialize(new ReportRequestWrapper(clientCode,startDate,startdateSpecified,endDate,enddateSpecified,userName,password,dataString,firmNumber,financialYear,'ContractNote','0','false'));
        }
        Database.SaveResult publishResult = EventBus.publish(caseIntOut);
        if(publishResult.isSuccess()){
            result.status = success;
            system.debug('status >>> '+result.status);
            result.response = Custom_Messages__mdt.getInstance('SOA_RUN_SUCCESS').Message__c;
            system.debug('response >>> '+result.response);
            system.debug('publishResult >>> '+publishResult);
        }else{
            result.status = error;
        }   
    }
    
    public static void sendEmailAttachments(List<ASF_Case_Integration__c> asfCaseIntList){
        set<Id> caserecords = new set<Id>();
        set<Id> asfRecordsIDs = new set<Id>();
        if(!asfCaseIntList.isEmpty()){
            for(ASF_Case_Integration__c aCase : asfCaseIntList){
                caserecords.add(aCase.Case__c);
                asfRecordsIDs.add(aCase.Id);
            }
        }
        
        Map<Id,Case> caserecordsMap = new Map<Id,Case>();
        List<Case> caseRecordList = [Select Id,Business_Unit__c,SuppliedEmail from Case where ID IN :caserecords];
        if(!caseRecordList.isEmpty()){
            for(Case caserec :caseRecordList){
                if(caserec.Business_Unit__c=='ABML' && caserec.SuppliedEmail != null){
                    caserecordsMap.put(caserec.Id,caserec);
                }
            }
        }
        Map<Id,ContentVersion> newContentMap = new Map<Id,ContentVersion>();
        List<ContentVersion> contRecords = [select Id,FirstPublishLocationId,Title,VersionData from ContentVersion where FirstPublishLocationId IN :asfRecordsIDs];
        if(!contRecords.isEmpty()){
            for(ContentVersion c2:contRecords){
                if(c2.FirstPublishLocationId != null && c2.Title != null){
                    newContentMap.put(c2.FirstPublishLocationId,c2);  
                }
            }
        }
        OrgWideEmailAddress[] owea = [select Id,DisplayName,Address from OrgWideEmailAddress where DisplayName =:System.Label.ASF_default_no_reply_email_address];
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        if(!owea.isEmpty() && !asfCaseIntList.isEmpty()){
            for (ASF_Case_Integration__c asfCaseRec2 : asfCaseIntList) {
                if (asfCaseRec2.Status__c == 'Success' && caserecordsMap.containsKey(asfCaseRec2.Case__c) && newContentMap.containskey(asfCaseRec2.Id)) {
                    
                    // Get the associated case record
                    Case caseRecord = caserecordsMap.get(asfCaseRec2.Case__c);
                    
                    // Check if the case record and email are not null
                    if (caseRecord != null && caseRecord.SuppliedEmail != null) {
                        email.setToAddresses(new String[] { caseRecord.SuppliedEmail });
                        email.setSubject('Email with File Attachment');
                        email.setPlainTextBody('Please find the attached file.');
                        email.setOrgWideEmailAddressId(owea.get(0).Id);
                        
                        // Create the attachment
                        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                        Blob versionData1 = newContentMap.get(asfCaseRec2.Id).VersionData;
                        attachment.setBody(versionData1);
                        attachment.setFileName(newContentMap.get(asfCaseRec2.Id).Title);
                        attachment.setContentType('application/pdf');
                        email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });    
                    } else {
                        System.debug('Case record or email address is null for Case ID: ' + asfCaseRec2.Case__c);
                    }
                    ABCL_IntegrationCommonUtility.transferAttachments(asfCaseRec2);
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
        //public String souce = ABHFL_Constants.SOA_SOURCE;
        //public String requestType = ABHFL_Constants.SOA_REQUEST_TYPE;
        public String reportName;
        //public String documentType = ABHFL_Constants.SOA_DOCUMENT_TYPE;
        
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
}