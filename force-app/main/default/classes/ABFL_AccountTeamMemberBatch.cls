/*********************************************************
*Class        :  ABFL_AccountTeamMemberBatch
*Author       :  Shubham Sinha 
*Created Date :  16/01/2024
*Description  :  This batch class is used to insert AccountTeamMember if RM Code of LAN matches with user for ABFL Sales Role and delete the ATM if doesnt match.
*********************************************************/
public class ABFL_AccountTeamMemberBatch implements Database.Batchable<SObject>  {
    public final String query;
    public ABFL_AccountTeamMemberBatch() {
    this.query = 'SELECT Id, Name, AccountId, RM_Code__c, LOB__c ' +'FROM Asset '+'WHERE RM_Assignment__c = \'Pending\' AND Business_Unit__c = \'ABFL\'';}
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC, List<Asset> scope) {
        Map<String, Id> codeToFederationMap = new Map<String, Id>();
        Set<String> accountId = new Set<String>();
        List<AccountTeamMember> accountTeamMembersToInsert = new List<AccountTeamMember>();
        List<AccountTeamMember> accountTeamMembersToDelete = new List<AccountTeamMember>();
        List<Asset> updateRmAssignment = new List<Asset>();
        Map<Id,Set<String>> mapRmCodes = new  Map<Id,Set<String>>();
        for (Asset asset : scope) {
            if(asset.RM_Code__c != null && asset.AccountId != null){
                accountId.add(asset.accountId);
                asset.RM_Assignment__c = 'Processed';
                updateRmAssignment.add(asset);
            }
        }
            for (Asset assetAll : [SELECT ID, AccountId ,RM_Code__c  FROM Asset WHERE AccountId IN:accountId]) {
                codeToFederationMap.put(assetAll.RM_Code__c, null);  
                if (!mapRmCodes.containsKey(assetAll.AccountId)) {
                    mapRmCodes.put(assetAll.AccountId, new Set<String>());
                }
                mapRmCodes.get(assetAll.AccountId).add(assetAll.RM_Code__c);
                system.debug('rmCodes---> '+mapRmCodes);
            }
            // Query for users with matching LAN's RM Code
            for (User user : [SELECT Id, FederationIdentifier FROM User WHERE FederationIdentifier IN :codeToFederationMap.keySet() AND  UserRole.DeveloperName = 'ABFL_Sales']) {
                codeToFederationMap.put(user.FederationIdentifier, user.Id);
            }
            if(!codeToFederationMap.isEmpty()){
                // Iterate through fetched assets and create Account Team Members
                for (Asset asset : scope) {
                    Id userId = codeToFederationMap.get(asset.RM_Code__c);
                    if (userId != null) {
                    AccountTeamMember atm = new AccountTeamMember();
                    atm.AccountId = asset.AccountId;
                    atm.UserId = userId;
                    atm.TeamMemberRole = 'ABFL RM';
                    atm.AccountAccessLevel  = 'Read';
                    atm.CaseAccessLevel = 'Read';
                    accountTeamMembersToInsert.add(atm);
                    }
                }
            }
             if (!accountTeamMembersToInsert.isEmpty()) {
                insert accountTeamMembersToInsert;
            }
            if (!updateRmAssignment.isEmpty()) {
                update updateRmAssignment;
            }
        // Identifying Account Team Members to delete 
        for (AccountTeamMember existingAccountTeamMembers :[SELECT Id, UserId,User.FederationIdentifier, AccountId FROM AccountTeamMember WHERE AccountId IN :accountId]){
            if (mapRmCodes.containsKey(existingAccountTeamMembers.AccountId)) {
                if (!mapRmCodes.get(existingAccountTeamMembers.AccountId).contains(existingAccountTeamMembers.User.FederationIdentifier)) {
                    accountTeamMembersToDelete.add(existingAccountTeamMembers); 
                    system.debug('accountTeamMembersToDelete--> '+accountTeamMembersToDelete); 
                }
            }    
        }
        if (!accountTeamMembersToDelete.isEmpty()) {    
            delete accountTeamMembersToDelete;
        }
    }
    public void finish(Database.BatchableContext BC) {
    }
}