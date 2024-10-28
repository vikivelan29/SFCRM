/**
 * @description         : ABCL DMS Retry implementation class
 * @author              : sjaitly@salesforce.com
 * @last modified on    : 05-10-2024
 * @last modified by    : udit.singhal@salesforce.com
 * 
 * /* MODIFICATION LOG
 * Developer                                Date               Description
 * -----------------------------------------------------------------------------------------------------
 * Arshad(msharieff@salesforce.com)        24/09/2024         ABHI OmniDoc FileTransfer Retry flow, ABHI_OmniDocUploadCtrlTestClass
 * 
 * ***********************************************************************************************
 */

@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity, PMD.StdCyclomaticComplexity')
public with sharing class ABCL_RetryDMSFileTransfer {
    /****************************************************************************************************************
    * @LOB - ABCL
    * @Function - retryDMSFileTransfer
    * @param dmsRecords - DMS record Ids.
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

        String query = 'SELECT ';
        query += ABFL_DMSSync_Orchestrator.getSOQLFieldsForDMS().DMS_Case_SOQL_Fields__c;
        query += ' FROM Case WHERE Id IN :caseIds';

        Map<Id,Case> relatedCaseRecords = new Map<Id,Case>((List<Case>)Database.query(String.escapeSingleQuotes(query)));

        DateTime startOfLast60Mins = System.now().addMinutes(-60);
        DateTime currentTime = System.now();
        Map<Integer,Integer> dmsRecordNoOfAttemptHashMap = new Map<Integer,Integer>();


        List<DMS_Files__c> oldDMSRecords = new List<DMS_Files__c> ();

        if(DMS_Files__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).isAccessible()){
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
        List<DMS_Files__c> abflRetryDMSRecords = new List<DMS_Files__c>();
        List<DMS_Files__c> lstABHIRetryDMSFiles = new List<DMS_Files__c>();
        List<Id> lstCaseIds = new List<Id>();

        for(DMS_Files__c dms : dmsRecords){
            if(dms.Case__c != null && ASF_Constants.RETRY_ENABLEDSTATUESES.contains(dms.Status__c)){
                String tempKey = dms.Case__c+'_'+dms.ContentVersionId__c;
                integer ihashKey = tempKey.hashCode();
                Integer noOfAttempts = 0;
                if(dmsRecordNoOfAttemptHashMap.containsKey(ihashKey)){
                    noOfAttempts = dmsRecordNoOfAttemptHashMap.get(ihashKey);
                    if(noOfAttempts <= 2){
                        if(ABFL_Constants.ABFL_ABWM_BUSINESSUNIT.contains(dms.Business_Unit__c)) {
                            abflRetryDMSRecords.add(ABFL_DMSSync_Orchestrator.prepareDMSRecord(dms, null, null));
                        }else if(dms.Business_Unit__c == ABHI_Constants.ABHI){
                            //for OmniDoc ABHI retry functionality - Arshad 20 Sept 24
                            if(relatedCaseRecords.containsKey(dms.Case__c)){
                                if(!lstCaseIds.contains(dms.Case__c)) lstCaseIds.add(dms.Case__c);
                                lstABHIRetryDMSFiles.add(dms);
                            }
                        }else {
                            retryDMSRecords.add(dms);
                        }
                    }
                }
            }
        }

        if(retryDMSRecords.size() > 0){
            retryDMSFileTransferIntegration(retryDMSRecords,relatedCaseRecords,dmsRecordNoOfAttemptHashMap);
        }

        if(abflRetryDMSRecords.size() > 0) {
            if(Schema.sObjectType.DMS_Files__c.isCreateable()) {
                insert abflRetryDMSRecords;

                ABFL_DMSSync_Orchestrator.prepareEventsAndPublish(abflRetryDMSRecords, relatedCaseRecords);
            }
        }

        if(lstABHIRetryDMSFiles.size() > 0) {
            ABHI_OmniDocUploadController.retryFileTransferToOmniDoc(lstABHIRetryDMSFiles, lstCaseIds);
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
                Case caseRecord = relatedCaseRecords.get(file.Case__c);
                string leadId = '';
                if(caseRecord.Asset.Lead_Id__c != null){
                    leadId = caseRecord.Asset.Lead_Id__c;
                } else if(caseRecord.Lead__c != null){
                    leadId = caseRecord.Lead__c;
                } else {
                    leadId = caseRecord.CaseNumber;
                }
                DMS_Files__c fileRec = new DMS_Files__c();
                fileRec.ContentDocumentId__c = file.ContentDocumentId__c;
                fileRec.Case__c = file.Case__c;
                fileRec.ContentVersionId__c = file.ContentVersionId__c;
                fileRec.Has_Multiple_Versions__c = file.Has_Multiple_Versions__c;
                fileRec.Is_Latest_Version__c = file.Is_Latest_Version__c;
                fileRec.Version_Number__c = file.Version_Number__c;
                fileRec.Business_Unit__c = file.Business_Unit__c;
                DateTime currentDateTime = System.now();
                fileRec.DMS_External_ID__c = file.ContentVersionId__c + '' + currentDateTime.getTime();
                fileRec.File_Extension__c = file.File_Extension__c;
                fileRec.Next_Retry__c = System.now().addMinutes((Integer)Asf_Dynamic_Datatable_Parent__mdt.getInstance(ABFL_Constants.DMS_METADATA).DMS_Retry_Interval__c);
                fileRec.Retry_Attempt__c = noOfAttempt;
                if(String.isBlank(leadId) && file.Business_Unit__c != ABSLI_Constants.BUSINESS_UNIT){
                    fileRec.Status__c = ABHFL_Constants.CANCELED;
                } else {
                    fileRec.Status__c = ABHFL_Constants.PENDING;
                }
                // Modified Attribute for ABSLI specific Business Unit
                fileRec.File_Name__c = file.File_Name__c;
                fileRec.DMS_Folder_Id__c = file.DMS_Folder_Id__c;
                fileRec.Application_ID__c = file.Application_ID__c;
                fileRec.Policy_No__c = file.Policy_No__c;
                fileRecList.add(fileRec);
            }
        }
        if(fileRecList.size() > 0 && Schema.sObjectType.DMS_Files__c.isCreateable()){
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

                if(file.Status__c == ABHFL_Constants.PENDING){
                    dmsEventList.add(new DMS_File_Transfer__e(
                        Business_Unit__c = file.Business_Unit__c,
                        CaseNumber__c = caseRecord.CaseNumber,
                        ContentVersionId__c = file.ContentVersionId__c,
                        Customer_Client_Code__c = caseRecord.Account.Client_Code__c,
                        DMS_External_ID__c = file.DMS_External_ID__c,
                        File_Name__c = file.File_Name__c,
                        Is_Latest_Version__c = file.Is_Latest_Version__c,
                        Version_Number__c = file.Version_Number__c,
                        Application_ID__c = file.Application_ID__c,
                        DMS_Folder_Id__c = file.DMS_Folder_Id__c,
                        Policy_No__c = file.Policy_No__c,
                        Document_Type__c = caseRecord.Type_Text__c+'-'+caserecord.Sub_Type_Text__c+'-'+caseRecord.Nature__c,
                        File_Extension__c = file.File_Extension__c,
                        Doc_SubType__c = caseRecord.Sub_Type_Text__c,
                        Docgroup_Type__c = caseRecord.Nature__c.left(1) + '-' + caserecord.Type_Text__c,
                        Lead_ID__c = leadId,
                        Contact_No__c = mobile,
                        Source__c = ASF_Constants.DMS_FILE_TRANSFER_SOURCE
                    ));
                }
            }

            if(dmsEventList.size() > 0){
                EventBus.publish(dmsEventList);
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
        if(Schema.sObjectType.DMS_Files__c.isUpdateable()){
            update dmsRecords;
        }
    }
}
