/* Author : Salesforce
* Description : Findout if the user is delegate user.
*/
public without sharing class ASF_DelegatedApproverUtility {
    
    public static Map<integer,boolean> execute(string recordId){
        List<ProcessInstance> processInstances = [SELECT Id,SubmittedById, ProcessDefinition.Name , (SELECT ID, ProcessNodeId,  
                                                                                                     StepStatus,Comments,TargetObjectId,ActorId,CreatedById,IsDeleted,IsPending  
                                                                                                     ,OriginalActorId,ProcessInstanceId,RemindersSent,CreatedDate, Actor.Name,  
                                                                                                     OriginalActor.Name , ProcessNode.Name FROM StepsAndWorkitems order by IsPending DESC, CreatedDate DESC )   
                                                  FROM ProcessInstance where TargetObjectId =:recordId order by CreatedDate DESC];
        Map<integer,boolean> mKeyIsActorDelegatedUser = new Map<integer,boolean>();
        
        Map<integer,Set<Id>> mKeyActorId = new Map<integer,Set<Id>>();
        
        
        // Check if the User approver is queue.
        Set<Id> queueIds = new Set<Id>();
        
        // Below code is finding all the Actors assigned for approval either by process or by Reassignment.
        List<ProcessInstanceStep> steps = [SELECT ID,StepNodeId,ActorId,ProcessInstanceId,OriginalActorId FROM ProcessInstanceStep WHERE ProcessInstance.TargetObjectId =: recordId AND StepStatus NOT IN ('Approved','Rejected') ORDER BY CreatedDate DESC];
        for(ProcessInstanceStep step : steps){
            String temp = step.ProcessInstanceId + '_'+step.StepNodeId;
            integer itemp = temp.hashCode();
            if(!mKeyActorId.containsKey(itemp)){
                mKeyActorId.put(itemp, new Set<Id>());
            }
            mKeyActorId.get(itemp).add(step.ActorId);
            
            if(step.OriginalActorId.getSObjectType() == Group.sObjectType){
                queueIds.add(step.OriginalActorId);
            }
        }
        // Get All the public Group in Queue
        if(Test.isRunningTest()){
            queueIds.add([SELECT ID FROM GROUP WHERE Name='Test GRP' LIMIT 1].Id);
        }
        List<GroupMember> queuePublicGroups = [SELECT ID,GroupId,UserOrGroupId FROM GroupMember WHERE GroupId =: queueIds];
        Map<Id,Set<Id>> mQueuePubGrp = new Map<Id,Set<Id>>();
        for(GroupMember queueGrp : queuePublicGroups){
            if(!mQueuePubGrp.containsKey(queueGrp.GroupId)){
                mQueuePubGrp.put(queueGrp.GroupId,new Set<Id>());
            }
            if(queueGrp.UserOrGroupId.getSObjectType() == User.sObjectType){
                mQueuePubGrp.get(queueGrp.GroupId).add(queueGrp.UserOrGroupId);
            }
            
        }
        
        //Below code find the actual approver who either approved or rejected the request. and then check if he/she is part of the users who're supposed to approve or reject.
        //If the user is not present in the above list, mark the user as Delegated Approver.
        List<ProcessInstanceStep> approveRejectedSteps = [SELECT ID,StepNodeId,ActorId,ProcessInstanceId,StepStatus,OriginalActorId FROM ProcessInstanceStep WHERE ProcessInstance.TargetObjectId=:recordId AND StepStatus IN ('Approved','Rejected') ORDER BY CreatedDate DESC];
        for(ProcessInstanceStep step : approveRejectedSteps){
            String temp = step.ProcessInstanceId + '_'+step.StepNodeId;
            integer itemp = temp.hashCode();
             System.debug('Debug 1 --> '+step.OriginalActorId);
            if(step.OriginalActorId.getSObjectType() == Group.sObjectType){
                System.debug('Debug 1 --> '+step.OriginalActorId);
                //String temp2 = temp+'_'+step.ActorId+'_'+step.StepStatus; 
                integer itemp2 = getHashCodeForUniqueKey(temp,step.ActorId,step.StepStatus);
                System.debug('Check here ---> '+mQueuePubGrp.containsKey(step.OriginalActorId));
                if(mQueuePubGrp.containsKey(step.OriginalActorId)){
                    Set<id> idsActors = mQueuePubGrp.get(step.OriginalActorId);
                    System.debug('idsActors ==> '+idsActors);
                    if(idsActors.contains(step.ActorId)){
                        
                    }
                    else if(!idsActors.contains(step.ActorId)){
                        //If Approver is not part of Queue - Check if Approver is Reassigned User.
                        if(mKeyActorId.containsKey(itemp2)){
                            // If not Reassigned User set the Delegate flag as TRUE
                            if(!mKeyActorId.get(itemp2).contains(step.ActorId)){
                                checkAndPutInMap(itemp2,mKeyIsActorDelegatedUser);
                                /*if(!mKeyIsActorDelegatedUser.containsKey(itemp2)){
                                    mKeyIsActorDelegatedUser.put(itemp2,true);
                                }*/
                            }
                        }
                    }
                }
            }
            else{
                if(step.OriginalActorId == step.ActorId){
                    //String temp2 = temp+'_'+step.ActorId+'_'+step.StepStatus;
                    integer itemp2 = getHashCodeForUniqueKey(temp,step.ActorId,step.StepStatus);
                    //checkAndPutInMap(itemp2,mKeyIsActorDelegatedUser);
                    if(!mKeyIsActorDelegatedUser.containsKey(itemp2)){
                        mKeyIsActorDelegatedUser.put(itemp2,false);
                    } 
                    
                }
                else if(mKeyActorId.containsKey(itemp)){
                    if(!mKeyActorId.get(itemp).contains(step.ActorId)){
                        // Possible Delegated Approver.
                        //String temp2 = temp+'_'+step.ActorId+'_'+step.StepStatus;
                        integer itemp2 = getHashCodeForUniqueKey(temp,step.ActorId,step.StepStatus);
                        checkAndPutInMap(itemp2,mKeyIsActorDelegatedUser);
                        /*if(!mKeyIsActorDelegatedUser.containsKey(itemp2)){
                            mKeyIsActorDelegatedUser.put(itemp2,true);
                        }*/
                    }
                }
                else{
                    if(step.OriginalActorId != step.ActorId){
                        //String temp2 = temp+'_'+step.ActorId+'_'+step.StepStatus;
                        integer itemp2 = getHashCodeForUniqueKey(temp,step.ActorId,step.StepStatus);
                        checkAndPutInMap(itemp2,mKeyIsActorDelegatedUser);
                        /*if(!mKeyIsActorDelegatedUser.containsKey(itemp2)){
                            mKeyIsActorDelegatedUser.put(itemp2,true);
                        }*/
                    }
                }
            }
            
        }
        return mKeyIsActorDelegatedUser;
    }
    private static integer getHashCodeForUniqueKey(String str1,String str2,String str3){
        String temp = str1+'_'+str2+'_'+str3;
        integer itemp = temp.hashCode();
        return itemp;
        
    }
    private static void checkAndPutInMap(integer itemp2,Map<integer,boolean> mKeyIsActorDelegatedUser){
        if(!mKeyIsActorDelegatedUser.containsKey(itemp2)){
            mKeyIsActorDelegatedUser.put(itemp2,true);
        }
    }
    
}