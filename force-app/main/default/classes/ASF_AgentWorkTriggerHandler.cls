public without sharing class ASF_AgentWorkTriggerHandler extends ASF_VTriggerHandler {
    private Boolean isTriggerDisabled(){
        return isDisabled('AgentWork');
    }
    public override void afterInsert(Map<Id, SObject> newAgentWorks) {
        if(isTriggerDisabled()){return;}

        Map<Id, List<Id>> assignedUserIdToCaseIdsMap = new Map<Id,List<Id>>();
        for(AgentWork awRec : (List<AgentWork>)newAgentWorks.values()){
            if(awRec.WorkItemId != null && awRec.WorkItemId.getSobjectType() == Schema.Case.SObjectType){
                if(!assignedUserIdToCaseIdsMap.containsKey(awRec.UserId)){
                    assignedUserIdToCaseIdsMap.put(awRec.UserId, new List<Id>());
                }
                assignedUserIdToCaseIdsMap.get(awRec.UserId).add(awRec.WorkItemId);
            }
        }
        if(!assignedUserIdToCaseIdsMap.isEmpty()){
            ASF_CaseSLAHandlerV1.modifySLAHistoryOnOmnichannelAssignment(assignedUserIdToCaseIdsMap);
        }
    }
}