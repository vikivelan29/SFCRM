public with sharing class Asf_BranchMasterTriggerHelper {

    public void prepopulateQueueIdFromNames(List<Branch_Master__c> newBranchMasters){

        
        Map<String,Id> queueNameIdMap = new Map<String,Id>();
        Set<String> queueNamesSet = new Set<String>();
       
        for(Branch_Master__c   bm: newBranchMasters){
           if (!String.isBlank(bm.Branch_Queue_Name__c ) && bm.Business_Unit__c == 'ABHFL'){
               queueNamesSet.add(bm.Branch_Queue_Name__c);
           }    
        }
       
       List<group> queueList = [Select id,name from group where type = 'Queue' AND name in :queueNamesSet];

        for(Group g:queueList ){
           queueNameIdMap.put(g.name,g.id);
        }

       for(Branch_Master__c   bm: newBranchMasters){
           if (!String.isBlank(bm.Branch_Queue_Name__c)){
               bm.Branch_Queue_Id__c  = queueNameIdMap.get(bm.Branch_Queue_Name__c);
               if(String.isNotBlank(bm.Branch_Queue_Id__c) && bm.Branch_Queue_Name__c == null){
                   bm.addError('Queue Populated Does not Exist in System'); 
               } 
            }    
       }
   }

}