/*********************************************************
** Class        :  ABFL_UserTeamDataUpdateBatch
** Author       :  SaiRahul
** Description  :  Update/Assign Queue, PublicGroup details on User Record, which the User is assigned to.
** Created Date :  21/02/2024
*********************************************************/
public class ABFL_UserTeamDataUpdateBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    Map<Id,Id> PublicgrpVsQueue = new Map<Id,Id>();// Store corresponding Queue and it's Public group data 
    Map<Id,String> userVsPublicgrp = new Map<Id,String>();// store USER vs Public Group data
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
            if(grp.Group.type == 'Regular' && !userVsPublicgrp.containsKey(grp.UserOrGroupId))
            {
                userVsPublicgrp.put(grp.UserOrGroupId, grp.GroupId);                
            }
        }
        
        if(userVsPublicgrp.keySet() != NULL)
        {               
            Id publicGrpId;
            Id queueId;
            
            For(Id userId : userVsPublicgrp.KeySet())
            {
                publicGrpId = userVsPublicgrp.get(userId); // fetch the Public group Id User is part of                
                queueId = PublicgrpVsQueue.get(publicGrpId); // fetch the Queue ID from the MAP PublicgrpVsQueue by passing the key Public grp Id
                
                User u = new User();
                u.Id = userId;                
                u.managerGroupId__c = queueId;
                usersList.add(u);                
            }            
            
        }        
        
        if (!usersList.isEmpty()) {
            try {
                update usersList;
            } catch (Exception e) {
                // Handle exceptions
                System.debug('Error: ' + e.getMessage());
                ABCL_Logger.enableExceptionLogging();
                ABCL_Logger.push('ABFL_UserTeamDataUpdateBatch.execute');
                ABCL_Logger.message(e.getMessage());
                ABCL_Logger.emit();
            }
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        System.debug('Batch job finished successfully.');
    }
}