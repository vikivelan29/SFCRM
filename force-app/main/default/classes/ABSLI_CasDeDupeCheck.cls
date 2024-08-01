/**
 * @description       : ABSLI Dedupe check class
 * @author            : dhinesh.t@salesforce.com
 * @group             : 
 * @last modified on  : 06-03-2024
 * @last modified by  : dhinesh.t@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   06-03-2024   dhinesh.t@salesforce.com   Initial Version
**/
public without sharing class ABSLI_CasDeDupeCheck {
     /****************************************************************************************************************
     * @Function - runDuplicateCheck
     * @param cases 
     * @Description - Method for Case dedupe
     *****************************************************************************************************************/
    public static void runDuplicateCheck(List<Case> cases)
    {
        List<ASF_Case_Category_Config__c> caseCategoryConfigs = new List<ASF_Case_Category_Config__c>();
        Set<String> transactionRelatedCCC = new Set<String>();
        Set<String> nontransactionRelatedCCC = new Set<String>();
        Map<String,Set<Id>> mCCCVsAccountIds = new Map<String,Set<Id>>();
        Map<Id,List<Case>> mAccountIdVsCases = new Map<Id,List<Case>>();
        Map<String, List<Case>> mlanVsCases = new Map<String, List<Case>>();
        Map<String, List<Case>> mIssueTypeVsCases = new Map<String, List<Case>>();
        Map<Id,ABSLI_Case_Detail__c> mABSLIExtension = new Map<Id,ABSLI_Case_Detail__c>();
        Set<Id> absliExtensionIds = new Set<Id>();
        
		/* Get the CCC External Id from Incoming List of Cases.
		 * Map CCC External Id against List of AccountId.
		 * Map Account Id Vs List of Incoming Cases from the incoming cases.
		 * Set of Payment Detail records Id.
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
            
            //absliExtensionIds.add(c.ABSLI_Case_Detail__c);
            
            if((!mlanVsCases.containsKey(c.AssetId))){
                mlanVsCases.put(c.AssetId, new List<Case>());
            }
            mlanVsCases.get(c.AssetId).add(c);
            
            if((!mIssueTypeVsCases.containsKey(c.Issue_Type__c))){
                mIssueTypeVsCases.put(c.Issue_Type__c, new List<Case>());
            }
            mIssueTypeVsCases.get(c.Issue_Type__c).add(c);
        }
        
        /* Get Issue Type from case extension record..
         
        
        if(absliExtensionIds.size()>0){
            mABSLIExtension = new Map<Id,ABSLI_Case_Detail__c>([SELECT ID,Issue_Type__c FROM ABSLI_Case_Detail__c WHERE Id =: absliExtensionIds]);
            System.debug(mABSLIExtension);
        }*/
        
        
        
        // Get Case Category Configuration. 
        caseCategoryConfigs = [SELECT ID,Nature__c,Type__c, Sub_Type__c,Is_Transaction_Related__c,CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c =: mCCCVsAccountIds.keySet() WITH SECURITY_ENFORCED];
        
        for(ASF_Case_Category_Config__c ccc : caseCategoryConfigs){
            if(ccc.Nature__c == ABSLI_Constants.QUERY || ccc.Nature__c == ABSLI_Constants.REQUEST){
                /* Prepare Collection of Queries and Requests             
                 */
                transactionRelatedCCC.add(ccc.CCC_External_Id__c);
            }
        }
        
       /* Get the list of Cases for Accountids, AssetIds and with Closed = False i.e. take all the cases not resolved or rejected or cancelled or merged.            
        * 		
       */
        
        for(Case dupeCase: [SELECT ID,CCC_External_Id__c,AccountId,Status,ABSLI_Case_Detail__c,Issue_Type__c,CaseNumber,Lead__c FROM Case WHERE AccountId =: mAccountIdVsCases.keySet() AND CCC_External_Id__c =: mCCCVsAccountIds.keySet() AND (AssetId IN :mlanVsCases.keySet()) AND isClosed = false WITH SECURITY_ENFORCED]){
            if(dupeCase.AccountId != null && dupeCase.Lead__c == null){
                if(transactionRelatedCCC.contains(dupeCase.CCC_External_Id__c )){
                System.debug(LoggingLevel.INFO,'I am here....'+dupeCase.Id);
                if(mAccountIdVsCases.containsKey(dupeCase.AccountId)){
                                    System.debug(LoggingLevel.INFO,'I am here....2'+dupeCase.Id);
                    for(Case accountCase : mAccountIdVsCases.get(dupeCase.AccountId)){
                        if(dupeCase.CCC_External_Id__c == accountCase.CCC_External_Id__c){
                            if(mIssueTypeVsCases.containsKey(dupeCase.Issue_Type__c)){
                                if(accountCase.Issue_Type__c == dupeCase.Issue_Type__c){
                                    accountCase.addError('Duplicate Case found. Case # '+dupeCase.CaseNumber);   
                                }
                            }
                        }
                    }

                    /*if(mIssueTypeVsCases.containsKey(dupeCase.Issue_Type__c)){
                                                            System.debug(LoggingLevel.INFO,'I am here....3'+dupeCase.Id);
                        for(Case c : mIssueTypeVsCases.get(dupeCase.Issue_Type__c)){// mAccountIdVsCases.get(dupeCase.AccountId)){
                            system.debug('DUplicate case acc id:'+dupeCase.AccountId);
                                                                System.debug(LoggingLevel.INFO,'Finally here....4'+dupeCase.Id);
                            if(c.Issue_Type__c == dupeCase.Issue_Type__c){
                             	c.addError('Duplicate Case found. Case # '+dupeCase.CaseNumber);   
                            }
                             
                        }
                    }*/
                }
                
            }
          }
        }
    }
    
}