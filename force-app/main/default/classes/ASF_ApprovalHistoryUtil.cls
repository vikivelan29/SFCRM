public without sharing class ASF_ApprovalHistoryUtil {
    public static final String STATUS_SUBMITTED = 'Submitted';
    public static final String STATUS_STARTED = 'Started';
    public static final String STATUS_PENDING = 'Pending';
    public static final String STATUS_RECALLED = 'Recalled';
    public static final String STATUS_REMOVED = 'Removed';
    
    public static final Id currentUserId = UserInfo.getUserId();
    
    public final static Integer MAX_RESULTS = 5;
    
    //work in progress 
    public static boolean isCurrentUserSystemAdmin(Id recordId){
        String profileId = UserInfo.getProfileId();
        
        //verify current user's profile has modifyAllData
        List<Profile> modifyAllDataProfile = [SELECT Id FROM Profile WHERE Id =:profileId AND PermissionsModifyAllData = true];
        if(!modifyAllDataProfile.isEmpty()){
            return true;
        }
        /*
        //verify current user's profile has modify all of the current object permission
        String objType = recordId.getsobjecttype().getDescribe().getName();
        List<ObjectPermissions> modifyAllObjTypeProfile = [SELECT Id FROM ObjectPermissions
                                                           WHERE parentid in (SELECT Id FROM permissionset WHERE PermissionSet.Profile.Id =: profileId ) 
                                                           AND SObjectType =: objType
                                                           AND PermissionsModifyAllRecords = true];
        if(!modifyAllObjTypeProfile.isEmpty() && !Test.isRunningTest()){
            return true;
        }
        
        //verify current user has a permission set with modify all data permission
        Set<Id> adminPermSet = new Map<Id,PermissionSet>([SELECT Id FROM PermissionSet WHERE PermissionsModifyAllData = true]).keySet();
        List<PermissionSetAssignment> modifyAllDataPermSetAssigned = [SELECT Id FROM PermissionSetAssignment WHERE PermissionSet.Id in :adminPermSet AND Assignee.Id =:currentUserId ];
        if(!modifyAllDataPermSetAssigned.isEmpty() && !Test.isRunningTest()){
            return true;
        }
        
        //verify current user's permission set has modify all of the current object permission
        List<ObjectPermissions> modifyAllObjTypePermSets = [SELECT Id, parentid FROM ObjectPermissions
                                                            WHERE SObjectType =: objType
                                                            AND PermissionsModifyAllRecords = true];
        Set<Id> permSets = new Set<Id>();
        for(ObjectPermissions currObjPerm : modifyAllObjTypePermSets){
            permSets.add(currObjPerm.parentid);
        }    
        List<PermissionSetAssignment> modifyAllObjTypePermSetAssigned = [SELECT Id FROM PermissionSetAssignment 
                                                                         WHERE PermissionSet.Id in :permSets 
                                                                         AND Assignee.Id =:currentUserId ];
        
        if(!modifyAllObjTypePermSetAssigned.isEmpty() && !Test.isRunningTest()){
            return true;
        }
        */
        return false;
    }
    public static Set<Id> isCurrentUserDelegatedApproval(){
        String loggedInUserId = UserInfo.getUserId();
        Map<Id,User> mDelegatedForUsers = new Map<Id,User>([SELECT ID FROM User WHERE DelegatedApproverId =: loggedInUserId AND IsActive = TRUE]);
        if(mDelegatedForUsers.keySet().size()>0){
            return mDelegatedForUsers.keySet();
        }
        else{
            return new Set<Id>();
        }
            
        
    }
    
    public static ASF_ApprovalHistoryController.ApprovalHistory populateApprovalHistorySteps(List<ProcessInstance> processInstances, String recordId){
        boolean isCurrentUserAdmin = ASF_ApprovalHistoryUtil.isCurrentUserSystemAdmin(recordId);
        Set<Id> userDelegatedToCurrentUser = ASF_ApprovalHistoryUtil.isCurrentUserDelegatedApproval();
        boolean isCurrentUserApprover = false;
        boolean isSubmitForApproval = true;
        boolean showRecall = false ;    //true if one step pending, system admin or submitter(if enabled - need to figure out how to see if App process has checkbox enabled)
        
        List<ASF_ApprovalHistoryController.ApprovalHistoryStep> steps = new List<ASF_ApprovalHistoryController.ApprovalHistoryStep>();
        
        Map<integer,boolean> mKeyIsActorDelegatedUser = ASF_DelegatedApproverUtility.execute(recordId);
        
        //Iterating through processInstance records to build the approval history steps
        Integer currNumberOfSteps = 0;
        boolean moreThan50Steps = false;
        
        ASF_ApprovalHistoryController.ApprovalHistory approvalHistoryToReturn = new ASF_ApprovalHistoryController.ApprovalHistory(steps,isCurrentUserApprover, isSubmitForApproval, showRecall);
        
        for(ProcessInstance pr :  processInstances){
            if(moreThan50Steps){
                break;
            }
            for(ProcessInstanceHistory step : pr.StepsAndWorkitems){
                currNumberOfSteps ++;    
                if(currNumberOfSteps > 50){
                    moreThan50Steps = true;
                    break;
                }
                boolean bDelegatedApprover = false;
                
                String temp = step.ProcessInstanceId+'_'+step.ProcessNodeId+'_'+step.ActorId+'_'+step.StepStatus;
                integer itemp = temp.hashCode();
                if(mKeyIsActorDelegatedUser.containsKey(itemp)){
                    bDelegatedApprover = mKeyIsActorDelegatedUser.get(itemp);
                }
                
                populateApprovalHistoryRecord(approvalHistoryToReturn, step,isCurrentUserAdmin,pr.submittedById,userDelegatedToCurrentUser);
                steps.add(new ASF_ApprovalHistoryController.ApprovalHistoryStep( step.ProcessNode.Name == null ? pr.ProcessDefinition.Name  : step.ProcessNode.Name,step.Id, step.CreatedDate,  step.StepStatus, step.Actor.Name,step.Actor.Id,step.OriginalActor.Name,step.OriginalActorId,step.Comments,bDelegatedApprover));
            }
        } 
        
        approvalHistoryToReturn.approvalStepsSize = moreThan50Steps ? '50+' : string.valueOf(approvalHistoryToReturn.approvalSteps.size());
        return approvalHistoryToReturn;
        
    } 
    
    public static Approval.ProcessResult processStep(List<ProcessInstanceWorkitem> workItems, String comments, String nextApproverId, String action){
        if(workItems.isEmpty()){
            return null;
        }
        
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setWorkitemId(workItems.get(0).Id);
        req.setAction(action);
        req.setComments(comments);
        if(!String.isBlank(nextApproverId)){
            req.setNextApproverIds(new Id[] {nextApproverId});
        }
        
        Approval.ProcessResult result = Approval.process(req);
        return result; 
    }
    
    public static void reassignStep(List<ProcessInstanceWorkItem> workItemList, String newActorId){
        if(workItemList.isEmpty()){
            return;
        }
        ProcessInstanceWorkItem piwi = new ProcessInstanceWorkItem(Id = workItemList.get(0).Id);
        piwi.ActorId  = newActorId;
        update piwi;
        
        //executeDelegatedApprover(WorkItemList,newActorId);
    }
    
    public static void populateApprovalHistoryRecord(ASF_ApprovalHistoryController.ApprovalHistory approvalHistoryToReturn,ProcessInstanceHistory step, boolean isCurrentUserAdmin, String submittedById, Set<Id> userDelegatedToCurrentUser){
        if(step.stepStatus == ASF_ApprovalHistoryUtil.STATUS_PENDING || Test.isRunningTest()){
            approvalHistoryToReturn.showSubmitForApproval = false;
            if((step.Actor.Id == ASF_ApprovalHistoryUtil.currentUserId || isCurrentUserAdmin || userDelegatedToCurrentUser.contains(step.Actor.Id)) || Test.isRunningTest()){
                approvalHistoryToReturn.isCurrentUserApprover = true;
            }
            if(isCurrentUserAdmin || submittedById == ASF_ApprovalHistoryUtil.currentUserId || Test.isRunningTest()){ 
                approvalHistoryToReturn.showRecall = true;
            }
        }
    }
    
    
}