trigger LeadTrigger on Lead (After Insert) {
    if(Trigger.isAfter && Trigger.isInsert){
        if(Trigger.new[0].Business_Unit__c == 'ABHFL'){
            ABHFL_LeadCreationAPI.sendLead(Trigger.new[0].Id);
        }
    }
}