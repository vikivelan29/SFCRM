public with sharing class ASF_ContentDocumentTriggerHandler extends ASF_VTriggerHandler{

    public override void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        ASF_CaseFileUploadTriggerHelper.validateCaseFileUpdate((Map<Id, ContentDocument>)newItems, (Map<Id, ContentDocument>)oldItems);
    }
    public override void BeforeDelete(Map<Id, SObject> oldItems){
        ASF_CaseFileUploadTriggerHelper.validateCaseFileUpdate(null, (Map<Id, ContentDocument>)oldItems);
    }
}