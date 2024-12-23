/****************************************************************************************************************
* Author       - Ekta Bist
* Date         - 25-Oct-2024
* @LOB         - ABML
* @description -  This class is used to assign cases to queue member in round robin fashion.
*****************************************************************************************************************/


public with Sharing class ABML_RoundRobinCaseAssBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable 
{
   
    public Database.QueryLocator start(Database.BatchableContext bc)
    {
        String query = 'SELECT Id, OwnerId, Owner.Name, Status, Business_Unit__c, Source__c FROM Case';
        query += ' WHERE Status != \'Closed\' AND Business_Unit__c = \'ABML\' AND Source__c = \'Email\'';	
        System.debug(query);
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Case> scope)
    {
        
        //Query ABML User record to check for their OOO
        
        Set<Id> setOfUnAvailableUserIds = new Set<Id>();
        Map<Id, Boolean> mapOfTUserAvailability = new Map<Id, Boolean>();
        for(OutOfOffice objOutOffice : [Select Id, UserId, StartDate, Enddate from OutOfOffice where StartDate <= Today AND Enddate >= today]){
            
            Date startDate = Date.valueOf(objOutOffice.StartDate);
            Date endDate = Date.valueOf(objOutOffice.Enddate);
            startDate = startDate.addDays(1);
            if(startDate == System.today() && endDate == System.today()){
                mapOfTUserAvailability.put(objOutOffice.UserId, true);
            }
            else if(startDate == System.today() && endDate > System.today()){
                mapOfTUserAvailability.put(objOutOffice.UserId, false);
            }
            else if(startDate < System.today() && endDate == System.today()){
                mapOfTUserAvailability.put(objOutOffice.UserId, true);
            }
            else if(startDate < System.today() && endDate > System.today()){//
                mapOfTUserAvailability.put(objOutOffice.UserId, false);
            }
            setOfUnAvailableUserIds.add(objOutOffice.UserId);
        }
        
        BusinessHours bh = [SELECT Id, Name, MondayStartTime, MondayEndTime FROM BusinessHours WHERE Name = 'ABML'LIMIT 1];        
        
        // Query all records from the custom setting
        List<ABML_Round_Robin_Assignment__c> customSettingRecords = [SELECT Name, ABML_Queue_Name__c, ABML_Index__c FROM ABML_Round_Robin_Assignment__c];
        Map<String, Integer> customSettingMap = new Map<String, Integer>();
        
        // Iterate through the records and populate the map
        for (ABML_Round_Robin_Assignment__c record : customSettingRecords) {
            customSettingMap.put(record.Name, (Integer)record.ABML_Index__c);
        }
        
        Map<String, List<String>> metaQueuedataMap = new Map<String, List<String>>();
		Map<String, String> metaQueuedataMapAll = new Map<String, String>();                
        Set<String> setOfGroupId = new Set<String>();
        Set<String> setOfUserId = new Set<String>();
        List<Case> lstCase = new List<Case>();
        Set<String> setOfPublicGroupId = new Set<String>();
        Map<String,Integer> mapOfUserIdCaseCount = new Map<String,Integer>();

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
            if(uId.startsWith('00G')){
                setOfPublicGroupId.add(uId);
                metaQueuedataMapAll.put(gId, uId); 
            }           
        }        
        
        if(setOfPublicGroupId != null){
            DateTime currentDateTime = System.now();  
            Time currentTime = currentDateTime.time();
            for (GroupMember objGroupMember : [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN: setOfPublicGroupId]){
                String gId = String.valueOf(objGroupMember.GroupId);
                String uId = String.valueOf(objGroupMember.UserOrGroupId);
                
                if(uId.startsWith('005') && mapOfTUserAvailability.containsKey(uId)){
                    if(mapOfTUserAvailability.get(uId) && (bh.MondayEndTime < currentTime || bh.MondayStartTime > currentTime)){
                        if (!metaQueuedataMap.containsKey(gId)) {
                            metaQueuedataMap.put(gId, new List<String>());
                        }
                        metaQueuedataMap.get(gId).add(uId); 
                    }
                    
                }  
                else if(uId.startsWith('005') && !mapOfTUserAvailability.containsKey(uId)){
                    if (!metaQueuedataMap.containsKey(gId)) {
                        metaQueuedataMap.put(gId, new List<String>());
                    }
                    
                }  
            }
        }
        
        for (Case objCase : scope) {            
            String caseIdCheck = String.valueOf(objCase.OwnerId);
            if(caseIdCheck.startsWith('00G')){
                Case cObj = objCase;                
                String ownerId = String.valueOf(objCase.OwnerId);
                String groupId = '';
                if(metaQueuedataMapAll.containsKey(ownerId)){
                	groupId = metaQueuedataMapAll.get(ownerId);
                }
                List<String> lstUserIds = new List<String>();
                if(metaQueuedataMap.containsKey(groupId)){
                    lstUserIds = metaQueuedataMap.get(groupId);
                }
                
                if (lstUserIds != null && !lstUserIds.isEmpty()) {
                    Integer currentIndex = customSettingMap.containsKey(objCase.Owner.Name) ? (Integer)customSettingMap.get(objCase.Owner.Name)  : 0 ;
                    cObj.OwnerId = lstUserIds[currentIndex];
                    // Update the current index
                    currentIndex = Math.mod((currentIndex + 1), lstUserIds.size());
                    customSettingMap.put(objCase.Owner.Name, currentIndex);
                 }
                 lstCase.add(cObj);
             }             
        }  
        if (lstCase != null) {
            update lstCase;
        }
        
        List<ABML_Round_Robin_Assignment__c> updateCustomSettingRecords = new List<ABML_Round_Robin_Assignment__c>();
        
        // Iterate through the records and populate the map
        for (ABML_Round_Robin_Assignment__c record : customSettingRecords) {
            if(customSettingMap.containsKey(record.Name)){
                record.ABML_Index__c = customSettingMap.get(record.Name);
                updateCustomSettingRecords.add(record);
            }
            
        }
        
        if (updateCustomSettingRecords != null) {
            update updateCustomSettingRecords;
        } 
        
    }
    public void finish(Database.BatchableContext bc) {
        system.debug('Completed');
        //Finished
    }
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ABML_RoundRobinCaseAssBatch(),50);
    }
}