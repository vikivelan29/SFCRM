public class ABCL_SurveyResponseTriggerHandler extends ASF_VTriggerHandler {
    
    
    public override void beforeInsert(list<sObject> newItems) {
        ABCL_SurveyResponseHelper.associateCustomerAndAsset(newItems);
    }
    public override void afterInsert(Map<Id, SObject> newItemsCase) {
        ABCL_SurveyResponseHelper.updateCustomersNPS((List<Survey_Response__c>)newItemsCase.values());
    }    
}