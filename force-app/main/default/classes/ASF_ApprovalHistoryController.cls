public without sharing class ASF_ApprovalHistoryController {
    
    public static final String APPROVE_ACTION = 'Approve';
    public static final String REJECT_ACTION = 'Reject';
    public static final String RECALL_ACTION = 'Removed';
    
    
    @AuraEnabled(Cacheable=true)
    public static List<ASF_LookupSearchResult> searchQueues(String searchTerm){
        searchTerm += '*';
        System.debug('searchTerm --> '+searchTerm);
        List<List<SObject>> searchResults = [
            FIND :searchTerm
            IN ALL FIELDS
            RETURNING
            Group(Id, Name,DeveloperName WHERE Type ='Queue')
            LIMIT :ASF_ApprovalHistoryUtil.MAX_RESULTS 
        ];
        
        List<ASF_LookupSearchResult> results = new List<ASF_LookupSearchResult>();
        
        // Extract Accounts & convert them into LookupSearchResult
        String userIcon = 'standard:queue';
        Group[] groups = (List<Group>) searchResults[0];
        for (Group currGrp : groups) {
            results.add(
                new ASF_LookupSearchResult(
                    currGrp.Id,
                    'Group',
                    userIcon,
                    currGrp.Name,
                    ''
                )
            );
        }
        
        // Optionnaly sort all results on title
        results.sort();
        
        return results;
    }
    
    @AuraEnabled(Cacheable=true)
    public static List<ASF_LookupSearchResult> searchUsers(String searchTerm) {
        // Prepare query paramters
        searchTerm += '*';
        
        //Commenting below lines as not required for current release
        //List<User> flattenRoleUsers = FlattenRoleHierarchyUtility.execute(UserInfo.getUserRoleId());
        //Map<Id,User> mFlattenRoleUsers = new Map<Id,User>(flattenRoleUsers);
        // Execute search query   
        /*List<List<SObject>> searchResults = [
FIND :searchTerm
IN ALL FIELDS
RETURNING
User(Id, FirstName, LastName,Title WHERE Id =: mFlattenRoleUsers.keySet())
LIMIT :ASF_ApprovalHistoryUtil.MAX_RESULTS 
];*/
        List<List<SObject>> searchResults = [
            FIND :searchTerm
            IN ALL FIELDS
            RETURNING
            User(Id, FirstName, LastName,Title)
            LIMIT :ASF_ApprovalHistoryUtil.MAX_RESULTS 
        ];
        
        // Prepare results
        List<ASF_LookupSearchResult> results = new List<ASF_LookupSearchResult>();
        
        // Extract Accounts & convert them into LookupSearchResult
        String userIcon = 'standard:user';
        User[] users = (List<User>) searchResults[0];
        for (User currUser : users) {
            results.add(
                new ASF_LookupSearchResult(
                    currUser.Id,
                    'User',
                    userIcon,
                    currUser.FirstName + ' ' + currUser.LastName,
                    currUser.Title
                )
            );
        }
        
        // Optionnaly sort all results on title
        results.sort();
        
        return results;
    }
    
    @AuraEnabled
    public static String getStepIdAfterApproval(String instanceId, String entityId,String action){
        String stepId ='';
        List<ProcessInstanceStep> steps = [SELECT ID FROM ProcessInstanceStep WHERE ProcessInstanceId=:instanceId AND ProcessInstance.TargetObjectId =: entityId AND StepStatus =:action ORDER By SystemModStamp DESC LIMIT 1];
        if(steps.size()>0){
            stepId = steps[0].Id;
        }
        return stepId;
        
        
    }
    public class approvalResponse{
        @AuraEnabled
        public string actorId{get;set;}
        @AuraEnabled
        public string entityId{get;set;}
        @AuraEnabled
        public string success{get;set;}
        @AuraEnabled
        public string instanceId{get;set;}
        @AuraEnabled
        public string stepId{get;set;}
        
    }
    
    @AuraEnabled
    public static String processStep(String recordId, String comments, String nextApproverId, String action){
        List<ProcessInstanceWorkitem> workItems = new List<ProcessInstanceWorkItem>();
        System.debug('Incoming Record Id --> '+recordId);
        Id loggedInUserId = UserInfo.getUserId();
        Id prfId = UserInfo.getProfileId();
        boolean isAdminUser = false;
        List<Profile> modifyAllDataProfile = [SELECT Id FROM Profile WHERE Id =:prfId AND PermissionsModifyAllData = true];
        if(!modifyAllDataProfile.isEmpty()){
            isAdminUser = true;
        }
        Set<Id> delegatedForUserId = new Set<Id>();
        delegatedForUserId.add(loggedInUserId);
        for(User u : [SELECT ID FROM User WHERE DelegatedApproverId =: loggedInUserId AND IsActive = TRUE]){
            delegatedForUserId.add(u.Id);
        }
        
        if(String.isNotBlank(recordId)){
            Id recId = Id.valueOf(recordId);
            String objectName = recId.getSobjectType().getDescribe().getName();
            if(recId.getSobjectType()== ProcessInstanceWorkitem.sObjectType){
                workItems = [
                    SELECT Id, ProcessInstanceId 
                    FROM ProcessInstanceWorkitem 
                    WHERE Id = :recordId 
                ];
            } 
            else{
                boolean isRecalled = false;
                if(String.isNotBlank(action)){
                    if(action.trim().toUpperCase() == 'REMOVED'){
                        isRecalled = true;
                    }
                }
                if(isAdminUser || isRecalled){
                    workItems = [
                        SELECT Id, ProcessInstanceId 
                        FROM ProcessInstanceWorkitem 
                        WHERE ProcessInstance.TargetObjectId = :recordId 
                    ];
                }
                else{
                    workItems = [
                        SELECT Id, ProcessInstanceId 
                        FROM ProcessInstanceWorkitem 
                        WHERE ProcessInstance.TargetObjectId = :recordId AND ActorId =: delegatedForUserId
                    ];
                    
                }
                
            }
        }
        
        
        
        Approval.ProcessResult result = ASF_ApprovalHistoryUtil.processStep(workItems,comments, nextApproverId,  action);
        return JSON.serialize(result);
    }
    /*
@AuraEnabled
public static void reassignStep(String recordId, String newActorId ){
List<ProcessInstanceWorkItem> items = new List<ProcessInstanceWorkItem>();

if(String.IsNotBlank(recordId)){
Id recId = Id.ValueOf(recordId);
if(recId.getSobjectType() == ProcessInstanceWorkItem.sObjectType){
items = [SELECT Id,ActorId,ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE Id = : recordId];
}
else{
items = [SELECT Id,ActorId,ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = : recordId];
}
ASF_ApprovalHistoryUtil.reassignStep(items, newActorId);
}


}*/
    
    /*
@AuraEnabled
public static String submitForApproval(String recordId, String comments, String nextApproverId){
Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
req.setComments(comments);
if(!String.isBlank(nextApproverId)){
req.setNextApproverIds(new Id[] {nextApproverId});
}
req.setObjectId(recordId);

// Submit on behalf of a specific submitter
req.setSubmitterId(ASF_ApprovalHistoryUtil.currentUserId); 
// Submit the approval request for the account
Approval.ProcessResult result = Approval.process(req);

return JSON.serialize(result);

}*/
    
    
    @AuraEnabled (cacheable=true)
    public static ApprovalHistory getApprovalHistory(String recordId){  
        
        List<ProcessInstance> processInstances = [SELECT Id,SubmittedById, ProcessDefinition.Name , (SELECT ID, ProcessNodeId,  
                                                                                                     StepStatus,Comments,TargetObjectId,ActorId,CreatedById,IsDeleted,IsPending  
                                                                                                     ,OriginalActorId,ProcessInstanceId,RemindersSent,CreatedDate, Actor.Name,  
                                                                                                     OriginalActor.Name , ProcessNode.Name FROM StepsAndWorkitems order by IsPending DESC, CreatedDate DESC )   
                                                  FROM ProcessInstance where TargetObjectId =:recordId order by CreatedDate DESC];                                                                         
        
        return ASF_ApprovalHistoryUtil.populateApprovalHistorySteps(processInstances, recordId);                                                 
        
        
    }  
    
    public class ApprovalHistoryStep{
        @AuraEnabled  
        public String stepName {get;set;}  
        @AuraEnabled  
        public String stepUrl {get;set;}
        @AuraEnabled  
        public DateTime createdDate {get;set;}   
        @AuraEnabled  
        public String stepStatus {get;set;}  
        @AuraEnabled  
        public String assignedTo {get;set;}   
        @AuraEnabled  
        public String assignedToUrl {get;set;}
        @AuraEnabled
        public String actualapprover{get;set;}
        @AuraEnabled
        public String actualapproverToUrl{get;set;}
        @AuraEnabled
        public String comments {get;set;}
        @AuraEnabled
        public boolean bDelegatedApprover {get;set;}
        
        public ApprovalHistoryStep(
            String stepName,
            String stepId,
            DateTime createdDate, 
            String stepStatus,
            String assignedTo,
            String assignedToId,
            String actualappr,
            String actualapprId,
            String comments,
            boolean isDelegatedApprover
        )  
        { 
            this.stepName = stepName;
            this.stepUrl = '/' + stepId;
            this.createdDate = createdDate;
            this.assignedTo = assignedTo;  
            this.assignedToUrl = '/'+assignedToId;
            this.comments = comments;
            this.actualapprover = actualappr;
            this.actualapproverToUrl = '/'+actualapprId;
            if(isDelegatedApprover){
                this.bDelegatedApprover = isDelegatedApprover;
            }
            else{
                this.bDelegatedApprover = false;
            }
            
            if(stepStatus == ASF_ApprovalHistoryUtil.STATUS_STARTED){
                this.stepStatus = ASF_ApprovalHistoryUtil.STATUS_SUBMITTED;
            }else if(stepStatus == ASF_ApprovalHistoryUtil.STATUS_REMOVED){
                this.stepStatus = ASF_ApprovalHistoryUtil.STATUS_RECALLED;
            }else{
                this.stepStatus = stepStatus;
            }
            
        } 
    }
    
    public class ApprovalHistory{
        @AuraEnabled
        public List<ApprovalHistoryStep> approvalSteps;
        @AuraEnabled
        public String approvalStepsSize;
        @AuraEnabled 
        public boolean isCurrentUserApprover; 
        @AuraEnabled 
        public boolean showRecall;  //Modify All Data" permission or "Modify All" on the object level
        // system admin and submitter(if it says so on the approval process)
        //SELECT Name FROM Profile WHERE PermissionsModifyAllData = true
        //query permission sets with modify all or modify all for object and see if curr user has them
        
        @AuraEnabled 
        public boolean showSubmitForApproval; 
        public ApprovalHistory(List<ApprovalHistoryStep> approvalSteps, boolean isCurrentUserApprover, boolean isSubmitForApproval, boolean showRecall){
            this.approvalSteps = approvalSteps;
            this.isCurrentUserApprover = isCurrentUserApprover; 
            //this.approvalStepsSize = moreThan6Steps ? '6+' : string.valueOf(approvalSteps.size());
            this.showSubmitForApproval = isSubmitForApproval;
            this.showRecall = showRecall;
        }
        
    }
    @AuraEnabled(cacheable = true)
    public static approvalHighlightedPanel getHighlightedPanelFields(String recordId){
        List<ProcessInstanceWorkItem> items = [SELECT ID,ProcessInstanceId,OriginalActor.Name,Actor.Name FROM ProcessInstanceWorkItem WHERE Id=: recordId];
        List<ProcessInstance> pInstance = [SELECT ID,TargetObjectId,Status,SubmittedBy.Name FROM ProcessInstance WHERE Id =: items[0].ProcessInstanceId];
        if(pInstance.size()>0){
            String OriginalActor = '';
            String ActorName = '';
            if(String.isNotBlank(items[0].OriginalActor.Name)){
                OriginalActor = items[0].OriginalActor.Name;
            }
            if(String.isNotBlank(items[0].Actor.Name)){
                ActorName = items[0].Actor.Name;
            }
            ProcessInstance pInst = pInstance[0];
            approvalHighlightedPanel cls = new approvalHighlightedPanel(pInst.SubmittedBy.Name,pInst.Status,pInst.TargetObjectId,OriginalActor,ActorName);
            return cls;
        }
        return new approvalHighlightedPanel();
        
        
    }
    public class approvalHighlightedPanel{
        @AuraEnabled
        public string submitter{get;set;}
        @AuraEnabled
        public string status{get;set;}
        @AuraEnabled
        public string objName{get;set;}
        @AuraEnabled
        public String OriginalActorName{get;set;}
        @AuraEnabled
        public String ActorAssignToName{get;set;}
        
        public approvalHighlightedPanel(String submittedBy,string status,String recordId,String OriginalActor,String ActorName){
            this.submitter = submittedBy;
            this.status = status;
            this.OriginalActorName = OriginalActor;// Assigned To on UI
            this.ActorAssignToName = ActorName; //Actual Approver To on UI
            if(String.IsNotBlank(recordId)){
                Id recId = Id.valueOf(recordId);
                String objectNm = recId.getSobjectType().getDescribe().getLabel();
                this.objName = objectNm;
            }
            
        }
        public approvalHighlightedPanel(){
            
        }
    }
    @AuraEnabled(cacheable=true)
    public static ASF_Case_Approv__c getCaseApprovalRecord(String recordId){
        return [SELECT ID,SR__c FROM ASF_Case_Approv__c WHERE Id =: recordId];
    }
    
    @AuraEnabled
    public static boolean isCommunity(){
        Id siteId = Site.getSiteId(); // take a look at the apex class Site, you may find more useful method concerning site/community
        if (siteId != null) {
            return true;
        }
        return false;
    }
    
    
}