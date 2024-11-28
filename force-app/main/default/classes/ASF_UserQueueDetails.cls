public without sharing class ASF_UserQueueDetails {
    
    @Auraenabled
    public static boolean getUserQueueDetails(Id userId,Id caseId){
        
        Boolean ownerFlag = false;
        List<Task> taskList = [SELECT Id,WhatId,OwnerId,Owner.Name,Status,createdbyid from Task where whatId =: CaseId];
        List<String> statusName = new List<String>();
        if(taskList.size() != 0){
            for(Task objTask :taskList ){
                if((string.valueOf(objTask.OwnerId).startsWith('005')&& (objTask.OwnerId == userId) ||objTask.createdbyid == userId) ){
                    statusName.add(objTask.status);
                }
            }    
            if(statusName.Contains('Open')){
                ownerFlag = true;  
                return ownerFlag;
            }
            else
            {
                ownerFlag = false;
            }
        } 
        return ownerFlag;
    }       
    
}