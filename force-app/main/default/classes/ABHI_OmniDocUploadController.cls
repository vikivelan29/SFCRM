/**
 * Class              :  ABHI_OmniDocUploadController
 * TestClass          :  ABHI_OmniDocUploadCtrlTestClass
 * Author             :  Arshad(msharieff@salesforce.com)
 * Created Date       :  20/09/2024
 * LastModified Audit :  26/09/2024 Aditya(aditya.jawadekar@salesforce.com)
 * Description        :  Controller for case file transfer/retry to OmniDoc
 * /* MODIFICATION LOG
 * Developer                                Date               Description
 * -------------------------------------------------------------------------------------------
 * Arshad(msharieff@salesforce.com)        24/09/2024         ABHI OmniDoc FileTransfer Upload & Retry implementation
 * Aditya(aditya.jawadekar@salesforce.com) 26/09/2024         Code Optimisation
 * *****************************************************************************************************
 */
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.ExcessiveParameterList,PMD.NcssMethodCount,PMD.StdCyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts')
public without sharing class ABHI_OmniDocUploadController {

    public static final List<String> OMNIDOCS_LINE_OF_BUSINESS = new List<String>{ABHI_Constants.ABHI};
   
    @InvocableMethod
    public static void transferFilesToOmniDoc(List<Id> lstCaseIds) {
        try{
            Map<Id,Case> mapCaseRecord = new Map<Id,Case>([Select Id,Business_Unit__c,CaseNumber,Account.Client_Code__c,
                                                            Type_Text__c,Sub_Type_Text__c,Nature__c,Lead__c,CreatedDate,AssetId,Asset.LAN__c,
                                                            Asset.Lead_Id__c,AccountId,Account.Phone,Account.PersonMobilePhone,Account.RecordType.Name
                                                            FROM Case WHERE Id IN:lstCaseIds AND Business_Unit__c =:OMNIDOCS_LINE_OF_BUSINESS AND isClosed=True WITH SYSTEM_MODE]);
            
            if(mapCaseRecord != null && !mapCaseRecord.keySet().isEmpty()){        
                List<ContentDocumentLink> lstContentDocLink = [Select Id,ContentDocumentId,LinkedEntityId from ContentDocumentLink
                                                                where LinkedEntityId In: mapCaseRecord.keySet() WITH SYSTEM_MODE];                                                
                
                Map<Id,Case> mapContentDocCase = new Map<Id,Case>();
                if(!lstContentDocLink.isEmpty()){
                    for(ContentDocumentLink docLink : lstContentDocLink){
                        if(mapCaseRecord.containsKey(docLink.LinkedEntityId)) mapContentDocCase.put(docLink.ContentDocumentId,mapCaseRecord.get(docLink.LinkedEntityId));
                    }
                }
    
                if(mapContentDocCase != null && mapContentDocCase.keySet().size() > 0){
                    List<ContentVersion> lstContentVersion = [Select Id,Title,ContentDocumentId,VersionNumber,FileExtension,ContentDocument.ContentSize  
                                                                from ContentVersion where ContentDocumentId In: mapContentDocCase.keySet() WITH SYSTEM_MODE ];

                    Map<String,Integer> mapContentDocVerCount = new Map<String,Integer>();
                    if(!lstContentVersion.isEmpty()){
                        for(ContentVersion version : lstContentVersion){
                            Integer count = 0;
                            if(mapContentDocVerCount.containsKey(version.ContentDocumentId)){
                                count = mapContentDocVerCount.get(version.ContentDocumentId);
                            }
                            count += 1;
                            mapContentDocVerCount.put(version.ContentDocumentId,count);
                        }
                     }

                    List<DMS_Files__c> lstDMSFiles2Insert = new List<DMS_Files__c>();
                    if(!lstContentVersion.isEmpty()){
                        for(ContentVersion objFileVersion : lstContentVersion){
                            if(mapContentDocCase.containsKey(objFileVersion.ContentDocumentId) && mapContentDocVerCount != null && mapContentDocVerCount.containsKey(objFileVersion.ContentDocumentId)){
                                lstDMSFiles2Insert.add(prepareDMSRecord(new DMS_Files__c(), mapContentDocCase.get(objFileVersion.ContentDocumentId), objFileVersion, mapContentDocVerCount.get(objFileVersion.ContentDocumentId)));
                            }
                        }
                    }

                    if(!lstDMSFiles2Insert.isEmpty() && Schema.sObjectType.DMS_Files__c.isCreateable()){
                        insert lstDMSFiles2Insert;
        
                        List<DMS_File_Transfer__e> lstDMSFileTransfer2Publish = new List<DMS_File_Transfer__e>();
                        for(DMS_Files__c objDMSFile : lstDMSFiles2Insert){
                            if(objDMSFile.Status__c == ABHI_Constants.PENDING && objDMSFile.ContentDocumentId__c != null && mapContentDocCase.containsKey(objDMSFile.ContentDocumentId__c)){
                                lstDMSFileTransfer2Publish.add(prepareDMSFileTransferRecord(new DMS_File_Transfer__e(), mapContentDocCase.get(objDMSFile.ContentDocumentId__c), objDMSFile));
                            }
                        }
        
                        if(!lstDMSFileTransfer2Publish.isEmpty()){
                            EventBus.publish(lstDMSFileTransfer2Publish);
                        }
                    }
                }
            }    
        }catch(Exception e){
            logException(e,'ABHI_OmniDocUploadController.transferFilesToOmniDoc');
        }
    }

    public static DMS_Files__c prepareDMSRecord(DMS_Files__c objDMSFileOld, Case objCase, ContentVersion objFileVersion, Integer versionCount){
        DMS_Files__c objDMSFile = new DMS_Files__c();
        
        String leadId = '';
        if(!String.isBlank(objCase.AssetId) && !String.isBlank(objCase.Asset.Lead_Id__c)){
            leadId = objCase.Asset.Lead_Id__c;
        }else if(!String.isBlank(objCase.Lead__c)){
            leadId = objCase.Lead__c;
        }

        objDMSFile.ContentDocumentId__c = objFileVersion != null ? objFileVersion.ContentDocumentId : objDMSFileOld.ContentDocumentId__c;
        objDMSFile.Case__c = objCase.Id;
        objDMSFile.ContentVersionId__c = objFileVersion != null ? objFileVersion.Id : objDMSFileOld.ContentVersionId__c;
        objDMSFile.Has_Multiple_Versions__c = objFileVersion != null ? (versionCount > 1) : objDMSFileOld.Has_Multiple_Versions__c;
        objDMSFile.Is_Latest_Version__c = objFileVersion != null ? (versionCount == Integer.valueof(objFileVersion.VersionNumber)) : objDMSFileOld.Is_Latest_Version__c;
        objDMSFile.Version_Number__c = objFileVersion != null ? objFileVersion.VersionNumber : objDMSFileOld.Version_Number__c;
        objDMSFile.Business_Unit__c = objCase.Business_Unit__c;
        objDMSFile.DMS_External_ID__c = (objFileVersion != null ? objFileVersion.Id : objDMSFileOld.ContentVersionId__c) + '' + System.now().getTime();
        objDMSFile.File_Extension__c = objFileVersion != null ? objFileVersion.FileExtension : objDMSFileOld.File_Extension__c;
        objDMSFile.Next_Retry__c = System.now().addMinutes(15);
        objDMSFile.Status__c = ABHI_Constants.PENDING;
        objDMSFile.File_Name__c = objFileVersion != null ? objFileVersion.Title : objDMSFileOld.File_Name__c;
        //objDMSFile.DMS_Folder_Id__c = '';
        objDMSFile.Application_ID__c = (!String.isBlank(objCase.Asset.LAN__c)) ? objCase.Asset.LAN__c : '';
        //objDMSFile.Policy_No__c = '';
        
        //Cancel if lead missing
        /*if(String.isBlank(leadId)){
            objDMSFile.Status__c = ABHI_Constants.CANCELED;
            objDMSFile.Error_Description__c = ABHI_Constants.ERROR_MISSING_LEAD_FOR_CANCELLED;
        }*/
        
        //Cancel sync if file size exceed 5 MB
        /*if(objFileVersion != null && objDMSFile.Status__c != ABHI_Constants.CANCELED){
            objDMSFile.Status__c = objFileVersion.ContentDocument.ContentSize <= ABFL_Constants.FIVE_MB_FILE_SIZE_BYTES ? ABHI_Constants.PENDING : ABHI_Constants.CANCELED;
            objDMSFile.Error_Description__c = objDMSFile.Status__c == ABHI_Constants.CANCELED ? ABFL_Constants.DMS_SYNC_FILE_SIZE_ERROR : '';
        }*/
        
        return objDMSFile;
    }

    public static DMS_File_Transfer__e prepareDMSFileTransferRecord(DMS_File_Transfer__e objDMSFileTransfer, Case objCase, DMS_Files__c objDMSFile){
        String mobile = (ABHI_Constants.INDIVIDUAL == objCase.Account.RecordType.Name) ? objCase.Account.PersonMobilePhone : objCase.Account.Phone;
                                
        String leadId = '';
        if(!String.isBlank(objCase.AssetId) && !String.isBlank(objCase.Asset.Lead_Id__c)){
            leadId = objCase.Asset.Lead_Id__c;
        }else if(!String.isBlank(objCase.Lead__c)){
            leadId = objCase.Lead__c;
        }

        objDMSFileTransfer = new DMS_File_Transfer__e(
            Business_Unit__c = objDMSFile.Business_Unit__c,
            CaseNumber__c = objCase.CaseNumber,
            ContentVersionId__c = objDMSFile.ContentVersionId__c,
            Customer_Client_Code__c = objCase.Account.Client_Code__c,
            DMS_External_ID__c = objDMSFile.DMS_External_ID__c,
            File_Name__c = objDMSFile.File_Name__c,
            Is_Latest_Version__c = objDMSFile.Is_Latest_Version__c,
            Version_Number__c = objDMSFile.Version_Number__c,
            Application_ID__c = objDMSFile.Application_ID__c,
            DMS_Folder_Id__c = objDMSFile.DMS_Folder_Id__c,
            Policy_No__c = objDMSFile.Policy_No__c,
            Document_Type__c = objCase.Type_Text__c+'-'+objCase.Sub_Type_Text__c+'-'+objCase.Nature__c,
            File_Extension__c = objDMSFile.File_Extension__c,
            Doc_SubType__c = objCase.Sub_Type_Text__c,
            Docgroup_Type__c = objCase.Nature__c.left(1) + '-' + objCase.Type_Text__c,
            Lead_ID__c = leadId,
            Contact_No__c = mobile,
            Source__c = ABHI_Constants.OMNIDOC_FILE_TRANSFER_SOURCE,
            CategoryID__c = ABHI_Constants.OMNIDOC_FILE_TRANSFER_CATEGORYID,
            DocSearchParamId__c = ABHI_Constants.OMNIDOC_FILE_TRANSFER_DOCSEARCHPARAMID_CASE,
            LogicalID__c = ABHI_Constants.OMNIDOC_FILE_TRANSFER_LOGICALID,
            TaskID__c = ABHI_Constants.OMNIDOC_FILE_TRANSFER_TASKID,
            ReferenceID__c = objCase.Id,
            TODID__c = objCase.Id
        );

        return objDMSFileTransfer;
    }

    public static void retryFileTransferToOmniDoc(List<DMS_Files__c> lstOldDMSFiles, List<Id> lstCaseIds){
        try{
            Map<Id,Case> mapCaseRecord = new Map<Id,Case>([Select Id,Business_Unit__c,CaseNumber,Account.Client_Code__c,
                                                            Type_Text__c,Sub_Type_Text__c,Nature__c,Lead__c,CreatedDate,AssetId,Asset.LAN__c,
                                                            Asset.Lead_Id__c,AccountId,Account.Phone,Account.PersonMobilePhone,Account.RecordType.Name
                                                            FROM Case WHERE Id IN:lstCaseIds AND Business_Unit__c =:OMNIDOCS_LINE_OF_BUSINESS AND isClosed=True WITH SYSTEM_MODE]);

            List<DMS_Files__c> lstNewDMSFiles2Insert = new List<DMS_Files__c>();
            if(!lstOldDMSFiles.isEmpty()){
                for(DMS_Files__c objDMSFile : lstOldDMSFiles){
                    if(objDMSFile.Case__c != null && mapCaseRecord.containsKey(objDMSFile.Case__c)) lstNewDMSFiles2Insert.add(prepareDMSRecord(objDMSFile, mapCaseRecord.get(objDMSFile.Case__c), null, 0));
                }
            }
            
            if(!lstNewDMSFiles2Insert.isEmpty() && Schema.sObjectType.DMS_Files__c.isCreateable()){
                insert lstNewDMSFiles2Insert;

                List<DMS_File_Transfer__e> lstDMSFileTransfer2Publish = new List<DMS_File_Transfer__e>();
                for(DMS_Files__c objDMSFile : lstNewDMSFiles2Insert){
                    if(objDMSFile.Status__c == ABHI_Constants.PENDING && objDMSFile.Case__c != null && mapCaseRecord.containsKey(objDMSFile.Case__c)){                
                        lstDMSFileTransfer2Publish.add(prepareDMSFileTransferRecord(new DMS_File_Transfer__e(), mapCaseRecord.get(objDMSFile.Case__c), objDMSFile));
                    }
                }

                if(!lstDMSFileTransfer2Publish.isEmpty()){
                    EventBus.publish(lstDMSFileTransfer2Publish);
                }
            }
        }catch(Exception e){
            logException(e,'ABHI_OmniDocUploadController.retryFileTransferToOmniDoc');
        }
    }

    public static void logException(Exception objException, String methodName){
        //System.debug('Exception ~> '+ objException.getMessage()+'; at line ~> '+objException.getStackTraceString());
        ABCL_Logger.enableExceptionLogging();
        ABCL_Logger.push(methodName);
        ABCL_Logger.message(objException.getMessage());
        ABCL_Logger.message(objException.getStackTraceString());
        ABCL_Logger.emit();
        //throw new AuraHandledException(objException.getMessage()+'; at line ~> '+objException.getStackTraceString());
    }
}