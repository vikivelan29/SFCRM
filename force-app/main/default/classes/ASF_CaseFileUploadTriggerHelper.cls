public with sharing class ASF_CaseFileUploadTriggerHelper {
	
    public static Boolean isSuperUser = FeatureManagement.checkPermission('Bypass_Case_File_Update_Validation');
    
    public static void validateFileDelete(List<ContentDocumentLink> newList, Map<Id, ContentDocumentLink> oldMap){
        
        if(ASF_CaseFileUploadTriggerHelper.bypassValidation() && !Test.isRunningTest()){
           return;
        }
        Boolean isDelete = newList==null ? true : false;
        List<ContentDocumentLink> contentDocLinkList = isDelete ? oldMap.values() : newList;
        List<ContentDocumentLink> eligibleRecords = new List<ContentDocumentLink>();
        List<Id> linkedCaseIds = new List<Id>();  
        List<Id> closedCaseIds = new List<Id>();
        List<Id> contentDocIds = new List<Id>();
        Map<Id, ContentDocument> contentDocMap;
        
        for(ContentDocumentLink cdLinkRec : contentDocLinkList){
            if(cdLinkRec.LinkedEntityId.getSObjectType() == Case.SObjectType){
                linkedCaseIds.add(cdLinkRec.LinkedEntityId);
                contentDocIds.add(cdLinkRec.ContentDocumentId);
                eligibleRecords.add(cdLinkRec);
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
                if(!closedCaseIds.isEmpty() && closedCaseIds.contains(cdLinkRec.LinkedEntityId)){
                    cdLinkRec.addError(System.Label.ASF_File_Update_Validation);
                }
                if(!isSuperUser && UserInfo.getUserId() != contentDocMap.get(cdLinkRec.ContentDocumentId).OwnerId){
                    cdLinkRec.addError(System.Label.ASF_File_Update_Val_Message);
                }
            }
        }
    }
    public static void validateCaseFileUpdate(Map<Id, ContentDocument> newMap, Map<Id, ContentDocument> oldMap){
        if(ASF_CaseFileUploadTriggerHelper.bypassValidation() && !Test.isRunningTest()){
            return;
        }
        Boolean isDelete = newMap==null ? true : false;
        Map<Id,Id> contentDocLinkandCaseMap = new Map<Id,Id>();
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
                        if(closedCaseIds.contains(contentDocLinkandCaseMap.get(linkedDocRec))){
                            contentDocRec.addError(System.Label.ASF_File_Update_Validation);
                        }
                    }    
                }  
                if(!isSuperUser && UserInfo.getUserId() != contentDocRec.OwnerId){
                    contentDocRec.addError(System.Label.ASF_File_Update_Val_Message);
                }
            }
        } 
    } 
    public static boolean bypassValidation(){
        boolean result = false;
        
        List<Id> bypassProfileId = new List<Id>();
        for(Profile profRec : [select Id, Name from profile where Name IN : ASF_Constants.VALIDATION_BYPASS_PROFILES]){
            bypassProfileId.add(profRec.Id);
        }
        //Bypass owner validations for the sys admin and Integration Profiles
        if(bypassProfileId.contains(UserInfo.getProfileId())){
            return true;
        }
        return result;
    }
}