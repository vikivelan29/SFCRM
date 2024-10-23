/*********************************************************
*Class        :  ABSLAMC_IDAMHelperClass
*Author       :  Udit Singhal
*Created Date :  10/10/2024
*Description  :  IDAM helper class
*********************************************************/
public class ABSLAMC_IDAMHelperClass {
    
    public static void populateOldEmail(List<User> newUserList) {
        for(User userRecord :newUserList) {
            if(isUserEligibleForProcessing(userRecord)) {
                userRecord.Old_Email__c = userRecord.email;
            }
        }
    }

    public static void handleLOBChanges(Map<Id, User> newUsersMap, Map<Id, User> oldUsersMap) {
        ASF_TriggerSkipperUtility.markTriggerRun('Case'); // Disable the  case trigger
        
        List<GroupMember> groupMembersToAdd = new List<GroupMember>();
        List<GroupMember> groupMembersToRemove = new List<GroupMember>();
        
        Set<Id> allLobGrpIdSet = new Set<Id>();
        
        Map<String, Id> lobToGroupIdMap = new Map<String, String>();
        Map<Id, Set<Id>> userIdToGrpToRemoveMap = new  Map<Id, Set<Id>>();
        List<Group> groupsList = [
            SELECT Id, Name 
            FROM Group 
            WHERE Type = 'Regular'
            AND Name 
            IN :ABSLAMC_Constants.ABSLAMC_ALL_LOB_GRP_SET
        ];
        
        for (Group groupRecord : groupsList) {
            if(groupRecord.name.contains('MF')) {
                allLobGrpIdSet.add(groupRecord.Id);
                lobToGroupIdMap.put('MF', groupRecord.Id);
            }else if(groupRecord.name.contains('AIF')) {
                allLobGrpIdSet.add(groupRecord.Id);
                lobToGroupIdMap.put('AIF', groupRecord.Id);
            } else if(groupRecord.name.contains('RE')) {
                allLobGrpIdSet.add(groupRecord.Id);
                lobToGroupIdMap.put('RE', groupRecord.Id);
            } else if(groupRecord.name.contains('PMS')) {
                allLobGrpIdSet.add(groupRecord.Id);
                lobToGroupIdMap.put('PMS', groupRecord.Id);
            }
        }
        
        // Evaluate group membership additions and removals
        for (User userRecord : newUsersMap.values()) {
            if(isUserEligibleForProcessing(userRecord)){
                // Get new LOB values (after ';' split)
                Set<String> newLOBSet = new Set<String>(userRecord.LOB__c != null ? userRecord.LOB__c.split(';') : new String[]{});
                
                // If in "after insert" context, add all LOBs except the first
                if(Trigger.isAfter && Trigger.isInsert && newLOBSet.size() > 1) {
                    // Add user to groups for all eligible LOBs except the first one
                    List<String> newLOBList = new List<String>(newLOBSet);
                    for (Integer i = 1; i < newLOBList.size(); i++) {
                        String lob = newLOBList[i];
                        if (lob != null && lobToGroupIdMap.containsKey(lob)) {
                            groupMembersToAdd.add(new GroupMember(GroupId = lobToGroupIdMap.get(lob), UserOrGroupId = userRecord.Id));
                        }
                    }
                }
                
                else if(Trigger.isAfter && Trigger.isUpdate && userRecord.LOB__c != oldUsersMap.get(userRecord.Id).LOB__c){
                    User oldUserRecord = oldUsersMap.get(userRecord.Id);
                    Set<String> oldLOBSet = new Set<String>(oldUserRecord.LOB__c != null ? oldUserRecord.LOB__c.split(';') : new String[]{});
                    
                    // Determine LOBs to add and remove
                    
                    Set<String> lobsToAdd = newLOBSet.clone();
                    lobsToAdd.removeAll(oldLOBSet); // Find LOBs to add
                    
                    // Add users to new LOB groups
                    for (String lob :lobsToAdd) {
                        if (lobToGroupIdMap.containsKey(lob)) {
                            groupMembersToAdd.add(new GroupMember(GroupId = lobToGroupIdMap.get(lob), UserOrGroupId = userRecord.Id));
                        }
                    }
                    
                    Set<String> lobsToRemove = oldLOBSet.clone();
                    lobsToRemove.removeAll(newLOBSet); // Find LOBs to remove
                    
                    // Create a Map of User Id to Set to LOB group which needs to be removed
                    for(String lob :lobsToRemove){
                        if(userIdToGrpToRemoveMap.containsKey(userRecord.Id)) {
                            userIdToGrpToRemoveMap.get(userRecord.Id).add(lobToGroupIdMap.get(lob));
                        } else {
                            userIdToGrpToRemoveMap.put(userRecord.Id, new Set<Id> {lobToGroupIdMap.get(lob)});
                        }
                    }
                }
            }
        }
        
        if(userIdToGrpToRemoveMap.size() > 0) {
            List<GroupMember> groupMemberList  = [
                SELECT Id,GroupId, UserOrGroupId, Group.Name
                FROM GroupMember 
                WHERE UserOrGroupId 
                IN :userIdToGrpToRemoveMap.keySet() 
                AND GroupId 
                IN :allLobGrpIdSet];
            
            for(GroupMember gm :groupMemberList) {
                if(userIdToGrpToRemoveMap.containsKey(gm.UserOrGroupId) && userIdToGrpToRemoveMap.get(gm.UserOrGroupId).contains(gm.GroupId)) {
                    groupMembersToRemove.add(gm);
                }
            }
        }
        
        // Perform bulk DML for group member additions and removals
        if (!groupMembersToAdd.isEmpty()) {
            insert groupMembersToAdd;
        }
        
        if (!groupMembersToRemove.isEmpty()) {
            delete groupMembersToRemove;
        }
    }
    
    public static void evaluateSLATargetUpdates(Map<Id, User> newUsersMap, Map<Id, User> oldUsersMap) {
        ASF_TriggerSkipperUtility.markTriggerRun('Case'); // Disable the  case trigger
        
        Set<Id> updatedManagersSet = new Set<Id>();
        Set<Id> updatedEmailUserSet = new Set<Id>();
        Set<String> emailsToCheckSet = new Set<String>();
        
        for (User user : newUsersMap.values()) {
            User oldUser = oldUsersMap.get(user.Id);
            
            if(isUserEligibleForProcessing(user)){
                // Scenario 1 & 2: Manager update handling
                if (user.ManagerId != oldUser.ManagerId) {
                    updatedManagersSet.add(user.Id);
                    emailsToCheckSet.add(user.email);
                }
            }
        }
        
        // Proceed to update cases if there are updated users
        if (!updatedManagersSet.isEmpty() || !emailsToCheckSet.isEmpty()) {
            updateSLATargetsOnManagerChange(updatedManagersSet, emailsToCheckSet, oldUsersMap);
        }
    }

    public static void updateSLATargetsOnUserEmailChange(List<UserChangeEvent> userChangeEvtList) {
        ASF_TriggerSkipperUtility.markTriggerRun('Case'); // Disable the  case trigger

        Set<String> userIdsSet = new Set<String>();
        List<Case> casesToUpdateList = new List<Case>();
        List<User> usersToUpdateList = new List<User>();
        
        for (UserChangeEvent event : userChangeEvtList) {
            EventBus.ChangeEventHeader header = event.ChangeEventHeader;
            if (header.changedFields.contains('Email') && header.changeType == 'Update') {
                userIdsSet.addAll(header.recordIds);
            }
        }

        if(userIdsSet.size() > 0) {
            Map<String, User> oldEmailToUserMap = new Map<String, User>();

            Map<Id, User> userMap = new Map<Id, User>([
                SELECT Id, Email, Old_Email__c, Business_Unit__c
                FROM User
                WHERE Id
                IN :userIdsSet]);
            
            for(User userRecord :userMap.values()) {
                if(userRecord.email != userRecord.Old_Email__c && isUserEligibleForProcessing(userRecord)) {
                    oldEmailToUserMap.put(userRecord.Old_Email__c, userRecord);

                    userRecord.Old_Email__c = userRecord.email;
                    usersToUpdateList.add(userRecord);
                }
            }

            // Scenario 3: Email update handling
            if(oldEmailToUserMap.size() > 0) {
                List<Case> casesToEvaluateList = [
                    SELECT Id, OwnerId, SLA_Target_1__c, SLA_Target_2__c, SLA_Target_3__c
                    FROM Case
                    WHERE IsClosed = FALSE
                    AND (
                        SLA_Target_1__c IN :oldEmailToUserMap.keySet() OR
                        SLA_Target_2__c IN :oldEmailToUserMap.keySet() OR
                        SLA_Target_3__c IN :oldEmailToUserMap.keySet()
                    )
                ];

                for(Case caseRecord :casesToEvaluateList) {
                    Boolean isUpdated = false;

                    // Scenario 3: When user's email changes and old email is populated on SLA_Target_1 or SLA_Target_2 or SLA_Target_3 field (Update respective SLA_Target field)
                    if(oldEmailToUserMap.containsKey(caseRecord.SLA_Target_1__c)) {
                        caseRecord.SLA_Target_1__c = oldEmailToUserMap.get(caseRecord.SLA_Target_1__c).email;
                        isUpdated = true;
                    }
                    if(oldEmailToUserMap.containsKey(caseRecord.SLA_Target_2__c)) {
                        caseRecord.SLA_Target_2__c = oldEmailToUserMap.get(caseRecord.SLA_Target_2__c).email;
                        isUpdated = true;
                    }
                    if(oldEmailToUserMap.containsKey(caseRecord.SLA_Target_3__c)) {
                        caseRecord.SLA_Target_3__c = oldEmailToUserMap.get(caseRecord.SLA_Target_3__c).email;
                        isUpdated = true;
                    }

                    // Add to cases to update if any changes were made
                    if (isUpdated) {
                        casesToUpdateList.add(caseRecord);
                    }
                }

                // Perform bulk update on updated cases
                if (!casesToUpdateList.isEmpty()) {
                    update casesToUpdateList;
                }

                // Perform bulk update on updated users
                if (!usersToUpdateList.isEmpty()) {
                    ASF_TriggerSkipperUtility.markTriggerRun('Case'); // Disable the  case trigger
                    update usersToUpdateList;
                }
            }
        }
    }
    
    private static void updateSLATargetsOnManagerChange(Set<Id> updatedManagersSet, Set<String> emailsToCheckSet, Map<Id, User> oldUsersMap) {
        ASF_TriggerSkipperUtility.markTriggerRun('Case'); // Disable the  case trigger

        List<Case> casesToUpdateList = new List<Case>();
        
        List<Case> casesToEvaluateList = [
            SELECT Id, OwnerId, SLA_Target_1__c, SLA_Target_2__c, SLA_Target_3__c
            FROM Case
            WHERE IsClosed = FALSE
            AND (
                OwnerId IN :updatedManagersSet OR
                SLA_Target_1__c IN :emailsToCheckSet OR
                SLA_Target_2__c IN :emailsToCheckSet OR
                SLA_Target_3__c IN :emailsToCheckSet
            )
        ];
        
        // Query User details for all involved users in cases (owners and SLA targets)
        Map<Id, User> updatedUsersMap = new Map<Id, User>([SELECT Id, Email, Manager.Email, Manager.Manager.Email, Manager.Manager.Manager.Email FROM User WHERE Id IN :updatedManagersSet]);
        Map<String, User> userEmailToUserRecordMap = new Map<String, User>();
        
        for(User userRecord :updatedUsersMap.values()) {
            userEmailToUserRecordMap.put(userRecord.email, userRecord);
        }
        
        // Process each case
        for (Case caseRecord : casesToEvaluateList) {
            Boolean isUpdated = false;
            
            // Scenario 1: When manager changes for an user who is the owner of the case (Update SLA_Target_1, SLA_Target_2 & SLA_Target_3 fields)
            if(updatedManagersSet.contains(caseRecord.OwnerId)) {
                User userRecord = updatedUsersMap.get(caseRecord.OwnerId);
                if (userRecord.Manager != null) {
                    caseRecord.SLA_Target_1__c = String.isNotBlank(userRecord?.Manager?.Email) ? userRecord.Manager.Email : null;
                    caseRecord.SLA_Target_2__c = String.isNotBlank(userRecord?.Manager?.Manager?.Email) ? userRecord.Manager.Manager.Email : null;
                    caseRecord.SLA_Target_3__c = String.isNotBlank(userRecord?.Manager?.Manager?.Manager?.Email) ? userRecord.Manager.Manager.Manager.Email : null;
                } else {
                    // Case owner's manager is removed, so clear all SLA fields
                    caseRecord.SLA_Target_1__c = null;
                    caseRecord.SLA_Target_2__c = null;
                    caseRecord.SLA_Target_3__c = null;
                }
                isUpdated = true;
            }
            // Scenario 2 (i): When manager changes for an user where the user’s email present in SLA_Target_1 (Update SLA_Target_2 & SLA_Target_3 fields)
            else if(emailsToCheckSet.contains(caseRecord.SLA_Target_1__c)) {
                User userRecord = userEmailToUserRecordMap.get(caseRecord.SLA_Target_1__c);
                caseRecord.SLA_Target_2__c = String.isNotBlank(userRecord?.Manager?.Email) ? userRecord.Manager.Email : null;
                caseRecord.SLA_Target_3__c = String.isNotBlank(userRecord?.Manager?.Manager?.Email) ? userRecord.Manager.Manager.Email : null;
                isUpdated = true;
            }
            // Scenario 2 (ii): When manager changes for an user where the user’s email present in SLA_Target_2 (Update SLA_Target_3 field)
            else if(emailsToCheckSet.contains(caseRecord.SLA_Target_2__c)) {
                User userRecord = userEmailToUserRecordMap.get(caseRecord.SLA_Target_2__c);
                caseRecord.SLA_Target_3__c = String.isNotBlank(userRecord?.Manager?.Email) ? userRecord.Manager.Email : null;
                isUpdated = true;
            }
            
            // Add to cases to update if any changes were made
            if (isUpdated) {
                casesToUpdateList.add(caseRecord);
            }
        }
        
        // Perform bulk update on modified cases
        if (!casesToUpdateList.isEmpty()) {
            update casesToUpdateList;
        }
    }
    
    private static boolean isUserEligibleForProcessing(User userRecord) {
        if(userRecord.Business_Unit__c == System.label.ASF_BUs_Eligible_For_IDAM_Processing) {
            return true;
        } else {
            return false;
        }
    }
}