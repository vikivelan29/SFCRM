public class ConversionDetailsTriggerHandler extends ASF_VTriggerHandler{
    public override void AfterInsert(Map<Id, SObject> newItems) {
        ABSLAMC_BusinessLogic_HelperClass.closeEligibleLeads((Map<Id, Conversion_Details__c>) newItems);
    }
}