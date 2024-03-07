public without sharing class ABCL_SurveyResponseHelper {
    public static final List<String> LINE_OF_BUSINESS = new List<String>{'ABFL'};
    public static void associateCustomerAndAsset(List<Survey_Response__c> newItems){
        Set<String> accountsClientCode = new Set<String>();
        Map<Integer,Id> accClientCodeVsAccIds = new Map<Integer,Id>();
        Set<String> surveyLANNo = new Set<String>();
        Map<Integer,Asset> lanNoVsAsset = new Map<Integer,Asset>();
        Map<Integer,String> iHashClientCodeVsLob = new Map<Integer,String>();
        Map<Integer,String> iHashLANVsLob = new Map<Integer,String>();
        
        for(Survey_Response__c surveyResponse : (List<Survey_Response__c>)newItems){
            if(surveyResponse.Client_Code_Text__c  != null){
                accountsClientCode.add(surveyResponse.Client_Code_Text__c);
                String tempKey = surveyResponse.Business_Unit__c+'_'+surveyResponse.Client_Code_Text__c;
                integer itempKey = tempKey.hashCode();
                if(!iHashClientCodeVsLob.containsKey(itempKey)){
                    iHashClientCodeVsLob.put(itempKey,surveyResponse.Business_Unit__c);
                }
            }
            if(surveyResponse.LAN_Text__c  != null){
                String tempKey = surveyResponse.Business_Unit__c+'_'+surveyResponse.LAN_Text__c;
                integer itempKey = tempKey.hashCode();
                if(!iHashLANVsLob.containsKey(itempKey)){
                    iHashLANVsLob.put(itempKey,surveyResponse.Business_Unit__c);
                }
                surveyLANNo.add(surveyResponse.LAN_Text__c); 
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
        if(surveyLANNo.size()>0){
            System.debug('Check here ---> '+surveyLANNo);
            for(Asset ast : [SELECT ID,LAN__c,AccountId,Business_Unit__c  FROM Asset WHERE LAN__c =: surveyLANNo AND Business_Unit__c =: LINE_OF_BUSINESS]){
                System.debug('Inside for loop ');
                String tempKey = ast.Business_Unit__c +'_'+ast.LAN__c;
                integer itempKey = tempKey.hashCode();
                System.debug('lanNoVsAsset --> '+lanNoVsAsset.containsKey(itempKey));
                if(!lanNoVsAsset.containsKey(itempKey)){
                    lanNoVsAsset.put(itempKey,ast);
                }
            } 
        }
        
        
        
        for(Survey_Response__c surveyResponse : (List<Survey_Response__c>)newItems){
            if(surveyResponse.Client_Code_Text__c != null){
                String tempKey = surveyResponse.Business_Unit__c+'_'+surveyResponse.Client_Code_Text__c;
                integer itempKey = tempKey.hashCode();
                
                if(accClientCodeVsAccIds.containsKey(itempKey)){
                    surveyResponse.Client_Code__c = accClientCodeVsAccIds.get(itempKey);
                }
            }
            if(surveyResponse.LAN_Text__c != null){
                String tempKey = surveyResponse.Business_Unit__c+'_'+surveyResponse.LAN_Text__c;
                System.debug('tempKey --> '+tempKey);
                integer itempKey = tempKey.hashCode();    
                System.debug('lanNoVsAsset --> '+lanNoVsAsset);
                if(lanNoVsAsset.containsKey(itempKey)){
                    
                    if(lanNoVsAsset.containsKey(itempKey)){
                        surveyResponse.LAN__c = lanNoVsAsset.get(itempKey).Id;
                        // in case account id is blank
                        surveyResponse.Client_Code__c = surveyResponse.Client_Code__c==null?lanNoVsAsset.get(itempKey).AccountId:surveyResponse.Client_Code__c;
                    }
                }
            }
        }
    }
    
    public static void updateCustomersNPS(List<Survey_Response__c> newItems){
        Set<String> accountsClientCode = new Set<String>();
        Map<Integer,Id> accClientCodeVsAccIds = new Map<Integer,Id>();
        Set<String> surveyLANNo = new Set<String>();
        Map<Integer,Asset> lanNoVsAsset = new Map<Integer,Asset>();
        Map<Integer,Survey_Response__c> iHashClientCodeVsLob = new Map<Integer,Survey_Response__c>();
        Map<Integer,String> iHashLANVsLob = new Map<Integer,String>();
        
        for(Survey_Response__c surveyResponse : (List<Survey_Response__c>)newItems){
            if(surveyResponse.Client_Code_Text__c  != null){
                accountsClientCode.add(surveyResponse.Client_Code_Text__c);
                String tempKey = surveyResponse.Business_Unit__c+'_'+surveyResponse.Client_Code_Text__c;
                integer itempKey = tempKey.hashCode();
                if(!iHashClientCodeVsLob.containsKey(itempKey)){
                    iHashClientCodeVsLob.put(itempKey,surveyResponse);
                }
            }
        }
        List<Account> accounts = new List<Account>();
        if(accountsClientCode.size()>0){
            for(Account acc : [SELECT ID,Client_Code__c,Business_Unit__c FROM Account WHERE Client_Code__c =: accountsClientCode AND Business_Unit__c =: LINE_OF_BUSINESS]){
                String tempKey = acc.Business_Unit__c +'_'+acc.Client_Code__c;
                integer itempKey = tempKey.hashCode();
                if(!accClientCodeVsAccIds.containsKey(itempKey)){
                    if(iHashClientCodeVsLob.containsKey(itempKey)){
                        accClientCodeVsAccIds.put(itempKey,acc.Id);
                        Survey_Response__c surResp1 = iHashClientCodeVsLob.get(itempKey);
                        Account a = new Account(Id=acc.Id);
                        a.NPS_Score__c = surResp1.Primary_Question_NPS__c;
                        accounts.add(a);
                    }
                }
            } 
        }
        if(accounts.size()>0){
            update accounts;
        }
    }
    
}