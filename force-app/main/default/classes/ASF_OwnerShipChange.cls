public with sharing class ASF_OwnerShipChange {
    public ASF_OwnerShipChange() {

    }
    @AuraEnabled(cacheable=false)
    public static void changeOwnerToOtherUser(String caseRecordId,String newOwnerId) {
        if(checkManagerAccess(caseRecordId)){
           List<case> caseUpdateListSecurity = new List<Case>();
            Case c = new Case();
            c.Id = caseRecordId;
            c.ownerId = newOwnerId;
            caseUpdateListSecurity.add(c);
            update caseUpdateListSecurity;
            List<Case> caseUpdateList = new List<Case>();
            caseUpdateList.add(c);
            update caseUpdateList;
        }
    }   

    @AuraEnabled(cacheable=false)
    public static boolean checkManagerAccess(String caseRecordId) {
        boolean ismanager = false;
        caseRecordId = String.escapeSingleQuotes(caseRecordId);
        Case cas = [Select ownerId from Case where id = :caseRecordId limit 1];
        user u = [select managerGroupId__c,managerId,manager.Id,manager.manager.Id,manager.manager.manager.id,manager.manager.manager.manager.id,manager.manager.manager.manager.manager.id from user where id =:cas.ownerId ];
        
        if (userInfo.getUserId() == u.managerId){
            ismanager = true;
        }
        else if(userInfo.getUserId() == u.manager.manager.Id){
            ismanager = true;
        }
        else if(userInfo.getUserId() == u.manager.manager.manager.Id){
            ismanager = true;
        }
        else if(userInfo.getUserId() == u.manager.manager.manager.manager.Id){
            ismanager = true;
        }
        else if(userInfo.getUserId() == u.manager.manager.manager.manager.manager.Id){
            ismanager = true;
        }
        else {
            List<GroupMember> groupMemberList = [Select userOrGroupId from GroupMember where groupId = :u.managerGroupId__c];
            for(Groupmember g:groupMemberList){
                if(g.userOrGroupId ==userInfo.getUserId()){
                    ismanager = true;
                }
            }
        }
        return ismanager;
    }   
}