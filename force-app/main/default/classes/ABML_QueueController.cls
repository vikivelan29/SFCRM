/******************************************************  
* Author           - Souvik Gosh
* Date             - 10-October-2024
* Description      - Class for ABML_Queue Component
********************************************************
*/
public with sharing class ABML_QueueController {
    
    @AuraEnabled(cacheable=true)
    public static List<Group> getQueues() {
        return [SELECT Id, Name FROM Group WHERE Type = 'Queue' and Name like 'ABML%'];
    }


    
    @AuraEnabled
    public static List<Map<String, String>> getQueueNames() {
        List<Map<String, String>> queues = new List<Map<String, String>>();
        for (Group g : [SELECT Id, Name FROM Group where Type = 'Queue' and Name like 'ABML%']) {
            queues.add(
                new Map<String, String>{ 'label' => g.Name, 'value' => g.Id }
            );
        }
        return queues;
    }


    
    @AuraEnabled(cacheable=true)
    public static List<User> getUsersByQueue(Id queueId) {
        return [
            SELECT Id, Name, Email
            FROM User
            WHERE Id IN (SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :queueId)
        ];
    }


    @AuraEnabled
    Public static void updateCaseOwner(List<id> caseid, Id ownerids){
    try {
        
          /*case c = new case();
          c.id = caseid;
          c.ownerid = Ownerids;
          update c;*/
        List<Case> caseList = new List<Case>();
        for(Case cs:[Select Id,ownerid from Case where Id IN:caseid]){
            cs.OwnerId = ownerids;
            caseList.add(cs);
        }
        update caseList;
  

    } catch (Exception e) {
            throw new AuraHandledException('Error updating record: ' + e.getMessage());
        }
}


@AuraEnabled(cacheable=true)
    public static List<User> getUsersInQueue(String queueId, String userName) {
        if (String.isEmpty(queueId)) {
            return new List<User>();
        }

        // Fetch users in the selected queue with an optional user name filter
        return [SELECT Id, Name, Email FROM User WHERE Id IN (SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :queueId) AND Name LIKE :('%' + userName + '%') ORDER BY Name];
    }




     @AuraEnabled(cacheable=true)
    public static List<Group> searchQueuesByName(String queueName) {
        // Ensure we only retrieve Queues with the provided name filter.
        String searchKey = '%' + queueName + '%';
        return [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name LIKE :searchKey ORDER BY Name LIMIT 100];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Case> getCaseDetails(List<id> caseid) {//added by Dinoy
        return [SELECT Id,ownerid,CaseNumber,Subject FROM Case WHERE Id IN:caseid];
    }
    
    @AuraEnabled(cacheable=true)
    public static Boolean checkBusinessHours(){ //added by Dinoy, To show the abml_Queue component based on the business hours
     
       //String businessName = 'ABML';
       BusinessHours bh = [SELECT Id FROM BusinessHours WHERE Name=:System.Label.ABML_BU]; 
       Datetime targetTime = System.Now();

       // Check whether the time is within the default business hours
       Boolean isWithin= BusinessHours.isWithin(bh.id, targetTime);
        
        return isWithin;
    }
    
    @AuraEnabled(cacheable=true)
    public static Boolean checkProfile(){ //added by Dinoy, To show the abml_Queue component based on the permission set ABML_Bulk_Assignment_PS
     
        Boolean isCheck;
        User usr = [SELECT Id,ProfileId FROM User WHERE Id=:UserInfo.getUserId()];
        
        List<PermissionSetAssignment> lstcurrentUserPerSet =    [   SELECT Id, PermissionSet.Name,AssigneeId
                                                                FROM PermissionSetAssignment
                                                                WHERE AssigneeId = :usr.Id and PermissionSet.Name =:System.Label.ABML_Bulk_Assignment_PS];
        isCheck = lstcurrentUserPerSet.size()>0 ? true : false;
        
        return isCheck;
    }

}