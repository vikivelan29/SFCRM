public class ASF_ContactTriggerHandler extends ASF_VTriggerHandler {

    public override void BeforeInsert(list<SObject> newItemsCase){
        ASF_ContactTriggerHelper helper = new ASF_ContactTriggerHelper();
        helper.setLastContactInALoadAsPrimary((List<Contact>)newItemsCase);
        
    }
    public override void AfterInsert(map<Id, sObject> newItemsCase){
        ASF_ContactTriggerHelper helper = new ASF_ContactTriggerHelper();
        helper.updatePrimaryFlagOnContact((Map<Id,Contact>)newItemsCase);
    }
}