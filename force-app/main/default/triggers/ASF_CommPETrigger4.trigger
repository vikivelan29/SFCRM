trigger ASF_CommPETrigger4 on ASF_CommnunicationLog__e (after insert) {
    Final Integer Total_Triggers = 5;
    Final Integer Trigger_Number = 4;
    Apex_PE_Framework__mdt mdtPEFramework = Apex_PE_Framework__mdt.getInstance('ASF_CommPETriggerHandler'); 
    if(mdtPEFramework.TriggerEnabled__c ){
        ASF_CommPETriggerHandler.executeAfterInsert(trigger.new, Total_Triggers,Trigger_Number );
    }
    
}