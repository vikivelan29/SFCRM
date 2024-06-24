/**
 * @description       : Update/Assign Queue, PublicGroup details on User Record, which the User is assigned to.
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 05-14-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   05-13-2024   rsinghnagar@salesforce.com   Initial Version
**/
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts,PMD.EmptyStatementBlock')
public class ABFL_UserTeamDataUpdateBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    Map<Id,Id> publicgrpVsQueue = new Map<Id,Id>();// Store corresponding Queue and it's Public group data 
    Map<Id,List<Id>> userVsPublicgrp = new Map<Id,List<Id>>();// store USER vs Public Group data
    List<User> usersList = new List<User>();// List of Users to be updated/modified
    
    /**
    * @description : Constructor
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    **/
    public ABFL_UserTeamDataUpdateBatch(){
               
       for(GroupMember grp : [SELECT GroupId,UserOrGroupId FROM GroupMember WHERE Group.Type = 'Queue' AND Group.DeveloperName LIKE 'ABFL%'])
        {
            // UserOrGroupId is Public Group ID & GroupId is Queue Id
            publicgrpVsQueue.put(grp.UserOrGroupId,grp.GroupId);
        }
    }
    
    /**
    * @description : Start method to query eligible records
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param bc 
    * @return Database.QueryLocator 
    **/
    public Database.QueryLocator start(Database.BatchableContext bc) {
        
        // Query ALL Active User records
        return Database.getQueryLocator([
            SELECT Id, Name, Assigned_Team__c,managerGroupId__c  
            FROM USER             
            WHERE IsActive = TRUE AND Business_Unit__c = :ABFL_Constants.ABFL]);            
    }
    
    /**
    * @description
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param bc 
    * @param scope 
    **/
    public void execute(Database.BatchableContext bc, List<User> scope) {
        try{
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
                        if(publicgrpVsQueue.get(groupId) != null){
                            if(groupIndex == 0){
                                queueId = publicgrpVsQueue.get(groupId); // fetch the Queue ID from the MAP publicgrpVsQueue by passing the key Public grp Id
                            }else{
                                queueId += ','+publicgrpVsQueue.get(groupId);
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
        } catch (Exception e) {
            // Handle exceptions
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABFL_ReassignProspectsBatch.execute');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
        }
    }
    
    /**
    * @description 
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param bc 
    **/
    public void finish(Database.BatchableContext bc) {
    }
}