/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 04-24-2024
 * @last modified by  : rsinghnagar@salesforce.com 
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   04-24-2024   rsinghnagar@salesforce.com   Initial Version
**/
public with sharing class ASF_ContentDocLinkTriggerHandler extends ASF_VTriggerHandler{

    public override void BeforeDelete(Map<Id, SObject> oldItems){
        ASF_CaseFileUploadTriggerHelper.validateFileDelete(null, (Map<Id, ContentDocumentLink>)oldItems);
    }    
    //Added by Zahed [PR1030924-211]
    public override void BeforeInsert(List<SObject> newItems){
         ASF_CaseFileUploadTriggerHelper.validateCaseFile((List<ContentDocumentLink>)newItems);
    }
    //Added for firing system notif on file upload - AMC
    public override void AfterInsert(Map<Id, SObject> newItems){
        ASF_CaseFileUploadTriggerHelper.checkifCaseAttachmentAdded((Map<Id, ContentDocumentLink>)newItems);
    }
    /*public override void AfterInsert(Map<Id, SObject> newMap){
        checkForClosedCase(newMap);
    }    
    public static void checkForClosedCase(Map<Id, SObject> contentLinksMap){
        if(ABCL_CommonCLass.bypassValidation() && !Test.isRunningTest()){
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
 */
}