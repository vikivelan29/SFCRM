/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-27-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class ABCD_CaseDeDupeCheck {
	 public static void runDuplicateCheck(Object newItems, Object oldItems){
        List<Case> newList = new List<Case>();
    	List<Case> oldList = new List<Case>();

    	// Handle beforeInsert scenario (newItems is a List)
    	if (newItems instanceof List<Case>) {
        	newList = (List<Case>) newItems;
            oldList = new List<Case>();
    	}

    	// Handle beforeUpdate scenario (newItems and oldItems are Maps)
    	if (newItems instanceof Map<Id, Case> && oldItems instanceof Map<Id, Case>) {
        	Map<Id, Case> newMap = (Map<Id, Case>) newItems;
        	Map<Id, Case> oldMap = (Map<Id, Case>) oldItems;
        	newList.addAll(newMap.values());
        	oldList.addAll(oldMap.values());
    	}     
         
        Map<String,Map<String,String>> mLobToChannelToQueue = new Map<String,Map<String,String>>();
        List<LOBVsAPIChannels__mdt> lobToChannelQueue = [SELECT Id, Line_Of_Business__c, Source__c, Queue_DeveloperName__c FROM LOBVsAPIChannels__mdt WITH SYSTEM_MODE];
        Map<String,List<Case>> mChannelVsCases = new Map<String,List<Case>>();
        Map<String,List<Case>> mChannelVsCasesOld = new Map<String,List<Case>>();
        Set<String> queueDevName = new Set<String>();
                
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
        }
         
        for(String key : mChannelVsCases.keySet()){
            if(key == 'ONEABC'){
                duplicateCheck(mChannelVsCases.get(key), oldList);
            }
        } 
   }

	public static void duplicateCheck(List<Case> cases, List<Case> oldList)
    {
        List<ASF_Case_Category_Config__c> caseCategoryConfigs = new List<ASF_Case_Category_Config__c>();
        Set<String> transactionRelatedCCC = new Set<String>();
        Set<String> nontransactionRelatedCCC = new Set<String>();
        Map<String,Set<Id>> mCCCVsAccountIds = new Map<String,Set<Id>>();
        Map<Id,List<Case>> mAccountIdVsCases = new Map<Id,List<Case>>();
        Map<Id,Case> oldCasesMap = new Map<Id,Case>();
        
		/* Get the CCC External Id from Incoming List of Cases.
		 * Map CCC External Id against List of AccountId.
		 * Map Account Id Vs List of Incoming Cases from the incoming cases.
		 */
        
        System.debug(LoggingLevel.INFO,cases);
        for(Case c : cases){
            if(!mCCCVsAccountIds.containsKey(c.CCC_External_Id__c)){
                mCCCVsAccountIds.put(c.CCC_External_Id__c, new Set<Id>());
            } 
            mCCCVsAccountIds.get(c.CCC_External_Id__c).add(c.AccountId);
            
            
            if(!mAccountIdVsCases.containsKey(c.AccountId)){
                mAccountIdVsCases.put(c.AccountId, new List<Case>());
            }
            mAccountIdVsCases.get(c.AccountId).add(c);
            
        }
        if(oldList != null && !oldList.isEmpty()){
          for (Case oldCase : oldList) {
        	oldCasesMap.put(oldCase.Id, oldCase);
    	  }   
        } 
        
        
        // Get Case Category Configuration. 
        caseCategoryConfigs = [SELECT ID,Nature__c,Type__c, Sub_Type__c,Is_Transaction_Related__c,CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c =: mCCCVsAccountIds.keySet() WITH SECURITY_ENFORCED];
        
        for(ASF_Case_Category_Config__c ccc : caseCategoryConfigs){
            if(ccc.Nature__c == ONEABC_Constants.REQUEST_NATURE || ccc.Nature__c == ONEABC_Constants.COMPLAINT_NATURE){
                /* Prepare Collection of Complaints and Requests             
                 */
                transactionRelatedCCC.add(ccc.CCC_External_Id__c);
            }
        }
        
       /* Get the list of Cases for Accountids and with Closed = False i.e. take all the cases not resolved or rejected or cancelled or merged.            
        * 		
       */
        
        for(Case dupeCase: [SELECT ID,CCC_External_Id__c,AccountId,Status,CaseNumber,Lead__c,Preframework_to_Framework_FromUI__c FROM Case WHERE AccountId =: mAccountIdVsCases.keySet() AND CCC_External_Id__c =: mCCCVsAccountIds.keySet() AND isClosed = false WITH SECURITY_ENFORCED]){
            if(dupeCase.AccountId != null && dupeCase.Lead__c == null){
                if(transactionRelatedCCC.contains(dupeCase.CCC_External_Id__c )){
                if(mAccountIdVsCases.containsKey(dupeCase.AccountId)){
                    for(Case accountCase : mAccountIdVsCases.get(dupeCase.AccountId)){
                        if(dupeCase.CCC_External_Id__c == accountCase.CCC_External_Id__c){
                            if(oldList != null && !oldList.isEmpty()){
                            	Case oldCase = oldCasesMap.get(accountCase.Id); 
                                if(oldCase.Preframework_to_Framework_FromUI__c == false && accountCase.Preframework_to_Framework_FromUI__c == true){
                                  	accountCase.addError('Duplicate Case found. Case # '+dupeCase.CaseNumber);  
                                }
                            }else{
                               accountCase.addError('Duplicate Case found. Case # '+dupeCase.CaseNumber);
                            }
                            
                        }
                    }
                }
                
            }
          }
        }
    }    
}