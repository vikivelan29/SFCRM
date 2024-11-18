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
        String query = 'SELECT Id, OwnerId, Owner.Name, Status, Business_Unit__c, Source__c FROM Case';
        query += ' WHERE Status != \'Closed\' AND Business_Unit__c = \'ABML\' AND Source__c = \'Email\'';	
        System.debug(query);
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Case> scope)
    {
        Map<String, List<String>> metaQueuedataMap = new Map<String, List<String>>();
		Map<String, String> metaQueuedataMapAll = new Map<String, String>();                
        Set<String> setOfGroupId = new Set<String>();
        Set<String> setOfUserId = new Set<String>();
        List<Case> lstCase = new List<Case>();
        Set<String> setOfPublicGroupId = new Set<String>();
        List<RoundRobinCountWrapper> roundRobinWrapperList = new List<RoundRobinCountWrapper>();
        Map<String,List<RoundRobinCountWrapper>> roundRobinWrapperMap = new Map<String,List<RoundRobinCountWrapper>>();
        Map<String,Integer> mapOfUserIdCaseCount = new Map<String,Integer>();


        for(Case obCase : scope)
        {
            String caseIdCheck = String.valueOf(obCase.OwnerId);
            if(caseIdCheck.startsWith('00G')){ //queue - ABML F HD
                setOfGroupId.add(obCase.OwnerId); //                
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
        for(String objMap : metaQueuedataMap.keySet()){
            List<String> lstUserIds = metaQueuedataMap.get(objMap);
            for (String userId : lstUserIds) {
                setOfUserId.add(userId);
            }
        }
        System.debug('setOfUserId=='+setOfUserId);
        List<AggregateResult> caseCounts = [ SELECT OwnerId, COUNT(Id) caseCount FROM Case WHERE Business_Unit__c = 'ABML' AND Source__c = 'Email'AND  OwnerId IN :setOfUserId GROUP BY OwnerId Order By COUNT(Id)];
        // Populate map with case counts
        for (String strUserId : setOfUserId) {  
            mapOfUserIdCaseCount.put(strUserId,0);//a-0,v-0,a-0
        }
        for (AggregateResult ar : caseCounts) {
            String userId = (String)ar.get('OwnerId');
            if(mapOfUserIdCaseCount.containsKey(userId)){
                mapOfUserIdCaseCount.put(userId , (Integer)ar.get('caseCount')); // a-2, v- 1,a-0
            }
           // if(roundRobinWrapperList.contains)
          //  roundRobinWrapperList.add(new RoundRobinCountWrapper((Integer) ar.get('caseCount'), (Id) ar.get('OwnerId')));           
        }
        
        if(mapOfUserIdCaseCount != null){
            // Populate map with case counts
            for (String str : mapOfUserIdCaseCount.keySet()) {
                //caseCountMap.put((Id) ar.get('OwnerId'), (Integer) ar.get('caseCount'));
                roundRobinWrapperList.add(new RoundRobinCountWrapper(mapOfUserIdCaseCount.get(str), str));
            }
        }
        
        roundRobinWrapperList.sort();//// ,a-0, v-1,a-2
        
        System.debug('roundRobinWrapperList==='+roundRobinWrapperList);
        
        for(String publicGroupID : metaQueuedataMap.keySet()){
            List<String> lstUserIds = metaQueuedataMap.get(publicGroupID);
            for(RoundRobinCountWrapper objRRWrap : roundRobinWrapperList){
                System.debug('OwnerId==='+objRRWrap.OwnerId);
                if(lstUserIds.contains(objRRWrap.OwnerId)){
                    if (!roundRobinWrapperMap.containsKey(publicGroupID)) {
                        roundRobinWrapperMap.put(publicGroupID, new List<RoundRobinCountWrapper>());
                    }
                    roundRobinWrapperMap.get(publicGroupID).add(objRRWrap); // 
                }
            }
        }
        
        System.debug('roundRobinWrapperMap==='+roundRobinWrapperMap);

        
        for (Case objCase : scope) {
            String caseIdCheck = String.valueOf(objCase.OwnerId);
             if(caseIdCheck.startsWith('00G')){
                Case cObj = objCase;                
                String ownerId = String.valueOf(objCase.OwnerId).substring(0, 15);
                 String groupId = metaQueuedataMapAll.get(ownerId);
                 System.debug('groupId==='+groupId);
                 List<RoundRobinCountWrapper> lstRoundRobinWrapper = roundRobinWrapperMap.get(groupId);
                 if (lstRoundRobinWrapper != null && !lstRoundRobinWrapper.isEmpty()) {
                     System.debug('lstRoundRobinWrapper==='+lstRoundRobinWrapper);
                     RoundRobinCountWrapper selectedWrapper = lstRoundRobinWrapper[currentIndex];
                     cObj.OwnerId = selectedWrapper.ownerId;
                     selectedWrapper.count++;
                     
                     // Move to the next index, wrapping around if necessary
                     currentIndex = Math.mod((currentIndex + 1) , lstRoundRobinWrapper.size() );
                 }
                 lstCase.add(cObj);
             }             
        }        
        update lstCase;
    }
    public void finish(Database.BatchableContext bc) {
        system.debug('Completed');
        //Finished
    }
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ABML_RoundRobinCaseAssBatch(),50);
    }
    
    public class RoundRobinCountWrapper implements Comparable {
    Integer count;
    Id ownerId; // Change String to Id for better type safety

    // Constructor
    public RoundRobinCountWrapper(Integer count, Id ownerId) {
        this.count = count;
        this.ownerId = ownerId;
    }

    // Implement the compareTo() method
    public Integer compareTo(Object compareTo) {
        RoundRobinCountWrapper compareToEmp = (RoundRobinCountWrapper) compareTo;
        if (count == compareToEmp.count) return 0;
        if (count > compareToEmp.count) return 1;
        return -1;
    }
}
}