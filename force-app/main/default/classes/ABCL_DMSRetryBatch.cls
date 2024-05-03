public class ABCL_DMSRetryBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        string queryForContentLink = 'Select id,ContentDocumentid,LinkedEntityId from ContentDocumentLink where LinkedEntityId in'+
            						 '(Select id from Case where IsClosed = true and ClosedDate <= today and Business_Unit__c = \'ABHFL\')';
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
                                                       Asset.Lead_Id__c,Account.Phone,Account.PersonMobilePhone,Account.RecordType.Name  
                                                       from Case where Id =: pendingCaseRecords]);
        
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
            fileRec.File_Name__c = fileVersion.Title;
            fileRec.Has_Multiple_Versions__c = versionCount > 1 ? true : false;
            fileRec.Is_Latest_Version__c = versionCount == Integer.valueof(fileVersion.VersionNumber) ? true : false;
            fileRec.Version_Number__c = fileVersion.VersionNumber;
            fileRec.Business_Unit__c = relatedCase.Business_Unit__c;
            DateTime currentDateTime = System.now();
            fileRec.DMS_External_ID__c = fileVersion.Id + '' + currentDateTime.getTime();
            fileRec.File_Extension__c = fileVersion.FileExtension;
            fileRec.Next_Retry__c = System.now().addMinutes(15);
            if(String.isBlank(leadId)){
                fileRec.Status__c = ABHFL_Constants.CANCELED;
            } else {
                fileRec.Status__c = ABHFL_Constants.PENDING;
            }
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
                    
                    dmsEventList.add(new DMS_File_Transfer__e(
                        Business_Unit__c = file.Business_Unit__c,
                        CaseNumber__c = relatedCase.CaseNumber,
                        ContentVersionId__c = file.ContentVersionId__c,
                        Customer_Client_Code__c = relatedCase.Account.Client_Code__c,
                        DMS_External_ID__c = file.DMS_External_ID__c,
                        File_Name__c = file.File_Name__c,
                        Is_Latest_Version__c = file.Is_Latest_Version__c,
                        Version_Number__c = file.Version_Number__c,
                        Application_ID__c = relatedCase.Asset.LAN__c,
                        Document_Type__c = relatedCase.Type_Text__c+'-'+relatedCase.Sub_Type_Text__c+'-'+relatedCase.Nature__c,
                        File_Extension__c = file.File_Extension__c,
                        Doc_SubType__c = relatedCase.Sub_Type_Text__c,
                        Docgroup_Type__c = relatedCase.Nature__c.left(1) + '-' + relatedCase.Type_Text__c,
                        Lead_ID__c = leadId,
                        Contact_No__c = mobile,
                        Source__c = ASF_Constants.DMS_FILE_TRANSFER_SOURCE
                    ));
                }
            }
            
            if(dmsEventList.size() > 0){
                List<Database.SaveResult> eventResult = EventBus.publish(dmsEventList);
            }
        }
        
    }
    
    public void finish(Database.BatchableContext bc){
    }    
    
    public void execute(SchedulableContext sc) {
    }
    
    
}