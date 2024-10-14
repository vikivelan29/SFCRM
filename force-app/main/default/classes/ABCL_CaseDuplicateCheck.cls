public without sharing class ABCL_CaseDuplicateCheck {
    
    public void runDuplicateCheck(List<Case> newList){
        Map<String,Map<String,String>> mLobToChannelToQueue = new Map<String,Map<String,String>>();
        List<Case> paymentCases = new List<Case>();
        List<LOBVsAPIChannels__mdt> lobToChannelQueue = [SELECT Id, Line_Of_Business__c, Source__c, Queue_DeveloperName__c FROM LOBVsAPIChannels__mdt WITH SYSTEM_MODE];
        Map<String,List<Case>> mChannelVsCases = new Map<String,List<Case>>();
                Set<String> queueDevName = new Set<String>();
        List<Case> abhflCases = new List<Case>();//AM-ABHFL Case DEDUPE
        List<Case> abslamcCases = new List<Case>();
        
        for(LOBVsAPIChannels__mdt mdt : lobToChannelQueue){
            if(!mLobToChannelToQueue.containsKey(mdt.Line_Of_Business__c)){
                mLobToChannelToQueue.put(mdt.Line_Of_Business__c,new Map<String,String>());
            }
            if(!mLobToChannelToQueue.get(mdt.Line_Of_Business__c).containsKey(mdt.Source__c)){
                mLobToChannelToQueue.get(mdt.Line_Of_Business__c).put(mdt.Source__c,mdt.Queue_DeveloperName__c);
                if(mdt.Queue_DeveloperName__c != null){
                    queueDevName.add(mdt.Queue_DeveloperName__c);
                }
            }
        }
        
        
        for(Case c : newList){
            if(mLobToChannelToQueue.containsKey(c.Business_Unit__c)){
                if(mLobToChannelToQueue.get(c.Business_Unit__c).containsKey(c.Technical_Source__c)){
                    if(!mChannelVsCases.containsKey(c.Business_Unit__c)){
                        mChannelVsCases.put(c.Business_Unit__c,new List<Case>());
                    }
                    mChannelVsCases.get(c.Business_Unit__c).add(c);
                }
            }
            if(c.Business_Unit__c=='ABHFL'){//AM-ABHFL Case DEDUPE
                abhflCases.add(c);
            }
             else if(c.Business_Unit__c== ABSLAMC_Constants.ABSLAMCBU){//AM-ABSLAMC Case DEDUPE
                abslamcCases.add(c);
            }
        }
        
        for(String key : mChannelVsCases.keySet()){
            if(key == 'Payments'){
                PAY_CaseDeDupeCheck.runDuplicateCheck(mChannelVsCases.get(key));
            }
            else if(key == 'ABSLI'){
                ABSLI_CasDeDupeCheck.runDuplicateCheck(mChannelVsCases.get(key));
            }
        }
        if(Label.ABHFL_Case_Dedupe_Active=='Active'){//AM-ABHFL Case DEDUPE
        	ABHFL_CTSTHelper.runDuplicateCheck(abhflCases);  
        }
        if(Label.ABSLAMC_Case_Dedupe_Active=='Active'){//AM-ABHFL Case DEDUPE
        	ABSLAMC_CaseCreationDuplicateChecker.runDuplicateCheck2(abslamcCases);
        }
        
    }
    
}