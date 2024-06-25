@SuppressWarnings('PMD.FormalParameterNamingConventions')
public without sharing class ASF_CommPETriggerHandler {
    
    /**Added for Mod Code to divide PE as per reply Id */
    public static Integer intTotalTriggers = 0;
    public static Integer intTriggerNumber = 0;
    
    /**Added for Mod Code to divide PE as per reply Id */
    
    
    public static void executeAfterInsert(List<ASF_CommnunicationLog__e > newList, Final Integer Total_Triggers, 
                                          Final Integer Trigger_Number)
    {
        intTotalTriggers   = Total_Triggers; 
        intTriggerNumber = Trigger_Number; 
        executeAfterInsert(newList);
    }
    private static void executeAfterInsert(List<ASF_CommnunicationLog__e > newList){
        
        Integer counter = 0;
        Integer batchSize = getBatchSize();
        Set<Id> peIds = new Set<Id>();
        Map<integer,Map<String,Set<Id>>> mCaseVsMetadata = new Map<integer,Map<String,Set<Id>>>();
        
        Set<integer> caseCustomMetadata = new Set<integer>();
        Map<Id,Id> mPEIdVsCaseId = new Map<Id,Id>();
        List<PE_Logger__c> subScriberList = new List<PE_Logger__c>();
        List<PE_Logger__c> peLoggerList = new List<PE_Logger__c>();
        List<PE_Logger__c> allPeLoggerList = new List<PE_Logger__c>();
        Map<String, List<PE_Logger__c>> mSObjectVsLoggerList = new Map<String,List<PE_Logger__c>>();
        
        
        
        for(ASF_CommnunicationLog__e  event : newList){
            if(math.mod(Integer.valueOf(event.replayId), intTotalTriggers) == intTriggerNumber -1){
                // Condition satisfied by Event Records.
                if(counter < batchSize){
                    String tempCompositeKey = event.RecordID__c+'_'+event.CustomMetadataName__c;
                    integer tempCompositeKeyHashCode = tempCompositeKey.hashCode();
                    
                    if(String.isNotBlank(event.PELoggerId__c)){
                        Id temp_peId = event.PELoggerId__c;
                        if(temp_peId != null){
                            peIds.add(temp_peId);
                        }
                    }
                    Id idRecordId = Id.ValueOf(event.RecordID__c);
                    if(idRecordId.getSobjectType() == Case.sObjectType || idRecordId.getSobjectType() == Account.sObjectType){
                        if(!mCaseVsMetadata.containsKey(tempCompositeKeyHashCode)){
                            //mCaseVsMetadata.put(tempCompositeKeyHashCode,event.CustomMetadataName__c);
                            mCaseVsMetadata.put(tempCompositeKeyHashCode,new Map<String,Set<Id>>());
                        }
                        if(!mCaseVsMetadata.get(tempCompositeKeyHashCode).containsKey(event.CustomMetadataName__c)){
                            mCaseVsMetadata.get(tempCompositeKeyHashCode).put(event.CustomMetadataName__c, new Set<Id>());                           
                        }
                        mCaseVsMetadata.get(tempCompositeKeyHashCode).get(event.CustomMetadataName__c).add(event.RecordID__c);
                    }
                    caseCustomMetadata.add(tempCompositeKeyHashCode);
                    
                    counter++;
                }
                else{
                    break;
                }
            }
        }
        
        if(peIds.size()>0){
            allPeLoggerList = ASF_CommPETriggerQueryHandler.getPELoggerRecords(peIds,'Completed');
            for(PE_Logger__c peLog : allPeLoggerList){
                System.debug(peLog.Case__c);
                if(peLog.Case__c !=null){
                    if(!mSObjectVsLoggerList.containsKey('Case')){
                        mSObjectVsLoggerList.put('Case', new List<PE_Logger__c>());
                    }
                    mSObjectVsLoggerList.get('Case').add(peLog);
                }
                else if((peLog.AccountId__c != null && peLog.AccountId__c != '') && (peLog.Case__c == '' || peLog.Case__c == null)){
                    if(!mSObjectVsLoggerList.containsKey('Account')){
                        mSObjectVsLoggerList.put('Account', new List<PE_Logger__c>());
                    }
                    mSObjectVsLoggerList.get('Account').add(peLog);
                }
            }
            peLoggerList = ASF_CommPETriggerQueryHandler.getPELoggerRecords(peIds,'Completed');
            for(PE_Logger__c peL : peLoggerList){
                String tempCompositeKey = peL.Case__c+'_'+peL.CustomMetadataName__c;
                integer tempCompositeKeyHash = tempCompositeKey.hashCode();
                if(!caseCustomMetadata.contains(tempCompositeKeyHash)){
                    // Record Not found, may be processed already.
                    if(mCaseVsMetadata.containsKey(tempCompositeKeyHash)){
                        mCaseVsMetadata.remove(tempCompositeKeyHash);
                    }
                }
                if(!mPEIdVsCaseId.containsKey(peL.Id)){
                    mPEIdVsCaseId.put(peL.ID,peL.Case__c);
                }
                
                subScriberList.add(appendsubscriberDetail(peL,peIds));
            }
        }
        if(subScriberList.size()>0){
            Database.SaveResult[] subscriberUpd = Database.Update(subScriberList,false);
        }
        
        
        List<PE_Logger__c> updPELoggerStatus = new List<PE_Logger__c>();
        
        if(mCaseVsMetadata.keySet().size()>0 && mSObjectVsLoggerList.containsKey('Case')){
            Map<Id,ASF_CommPETriggerHelper.responseWrapper> results = ASF_CommPETriggerHelper.executeContructor(mSObjectVsLoggerList.get('Case'));
            System.debug(results);
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
            
            
            if(updPELoggerStatus.size()>0){
                update updPELoggerStatus;
            }
        }
        if(mCaseVsMetadata.keySet().size()>0 && mSObjectVsLoggerList.containsKey('Account')){
            Map<Id,ASF_AccountCommPETriggerHelper.responseWrapper> results = ASF_AccountCommPETriggerHelper.executeContructor(mSObjectVsLoggerList.get('Account'));
            System.debug(results);
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
            
            
            if(updPELoggerStatus.size()>0){
                update updPELoggerStatus;
            }
        }
        
        
    }
    private static integer getBatchSize(){
        Apex_PE_Framework__mdt mdtPEFramework = Apex_PE_Framework__mdt.getInstance('ASF_CommPETriggerHandler'); 
        Integer batchSize = Integer.valueOf(mdtPEFramework.TriggerBatchSize__c);
        return batchSize;
    }
    private static PE_Logger__c appendsubscriberDetail(PE_Logger__c peL,Set<Id> peIds){
        peL.Subscriber_Picked_Up_Time__c = DateTime.now();
        peL.Process_Batch_Size__c = peIds.size();
        peL.PE_JSON__c = String.ValueOf(peIds);
        peL.Subscriber_Number__c = intTriggerNumber;
        peL.Status__c = 'Processing';
        return peL;
    }
    
}