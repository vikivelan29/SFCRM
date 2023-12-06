public without sharing class PAY_CustomerTriggerHandler {
    
    public static Integer intTotalTriggers = 0;
    public static Integer intTriggerNumber = 0;
    
    
    public static void executeAfterInsert(List<PAY_Staging_Customer_to_Account__e> newList, Final Integer Total_Triggers, 
                                          Final Integer Trigger_Number)
    {
        intTotalTriggers   = Total_Triggers; //4
        intTriggerNumber = Trigger_Number; //1 , 2
        executeAfterInsert(newList);
    }
    
    public static void executeAfterInsert(List<PAY_Staging_Customer_to_Account__e> newList){
        Apex_PE_Framework__mdt mdtPEFramework = Apex_PE_Framework__mdt.getInstance('PAY_CustomerTriggerHandler'); 
        
        Integer counter = 0;
        Integer batchSize = Integer.valueOf(mdtPEFramework.TriggerBatchSize__c);
        
        String replayId='';
        List<PAY_Staging_Customer_to_Account__e> stgCustomers = new List<PAY_Staging_Customer_to_Account__e>();
        
        for(PAY_Staging_Customer_to_Account__e event : newList){
            if(math.mod(Integer.valueOf(event.replayId), intTotalTriggers) == intTriggerNumber -1){
                if(counter < batchSize){
					stgCustomers.add(event);                  
                    replayId = event.ReplayId;
                    counter++;
                }
                else{
                    break;
                }
            } 
        }
        if(stgCustomers.size()>0){
            System.debug('adadadad');
            PAY_CustomerCreationListener.processEvents(stgCustomers);
        }
        
    }
}