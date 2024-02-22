trigger LeadTrigger on Lead (After Insert) {
    if(Trigger.isAfter && Trigger.isInsert){
        ABHFL_LeadCreationAPI.sendLead(Trigger.new[0].Id);
    }
}