public without sharing class ASF_AssocCustomerForAPICases {
    public static final List<String> lineOfBusinesses = new List<String>{'Payments'};
        
        
    public static void searchAndAssocCustomerForAPICases(List<Case> newList){
        Set<String> accountsClientCode = new Set<String>();
        Map<String,Id> accClientCodeVsAccIds = new Map<String,Id>();
        
        for(Case individualCase : newList){
            if(individualCase.Technical_Source__c == 'API'){
                if(individualCase.Client_Code_Text__c != null){
                    accountsClientCode.add(individualCase.Client_Code_Text__c); 
                }
            }
        }
        if(accountsClientCode.size()>0){
            for(Account acc : [SELECT ID,Client_Code__c FROM Account WHERE Client_Code__c =: accountsClientCode AND Business_Unit__c =: lineOfBusinesses]){
                if(!accClientCodeVsAccIds.containsKey(acc.Client_Code__c))
                    accClientCodeVsAccIds.put(acc.Client_Code__c,acc.Id);
            } 
        }
        for(Case individualCase : newList){
            if(individualCase.Technical_Source__c == 'API'){
                if(individualCase.Client_Code_Text__c != null){
                    if(accClientCodeVsAccIds.containsKey(individualCase.Client_Code_Text__c)){
                        individualCase.AccountId = accClientCodeVsAccIds.get(individualCase.Client_Code_Text__c);
                    }
                }
            }
        }
        
    }
    
}