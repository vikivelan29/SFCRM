trigger PAY_CustomerTrigger2 on PAY_Staging_Customer_to_Account__e (after insert) {
    Final Integer Total_Triggers = 5;
    Final Integer Trigger_Number = 2;
    Apex_PE_Framework__mdt mdtPEFramework = Apex_PE_Framework__mdt.getInstance('PAY_CustomerTrigger1'); 
    if(mdtPEFramework.TriggerEnabled__c ){
        PAY_CustomerTriggerHandler.executeAfterInsert(trigger.new, Total_Triggers,Trigger_Number );
    }
}