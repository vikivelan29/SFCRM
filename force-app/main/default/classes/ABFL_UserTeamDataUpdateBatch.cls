/*********************************************************
** Class        :  ABFL_UserTeamDataUpdateBatch
** Author       :  SaiRahul
** Description  :  Update/Assign Queue, PublicGroup details on User Record, which the User is assigned to.
** Created Date :  21/02/2024
*********************************************************/
public class ABFL_UserTeamDataUpdateBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    Map<Id,Id> PublicgrpVsQueue = new Map<Id,Id>();// Store corresponding Queue and it's Public group data 
    Map<Id,List<Id>> userVsPublicgrp = new Map<Id,List<Id>>();// store USER vs Public Group data
    List<User> usersList = new List<User>();// List of Users to be updated/modified
    
    public ABFL_UserTeamDataUpdateBatch(){
               
       for(GroupMember grp : [SELECT GroupId,UserOrGroupId FROM GroupMember WHERE Group.Type = 'Queue' AND Group.DeveloperName LIKE 'ABFL%'])
        {
            // UserOrGroupId is Public Group ID & GroupId is Queue Id
            PublicgrpVsQueue.put(grp.UserOrGroupId,grp.GroupId);
        }
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        
        // Query ALL Active User records
        return Database.getQueryLocator([
            SELECT Id, Name, Assigned_Team__c,managerGroupId__c  
            FROM USER             
            WHERE IsActive = TRUE AND Business_Unit__c = :ABFL_Constants.ABFL]);            
    }
    
    public void execute(Database.BatchableContext BC, List<User> scope) {
        
        List<GroupMember> grpMemList = [SELECT UserOrGroupId, Group.Name, Group.type, GroupId FROM GroupMember WHERE Group.DeveloperName LIKE 'ABFL%' AND UserOrGroupId IN :scope order by SystemModstamp DESC];
                
        For(GroupMember grp : grpMemList){
            if(grp.Group.type == 'Regular'){
                if(!userVsPublicgrp.containsKey(grp.UserOrGroupId)){
                    userVsPublicgrp.put(grp.UserOrGroupId, new List<String>{grp.GroupId});
                }else{
                    userVsPublicgrp.get(grp.UserOrGroupId).add(grp.GroupId);
                }  
            }
        }
        
        if(userVsPublicgrp.keySet() != NULL)
        {               
            List<Id> publicGrpId = new List<Id>();
            String queueId;
            
            For(Id userId : userVsPublicgrp.KeySet())
            {
                publicGrpId = userVsPublicgrp.get(userId); // fetch the Public group Id User is part of   
                Integer groupIndex = 0;
                for(Id groupId : publicGrpId){
                    if(PublicgrpVsQueue.get(groupId) != null){
                        if(groupIndex == 0){
                            queueId = PublicgrpVsQueue.get(groupId); // fetch the Queue ID from the MAP PublicgrpVsQueue by passing the key Public grp Id
                        }else{
                            queueId += ','+PublicgrpVsQueue.get(groupId);
                        }
                        groupIndex ++;
                    }
                }
                
                User u = new User();
                u.Id = userId;                
                u.managerGroupId__c = queueId;
                usersList.add(u);                
            }            
            
        }        
        
        if (!usersList.isEmpty()) {
            Database.SaveResult[] saveResults = Database.update(usersList, false);
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        System.debug('Batch job finished successfully.');
    }
}