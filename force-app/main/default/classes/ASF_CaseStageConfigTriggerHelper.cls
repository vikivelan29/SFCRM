public without sharing class ASF_CaseStageConfigTriggerHelper {
    
    public void prepopulateQueueIdFromNames(List<ASF_Case_Stage_Config__c> newStageList){
        
        Map<String,Id> queueNameIdMap = new Map<String,Id>();
        Set<String> queueNamesSet = new Set<String>();
        
        for(ASF_Case_Stage_Config__c c: newStageList){
            if (!String.isBlank(c.Default_Queue_user_Name__c)){
                queueNamesSet.add(c.Default_Queue_user_Name__c);
            }    
        }
        
        List<group> queueList = [Select id,name from group where type = 'Queue' AND name in :queueNamesSet];
        for(Group g:queueList ){
            queueNameIdMap.put(g.name,g.id);
        }
        
        for(ASF_Case_Stage_Config__c c: newStageList){
            if (!String.isBlank(c.Default_Queue_user_Name__c)){
                c.Default_Queue__c = queueNameIdMap.get(c.Default_Queue_user_Name__c);
                if(String.isNotBlank(c.Default_Queue_user_Name__c) && c.Default_Queue__c == null ){
                    c.addError('Queue Populated Does not Exist in System');
                }
            }    
        }
    }
    
    public void validateStageNames(List<ASF_Case_Stage_Config__c> newStageList){
        List<String> pickListValuesList= new List<String>();
        List<String> workpickListValuesList= new List<String>();
        //For Case
        Schema.DescribeFieldResult fieldResult = Case.Stage__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }   
        
        
        for(ASF_Case_Stage_Config__c s:newStageList ){
            System.debug('s.Case_Category_Config__r --> '+s.Case_Category_Config__r.CCC_External_Id__c);
            if(s.Case_Category_Config__r.Process__c == 'Case'){
                if (!pickListValuesList.contains(s.StageName__c)){
                    system.debug('Bas Record '+ s.id + '---' + s.StageName__c);
                    s.addError(s.StageName__c + ' is not Matching with Case Stage PickList. ');
                }
            }
        }
        
    }
    
   
    
}