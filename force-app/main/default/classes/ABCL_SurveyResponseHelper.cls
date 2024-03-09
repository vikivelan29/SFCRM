public without sharing class ABCL_SurveyResponseHelper {
    public static final List<String> LINE_OF_BUSINESS = new List<String>{'ABFL','ABWM'};
        public static void associateCustomerAndAsset(List<Survey_Response__c> newItems){
            Set<String> accountsClientCode = new Set<String>();
            Map<Integer,Id> accClientCodeVsAccIds = new Map<Integer,Id>();
            Set<String> surveyLANNo = new Set<String>();
            Map<Integer,Asset> lanNoVsAsset = new Map<Integer,Asset>();
            Map<Integer,String> iHashClientCodeVsLob = new Map<Integer,String>();
            Map<Integer,String> iHashLANVsLob = new Map<Integer,String>();
            Map<Id,Case> mCaseDetails = new Map<Id,Case>();
            
            
            /* Scenario 1 - Client Code, Case # and LAN # is provided.
* Scenario 2 - Client Code, Case # provided, LAN # not provided --> Do not map Asset.
* Scenario 3 - Case # provided, Client Code and LAN not provided --> Map Customer from Case and do not map Asset.
* Scenario 4 - Case # and LAN provided, Client Code not provided --> Map Customer from Case #.
* Scenario 5 - Case # provided, but given Case is reparented to non customer --> Map Customer from Client Code.
*/
            
            /// GET MAP OF CASE AND DETAILS.
            for(Survey_Response__c surveyResponse : (List<Survey_Response__c>)newItems){
                if(surveyResponse.Case__c != null){
                    if(!mCaseDetails.containsKey(surveyResponse.Case__c)){
                        mCaseDetails.put(surveyResponse.Case__c,null);
                    }
                } 
            }
            /// QUERY CASE TO GET THE DETAILS RELATED TO CASE.
            if(mCaseDetails.keySet().size()>0){
                getCaseDetails(mCaseDetails);
            }
            
            // JUST IN SCENARIO WHEN CURRENT CASE ACCOUNT IS NOT THE SURVEY CUSTOMER.
            for(Survey_Response__c surveyResponse : (List<Survey_Response__c>)newItems){
                if(surveyResponse.Client_Code_Text__c  != null){
                    createAccountHashMap(accountsClientCode,surveyResponse,iHashClientCodeVsLob);
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
                for(Asset ast : [SELECT ID,LAN__c,AccountId,Business_Unit__c  FROM Asset WHERE LAN__c =: surveyLANNo AND Business_Unit__c =: LINE_OF_BUSINESS]){
                    String tempKey = ast.Business_Unit__c +'_'+ast.LAN__c;
                    integer itempKey = tempKey.hashCode();
                    if(!lanNoVsAsset.containsKey(itempKey)){
                        lanNoVsAsset.put(itempKey,ast);
                    }
                } 
            }
            
            
            
            for(Survey_Response__c surveyResponse : (List<Survey_Response__c>)newItems){
                Id accountId = null;
                accountId = getAccountIdFromCase(surveyResponse,mCaseDetails);
                
                if(surveyResponse.Client_Code_Text__c != null){
                    String tempKey = surveyResponse.Business_Unit__c+'_'+surveyResponse.Client_Code_Text__c;
                    integer itempKey = tempKey.hashCode();
                    
                    /* CHECK IF THE SURVEY RESPONSE CUSTOMER IS EQUALS TO THE CASE CUSTOMER.
* MEANING WHILE SENDING CUSTORE SURVEY Case CUSTOMER WAS DIFFERENT AND NOW CASE CUSTOMER IS DIFFERENT.
*/ 
                    if(accClientCodeVsAccIds.containsKey(itempKey)){
                        if(accountId != accClientCodeVsAccIds.get(itempKey)){
                            // ASSIGN TO CLIENT WHO SEND THE CUSTOMER RESPONSE.
                            accountId = accClientCodeVsAccIds.get(itempKey);
                        }
                    }
                }
                if(accountId != null){
                    surveyResponse.Client_Code__c = accountId;
                }
                if(surveyResponse.LAN_Text__c != null){
                    String tempKey = surveyResponse.Business_Unit__c+'_'+surveyResponse.LAN_Text__c;
                    integer itempKey = tempKey.hashCode();    
                    if(lanNoVsAsset.containsKey(itempKey)){
                        
                        if(lanNoVsAsset.containsKey(itempKey)){
                            surveyResponse.LAN__c = lanNoVsAsset.get(itempKey).Id;
                            // in case account id is blank
                        }
                    }
                }
            }
        }
    
    public static void updateCustomersNPS(List<Survey_Response__c> newItems){
        List<Account> accounts = new List<Account>();
        for(Survey_Response__c surveyResponse : newItems){
            if(surveyResponse.Client_Code__c != null){
                
                if(surveyResponse.Primary_Question_NPS__c != null){
                    Account a = new Account(Id=surveyResponse.Client_Code__c);
                    a.NPS_Score__c = surveyResponse.Primary_Question_NPS__c; 
                    accounts.add(a);
                }
                
            }
        }
        if(accounts.size()>0){
            Database.SaveResult[] results = Database.update(accounts,false);
        }
    }
    
    private static void createAccountHashMap(Set<String> accountsClientCode,Survey_Response__c surveyResponse,Map<Integer,String> iHashClientCodeVsLob){
        accountsClientCode.add(surveyResponse.Client_Code_Text__c);
        String tempKey = surveyResponse.Business_Unit__c+'_'+surveyResponse.Client_Code_Text__c;
        integer itempKey = tempKey.hashCode();
        if(!iHashClientCodeVsLob.containsKey(itempKey)){
            iHashClientCodeVsLob.put(itempKey,surveyResponse.Business_Unit__c);
        }
    }
    
    private static void getCaseDetails(Map<Id,Case> mCaseDetails){
        for(Case surveyCase : [SELECT ID,AccountId,Business_Unit__c FROM Case WHERE Id=:mCaseDetails.keySet()]){
            if(mCaseDetails.containsKey(surveyCase.Id)){
                mCaseDetails.put(surveyCase.Id,surveyCase);
            }
        }
    }
    
    private static Id getAccountIdFromCase(Survey_Response__c surveyResponse,Map<Id,Case> mCaseDetails){
        Id accountId = null;
        if(surveyResponse.Case__c != null){
            if(mCaseDetails.containsKey(surveyResponse.Case__c)){
                if(mCaseDetails.get(surveyResponse.Case__c).AccountId != null){
                    accountId = mCaseDetails.get(surveyResponse.Case__c).AccountId;    
                }
            }
        }
        return accountId;
    }
    
}