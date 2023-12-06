public class ASF_CaseSLAHistoryTriggerHandler extends ASF_VTriggerHandler{
    
    ASF_CaseSLAHistoryTriggerHelper helper = new ASF_CaseSLAHistoryTriggerHelper();
    
    public override void BeforeInsert(List<SObject> newItems) {
        ASF_CaseSLAHistoryTriggerHelper.populateSLAUserDEtails(newItems);
    }

    public override void AfterInsert(Map<Id, SObject> newItems){
        ASF_CaseSLAHistoryTriggerHelper.createCaseTeamMember(newItems.values());
    }

}