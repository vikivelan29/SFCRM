global class ABHI_UpdateCaseAccountAssetBatch  implements Database.Batchable<sObject> ,Database.Stateful,Schedulable{

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, LAN__c, Client_Code_Text__c
            FROM Case
            WHERE (LAN__c != NULL OR Client_Code_Text__c != NULL ) AND Business_Unit__c = 'ABHI' AND (AccountId = NULL OR AssetId  = NULL) AND Isclosed = FALSE
        ]);
    }

    global void execute(Database.BatchableContext BC, List<Case> caseList) {
        Set<String> clientCodes = new Set<String>();
        Set<String> lanCodes = new Set<String>();

        for (Case c : caseList) {
            clientCodes.add(c.Client_Code_Text__c);
            lanCodes.add(c.LAN__c);
        }

       Map<String, Account> accountMap = new Map<String, Account>();
            for (Account acc : [SELECT Id, Client_Code__c FROM Account WHERE Business_Unit__c = 'ABHI' AND Client_Code__c IN :clientCodes]) {
            accountMap.put(acc.Client_Code__c, acc);
        }
        Map<String, Asset> assetMap = new Map<String, Asset>();
            for (Asset asset : [SELECT Id, LAN__c FROM Asset WHERE Business_Unit__c = 'ABHI' AND LAN__c IN :lanCodes]) {
            assetMap.put(asset.LAN__c, asset);
        }
              
        List<Case> casesToUpdate = new List<Case>();

        for (Case c : caseList) {
            system.debug('Client_Code_Text__c----> '+c.Client_Code_Text__c +c.LAN__c);
                system.debug('accountMap----> '+accountMap);
                system.debug('assetMap----> '+assetMap);
            if ( !assetMap.isEmpty() && assetMap.containsKey(c.LAN__c)) {
                system.debug('assetToUpdate----> '+assetMap);
               // Asset assetToUpdate = assetMap.get(c.LAN__c);
                c.AssetId = assetMap.get(c.LAN__c).Id;
                casesToUpdate.add(c);
            }
            else if(!accountMap.isEmpty() &&accountMap.containsKey(c.Client_Code_Text__c)){  
                Account accountToUpdate = accountMap.get(c.Client_Code_Text__c);
                system.debug('accountToUpdate----> '+accountToUpdate);
                c.AccountId = accountToUpdate.Id;
                casesToUpdate.add(c);
            }
        }

        if (!casesToUpdate.isEmpty()) {
            system.debug('casesToUpdate----> '+casesToUpdate);
            update casesToUpdate;
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Batch process completed.');
    }
     public void execute(SchedulableContext SC) {
        Database.executeBatch(this, 200);  
    }
}