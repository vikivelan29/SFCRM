/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 10-09-2024
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts,PMD.StdCyclomaticComplexity')
public without sharing class ASF_AssocCustomerForAPICases {
    public static final List<String> LINE_OF_BUSINESS = new List<String>{'Payments','ABHFL','ABFL','ABWM','ABSLI'};
        
        /**
* @description : Associate AccountId and AssetId based on text fields.
* @author rsinghnagar@salesforce.com | 05-13-2024 
* @param newList 
**/
        public static void searchAndAssocCustomerForAPICases(List<Case> newList){
            Set<String> accountsClientCode = new Set<String>();
            Map<Integer,Id> accClientCodeVsAccIds = new Map<Integer,Id>();
            Set<String> caseLANNo = new Set<String>();
            Map<Integer,Asset> lanNoVsAsset = new Map<Integer,Asset>();
            Map<Integer,String> iHashClientCodeVsLob = new Map<Integer,String>();
            Map<Integer,String> iHashLANVsLob = new Map<Integer,String>();
            
            for(Case individualCase : newList){
                if(individualCase.Technical_Source__c == 'API' || individualCase.Technical_Source__c == 'Email'){
                    if(individualCase.Client_Code_Text__c != null){
                        accountsClientCode.add(individualCase.Client_Code_Text__c);
                        String tempKey = individualCase.Business_Unit__c+'_'+individualCase.Client_Code_Text__c;
                        integer itempKey = tempKey.hashCode();
                        if(!iHashClientCodeVsLob.containsKey(itempKey)){
                            iHashClientCodeVsLob.put(itempKey,individualCase.Business_Unit__c);
                        }
                    }
                    if(individualCase.LAN__c  != null){
                        String tempKey = individualCase.Business_Unit__c+'_'+individualCase.LAN__c;
                        integer itempKey = tempKey.hashCode();
                        if(!iHashLANVsLob.containsKey(itempKey)){
                            iHashLANVsLob.put(itempKey,individualCase.Business_Unit__c);
                        }
                        String assetExternalId = getExternalKeyForLANPerBU(individualCase.Business_Unit__c, individualCase.LAN__c);
                        System.debug(assetExternalId);
                        caseLANNo.add(assetExternalId);
                    }
                    
                }
            }
            if(accountsClientCode.size()>0){
                for(Account acc : [SELECT ID,Client_Code__c,Business_Unit__c FROM Account WHERE Client_Code__c =: accountsClientCode AND Business_Unit__c =: LINE_OF_BUSINESS]){
                    String tempKey = acc.Business_Unit__c +'_'+acc.Client_Code__c;
                    integer itempKey = tempKey.hashCode();
                    if(!accClientCodeVsAccIds.containsKey(itempKey)){
                        if(iHashClientCodeVsLob.containsKey(itempKey)){
                            accClientCodeVsAccIds.put(itempKey,acc.Id);
                        }
                    }
                } 
            }
            if(caseLANNo.size()>0){
                for(Asset ast : [SELECT ID,LAN__c,AccountId,Business_Unit__c  FROM Asset WHERE (LAN__c =: caseLANNo OR Policy_No__c =:caseLANNo) AND Business_Unit__c =: LINE_OF_BUSINESS]){
                    
                    String assetExternalId = ast.LAN__c;

                    String tempKey = ast.Business_Unit__c +'_'+assetExternalId;
                    integer itempKey = tempKey.hashCode();
                    
                    if(!lanNoVsAsset.containsKey(itempKey)){
                        lanNoVsAsset.put(itempKey,ast);
                    }
                } 
            }   
            for(Case individualCase : newList){
                if(individualCase.Technical_Source__c == 'API' || individualCase.Technical_Source__c == 'Email'){
                    if(individualCase.Client_Code_Text__c != null){
                        String tempKey = individualCase.Business_Unit__c+'_'+individualCase.Client_Code_Text__c;
                        integer itempKey = tempKey.hashCode();
                        
                        if(accClientCodeVsAccIds.containsKey(itempKey)){
                            individualCase.AccountId = accClientCodeVsAccIds.get(itempKey);
                        }
                    }
                    if(individualCase.LAN__c != null){
                        String assetExternalId = getExternalKeyForLANPerBU(individualCase.Business_Unit__c, individualCase.LAN__c);
                        //String tempKey = individualCase.Business_Unit__c+'_'+individualCase.LAN__c;
                        
                        // VIRENDRA - ADDED FOR OTHER LOBs THAN ABHFL AND ABFL.
                        String tempKey = individualCase.Business_Unit__c+'_'+assetExternalId;
                        
                        integer itempKey = tempKey.hashCode();
                        if(lanNoVsAsset.containsKey(itempKey)){
                            if(lanNoVsAsset.containsKey(itempKey)){
                                individualCase.AssetId = lanNoVsAsset.get(itempKey).Id;
                                // in case account id is blank
                                individualCase.AccountId = individualCase.AccountId==null?lanNoVsAsset.get(itempKey).AccountId:individualCase.AccountId;
                            }
                        }
                    }
                }
            }
            
        }
    private static String getExternalKeyForLANPerBU(String BusinessUnit, String LANVal){
        String assetExternalId = '';
        if(ASF_Constants.BUSpecificLANKey.contains(BusinessUnit)){
            assetExternalId = BusinessUnit+'_'+LANVal;
        }
        else{
            assetExternalId = LANVal;
        }
        return assetExternalId;
    }
    
}