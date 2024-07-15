/*********************************************************
*Class        :  ABCL_SurveyResponseTriggerHandler
*Author       :  Virendra Patil
*Created Date :  03/03/2024
*Last Modified:  14/05/2024
*Test Class   :  ABCL_SurveyResponseTriggerHandlerTest
*@description :  Trigger handler class for SurveyResponse object
*********************************************************/
public class ABCL_SurveyResponseTriggerHandler extends ASF_VTriggerHandler {
    
    
    public override void beforeInsert(list<sObject> newItems) {
        ABCL_SurveyResponseHelper.associateCustomerAndAsset(newItems);
    }
    public override void afterInsert(Map<Id, SObject> newItemsCase) {
        ABCL_SurveyResponseHelper.updateCustomersNPS((List<Survey_Response__c>)newItemsCase.values());
    }    
}