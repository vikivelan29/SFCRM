public with sharing class ASF_ContentDocLinkTriggerHandler extends ASF_VTriggerHandler{

    public override void BeforeDelete(Map<Id, SObject> oldItems){
        ASF_CaseFileUploadTriggerHelper.validateFileDelete(null, (Map<Id, ContentDocumentLink>)oldItems);
    }
    public override void AfterInsert(Map<Id, SObject> newMap){
        checkForClosedCase(newMap);
    }
    
    public static void checkForClosedCase(Map<Id, SObject> contentLinksMap){
        if(ASF_ContentDocLinkTriggerHandler.bypassValidation() && !Test.isRunningTest()){
            return ;
        }
        Map<Id,Id> contentDocLinkandCaseMap = new Map<Id,Id>();
        List<Id> closedCaseIds = new List<Id>();
     	for(ContentDocumentLink cdLinkRec : (List<ContentDocumentLink>)contentLinksMap.values()){
            if(cdLinkRec.LinkedEntityId.getSObjectType() == Schema.Case.SObjectType ){
                contentDocLinkandCaseMap.put(cdLinkRec.Id,cdLinkRec.LinkedEntityId);
            }    
        }
        if(!contentDocLinkandCaseMap.isEmpty()){
            for(Case caseRec : [select Id, isClosed from case where ID IN: contentDocLinkandCaseMap.values() and isClosed = true]){
                closedCaseIds.add(caseRec.Id);
            }
    	}
        if(!contentDocLinkandCaseMap.isEmpty()){
            for (ContentDocumentLink cdLinkRec : (List<ContentDocumentLink>)contentLinksMap.values()) {
                //validation for create link for uploaded file on a closed case
                if(!closedCaseIds.isEmpty() && contentDocLinkandCaseMap.containsKey(cdLinkRec.Id)){
                    if(closedCaseIds.contains(contentDocLinkandCaseMap.get(cdLinkRec.Id))){
                        cdLinkRec.addError(System.Label.ASF_File_Update_Validation);
                    }  
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