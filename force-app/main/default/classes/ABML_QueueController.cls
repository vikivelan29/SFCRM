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
        for (Group objGroup : [SELECT Id, Name FROM Group where Name like 'ABML%' AND Type = 'Queue']) {
            String uId = String.valueOf(objGroup.Id); 
            listOfQueues.add(
                new Map<String, String>{ 'label' => objGroup.Name, 'value' => objGroup.Id }
            );            
        }
        return listOfQueues;
    }  
    
    @AuraEnabled(cacheable=true)
    public static List<User> getUsersByQueue(Id queueId) {
        Set<String> setOfPublicGroupId = new Set<String>();
        Set<String> setOfUserId = new Set<String>();
        if(queueId != null){
            for (GroupMember objGroupMember : [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId =: queueId]) {
                 String uId = String.valueOf(objGroupMember.UserOrGroupId); 
                if(uId.startsWith('00G')){
                    setOfPublicGroupId.add(objGroupMember.UserOrGroupId);
                }
            }
        }
        for (GroupMember objGroupMember : [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN: setOfPublicGroupId]) {
            setOfUserId.add(objGroupMember.UserOrGroupId);
        }
        if(setOfUserId != null){
        	return [SELECT Id, Name, Email FROM User WHERE Id IN: setOfUserId];
        }
        else{
            return new List<User>();
        }
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
        Set<String> setOfPublicGroupId = new Set<String>();
        Set<String> setOfUserId = new Set<String>();
        if(queueId != null){
            for (GroupMember objGroupMember : [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId =: queueId]) {
                 String uId = String.valueOf(objGroupMember.UserOrGroupId); 
                if(uId.startsWith('00G')){
                    setOfPublicGroupId.add(objGroupMember.UserOrGroupId);
                }
            }
        }
        for (GroupMember objGroupMember : [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN: setOfPublicGroupId]) {
            setOfUserId.add(objGroupMember.UserOrGroupId);
        }
        if(setOfUserId != null){
        	return [SELECT Id, Name, Email FROM User WHERE Id IN: setOfUserId AND Name LIKE :('%' + userName + '%') ORDER BY Name LIMIT 100];
        }  
        else{
            return new List<User>();
        }
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
    public static List<ListView> getCaseListViews() {
        return [SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE SobjectType = 'Case' AND Name LIKE '%ABML%'];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Case> getCaseRecords(String listViewId) {
        if (String.isEmpty(listViewId)) {
            return new List<Case>();
        } 
        String query = ABML_Listviewcallout.doCallout(listViewId);
        return Database.query(query);
    } 
    
    @AuraEnabled(cacheable=true)
    public static List<Case> getSearchRecords(String searchText) {
        if (String.isEmpty(searchText)) {
            return new List<Case>();
        }        
        return [SELECT Id, CaseNumber, Subject, Status, CreatedDate, Owner.Name, OwnerText__c, Description FROM Case WHERE Subject!=null and Status!='Resolved' and (Subject LIKE :('%' + searchText + '%') OR CaseNumber LIKE :('%' + searchText + '%') OR OwnerText__c LIKE :('%' + searchText + '%')) ORDER BY Subject LIMIT 200];
    }
    
}