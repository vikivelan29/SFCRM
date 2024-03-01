public with sharing class ABCL_RetryDMSFileTransfer {
    /****************************************************************************************************************
    * @LOB - ABCL
    * @Function - retryDMSFileTransfer
    * @param recId - DMS record Id.
    * @description - Initiates File Transfer to DMS
    *****************************************************************************************************************/
    @InvocableMethod(label='Retry DMS File Transfer' description='This Apex is used to invoke the Failed or Pending DMS Integrations')
    public static void retryDMSFileTransfer(List<DMS_Files__c> dmsRecords){

        Set<Id> caseIds = new Set<Id>();
        for(DMS_Files__c dms : dmsRecords){
            if(ASF_Constants.RETRY_ENABLEDSTATUESES.contains(dms.Status__c)){
                caseIds.add(dms.Case__c);
            }
        } 

        if(caseIds.size() < 1){
            return;
        }

        Map<Id,Case> relatedCaseRecords = new Map<ID, Case>([Select id,Business_Unit__c,CaseNumber,Account.Client_Code__c,Type_Text__c,Sub_Type_Text__c,Nature__c,Lead__c,
                                                                CreatedDate,Asset.LAN__c,Asset.Lead_Id__c,Account.Phone,Account.PersonMobilePhone,Account.RecordType.Name  
                                                                from Case where Id in: caseIds]);

        DateTime startOfLast60Mins = System.now().addMinutes(-60);
        DateTime currentTime = System.now();
        Map<Integer,Integer> dmsRecordNoOfAttemptHashMap = new Map<Integer,Integer>();
        
        
        List<DMS_Files__c> oldDMSRecords = new List<DMS_Files__c> ();
        
        if(DMS_Files__c.SObjectType.getDescribe().isAccessible()){
            oldDMSRecords = [SELECT ID,Case__c,ContentVersionId__c FROM DMS_Files__c WHERE Case__c =:caseIds AND Case__r.IsClosed = true AND (CreatedDate > :startOfLast60Mins AND CreatedDate <= :currentTime)];
        }

        for(DMS_Files__c oldDMS : oldDMSRecords){
            
            String tempKey = oldDMS.Case__c+'_'+oldDMS.ContentVersionId__c;
            integer ihashKey = tempKey.hashCode();
            
            
            if(!dmsRecordNoOfAttemptHashMap.containsKey(ihashKey)){
                dmsRecordNoOfAttemptHashMap.put(ihashKey,0);
            }
            integer iTempCounter = dmsRecordNoOfAttemptHashMap.get(ihashKey);
            iTempCounter++;
            dmsRecordNoOfAttemptHashMap.put(ihashKey,iTempCounter);
        }

        List<DMS_Files__c> retryDMSRecords = new List<DMS_Files__c>();
        for(DMS_Files__c dms : dmsRecords){
            if(dms.Case__c != null && ASF_Constants.RETRY_ENABLEDSTATUESES.contains(dms.Status__c)){
                String tempKey = dms.Case__c+'_'+dms.ContentVersionId__c;
                integer ihashKey = tempKey.hashCode();
                Integer noOfAttempts = 0;
                if(dmsRecordNoOfAttemptHashMap.containsKey(ihashKey)){
                    noOfAttempts = dmsRecordNoOfAttemptHashMap.get(ihashKey);
                    if(noOfAttempts <= 2){
                        retryDMSRecords.add(dms);
                    }
                }
            }
        }

        if(retryDMSRecords.size() > 0){
            retryDMSFileTransferIntegration(retryDMSRecords,relatedCaseRecords,dmsRecordNoOfAttemptHashMap);
        }

        if(dmsRecords.size() > 0){
            processOldDMSFileTransferRecords(dmsRecords);
        }
    }
    /****************************************************************************************************************
    * @LOB - ABCL
    * @Function - retryDMSFileTransferIntegration
    * @param dmsRecords - DMS records.
    * @param relatedCaseRecords - Related Case records.
    * @param dmsRecordNoOfAttemptHashMap - DMS records with Attempt Count.
    * @description - Initiates Retry for File Transfer to DMS
    *****************************************************************************************************************/
    private static void retryDMSFileTransferIntegration(List<DMS_Files__c> dmsRecords,Map<Id,Case> relatedCaseRecords,Map<Integer,Integer> dmsRecordNoOfAttemptHashMap){
        List<DMS_Files__c> fileRecList = new List<DMS_Files__c>();
        for(DMS_Files__c file : dmsRecords){
            String tempKey = file.Case__c+'_'+file.ContentVersionId__c;
            integer ihashKey = tempKey.hashCode();
            integer noOfAttempt = 0;
            if(!dmsRecordNoOfAttemptHashMap.containsKey(ihashKey)){
                noOfAttempt = 1;
            }else {
                noOfAttempt = dmsRecordNoOfAttemptHashMap.get(ihashKey);
            }
            if(relatedCaseRecords.containsKey(file.Case__c)){
                DMS_Files__c fileRec = new DMS_Files__c();
                fileRec.ContentDocumentId__c = file.ContentDocumentId__c;
                fileRec.Case__c = file.Case__c;
                fileRec.ContentVersionId__c = file.ContentVersionId__c;
                fileRec.File_Name__c = file.File_Name__c;
                fileRec.Has_Multiple_Versions__c = file.Has_Multiple_Versions__c;
                fileRec.Is_Latest_Version__c = file.Is_Latest_Version__c;
                fileRec.Status__c = ABHFL_Constants.PENDING;
                fileRec.Version_Number__c = file.Version_Number__c;
                fileRec.Business_Unit__c = file.Business_Unit__c;
                DateTime currentDateTime = System.now();
                fileRec.DMS_External_ID__c = file.ContentVersionId__c + '' + currentDateTime.getTime();
                fileRec.File_Extension__c = file.File_Extension__c;
                fileRec.Next_Retry__c = System.now().addMinutes(15);
                fileRec.Retry_Attempt__c = noOfAttempt;
                fileRecList.add(fileRec);
            }
        }
        if(fileRecList.size() > 0){
            insert fileRecList;

            List<DMS_File_Transfer__e> dmsEventList = new List<DMS_File_Transfer__e>();

            for(DMS_Files__c file : fileRecList){

                Case caseRecord = relatedCaseRecords.get(file.Case__c);
                string leadId = '';
                string mobile = '';
                if(caseRecord.Asset.Lead_Id__c != null){
                    leadId = caseRecord.Asset.Lead_Id__c;
                } else if(caseRecord.Lead__c != null){
                    leadId = caseRecord.Lead__c;
                } else {
                    leadId = caseRecord.CaseNumber;
                }
                if(ABHFL_Constants.ACCOUNT_RECORDTYPE_NON_INDIVIDUAL == caseRecord.Account.RecordType.Name){
                    mobile = caseRecord.Account.PersonMobilePhone;
                }else {
                    mobile = caseRecord.Account.Phone;
                }

                dmsEventList.add(new DMS_File_Transfer__e(
                    Business_Unit__c = file.Business_Unit__c,
                    CaseNumber__c = caseRecord.CaseNumber,
                    ContentVersionId__c = file.ContentVersionId__c,
                    Customer_Client_Code__c = caseRecord.Account.Client_Code__c,
                    DMS_External_ID__c = file.DMS_External_ID__c,
                    File_Name__c = file.File_Name__c,
                    Is_Latest_Version__c = file.Is_Latest_Version__c,
                    Version_Number__c = file.Version_Number__c,
                    Application_ID__c = caseRecord.Asset.LAN__c,
                    Document_Type__c = caseRecord.Type_Text__c+'-'+caserecord.Sub_Type_Text__c+'-'+caseRecord.Nature__c,
                    File_Extension__c = file.File_Extension__c,
                    Doc_SubType__c = caseRecord.Sub_Type_Text__c,
                    Docgroup_Type__c = caseRecord.Nature__c.left(1) + '-' + caserecord.Type_Text__c,
                    Lead_ID__c = leadId,
                    Contact_No__c = mobile,
                    Source__c = ASF_Constants.DMS_FILE_TRANSFER_SOURCE
                ));
            }

            if(dmsEventList.size() > 0){
                List<Database.SaveResult> eventResult = EventBus.publish(dmsEventList);
            }
        }
    }
    /****************************************************************************************************************
    * @LOB - ABCL
    * @Function - processOldDMSFileTransferRecords
    * @param dmsRecords - DMS records.
    * @description - Updates older DMS File Transfer Records
    *****************************************************************************************************************/
    private static void processOldDMSFileTransferRecords(List<DMS_Files__c> dmsRecords){
        for(DMS_Files__c file : dmsRecords){
            file.Next_Retry__c = null;
            if(file.Status__c == 'Pending'){
                file.Status__c = 'Canceled';
            }
        }
        update dmsRecords;
    }
}