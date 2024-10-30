public without sharing class ASF_CaseFileUploadTriggerHelper {
    
    public static Boolean isSuperUser = FeatureManagement.checkPermission('Bypass_Case_Validation');
    public static Boolean isCustomDelete = false;
    
    public static void validateFileDelete(List<ContentDocumentLink> newList, Map<Id, ContentDocumentLink> oldMap){
        Boolean isDelete = newList==null ? true : false;
        if(ABCL_CommonCLass.bypassValidation() && !Test.isRunningTest()){
            if(isDelete){
                createFeedItem(null, oldMap.values(), 'contentDocumentLink');
            }
            return;
        }
        List<ContentDocumentLink> contentDocLinkList = isDelete ? oldMap.values() : newList;
        List<ContentDocumentLink> eligibleRecords = new List<ContentDocumentLink>();
        List<Id> linkedCaseIds = new List<Id>();
        Map<Id,ContentDocumentLink> linkedEmIds = new Map<Id,ContentDocumentLink>();
        List<Id> closedCaseIds = new List<Id>();
        List<Id> contentDocIds = new List<Id>();
        Map<Id, ContentDocument> contentDocMap;
        Map<Id,Id> entityToCaseMap = new Map<Id,Id>();
        for(ContentDocumentLink cdLinkRec : contentDocLinkList){
            if(cdLinkRec.LinkedEntityId.getSObjectType() == Case.SObjectType){
                linkedCaseIds.add(cdLinkRec.LinkedEntityId);
                contentDocIds.add(cdLinkRec.ContentDocumentId);
                eligibleRecords.add(cdLinkRec);
            }
            else if(cdLinkRec.LinkedEntity.Type == 'EmailMessage'){
                linkedEmIds.put(cdLinkRec.LinkedEntityId, cdLinkRec);
                contentDocIds.add(cdLinkRec.ContentDocumentId);
                eligibleRecords.add(cdLinkRec);
            }
        }
        if(!linkedEmIds.isEmpty()){
            for(EmailMessage emailMessageRec : [select Id, RelatedToId from EmailMessage where Id IN: linkedEmIds.keySet()]){
                if(String.valueOf(emailMessageRec.RelatedToId).startsWith('500')){
                    linkedCaseIds.add(emailMessageRec.RelatedToId);
                    entityToCaseMap.put(linkedEmIds.get(emailMessageRec.Id).Id, emailMessageRec.RelatedToId);
                } 
            }
        }
        if(!linkedCaseIds.isEmpty()){
            for(Case caseRec : [select Id, isClosed from case where ID IN: linkedCaseIds and isClosed = true]){
                closedCaseIds.add(caseRec.Id);
            }
        }
        if(!contentDocIds.isEmpty()){
            contentDocMap = new Map<Id, ContentDocument>([select Id, OwnerId from ContentDocument where ID IN: contentDocIds]);
        }
        if(!eligibleRecords.isEmpty()){
            for(ContentDocumentLink cdLinkRec : eligibleRecords){
                //Validation for Remove from Record of closed case
                if(!closedCaseIds.isEmpty()){
                    if(cdLinkRec.LinkedEntity.Type == 'EmailMessage' && entityToCaseMap.containsKey(cdLinkRec.LinkedEntityId) && closedCaseIds.contains(entityToCaseMap.get(cdLinkRec.LinkedEntityId))){
                        cdLinkRec.addError(System.Label.ASF_File_Update_Validation);
                    } else if(closedCaseIds.contains(cdLinkRec.LinkedEntityId)){
                        cdLinkRec.addError(System.Label.ASF_File_Update_Validation);
                    }                    
                }
                if(!isSuperUser && UserInfo.getUserId() != contentDocMap.get(cdLinkRec.ContentDocumentId).OwnerId){
                    cdLinkRec.addError(System.Label.ASF_File_Update_Val_Message);
                }
            }
            if(isDelete){
                createFeedItem(null, oldMap.values(), 'contentDocumentLink');
            }
        }
    }

    public static void validateCaseFileUpdate(Map<Id, ContentDocument> newMap, Map<Id, ContentDocument> oldMap){
        Boolean isDelete = newMap==null ? true : false;
        if(ABCL_CommonCLass.bypassValidation() && !Test.isRunningTest()){
            if(isDelete){
                createFeedItem(oldMap, null, 'contentDocument');
            }
            return;
        }
        Map<Id,Id> contentDocLinkandCaseMap = new Map<Id,Id>();
        Map<Id,ContentDocumentLink> contentDocLinkandEMMap = new Map<Id,ContentDocumentLink>();
        Map<Id,List<Id>> contentDocandLinkMap = new Map<Id,List<Id>>();
        List<Id> closedCaseIds = new List<Id>();
        Map<Id, ContentDocument> contentDocMap = !isDelete ? newMap : oldMap;
        for(ContentDocumentLink cdLinkRec : [SELECT Id, LinkedEntityId, LinkedEntity.Type, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN: contentDocMap.keySet()]){
            
            if(cdLinkRec.LinkedEntity.Type == 'Case'){
                contentDocLinkandCaseMap.put(cdLinkRec.Id,cdLinkRec.LinkedEntityId);
                if(!contentDocandLinkMap.containsKey(cdLinkRec.ContentDocumentId)){
                    contentDocandLinkMap.put(cdLinkRec.ContentDocumentId, new List<Id>());
                }
                contentDocandLinkMap.get(cdLinkRec.ContentDocumentId).add(cdLinkRec.Id);
            }    
            else if(cdLinkRec.LinkedEntity.Type == 'EmailMessage'){
                contentDocLinkandEMMap.put(cdLinkRec.LinkedEntityId,cdLinkRec);
            }
        }
        if(!contentDocLinkandEMMap.isEmpty()){
            for(EmailMessage emailMessageRec : [select Id, RelatedToId from EmailMessage where Id IN: contentDocLinkandEMMap.keySet()]){
                if(String.valueOf(emailMessageRec.RelatedToId).startsWith('500')){
                    contentDocLinkandCaseMap.put(contentDocLinkandEMMap.get(emailMessageRec.Id).Id,emailMessageRec.RelatedToId);
                    if(!contentDocandLinkMap.containsKey(contentDocLinkandEMMap.get(emailMessageRec.Id).ContentDocumentId)){
                        contentDocandLinkMap.put(contentDocLinkandEMMap.get(emailMessageRec.Id).ContentDocumentId, new List<Id>());
                    }
                    contentDocandLinkMap.get(contentDocLinkandEMMap.get(emailMessageRec.Id).ContentDocumentId).add(contentDocLinkandEMMap.get(emailMessageRec.Id).Id);
                }
            }
        }
        if(!contentDocLinkandCaseMap.isEmpty()){
            for(Case caseRec : [select Id, isClosed from case where ID IN: contentDocLinkandCaseMap.values() and isClosed = true]){
                closedCaseIds.add(caseRec.Id);
            }
        }
        if(!contentDocLinkandCaseMap.isEmpty()){
            for (ContentDocument contentDocRec : contentDocMap.values()) {
                //validation for upload new version, edit and delete file details of closed case
                if(!closedCaseIds.isEmpty() && contentDocandLinkMap.containsKey(contentDocRec.Id)){
                    List<Id> linkedDocIds = contentDocandLinkMap.get(contentDocRec.Id);
                    for(Id linkedDocRec : linkedDocIds){
                        if(closedCaseIds.contains(contentDocLinkandCaseMap.get(linkedDocRec)) && !ASF_ContentDocumentTriggerHandler.beforeInsertProcessed){
                            contentDocRec.addError(System.Label.ASF_File_Update_Validation);
                        }
                    }    
                }  
                if(!isSuperUser && UserInfo.getUserId() != contentDocRec.OwnerId && !ASF_ContentDocumentTriggerHandler.beforeInsertProcessed){
                    contentDocRec.addError(System.Label.ASF_File_Update_Val_Message);
                }
            }
            if(isDelete){
                createFeedItem(oldMap, null, 'contentDocument');
            }
        } 
    } 
    @AuraEnabled
    public static String fetchContentDoc(String contentVersionId) {
        String docId = '';
        if(contentVersionId != null){
            try{
                Id contentDocumentId = [SELECT Id, ContentDocumentId from ContentVersion where Id =: contentVersionId LIMIT 1].contentDocumentId;
                docId = contentDocumentId;           
            }catch(Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
        return docId;
    }    
    @AuraEnabled
    public static String deleteFileById(String fileId, String comment) {
        String result = 'Error';
        List<Id> emailMessageIds = new List<Id>();
        Set<Id> caseIds = new Set<Id>();
        if(fileId != null){
            try{
                String contentDocId = ASF_CaseFileUploadTriggerHelper.fetchContentDoc(fileId);
                ContentDocument contentDocRec = [SELECT Id, Title from ContentDocument where Id =: contentDocId];
                List<ContentDocumentLink> contentdocLinkList = [SELECT Id, LinkedEntityId, LinkedEntity.Type from ContentDocumentLink 
                                                                WHERE ContentDocumentId =: contentDocId];
                if(!contentdocLinkList.isEmpty()){
                    List<FeedItem> feedItemList = new List<FeedItem>();
                    for(ContentDocumentLink contentLinkRec : contentdocLinkList){
                        if(contentLinkRec.LinkedEntity.Type == 'EmailMessage'){
                            emailMessageIds.add(contentLinkRec.LinkedEntityId);
                        }else if(contentLinkRec.LinkedEntity.Type == 'Case'){
                            caseIds.add(contentLinkRec.LinkedEntityId);
                        }
                    }
                    if(!emailMessageIds.isEmpty()){
                        for(EmailMessage emailMessageRec : [select Id, RelatedToId from EmailMessage where Id IN: emailMessageIds]){
                            if(String.valueOf(emailMessageRec.RelatedToId).startsWith('500')){
                                caseIds.add(emailMessageRec.RelatedToId);
                            }
                        }
                    }
                    for(Id caseId : caseIds){
                        FeedItem feedItem = new FeedItem();
                        feedItem.ParentId = caseId;
                        feedItem.Type = 'TextPost';
                        feedItem.Body = 'The file \''+contentDocRec.Title+'\' has been deleted - '+comment;
                        feedItemList.add(FeedItem);
                    }
                    isCustomDelete = true;   
                    delete contentDocRec;
                    insert feedItemList;
                } 
                result = contentDocId;                
            }catch(Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
        return result;
    }
    
    
    public static void createFeedItem(Map<Id, ContentDocument> newMap, List<ContentDocumentLink> newList, String objname){
        Map<Id, String> emailMessageIds = new Map<Id, String>();
        Map<Id, List<String>> caseIdToTitlesMap = new Map<Id, List<String>>();
        Set<Id> contentDocIds = new Set<Id>();
        if(objname == 'contentDocument'){
            contentDocIds = newMap.keySet();
        }else if(objname == 'contentDocumentLink'){
            for(ContentDocumentLink cdLinkRec : newList){
                if(cdLinkRec.LinkedEntityId.getSObjectType() == Case.SObjectType){
                    contentDocIds.add(cdLinkRec.ContentDocumentId);
                }
            }
        }
        List<ContentDocumentLink> contentdocLinkList = [SELECT Id, LinkedEntityId, LinkedEntity.Type, ContentDocument.Title from ContentDocumentLink 
                                                        WHERE ContentDocumentId =: contentDocIds];
        if(!contentdocLinkList.isEmpty()){
            List<FeedItem> feedItemList = new List<FeedItem>();
            for(ContentDocumentLink contentLinkRec : contentdocLinkList){
                if(contentLinkRec.LinkedEntity.Type == 'EmailMessage'){
                    emailMessageIds.put(contentLinkRec.LinkedEntityId,contentLinkRec.ContentDocument.Title);
                }else if(contentLinkRec.LinkedEntity.Type == 'Case'){
                    if(!caseIdToTitlesMap.containsKey(contentLinkRec.LinkedEntityId)){
                        caseIdToTitlesMap.put(contentLinkRec.LinkedEntityId, new List<String>{contentLinkRec.ContentDocument.Title});
                    }else{
                        caseIdToTitlesMap.get(contentLinkRec.LinkedEntityId).add(contentLinkRec.ContentDocument.Title);
                    }
                }
            }
            if(!emailMessageIds.isEmpty()){
                for(EmailMessage emailMessageRec : [select Id, RelatedToId from EmailMessage where Id IN: emailMessageIds.keySet()]){
                    if(String.valueOf(emailMessageRec.RelatedToId).startsWith('500')){
                        if(!caseIdToTitlesMap.containsKey(emailMessageRec.RelatedToId)){
                            caseIdToTitlesMap.put(emailMessageRec.RelatedToId, new List<String>{emailMessageIds.get(emailMessageRec.Id)});
                        }else{
                            caseIdToTitlesMap.get(emailMessageRec.RelatedToId).add(emailMessageIds.get(emailMessageRec.Id));
                        }
                    }
                }
            }
            if(!isCustomDelete){
                for(Id caseId : caseIdToTitlesMap.keySet()){
                    for(String title : caseIdToTitlesMap.get(caseId)){
                        FeedItem feedItem = new FeedItem();
                        feedItem.ParentId = caseId;
                        feedItem.Type = 'TextPost';
                        feedItem.Body = 'The file \''+title+'\' has been deleted';
                        feedItemList.add(FeedItem);
                    }
                }
                
                insert feedItemList; 
            }   
        }
    } 
    /**
    * @description : PR1030924-211: Method created to validate Case File.
    * @author zahedali.mohammed@salesforce.com | 09-24-2024 
    * @param List<ContentDocumentLink> newFiles
    * @return void
    **/
    public static void validateCaseFile(List<ContentDocumentLink> newFiles){
        try{
            Set<Id> recordIds = new Set<Id>();
            for (ContentDocumentLink link : newFiles) {
                if (link.LinkedEntityId != null) {
                    recordIds.add(link.LinkedEntityId);
                }
            }
            
            Map<Id, SObject> recordMap = new Map<Id, SObject>(
                [SELECT OwnerId,Business_Unit__c FROM Case WHERE Id IN :recordIds]
            );
            
            for (ContentDocumentLink link : newFiles) {
                SObject record = recordMap.get(link.LinkedEntityId);
                if (record != null && record.get('Business_Unit__c')==System.label.Wellness_BU) {                   
                    Id ownerId = (Id) record.get('OwnerId');                 
                    if (ownerId != UserInfo.getUserId() && !Test.isRunningTest()) {
                        link.addError(System.Label.Wellness_CaseComment_add_Err_Msg);
                    }
                }
            }
        }catch(Exception e){
            system.debug('Error-->'+e.getMessage());
        }
    }

    /****************************************************************************************************************
* @param newMap
* @description - for firing notification on file upload for sprinklr cases
*****************************************************************************************************************/

public static void checkifCaseAttachmentAdded(Map<Id, ContentDocumentLink> newMap) {
        
    Map<Id, Id> contentDocLinkToCaseMap = new Map<Id, Id>();
    Map<Id, Case> caseMap = new Map<Id, Case>();
    Set<Id> caseIds = new Set<Id>();
    string sprinklrUpdateBus = label.ABSLAMC_SprinklrUpdateSpecificBUs; 
    List<String> eligibleBUs = new List<String>(sprinklrUpdateBus.split(','));
    String currentUserProfileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
    boolean apiUser = true;
    apiUser = (currentUserProfileName == ABSLAMC_Constants.APIUSERPROILENAME) ? true : false;
    
    if(apiUser){
        List<ContentDocumentLink> existingLinks = [SELECT Id, LinkedEntityId, LinkedEntity.Type 
                                                   FROM ContentDocumentLink 
                                                   WHERE ContentDocumentId IN :newMap.keySet()];
        System.debug('existing links niks: ' + existingLinks);
        
        
        Set<String> existingKeys = new Set<String>();
        for (ContentDocumentLink link : existingLinks) {
            String key = link.ContentDocumentId + '-' + link.LinkedEntityId;
            existingKeys.add(key);
        }
        
        for (ContentDocumentLink cdLinkRec : newMap.values()) {
            if (cdLinkRec.LinkedEntityId.getSObjectType() == Case.SObjectType) {
                String key = cdLinkRec.ContentDocumentId + '-' + cdLinkRec.LinkedEntityId;
                if (!existingKeys.contains(key)) {
                    caseIds.add(cdLinkRec.LinkedEntityId);
                }
            }
        }            
        if (!caseIds.isEmpty()) {
            caseMap.putAll([SELECT Id,Business_Unit__c,Notes_from_Sprinklr__c,OwnerId,CaseNumber 
                            FROM Case 
                            WHERE Business_Unit__c IN: eligibleBUs
                            AND Id IN :caseIds]);
            
        }
        if(!caseMap.isEmpty()){
        ABSLAMC_SprinklrHelper.fireSystemNotification(caseMap,'File Upload');
        }
    }
}
}