/****************************************************************************************************************
* Author       - Ekta Bist
* Date         - 25-Oct-2024
* @LOB         - ABML
* @description -  This class is used to assign cases to queue member in round robin fashion.
*****************************************************************************************************************/


public with Sharing class ABML_RoundRobinCaseAssBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable 
{
    public Integer currentIndex = 0;
    public Database.QueryLocator start(Database.BatchableContext bc)
    {
        Date today = Date.today();
        Datetime startTimeUTC = Datetime.newInstance(today, Time.newInstance(18, 0, 0, 0)); // Today at 6:00 PM
        Datetime endTimeUTC = Datetime.newInstance(today.addDays(1), Time.newInstance(10, 0, 0, 0)); // Tomorrow at 10:00 AM
        String query = 'SELECT Id, OwnerId, Status, Business_Unit__c, Source__c FROM Case';
        query += ' WHERE Status != \'Closed\' AND Business_Unit__c = \'ABML\' AND Source__c = \'Email\'';	
        query += ' AND CreatedDate >= :startTimeUTC AND CreatedDate <: endTimeUTC';
        System.debug(query);
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Case> scope)
    {
        Map<String, List<String>> metaQueuedataMap = new Map<String, List<String>>();
		Map<String, String> metaQueuedataMapAll = new Map<String, String>();                
        Set<String> setOfGroupId = new Set<String>();
        List<Case> lstCase = new List<Case>();
        Set<String> setOfPublicGroupId = new Set<String>();
        for(Case obCase : scope)
        {
            String caseIdCheck = String.valueOf(obCase.OwnerId);
            if(caseIdCheck.startsWith('00G')){
                setOfGroupId.add(obCase.OwnerId);                
            }
        }        
        
        for (GroupMember objGroupMember : [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN :setOfGroupId]) {
            String uId = String.valueOf(objGroupMember.UserOrGroupId);
            String gId = String.valueOf(objGroupMember.GroupId);
            gId = gId.substring(0, 15);
            uId = uId.substring(0, 15);
            if(uId.startsWith('00G')){//public group
                setOfPublicGroupId.add(uId);
                metaQueuedataMapAll.put(gId, uId); // g, pb
            }           
        }
        
        if(setOfPublicGroupId != null){
            for (GroupMember objGroupMember : [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN: setOfPublicGroupId]) {
                String gId = String.valueOf(objGroupMember.GroupId);
                String uId = String.valueOf(objGroupMember.UserOrGroupId);
                gId = gId.substring(0, 15);
                if(uId.startsWith('005')){//users
                    if (!metaQueuedataMap.containsKey(gId)) {
                        metaQueuedataMap.put(gId, new List<String>());
                    }
                    metaQueuedataMap.get(gId).add(uId); // p, u
                    
                }          
            }  
        }
        for (Case objCase : scope) {
            String caseIdCheck = String.valueOf(objCase.OwnerId);
             if(caseIdCheck.startsWith('00G')){
                Case cObj = objCase;                
                String ownerId = String.valueOf(objCase.OwnerId).substring(0, 15);
                 String groupId = metaQueuedataMapAll.get(ownerId);
                 List<String> lstUserIds = metaQueuedataMap.get(groupId);
                 if (lstUserIds != null && !lstUserIds.isEmpty()) {
                     cObj.OwnerId = lstUserIds[currentIndex];
                     // Update the current index
                     currentIndex = Math.mod((currentIndex + 1), lstUserIds.size());//
                 }
                 lstCase.add(cObj);
             }             
        }        
        update lstCase;
    }
    public void finish(Database.BatchableContext bc) {
        system.debug('Completed');
    }
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ABML_RoundRobinCaseAssBatch(),50);
    }
}