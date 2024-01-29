public without sharing class ASF_AssocCustomerForAPICases {
    public static final List<String> LINE_OF_BUSINESS = new List<String>{'Payments','ABHFL','ABFL'};

    public static void searchAndAssocCustomerForAPICases(List<Case> newList){
        Set<String> accountsClientCode = new Set<String>();
        Map<String,Id> accClientCodeVsAccIds = new Map<String,Id>();
        Set<String> caseLANNo = new Set<String>();
        Map<String,Asset> lanNoVsAsset = new Map<String,Asset>();
        
        for(Case individualCase : newList){
            if(individualCase.Technical_Source__c == 'API' || individualCase.Technical_Source__c == 'Email'){
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
            for(Asset ast : [SELECT ID,LAN__c,AccountId  FROM Asset WHERE LAN__c =: caseLANNo AND Business_Unit__c =: LINE_OF_BUSINESS]){
                if(!lanNoVsAsset.containsKey(ast.LAN__c)){
                    lanNoVsAsset.put(ast.LAN__c,ast);
                }
            } 
        }   
        for(Case individualCase : newList){
            if(individualCase.Technical_Source__c == 'API' || individualCase.Technical_Source__c == 'Email'){
                if(individualCase.Client_Code_Text__c != null){
                    if(accClientCodeVsAccIds.containsKey(individualCase.Client_Code_Text__c)){
                        individualCase.AccountId = accClientCodeVsAccIds.get(individualCase.Client_Code_Text__c);
                    }
                }
                if(individualCase.LAN__c != null){
                    if(lanNoVsAsset.containsKey(individualCase.LAN__c)){
                        individualCase.AssetId = lanNoVsAsset.get(individualCase.LAN__c).Id;
                        // in case account id is blank
                        individualCase.AccountId = individualCase.AccountId==null?lanNoVsAsset.get(individualCase.LAN__c).AccountId:individualCase.AccountId;
                    }
                }
            }
        }
        
    }
    
}