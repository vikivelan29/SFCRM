/*********************************************************
*Class        :  ABSLAMC_OmniChannelServResBatchCtrl
*Author       :  Neeraj Kumar
*Created Date :  10/10/2024
*@description  :  This batch class is for handling creation/updation of service resources for Omnichannel feature
*********************************************************/
public class ABSLAMC_OmniChannelServResBatchCtrl implements Database.Batchable<SObject> { 
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, FirstName, LastName, Omnichannel_Status__c FROM User ' + 
            'WHERE IsActive = true AND Business_Unit__c = \'ABSLAMC\' AND Omnichannel_Status__c IN (\'Add\', \'Remove\', \'Reprocess\')';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<User> scope) {
        List<ServiceResource> serviceResourcesToInsert = new List<ServiceResource>();
        List<ServiceResource> serviceResourcesToUpdate = new List<ServiceResource>();
        Set<Id> userIds = new Set<Id>();
        Map<Id, User> usersToUpdateStatus = new Map<Id, User>();
        PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = 'ABSLAMC_Omnichannel' LIMIT 1];
        
        for (User usr : scope) {
            userIds.add(usr.Id);
        }
        
        Map<Id, ServiceResource> servResMap = new Map<Id, ServiceResource>([
            SELECT Id, Name, RelatedRecordId, IsActive 
            FROM ServiceResource 
            WHERE RelatedRecordId IN :userIds
        ]);
        
        Map<Id, ServiceResource> existingResources = new Map<Id, ServiceResource>();
        
        for (ServiceResource sr : servResMap.values()) {
            existingResources.put(sr.RelatedRecordId, sr);
        }
        
        for (User user : scope) {
            if (user.Omnichannel_Status__c == 'Add') {
                if (existingResources.containsKey(user.Id)) {
                    ServiceResource existingResource = existingResources.get(user.Id);
                    if (!existingResource.IsActive) {
                        existingResource.IsActive = true;
                    }
                    existingResource.Name = user.FirstName + ' ' + user.LastName;
                    serviceResourcesToUpdate.add(existingResource);
                } else {
                    ServiceResource newResource = new ServiceResource(
                        Name = user.FirstName + ' ' + user.LastName,
                        ResourceType = 'A',
                        RelatedRecordId = user.Id,
                        IsActive = true
                    );
                    serviceResourcesToInsert.add(newResource);
                }
            } else if (user.Omnichannel_Status__c == 'Remove') {
                System.debug('Existing Resource:'+existingResources.get(user.Id));
                if (existingResources.containsKey(user.Id)) {
                    ServiceResource resourceToUpdate = existingResources.get(user.Id);
                    resourceToUpdate.IsActive = false;
                    serviceResourcesToUpdate.add(resourceToUpdate);
                }
            } else if (user.Omnichannel_Status__c == 'Reprocess') {
                if (existingResources.containsKey(user.Id)) {
                    ServiceResource resourceToUpdate = existingResources.get(user.Id);
                    resourceToUpdate.Name = user.FirstName + ' ' + user.LastName;
                    serviceResourcesToUpdate.add(resourceToUpdate);
                }
            }
        }
        
        if (!serviceResourcesToInsert.isEmpty()) {
            Database.SaveResult[] insertResults = Database.insert(serviceResourcesToInsert, false);
            handleUpsertResults(insertResults, scope, usersToUpdateStatus, permSet, 'Add');
        }
        
        if (!serviceResourcesToUpdate.isEmpty()) {
            Database.SaveResult[] updateResults = Database.update(serviceResourcesToUpdate, false);
            handleUpsertResults(updateResults, scope, usersToUpdateStatus, permSet, 'Remove');
        }
        
        if (!usersToUpdateStatus.isEmpty()) {
            for (User user : usersToUpdateStatus.values()) {
                user.Omnichannel_Status__c = null;
            }
            update usersToUpdateStatus.values();
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        
    }
    
    private void handleUpsertResults(Database.SaveResult[] results, List<User> scope, Map<Id, User> usersToUpdateStatus, PermissionSet permSet, String actionType) {
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                User successfulUser = scope[i];
                usersToUpdateStatus.put(successfulUser.Id, successfulUser);
                System.debug('Success for ServiceResource: ' + successfulUser.Id);
                
                // Assign or remove permission set based on action type
                if (actionType == 'Add') {
                    assignPermissionSet(successfulUser.Id, permSet);
                } else if (actionType == 'Remove') {
                    removePermissionSet(successfulUser.Id, permSet);
                }
            } else {
                Database.Error[] errors = results[i].getErrors();
                for (Database.Error error : errors) {
                    System.debug('Failed for ServiceResource: ' + scope[i].Id + ', Error: ' + error.getMessage());
                }
            }
        }
    }
    
    private void assignPermissionSet(Id userId, PermissionSet permSet) {
        if (permSet != null) {
            PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = userId,
                PermissionSetId = permSet.Id
            );
            try {
                insert psa;
                System.debug('Permission set assigned to User: ' + userId);
            } catch (DmlException e) {
                System.debug('Failed to assign permission set: ' + e.getMessage());
            }
        }
    }
    
    private void removePermissionSet(Id userId, PermissionSet permSet) {
        if (permSet != null) {
            List<PermissionSetAssignment> psaList = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :userId AND PermissionSetId = :permSet.Id];
            if (!psaList.isEmpty()) {
                try {
                    delete psaList;
                    System.debug('Permission set removed from User: ' + userId);
                } catch (DmlException e) {
                    System.debug('Failed to remove permission set: ' + e.getMessage());
                }
            }
        }
    }
}