public class RNWL_AccountTriggerHandler extends ASF_VTriggerHandler{
    
    private Boolean isTriggerDisabled(){
        return isDisabled('Account');
    }

    public override void afterUpdate(Map<Id, SObject> newAccs, Map<Id, SObject> oldAccs) {
        
        if(isTriggerDisabled()){return;}
        RNWL_AccountTriggerHelper.updateOppsUponAccountDataChange((Map<Id, Account>)newAccs, (Map<Id, Account>)oldAccs);
    }

}