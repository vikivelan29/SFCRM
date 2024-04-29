/*********************************************************
** Class        :  ABFL_UserTeamDataUpdateBatch
** Author       :  SaiRahul
** Description  :  Created as part of US # PR970457-1205. 
                   Update managerGroupId__c on user record based on the queue user is part of.
** Created Date :  21/02/2024
*********************************************************/
public class ABFL_UserTeamDataUpdateBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    Map<Id,Id> publicgrpVsQueue = new Map<Id,Id>();// Store corresponding Queue and it's Public group data 
    Map<Id,String> userVsPublicgrp = new Map<Id,String>();// store USER vs Public Group data
    List<User> usersList = new List<User>();// List of Users to be updated/modified
    
    public ABFL_UserTeamDataUpdateBatch(){
            
        // prepare a map of all queue members with queue Id for ABFL - group will be part of queue
       for(GroupMember grp : [SELECT GroupId,UserOrGroupId FROM GroupMember WHERE Group.Type = 'Queue' AND Group.DeveloperName LIKE 'ABFL%'])
        {
            // UserOrGroupId is Public Group ID & GroupId is Queue Id
            publicgrpVsQueue.put(grp.UserOrGroupId,grp.GroupId);
        }
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        // Query ALL Active ABFL User records
        return Database.getQueryLocator([
            SELECT Id, Name, Assigned_Team__c,managerGroupId__c  
            FROM USER             
            WHERE IsActive = TRUE AND Business_Unit__c = :ABFL_Constants.ABFL]);            
    }
    
    public void execute(Database.BatchableContext bc, List<User> scope) {
        
        // prepare a map of group member => groupId (regular groups)
        List<GroupMember> grpMemList = [SELECT UserOrGroupId, Group.Name, Group.type, GroupId FROM GroupMember WHERE Group.DeveloperName LIKE 'ABFL%' AND UserOrGroupId IN :scope order by SystemModstamp DESC];
        for(GroupMember grp : grpMemList){
            if(grp.Group.type == 'Regular' && !userVsPublicgrp.containsKey(grp.UserOrGroupId))
            {
                userVsPublicgrp.put(grp.UserOrGroupId, grp.GroupId);                
            }
        }
        if(userVsPublicgrp.keySet() != NULL){
            // get the group to which a user belongs, then the queue to which that group belongs to
            Id publicGrpId;
            Id queueId;
            for(Id userId : userVsPublicgrp.KeySet()){
                publicGrpId = userVsPublicgrp.get(userId); // fetch the Public group Id User is part of                
                queueId = publicgrpVsQueue.get(publicGrpId); // fetch the Queue ID from the MAP publicgrpVsQueue by passing the key Public grp Id

                User u = new User(
                    Id = userId,
                    managerGroupId__c = queueId
                );
                usersList.add(u);                
            }            
            
        }        
        
        if (!usersList.isEmpty()) {
            try {
                update usersList;
            }catch (Exception e) {
                // Handle exceptions
                ABCL_Logger.enableExceptionLogging();
                ABCL_Logger.push('ABFL_UserTeamDataUpdateBatch.execute');
                ABCL_Logger.message(e.getMessage());
                ABCL_Logger.emit();
            }
        }
    }
    
    public void finish(Database.BatchableContext bc) {
    }
}