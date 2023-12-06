trigger PAY_CustomerTrigger1 on PAY_Staging_Customer_to_Account__e (after insert) {
    Final Integer Total_Triggers = 1;
    Final Integer Trigger_Number = 1;
    Apex_PE_Framework__mdt mdtPEFramework = Apex_PE_Framework__mdt.getInstance('PAY_CustomerTrigger1'); 
    if(mdtPEFramework.TriggerEnabled__c ){
        PAY_CustomerTriggerHandler.executeAfterInsert(trigger.new, Total_Triggers,Trigger_Number );
    }
}