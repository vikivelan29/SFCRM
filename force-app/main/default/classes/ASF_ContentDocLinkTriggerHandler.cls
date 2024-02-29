public with sharing class ASF_ContentDocLinkTriggerHandler extends ASF_VTriggerHandler{

    public override void BeforeDelete(Map<Id, SObject> oldItems){
        ASF_CaseFileUploadTriggerHelper.validateFileDelete(null, (Map<Id, ContentDocumentLink>)oldItems);
    }
}