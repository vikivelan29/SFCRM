public without sharing class ASF_AssocCustomerForAPICases {
    public static final List<String> LINE_OF_BUSINESS = new List<String>{'Payments','ABHFL'};
        
        
    public static void searchAndAssocCustomerForAPICases(List<Case> newList){
        Set<String> accountsClientCode = new Set<String>();
        Map<String,Id> accClientCodeVsAccIds = new Map<String,Id>();
        Set<String> caseLANNo = new Set<String>();
        Map<String,Id> lanNoVsAssetIds = new Map<String,Id>();
        
        for(Case individualCase : newList){
            if(individualCase.Technical_Source__c == 'API'){
                if(individualCase.Client_Code_Text__c != null){
                    accountsClientCode.add(individualCase.Client_Code_Text__c); 
                }
                if(individualCase.LAN__c  != null){
                    caseLANNo.add(individualCase.LAN__c); 
                }
            }
        }
        if(accountsClientCode.size()>0){
            for(Account acc : [SELECT ID,Client_Code__c FROM Account WHERE Client_Code__c =: accountsClientCode AND Business_Unit__c =: LINE_OF_BUSINESS]){
                if(!accClientCodeVsAccIds.containsKey(acc.Client_Code__c)){
                    accClientCodeVsAccIds.put(acc.Client_Code__c,acc.Id);
                }
            } 
        }
        if(caseLANNo.size()>0){
            for(Asset ast : [SELECT ID,LAN__c  FROM Asset WHERE LAN__c =: caseLANNo AND Business_Unit__c =: LINE_OF_BUSINESS]){
                if(!lanNoVsAssetIds.containsKey(ast.LAN__c)){
                    lanNoVsAssetIds.put(ast.LAN__c,ast.Id);
                }
            } 
        }        
        for(Case individualCase : newList){
            if(individualCase.Technical_Source__c == 'API'){
                if(individualCase.Client_Code_Text__c != null){
                    if(accClientCodeVsAccIds.containsKey(individualCase.Client_Code_Text__c)){
                        individualCase.AccountId = accClientCodeVsAccIds.get(individualCase.Client_Code_Text__c);
                    }
                }
                if(individualCase.LAN__c != null){
                    if(lanNoVsAssetIds.containsKey(individualCase.LAN__c)){
                        individualCase.AssetId = lanNoVsAssetIds.get(individualCase.LAN__c);
                    }
                }
            }
        }
        
    }
    
}