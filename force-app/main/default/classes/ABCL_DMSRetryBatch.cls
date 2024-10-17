
/**
* Class              :  ABCL_DMSRetryBatch
* TestClass          :  
* Author             :  
* Created Date       :  
* LastModified Audit :  24/09/2024 Arshad(msharieff@salesforce.com)
* Description        :  
* /* MODIFICATION LOG
* Developer                                Date               Description
* -------------------------------------------------------------------------------------------
* Arshad(msharieff@salesforce.com)        24/09/2024         ABHI OmniDoc FileTransfer Retry flow, ABHI_OmniDocUploadCtrlTestClass
* 
* *****************************************************************************************************
*/
public class ABCL_DMSRetryBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        string queryForContentLink = 'Select id,ContentDocumentid,LinkedEntityId from ContentDocumentLink where LinkedEntityId in'+
            '(Select id from Case where IsClosed = true and ClosedDate <= today and Business_Unit__c IN (\'ABHFL\',\'ABSLI\',\'ABHI\'))';
        return Database.getQueryLocator(queryForContentLink);
    }
    
    public void execute(Database.BatchableContext bc, List<ContentDocumentLink> contentDocumentLinkList){
        
        //ContentDocument Records of Closed Cases
        Set<String> contentDocumentIds = new Set<String>();
        for(ContentDocumentLink docLink : contentDocumentLinkList){
            contentDocumentIds.add(docLink.ContentDocumentId);
        }
        
        Map<Id,ContentVersion> contentVersionInitialMap = new Map<Id,ContentVersion>([ Select id,Title,ContentDocumentId,VersionNumber,FileExtension
                                                                                      from ContentVersion where ContentDocumentId in: contentDocumentIds]);
        
        Set<String> contentVersionIds = new Set<String>();
        Map<String,Set<String>> contentDocumentContentVersionMap = new Map<String,Set<String>>();
        for(ContentVersion contentVersion : contentVersionInitialMap.values()){
            contentVersionIds.add(contentVersion.Id);
            if(!contentDocumentContentVersionMap.containsKey(contentVersion.ContentDocumentId)){
                contentDocumentContentVersionMap.put(contentVersion.ContentDocumentId, new Set<String>{contentVersion.Id});
            }else{
                Set<String> contentVersionId = contentDocumentContentVersionMap.get(contentVersion.ContentDocumentId);
                contentVersionId.add(contentVersion.Id);
                contentDocumentContentVersionMap.put(contentVersion.ContentDocumentId,contentVersionId);
            }
        }
        
        //Find Out Successful DMS Transfers for relevant ContentDocuments
        Map<Id,DMS_Files__c> dmsRecords = new Map<Id,DMS_Files__c>([Select id,ContentDocumentId__c,Case__c,ContentVersionId__c from DMS_Files__c
                                                                    where ContentVersionId__c in: contentVersionIds and Status__c = 'Success']);
        Set<String> caseContentHashString = new Set<String>();
        for(DMS_Files__c dmsFiles : dmsRecords.values()){
            caseContentHashString.add(dmsFiles.Case__c+'_'+dmsFiles.ContentDocumentId__c+'_'+dmsFiles.ContentVersionId__c);
        }
        
        Set<String> pendingCaseRecords = new Set<String>();
        //Filter out ContentDocumentIds with unsuccessful DMS File Transfers
        List<contentDocumentLink> pendingContentDocumentLink = new List<ContentDocumentLink>();
        List<ContentVersion> contentVersionFinalList = new List<ContentVersion>();
        for(integer i=0;i < contentDocumentLinkList.size();i++){
            Set<String> conVersionList = contentDocumentContentVersionMap.get(contentDocumentLinkList[i].ContentDocumentId);
            for(String conVersion : conVersionList){
                if(!caseContentHashString.contains(contentDocumentLinkList[i].LinkedEntityId + '_' +contentDocumentLinkList[i].ContentDocumentId + '_' + conVersion)){
                    contentVersionFinalList.add(contentVersionInitialMap.get(conVersion));
                    pendingCaseRecords.add(contentDocumentLinkList[i].LinkedEntityId);
                    pendingContentDocumentLink.add(contentDocumentLinkList[i]);
                }
            }
            
        }
        
        Map<Id,Case> caseRecordMap = new Map<Id,Case>([Select id,Business_Unit__c,CaseNumber,Account.Client_Code__c,
                                                       Type_Text__c,Sub_Type_Text__c,Nature__c,Lead__c,CreatedDate,Asset.LAN__c,
                                                       Asset.Lead_Id__c,Asset.Application_Number__c, Asset.Policy_No__c, LAN__c, CCC_External_Id__c,Account.Phone,Account.PersonMobilePhone,Account.RecordType.Name
                                                       from Case where Id =: pendingCaseRecords]);
        
        // Custom Logic handling for ABSLI Business Unit
        Map<String,ASF_Case_Category_Config__c> cccRecord = new Map<String,ASF_Case_Category_Config__c>();
        Set<String> cccExternalIds = new Set<String>();
        for(Case cs : caseRecordMap.values()){
            if(cs.Business_Unit__c == ABSLI_Constants.BUSINESS_UNIT){
                cccExternalIds.add(cs.CCC_External_Id__c);
            }
        }
        for (ASF_Case_Category_Config__c ccc : [
            SELECT Id, CCC_External_Id__c, DMS_Folder_Id__c
            FROM ASF_Case_Category_Config__c
            WHERE CCC_External_Id__c IN :cccExternalIds
            WITH SECURITY_ENFORCED
        ]) {
            cccRecord.put(ccc.CCC_External_Id__c, ccc);
        }
        
        Map<Id,Case> contentDocumentCaseMap = new Map<Id,Case>();
        for(ContentDocumentLink docLink : pendingContentDocumentLink){
            contentDocumentCaseMap.put(docLink.ContentDocumentId,caseRecordMap.get(docLink.LinkedEntityId));
        }
        
        Map<String,Integer> contentDocumentVersionMap = new Map<String,Integer>();
        for(ContentVersion version : contentVersionFinalList){
            Integer count = 0;
            if(contentDocumentVersionMap.containsKey(version.ContentDocumentId)){
                count = contentDocumentVersionMap.get(version.ContentDocumentId);
            }
            count += 1;
            contentDocumentVersionMap.put(version.ContentDocumentId,count);
        }
        
        //Create DMS Files Records for unsuccessful ContentVersionids
        List<DMS_Files__c> fileRecList = new List<DMS_Files__c>();
        for(ContentVersion fileVersion : contentVersionFinalList){
            
            DMS_Files__c fileRec = new DMS_Files__c();
            Case relatedCase = contentDocumentCaseMap.get(fileVersion.ContentDocumentId);
            
            // Custom Logic handling for ABSLI Business Unit
            String dmsFolderId = '', businessFileName = '', policyNumber = '', applicationId = '';
            Boolean isABSLIBusiness = false;
            Boolean isABHI = (relatedCase.Business_Unit__c == ABHI_Constants.ABHI) ? true : false;
            if (relatedCase.Business_Unit__c == ABSLI_Constants.BUSINESS_UNIT) {
                isABSLIBusiness = true;
                policyNumber = relatedCase.Asset.Policy_No__c != '' ? relatedCase.Asset.Policy_No__c : relatedCase.LAN__c;
                dmsFolderId = cccRecord.get(relatedCase.CCC_External_Id__c).DMS_Folder_Id__c;
                applicationId = relatedCase.Asset.Application_Number__c;
                businessFileName =
                    applicationId +'_' +policyNumber +'_' +dmsFolderId +'_' +
                    Datetime.now().format('ddMMyyyy');
            }
            
            string leadId = '';
            if(relatedCase.Asset.Lead_Id__c != null){
                leadId = relatedCase.Asset.Lead_Id__c;
            } else if(relatedCase.Lead__c != null){
                leadId = relatedCase.Lead__c;
            }
            Integer versionCount = contentDocumentVersionMap.get(fileVersion.ContentDocumentId);
            fileRec.ContentDocumentId__c = fileVersion.ContentDocumentId;
            fileRec.Case__c = relatedCase.Id;
            fileRec.ContentVersionId__c = fileVersion.Id;
            fileRec.Has_Multiple_Versions__c = versionCount > 1 ? true : false;
            fileRec.Is_Latest_Version__c = versionCount == Integer.valueof(fileVersion.VersionNumber) ? true : false;
            fileRec.Version_Number__c = fileVersion.VersionNumber;
            fileRec.Business_Unit__c = relatedCase.Business_Unit__c;
            DateTime currentDateTime = System.now();
            fileRec.DMS_External_ID__c = fileVersion.Id + '' + currentDateTime.getTime();
            fileRec.File_Extension__c = fileVersion.FileExtension;
            if(String.isBlank(leadId) && !isABSLIBusiness){
                if(!isABHI){
                    fileRec.Status__c = ABHFL_Constants.CANCELED;
                    fileRec.Error_Description__c = ABHFL_Constants.ERROR_DESC_FOR_CANCELLED_DMS;
                }else{
                    fileRec.Status__c = ABHFL_Constants.PENDING;	
                }
            } else {
                fileRec.Status__c = ABHFL_Constants.PENDING;
            }
            // Modified Attribute for ABSLI specific Business Unit
            fileRec.File_Name__c = isABSLIBusiness ? businessFileName : fileVersion.Title;
            fileRec.DMS_Folder_Id__c = isABSLIBusiness ? dmsFolderId : '';
            fileRec.Application_ID__c = isABSLIBusiness ? applicationId : relatedCase.Asset.LAN__c;
            fileRec.Policy_No__c = isABSLIBusiness ? policyNumber : '';
            fileRec.Next_Retry__c = isABSLIBusiness ? null : System.now().addMinutes(15);
            fileRecList.add(fileRec);
        }
        
        if(fileRecList.size() > 0){
            insert fileRecList;
            
            List<DMS_File_Transfer__e> dmsEventList = new List<DMS_File_Transfer__e>();
            for(DMS_Files__c file : fileRecList){
                if(file.Status__c == ABHFL_Constants.PENDING){
                    Case relatedCase = contentDocumentCaseMap.get(file.ContentDocumentId__c);
                    string mobile = '';
                    if(ABHFL_Constants.ACCOUNT_RECORDTYPE_INDIVIDUAL == relatedCase.Account.RecordType.Name){
                        mobile = relatedCase.Account.PersonMobilePhone;
                    }else {
                        mobile = relatedCase.Account.Phone;
                    }
                    string leadId = '';
                    if(relatedCase.Asset.Lead_Id__c != null){
                        leadId = relatedCase.Asset.Lead_Id__c;
                    } else if(relatedCase.Lead__c != null){
                        leadId = relatedCase.Lead__c;
                    }
                    
                    DMS_File_Transfer__e objDMSEvent = new DMS_File_Transfer__e();
                    objDMSEvent.Business_Unit__c = file.Business_Unit__c;
                    objDMSEvent.CaseNumber__c = relatedCase.CaseNumber;
                    objDMSEvent.ContentVersionId__c = file.ContentVersionId__c;
                    objDMSEvent.Customer_Client_Code__c = relatedCase.Account.Client_Code__c;
                    objDMSEvent.DMS_External_ID__c = file.DMS_External_ID__c;
                    objDMSEvent.File_Name__c = file.File_Name__c;
                    objDMSEvent.Is_Latest_Version__c = file.Is_Latest_Version__c;
                    objDMSEvent.Version_Number__c = file.Version_Number__c;
                    objDMSEvent.Application_ID__c = file.Application_ID__c;
                    objDMSEvent.DMS_Folder_Id__c = file.DMS_Folder_Id__c;
                    objDMSEvent.Policy_No__c = file.Policy_No__c;
                    objDMSEvent.Document_Type__c = relatedCase.Type_Text__c+'-'+relatedCase.Sub_Type_Text__c+'-'+relatedCase.Nature__c;
                    objDMSEvent.File_Extension__c = file.File_Extension__c;
                    objDMSEvent.Doc_SubType__c = relatedCase.Sub_Type_Text__c;
                    objDMSEvent.Docgroup_Type__c = relatedCase.Nature__c.left(1) + '-' + relatedCase.Type_Text__c;
                    objDMSEvent.Lead_ID__c = leadId;
                    objDMSEvent.Contact_No__c = mobile;
                    objDMSEvent.Source__c = ASF_Constants.DMS_FILE_TRANSFER_SOURCE;
                    if(relatedCase.Business_Unit__c == ABHI_Constants.ABHI){
                        objDMSEvent.Source__c = ABHI_Constants.OMNIDOC_FILE_TRANSFER_SOURCE;
                        objDMSEvent.CategoryID__c = ABHI_Constants.OMNIDOC_FILE_TRANSFER_CATEGORYID;
                        objDMSEvent.DocSearchParamId__c = ABHI_Constants.OMNIDOC_FILE_TRANSFER_DOCSEARCHPARAMID_CASE;
                        objDMSEvent.LogicalID__c = ABHI_Constants.OMNIDOC_FILE_TRANSFER_LOGICALID;
                        objDMSEvent.TaskID__c = ABHI_Constants.OMNIDOC_FILE_TRANSFER_TASKID;
                        objDMSEvent.ReferenceID__c = relatedCase.Id;
                        objDMSEvent.TODID__c = relatedCase.Id;
                    }
                    
                    dmsEventList.add(objDMSEvent);
                }
                
                if(dmsEventList.size() > 0){
                    List<Database.SaveResult> eventResult = EventBus.publish(dmsEventList);
                }
            }
            
        }
    }
    
    public void finish(Database.BatchableContext bc){
    }
    
    public void execute(SchedulableContext sc) {
    }
    
    
}