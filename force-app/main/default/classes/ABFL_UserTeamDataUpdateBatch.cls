/**
 * @description       : Update/Assign Queue, PublicGroup details on User Record, which the User is assigned to.
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 09-23-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   05-13-2024   rsinghnagar@salesforce.com   Initial Version
 * 2.0   07-11-2024   udit.singhal@salesforce.com  Updated Assigned_Team__c on user records
**/
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts,PMD.EmptyStatementBlock')
public class ABFL_UserTeamDataUpdateBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    Map<Id,Id> publicgrpVsQueueIdMap = new Map<Id,Id>();// Store corresponding Queue and it's Public group data
    Map<Id,String> publicgrpVsQueueNameMap = new Map<Id,String>();
    Map<Id,Set<Id>> userVsPublicgrp = new Map<Id,Set<Id>>();// store USER vs queueId
    Map<Id,List<String>> userVslstQueueName = new Map<Id,List<String>>();// store USER vs queue name
    List<User> usersList = new List<User>();// List of Users to be updated/modified
    
    /**
    * @description : Constructor
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    **/
    public ABFL_UserTeamDataUpdateBatch(){
               
       for(GroupMember grp : [SELECT GroupId,Group.Name,UserOrGroupId FROM GroupMember WHERE Group.Type = 'Queue' AND (Group.DeveloperName LIKE 'ABFL%' OR Group.DeveloperName LIKE 'Wellness%')])
        {
            // UserOrGroupId is Public Group ID & GroupId is Queue Id
            if(!String.valueOf(grp.UserOrGroupId).startsWith('005')){
                publicgrpVsQueueIdMap.put(grp.UserOrGroupId,grp.GroupId);
                publicgrpVsQueueNameMap.put(grp.UserOrGroupId,grp.Group.Name);
            }
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
        return Database.getQueryLocator('SELECT Id, Name, Assigned_Team__c,managerGroupId__c FROM USER WHERE IsActive = TRUE AND Business_Unit__c IN ('+'\''+ABFL_Constants.ABFL+'\''+','+'\''+MCRM_Constants.MCRMBU+'\''+')'+(Test.isRunningTest()?' AND username like \'adminUserabcl@gmail.com%\'':''));
    }
    
    /**
    * @description
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param bc 
    * @param scope 
    **/
    public void execute(Database.BatchableContext bc, List<User> scope) {
        try{
            Set<Id> userIds = new Set<Id>();
            for (User u : scope) {
                userIds.add(u.Id);
            }
            List<GroupMember> grpMemList = [SELECT UserOrGroupId, Group.Name, Group.type, GroupId FROM GroupMember WHERE (Group.DeveloperName LIKE 'ABFL%' OR Group.DeveloperName LIKE 'Wellness%') AND UserOrGroupId IN :userIds order by SystemModstamp DESC];
            for(GroupMember grp : grpMemList){
                if(grp.Group.type == 'Regular'){
                    if(!userVsPublicgrp.containsKey(grp.UserOrGroupId)){
                        userVsPublicgrp.put(grp.UserOrGroupId, new Set<Id>());
                    }
                    Id tempqueueId = publicgrpVsQueueIdMap.get(grp.GroupId);
                    	userVsPublicgrp.get(grp.UserOrGroupId).add(tempqueueId); // creating map of User vs List of QueueIds
                    if(!userVslstQueueName.containsKey(grp.UserOrGroupId)){
                        userVslstQueueName.put(grp.UserOrGroupId, new List<String>());
                    }
                    String tempQueueName = publicgrpVsQueueNameMap.get(grp.GroupId);
                    	userVslstQueueName.get(grp.UserOrGroupId).add(tempQueueName); // creating map of User vs List of queueNames
                }
            }
            if(userVsPublicgrp.keySet() != null){                              
                String commaSeparatedQueueIds;
                String commaSeparatedQueueName;
                Set<Id> setQueueIds = new Set<Id>();
                List<String> lstQueueName  = new List<String>();
                for(Id userId : userVsPublicgrp.KeySet()){      
                    if(userVsPublicgrp.containsKey(userId)){
                        setQueueIds =userVsPublicgrp.get(userId);
                        lstQueueName = userVslstQueueName.get(userId);
                        commaSeparatedQueueIds = String.join(new List<Id>(setQueueIds), ',');
                        commaSeparatedQueueName = String.join(new List<String>(lstQueueName), ',');
    				// Updating managerGroupId__c and Assigned_Team__c for users
                        User u = new User();
                        u.Id = userId;                
                        u.managerGroupId__c = commaSeparatedQueueIds;
                        u.Assigned_Team__c = commaSeparatedQueueName;
                        usersList.add(u);
                	}  
				}
            }    
            Map<Id,User> userToUpdate = new Map<Id,User>();
            userToUpdate.putall(usersList);// to avoid duplicate Id in list
            if (!userToUpdate.isEmpty()) {
                Database.SaveResult[] saveResults = Database.update(userToUpdate.values(), false);
            }
        } catch (Exception e) {
            // Handle exceptions
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABFL_UserTeamDataUpdateBatch.execute');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.message(e.getStackTraceString());
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