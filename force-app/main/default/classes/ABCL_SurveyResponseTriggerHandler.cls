public class ABCL_SurveyResponseTriggerHandler extends ASF_VTriggerHandler {
    
    
    public override void beforeInsert(list<sObject> newItems) {
        ABCL_SurveyResponseHelper.associateCustomerAndAsset(newItems);
    }
    
}