/******************************************************  
* Author           - Souvik Gosh
* Date             - 10-October-2024
* Description      - Class for ABML_Queue Component
********************************************************
*/
public without sharing class ABML_QueueController { //Without sharing is added for avoiding apex class access issues
    
    @AuraEnabled
    public static List<Map<String, String>> getQueueNames() {
        List<Map<String, String>> listOfQueues = new List<Map<String, String>>();
        for (Group objGroup : [SELECT Id, Name FROM Group where Type = 'Queue' and Name like 'ABML%']) {
            listOfQueues.add(
                new Map<String, String>{ 'label' => objGroup.Name, 'value' => objGroup.Id }
            );
        }
        return listOfQueues;
    }  
    
    @AuraEnabled(cacheable=true)
    public static List<User> getUsersByQueue(Id queueId) {
        return [SELECT Id, Name, Email FROM User WHERE Id IN (SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :queueId)];
    }    
    
    @AuraEnabled
    public static void updateCaseOwner(List<Id> caseIdList, Id ownerId){
        try {
            List<Case> caseListToUpdate = new List<Case>();
            
            if(!Schema.sObjectType.Case.fields.OwnerId.isAccessible()){
                return;
            }
            
            for(Case objCase : [Select Id, OwnerId from Case where Id IN : caseIdList ]){
                objCase.OwnerId = ownerId;
                caseListToUpdate.add(objCase);
            }
            if(caseListToUpdate != null && caseListToUpdate.size() > 0){
                update caseListToUpdate; 
            }
            
        } 
        catch (Exception e) {
            throw new AuraHandledException('Error updating record: ' + e.getMessage());
        }
    }    
    
    @AuraEnabled(cacheable=true)
    public static List<User> getUsersInQueue(String queueId, String userName) {
        if (String.isEmpty(queueId)) {
            return new List<User>();
        }        
        // Fetch users in the selected queue with an optional user name filter
        return [SELECT Id, Name, Email FROM User WHERE Id IN (SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :queueId) AND Name LIKE :('%' + userName + '%') ORDER BY Name LIMIT 100];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Case> getCaseDetails(List<Id> caseIdList) {
        if(!Schema.sObjectType.Case.fields.OwnerId.isAccessible() || !Schema.sObjectType.Case.fields.CaseNumber.isAccessible() || 
           !Schema.sObjectType.Case.fields.Subject.isAccessible()){
            return null;
        }
        return [SELECT Id, OwnerId, CaseNumber, Subject FROM Case WHERE Id IN : caseIdList];
    }
    
    @AuraEnabled(cacheable=true)
    public static Boolean checkBusinessHours(){ 
        
        BusinessHours objBusinessHour = [SELECT Id FROM BusinessHours WHERE Name =: System.Label.ABML_BU Limit 1];         
        // Check whether the time is within the default business hours
        Boolean isWithin = BusinessHours.isWithin(objBusinessHour.id, System.Now());        
        return isWithin;
    }
    
    @AuraEnabled(cacheable=true)
    public static Boolean checkAssignedPermissionSet(){
        
        String userId = UserInfo.getUserId();
        List<PermissionSetAssignment> assignedPermissionSets = [SELECT Id, PermissionSet.Name,AssigneeId
                                                                FROM PermissionSetAssignment
                                                                WHERE AssigneeId =: userId and PermissionSet.Name =: System.Label.ABML_Bulk_Assignment_PS Limit 1];
        Boolean isCheck = assignedPermissionSets.size() > 0 ? true : false;        
        return isCheck;
    }
    
}