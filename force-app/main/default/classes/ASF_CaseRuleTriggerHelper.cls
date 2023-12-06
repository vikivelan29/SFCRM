public class ASF_CaseRuleTriggerHelper {
    

    public void prepopulateQueueIdFromNames(List<ASF_Case_Rule__c > newStageList){ 
        
         Map<String,Id> queueNameIdMap = new Map<String,Id>();
    	Set<String> queueNamesSet = new Set<String>();
        
         for(ASF_Case_Rule__c  c: newStageList){
            if (!String.isBlank(c.Assignment_Queue_Name__c )){
                queueNamesSet.add(c.Assignment_Queue_Name__c );
            }    
        }
        
        List<group> queueList = [Select id,name from group where type = 'Queue' AND name in :queueNamesSet];
        for(Group g:queueList ){
            queueNameIdMap.put(g.name,g.id);
        }
        
        for(ASF_Case_Rule__c  c: newStageList){
            if (!String.isBlank(c.Assignment_Queue_Name__c)){
                c.Assigned_Queue_Id__c  = queueNameIdMap.get(c.Assignment_Queue_Name__c);
                if(String.isNotBlank(c.Assignment_Queue_Name__c ) && c.Assignment_Queue_Name__c  == null ){
                    c.addError('Queue Populated Does not Exist in System'); 
                } 
            }    
        }
    }

}