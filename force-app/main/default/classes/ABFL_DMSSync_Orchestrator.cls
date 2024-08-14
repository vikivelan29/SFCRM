/**
 * @description       : Logic to handle ABFL DMS operations
 * @author            : udit.singhal@salesforce.com
 * @group             : 
 * @last modified on  : 07-02-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   04-30-2024   udit.singhal@salesforce.com  PR970457-1404
 * 2.0   05-09-2024   udit.singhal@salesforce.com  PR970457-1404
 * 3.0   07-12-2024   udit.singhal@salesforce.com  Prod-Bug-15 
**/
@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity, PMD.StdCyclomaticComplexity')
public without sharing class ABFL_DMSSync_Orchestrator{
    /**
    * @description Raises Platform Events to send DMS payload to MW
    * @author udit.singhal@salesforce.com | 05-01-2024 
    * @param caseIds 
    **/
    @InvocableMethod
    public static void transferABFLCaseFilesToDMS(List<Id> caseIds) {
        try{
            List<DMS_Files__c> dmsFileList = new List<DMS_Files__c>();
            final List<String> ABFL_ABWM_BUSINESSUNIT = ABFL_Constants.ABFL_ABWM_BUSINESSUNIT; // NOPMD
            String query = 'SELECT ';
            query += getSOQLFieldsForDMS().DMS_Case_SOQL_Fields__c;
            query += ' FROM Case WHERE Id IN :caseIds AND Business_Unit__c IN :ABFL_Constants.ABFL_ABWM_BUSINESSUNIT AND isClosed=True WITH SYSTEM_MODE';
            
            Map<Id,Case> mCaseIdToRecord = new Map<Id,Case>((List<Case>)Database.query(String.escapeSingleQuotes(query)));
            
            // in BRE scenerios, linkedEntityId will be of EmailMessage
            Map<Id,EmailMessage> mEmailMsgRec = new Map<Id,EmailMessage>([select id, parentId from EmailMessage where parentId IN :mCaseIdToRecord.keySet()]);
            
            List<ContentDocumentLink> lContentdoclLink = [SELECT ContentDocumentId, LinkedEntityId 
                                                          FROM ContentDocumentLink 
                                                          WHERE (LinkedEntityId IN :mCaseIdToRecord.keySet() OR LinkedEntityId IN :mEmailMsgRec.keyset())
                                                          WITH SYSTEM_MODE
                                                         ];
            
            if(!lContentdoclLink.isEmpty()){
                // Collecting ContentDocumentIds
                Set<Id> contentDocumentIdSet = new Set<Id>();
                for(ContentDocumentLink docLink : lContentdoclLink) {
                    contentDocumentIdSet.add(docLink.ContentDocumentId);
                }
                
                // Building a map of caseId to ContentVersion records
                map<Id, ContentVersion> mContentDocIdToLatestContentVer = new map<Id, ContentVersion>();
                for(ContentVersion cvRec: [SELECT Id, Title, ContentDocumentId, VersionNumber, FileExtension, ContentDocument.ContentSize
                                           FROM ContentVersion where ContentDocumentId 
                                           IN :contentDocumentIdSet and IsLatest=true
                                           WITH SYSTEM_MODE
                                          ]
                   )
                {
                    mContentDocIdToLatestContentVer.put(cvRec.ContentDocumentId, cvRec);
                }
                
                Map<Id, List<ContentVersion>> mCaseIdToContentVersion = new Map<Id, List<ContentVersion>>();
                for(ContentDocumentLink docLink : lContentdoclLink){
                    // Check type of linkedEntityId 
                    Id caseId;
                    if(docLink.LinkedEntityId.getSobjectType()==Case.getSObjectType()){
                        caseId = docLink.LinkedEntityId;
                    }else{
                        caseId = mEmailMsgRec.get(docLink.LinkedEntityId).parentId;
                    }
                    if(!mCaseIdToContentVersion.containsKey(caseId)){
                        mCaseIdToContentVersion.put(caseId, new List<ContentVersion>{mContentDocIdToLatestContentVer.get(docLink.ContentDocumentId)});
                    }else{
                        List<ContentVersion> tempList = mCaseIdToContentVersion.get(caseId);
                        tempList.add(mContentDocIdToLatestContentVer.get(docLink.ContentDocumentId));
                        mCaseIdToContentVersion.put(caseId, tempList);
                    }
                }
                
                for(Case caseRecord : mCaseIdToRecord.values()){
                    for(ContentVersion conVerRec : mCaseIdToContentVersion.get(caseRecord.Id)){
                        DMS_Files__c dmsRec = prepareDMSRecord(null, caseRecord, conVerRec);
                        
                        //Cancel sync if file size exceed 5 MB
                        dmsRec.Status__c = conVerRec.ContentDocument.ContentSize <= ABFL_Constants.FIVE_MB_FILE_SIZE_BYTES ? ABFL_Constants.PENDING : ABFL_Constants.CANCELED;
                        dmsRec.Error_Description__c = dmsRec.Status__c == ABFL_Constants.CANCELED ? ABFL_Constants.DMS_SYNC_FILE_SIZE_ERROR : '';
                        dmsFileList.add(dmsRec);
                    }
                }
                
                // Inserting DMS_Files__c records
                if(!dmsFileList.isEmpty() && Schema.sObjectType.DMS_Files__c.isCreateable()){
                    insert dmsFileList;
                    prepareEventsAndPublish(dmsFileList, mCaseIdToRecord);
                }
            }
        } catch (Exception e) {
            // Handle exceptions
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABFL_DMSSync_Orchestrator.transferABFLCaseFilesToDMS');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.message(e.getStackTraceString());
            ABCL_Logger.emit();
        }
    }

    /**
     * @description This method will be invoked from LWC component to manually sync DMS files
     * @param lDmsIds
     * @return ResponseWrapper 
     **/
    @AuraEnabled(Cacheable = false)
    public static ResponseWrapper syncDMSFilesManually(List<Id> lDmsIds) {
        try{
            if(lDmsIds.size() > 0){
                List<DMS_Files__c> dmsFileList = new List<DMS_Files__c>();
                String query = 'SELECT ';
                query += getSOQLFieldsForDMS().DMS_Files_SOQL_Fields__c;
                query += ' FROM DMS_Files__c WHERE Id = :lDmsIds WITH SYSTEM_MODE';
                
                // Execute the dynamic query
                dmsFileList = Database.query(String.escapeSingleQuotes(query));
                
                /*
                 * * run below only if list of DMS ids (lDmsIds) are passed 
                 * * Check if lastmodifieddate+ABFL_Manual_Sync_Threshold > then current time > if not, ask user to wait
                 */
                List<DMS_Files__c> dmsFilesToUpsertList = new List<DMS_Files__c>();
                if(!dmsFileList.isEmpty()) {
                    Boolean invalidDMSFlag = false;
                    for(DMS_Files__c dmsRec: dmsFileList){
                        DateTime thresholdTime = dmsRec.LastModifiedDate.addMinutes(Integer.valueOf(System.Label.ABFL_Manual_Sync_Threshold));
                        
                        // In case user doesn't wait for automated sync to complete - It is irrespective of status
                        if(dmsRec.Retry_Attempt__c >= 9){
                            return new ResponseWrapper(false, 'Maximum number of retries are exhausted. Please contact system admin.');
                        }
                        // for manual sync where users click repeatively
                        if(dmsRec.Status__c == ABFL_Constants.PENDING && thresholdTime > System.now() && !Test.isRunningTest()){
                            return new ResponseWrapper(false, 'Sync was recently initiated, please wait till '+thresholdTime.format()+'.');
                        }
                        //Cancel existing dms file record
                        if(ASF_Constants.RETRY_ENABLEDSTATUESES.contains(dmsRec.Status__c)){
                            DMS_Files__c file = dmsRec;
                            // file.Retry_Attempt__c = file.Retry_Attempt__c != null ? ++file.Retry_Attempt__c : 1;
                            file.Next_Retry__c = null;
                            
                            if(file.Status__c == ABFL_Constants.PENDING) {
                                file.Status__c = ABFL_Constants.CANCELED;
                            }
                            dmsFilesToUpsertList.add(file);
                        }else{
                            invalidDMSFlag = true;
                            break;
                        }
                        dmsFilesToUpsertList.add(prepareDMSRecord(dmsRec, null, null));
                    }
                    if(invalidDMSFlag){
                        return new ResponseWrapper(false, ABFL_Constants.INVALID_DMS_RECORD_ERROR);
                    }
                }
                
                if(dmsFilesToUpsertList.size() > 0 && Schema.sObjectType.DMS_Files__c.isCreateable() && Schema.sObjectType.DMS_Files__c.isUpdateable()){
                    upsert dmsFilesToUpsertList;
                    prepareEventsAndPublish(dmsFilesToUpsertList, null);
                }
                return new ResponseWrapper(true, null);
            } else {
                return new ResponseWrapper(false, ABFL_Constants.DMS_GENERIC_ERROR);
            }
        } catch (Exception e) {
            // Handle exceptions
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABFL_DMSSync_Orchestrator.syncDMSFilesManually');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.message(e.getStackTraceString());
            ABCL_Logger.emit();
            return new ResponseWrapper(false, ABFL_Constants.DMS_GENERIC_ERROR);
        }
    }

    /**
     * @description This method is used to prepare new DMS records for insertion from DMS_Files__c or caseRec record
     * @param dmsRec
     * @param caseRec
     * @param conVer
     * @return DMS_Files__c 
     **/
    public static DMS_Files__c prepareDMSRecord(DMS_Files__c dmsRec, Case caseRec, ContentVersion conVer){
        //Create new DMS File record to sync the file with DMS
        DMS_Files__c nDMSFileRec = new DMS_Files__c();
        nDMSFileRec.RecordTypeId = Schema.Sobjecttype.DMS_Files__c.getRecordTypeInfosByName().get(ABFL_Constants.ABFL).getRecordTypeId();
        nDMSFileRec.ContentDocumentId__c = conVer==null?dmsRec.ContentDocumentId__c:conVer.ContentDocumentId;
        nDMSFileRec.LOB__c = conVer==null?dmsRec.Lob__c:caseRec.Lob__c;
        String bu = conVer==null?dmsRec.Business_Unit__c:caseRec.Business_Unit__c;
        if(ABFL_Constants.ABFL_ABWM_BUSINESSUNIT.contains(bu)){
            bu = 'ABFL';
        }
        nDMSFileRec.Business_Unit__c = bu;
        nDMSFileRec.Branch_Name__c = conVer==null?dmsRec.Branch_Name__c:String.isNotBlank(caseRec.Branch_Master__r.Name) ? caseRec.Branch_Master__r.Name : '';
        nDMSFileRec.Branch_Code__c = conVer==null?dmsRec.Branch_Code__c:String.isNotBlank(caseRec.Branch_Master__r.Branch_Code__c) ? caseRec.Branch_Master__r.Branch_Code__c : '';
        nDMSFileRec.Case__c = conVer==null?dmsRec.Case__c:caseRec.Id;
        nDMSFileRec.ContentVersionId__c = conVer==null?dmsRec.ContentVersionId__c:conVer.Id;
        nDMSFileRec.File_Name__c = conVer==null?dmsRec.File_Name__c:conVer.Title;
        nDMSFileRec.File_Extension__c = conVer==null?dmsRec.File_Extension__c:conVer.FileExtension;
        nDMSFileRec.Has_Multiple_Versions__c = conVer==null?dmsRec.Has_Multiple_Versions__c:(Integer.valueOf(conVer.VersionNumber) > 1);
        nDMSFileRec.Is_Latest_Version__c = true;
        nDMSFileRec.Version_Number__c = conVer==null?dmsRec.Version_Number__c:conVer.VersionNumber;
        nDMSFileRec.DMS_External_ID__c = (conVer==null?dmsRec.ContentVersionId__c:conVer.Id) + '' + System.now().getTime();
        nDMSFileRec.Retry_Attempt__c = conVer==null? (dmsRec.Retry_Attempt__c+1) : 0;
        nDMSFileRec.Next_Retry__c = System.now().addMinutes((Integer)Asf_Dynamic_Datatable_Parent__mdt.getInstance(ABFL_Constants.DMS_METADATA).DMS_Retry_Interval__c);
        nDMSFileRec.Status__c = ABFL_Constants.PENDING;
        if(dmsRec != null) {
            nDMSFileRec.Case__r = dmsRec.Case__r; 
        }
        
        return nDMSFileRec;
    }

    /**
     * @description This method is used to publish PEs to sync files with DMS
     * @param lDMSFile
     * @param mCaseIdToRecord
     **/
    public static void prepareEventsAndPublish(List<DMS_Files__c> lDMSFile, Map<Id,Case> mCaseIdToRecord){
        List<DMS_File_Transfer__e> abflDmsEventList = new List<DMS_File_Transfer__e>();
        // Create events from DMS_Files
        for(DMS_Files__c dmsRec :lDMSFile){
            // lDMSFile will also contains existing cancelled records, ignore them
            if(dmsRec.Status__c == ABFL_Constants.PENDING) {
                Case caseRecord = mCaseIdToRecord?.get(dmsRec.Case__c);
                // get index mapping
                List<IndexWrapper> lIndexWrap = new List<IndexWrapper>();
                for(ABFL_DMSIndexMap__mdt recIn: ABFL_DMSIndexMap__mdt.getAll().values()){
                    String tempVal;
                    switch on recIn.Relationship__c {
                        when 'Account' {
                            tempVal = (String)(caseRecord != null && caseRecord.getSObject('Account') != null ? caseRecord.getSObject('Account').get(recIn.FieldAPI__c.substringAfter('.')) : (dmsRec != null && dmsRec.getSObject('Case__r') != null && dmsRec.getSObject('Case__r').getSObject('Account') != null ? dmsRec.getSObject('Case__r').getSObject('Account').get(recIn.FieldAPI__c.substringAfter('.')) : ''));
                        }   
                        when 'Case' {
                            tempVal = (String)(caseRecord!=null?caseRecord.get(recIn.FieldAPI__c):dmsRec?.getSObject('Case__r')?.get(recIn.FieldAPI__c));
                        }
                        when else {       // default block, optional
                            tempVal = (String)dmsRec.get(recIn.FieldAPI__c);
                        }
                    }
                    
                    // prepare index wrapper
                    lIndexWrap.add(new IndexWrapper(Integer.valueOf(recIn.IndexId__c), recIn.Type__c, tempVal));
                }

                // method to add complex indexwrapper
                addComplexWrapper(lIndexWrap, caseRecord, dmsRec);

                String cleanedType = cleanString(caseRecord!=null?caseRecord.Type_Text__c:dmsRec.Case__r.Type_Text__c);
                String cleanedSubType = cleanString(caseRecord!=null?(caseRecord.Nature__c.left(1) + '_' + caserecord.Sub_Type_Text__c):(dmsRec.Case__r.Nature__c.left(1) + '_' + dmsRec.Case__r.Sub_Type_Text__c));
                
                abflDmsEventList.add(new DMS_File_Transfer__e(
                    DMS_External_ID__c = dmsRec.DMS_External_ID__c,
                    LOB__c = dmsRec.Lob__c,
                    File_Extension__c = dmsRec.File_Extension__c,
                    ContentVersionId__c = dmsRec.ContentVersionId__c,
                    Business_Unit__c = dmsRec.Business_Unit__c,
                    File_Name__c = dmsRec.File_Name__c,
                    CaseNumber__c = caseRecord!=null?caseRecord.CaseNumber:dmsRec.Case__r.CaseNumber,
                    IssueTypeCode__c = caseRecord!=null?caseRecord.CCC_External_Id__c:dmsRec.Case__r.CCC_External_Id__c,
                    Docgroup_Type__c = cleanedType,
                    Doc_SubType__c = cleanedSubType.left(50),
                    ABFL_Index_Map__c = JSON.serialize(lIndexWrap),
                    Source__c = ASF_Constants.DMS_FILE_TRANSFER_SOURCE
                ));
            }
        }

        if(abflDmsEventList.size() > 0){
            EventBus.publish(abflDmsEventList);
        }
    }

    /**
     * @description This method is used get fields of Case/DMS_Files object from custom metadata that needs to be queried
     * @return Asf_Dynamic_Datatable_Parent__mdt 
     **/
    public static Asf_Dynamic_Datatable_Parent__mdt getSOQLFieldsForDMS() {
        Asf_Dynamic_Datatable_Parent__mdt  metadataRecord = [SELECT DMS_Case_SOQL_Fields__c, DMS_Files_SOQL_Fields__c  FROM Asf_Dynamic_Datatable_Parent__mdt WHERE DeveloperName =: ABFL_Constants.DMS_METADATA WITH SYSTEM_MODE LIMIT 1];
        return metadataRecord != null ? metadataRecord : null;
    }

    /**
     * @description This method is used add additional attributes to IndexWrapper passed in the input parameter
     * @param lIndexWrap
     * @param caseRecord
     * @param dmsRec
     **/
    private static void addComplexWrapper(List<IndexWrapper> lIndexWrap, Case caseRecord, DMS_Files__c dmsRec){
        // add SUBCONTENTCODE_DESC which is nature__c - Sub_Type_Text__c 
        lIndexWrap.add(new IndexWrapper(Integer.valueOf(System.Label.ABFL_DMS_Subcontentcode_Desc_Index_Id),'S',caseRecord!=null?caseRecord.Nature__c+' - '+caseRecord.Sub_Type_Text__c:dmsRec.Case__r.Nature__c+' - '+dmsRec.Case__r.Sub_Type_Text__c));

        // add Field_26 DOCUMENTS_OF
        if(caseRecord != null) {
            lIndexWrap.add(new IndexWrapper(Integer.valueOf(System.Label.ABFL_DMS_Documents_Of),'S',caseRecord.AssetId == null ? 'Customer' : 'Loan'));
        } else {
            lIndexWrap.add(new IndexWrapper(Integer.valueOf(System.Label.ABFL_DMS_Documents_Of),'S',dmsRec.Case__r.AssetId == null ? 'Customer' : 'Loan'));
        }
        // add Field_1141 MASKING_STATUS - A (Already Masked), S (Aadhaar image not found)
        lIndexWrap.add(new IndexWrapper(Integer.valueOf(System.Label.ABFL_DMS_Masking_Status),'S',dmsRec.File_Name__c.toLowerCase().contains('aadhaar') ? 'A' : 'S'));
        // add Field_1139 AADHAAR_FLAG
        lIndexWrap.add(new IndexWrapper(Integer.valueOf(System.Label.ABFL_DMS_Aadhaar_Flag),'S',dmsRec.File_Name__c.toLowerCase().contains('aadhaar') ? 'Y' : 'N'));
    }

    /**
     * @description This method is uses below logic to cleanup path names
     > Replace space, ) with empty space.
     > Replace -, (, &, /, , , . with _
     * @param valToClean
     * @return String
     */
    public static String cleanString(String valToClean){
        String cleanedVal = valToClean.replace(' ','').replace(')','');
        cleanedVal = cleanedVal.replace('-','_').replace('()','_').replace('&','_').replace('/','_').replace(',','_').replace('.','_');
        return cleanedVal;
    }

    /**
     * @description Wrapper class used createa field index pairs for the PE
     **/
    private Class IndexWrapper{
        public Integer indexId;
        public String indexType;
        public String indexValue;

        /**
         * @description Custom constructor for the wrapper class
         * @param id
         * @param type
         * @param value
        **/
        public IndexWrapper(Integer id, String type, String value){
            this.indexId = id;
            this.indexType = type;
            this.indexValue = value;
        }
    }
    /**
     * @description Wrapper class used which is used to send response to LWC component 
     **/
    public Class ResponseWrapper{
        @AuraEnabled
        public Boolean isSuccess;
        @AuraEnabled
        public String errorMsg;

        /**
         * @description Custom constructor for the wrapper class
         * @param isSuccess
         * @param errorMsg
         **/
        public ResponseWrapper(Boolean isSuccess, String errorMsg){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
        }
    }
}