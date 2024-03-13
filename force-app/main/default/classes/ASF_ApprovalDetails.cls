/******************************************************  
* Author           - Salesforce
* Description      - Class to get the approval history records
********************************************************
*/
public without sharing class ASF_ApprovalDetails {
    @AuraEnabled (cacheable=true)
    public static  List<returnValue> getApprovalHistory(String recordId){  
        Set<Id> caseApprovalId = new Set<Id>();
        List<returnValue> retVal = new List<returnValue>();
        
        Map<Id,ASF_Case_Approv__c> mCaseApprov = new Map<Id,ASF_Case_Approv__c>([SELECT ID,Approval_Type__c,SR__c, Case_Stage_At_Creation__c  FROM ASF_Case_Approv__c WHERE SR__c =:recordId ]);
        
        List<ProcessInstance> processInstances = [SELECT Id,SubmittedById, ProcessDefinition.Name,TargetObjectId , (SELECT ID, ProcessNodeId,  
                                                                                                                    StepStatus,Comments,TargetObjectId,ActorId,CreatedById,IsDeleted,IsPending  
                                                                                                                    ,OriginalActorId,ProcessInstanceId,RemindersSent,CreatedDate, Actor.Name,  
                                                                                                                    OriginalActor.Name , ProcessNode.Name FROM StepsAndWorkitems WHERE StepStatus != 'started'order by IsPending DESC, CreatedDate DESC )   
                                                  FROM ProcessInstance where TargetObjectId =:mCaseApprov.keySet() order by CreatedDate DESC];                                                                         
        //system.debug('processInstances'+processInstances[0].StepsAndWorkitems);
        
        for(ProcessInstance pInst : processInstances){
            if(mCaseApprov.containsKey(pInst.TargetObjectId)){
                Id caId = pInst.TargetObjectId;
                List<stepsDetail> steps = new List<stepsDetail>();
                
                for(ProcessInstanceHistory swItem : pInst.StepsAndWorkitems){
                    if(swItem.OriginalActorId !=null){
                        string actorName = swItem.OriginalActor.Name;
                        String stepStat = swItem.StepStatus;
                        steps.add(new stepsDetail(actorName,stepStat));
                    }
                }
                returnValue cls = new returnValue(caId,mCaseApprov.get(caId).Approval_Type__c,steps,mCaseApprov.get(caId).Case_Stage_At_Creation__c);
                retVal.add(cls);
            }
        }
        return retVal; 
        
    } 
    
    //Case_Approval_Id
    //ApprovalType
    //List<ProcessInstace>{}
    public class returnValue{
        @AuraEnabled
        public Id caseApprovalId{get;set;}
        @AuraEnabled
        public String approvalType{get;set;}
        @AuraEnabled
        public List<stepsDetail> stepDetails {get;set;}
        @AuraEnabled
        public String currStg{get;set;}
        
        public returnValue(Id caId,String caType,List<stepsDetail> steps,String currStage){
            this.caseApprovalId = caId;
            this.approvalType = caType;
            this.stepDetails = steps;
            this.currStg = currStage;
        }
    }
    public class stepsDetail{
        @AuraEnabled
        public string actorName{get;set;}
        @AuraEnabled
        public String stepName{get;set;}
        
        public stepsDetail(String actName,String stepNm){
            this.actorName = actName;
            this.stepName = stepNm;
        }
    }
    
}