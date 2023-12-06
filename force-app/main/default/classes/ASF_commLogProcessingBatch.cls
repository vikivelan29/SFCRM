public class ASF_commLogProcessingBatch implements Database.Batchable<sObject>,Schedulable {
    public string strQuery = '';
    public ASF_commLogProcessingBatch(){
        //default constructor
        this.strQuery = '';
    }
    public ASF_commLogProcessingBatch(String qry){
        this.strQuery = qry;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        System.debug(this.strQuery);
        if(String.isNotBlank(this.strQuery)){
            return Database.getQueryLocator(strQuery);
        }
        else{
            return Database.getQueryLocator([SELECT ID,RecordID__c,CustomMetadataName__c,Case__c,AccountId__c,ContactId__c,Email_Template_Name__c,
                                             SMS_Template_Dev_Name__c ,WhatsApp_Template_Dev_Name__c,Status__c  FROM PE_Logger__c WHERE Status__c='Processing' AND CreatedDate = Today ORDER BY CreatedDate ASC]);
        }
    }
    public void execute(Database.BatchableContext bc, List<PE_Logger__c> scope){
        Map<Id,String> mCaseVsCustomMetadata = new Map<Id,String>();
        Map<Id,Set<Pe_logger__c>> mCaseIdPELoggers = new Map<Id,Set<PE_Logger__c>>();
        List<PE_Logger__c> temp_Update = new List<PE_Logger__c>();
        Map<Id,PE_Logger__c> mIncomingScopeIds = new Map<Id,PE_Logger__c>(scope); // Just to get the PE_Logger__c Id coming from Scope variable.
        
        // Get the latest Status of PE_Logger__c record, if during the start and execute method, if the status is changed, don't process PE_Logger__c record.
        Map<Id,PE_Logger__c> mPELoggerLatestStatus = new Map<Id,PE_Logger__c>([SELECT ID,RecordID__c,CustomMetadataName__c,Case__c,AccountId__c,ContactId__c,Email_Template_Name__c,
                                             SMS_Template_Dev_Name__c ,WhatsApp_Template_Dev_Name__c,Status__c FROM PE_Logger__c WHERE Id =: mIncomingScopeIds.keySet()]);
        
        
        List<PE_Logger__c> toProcessingClass = new List<PE_Logger__c>();
        List<PE_Logger__c> updPELoggerStatus = new List<PE_Logger__c>();
        
        for(PE_Logger__c p : scope){
            if(mPELoggerLatestStatus.containsKey(p.Id)){
                if(mPELoggerLatestStatus.get(p.Id).Status__c == 'Processing'){
                    toProcessingClass.add(mPELoggerLatestStatus.get(p.Id));
                }
            }
        }
        
        if(toProcessingClass.size()>0){
            Map<Id,ASF_CommPETriggerHelper.responseWrapper> results = ASF_CommPETriggerHelper.executeContructor(toProcessingClass);
            for(Id pLogId : results.keySet()){
                PE_Logger__c peL = new PE_Logger__c(Id=pLogId);
                if(results.get(pLogId).status == 'Success'){
                    peL.status__c = 'Completed'; 
                    peL.retry_PE__c=false;
                }
                else if(results.get(pLogId).status == 'Error'){
                    peL.Status__c = 'Error';
                    peL.Error_Message__c = results.get(pLogId).message;
                    peL.Retry_Time__c = DateTime.now().addMinutes(15);
                    peL.retry_PE__c=true;
                }
                else{
                    peL.Retry_Time__c = DateTime.now().addMinutes(15);
                    peL.retry_PE__c=true;                                 
                }
                updPELoggerStatus.add(peL);
            }
            
        }
        
        if(updPELoggerStatus.size()>0){
                Database.SaveResult[] results = Database.update(updPELoggerStatus,false);
            }
    }
    public void finish(Database.BatchableContext bc){
        
    }
    
    public void execute(SchedulableContext sc){
        if(String.isNotBlank(this.strQuery)){
            Database.executeBatch(new ASF_commLogProcessingBatch(this.strQuery),1);
        }
        else{
            Database.executeBatch(new ASF_commLogProcessingBatch(),1);
        }
        
    }
}