public class PAY_CaseDeDupeCheckLWC {
    @AuraEnabled
    public static void getDuplicateCases(List<Case> cases, String transactionNo)
    {
        List<ASF_Case_Category_Config__c> caseCategoryConfigs = new List<ASF_Case_Category_Config__c>();
        Set<String> transactionRelatedCCC = new Set<String>();
        Set<String> nontransactionRelatedCCC = new Set<String>();
        Map<String,Set<Id>> mCCCVsAccountIds = new Map<String,Set<Id>>();
        Map<Id,List<Case>> mAccountIdVsCases = new Map<Id,List<Case>>();
        Map<Id,PAY_Payment_Detail__c> mPayExtension = new Map<Id,PAY_Payment_Detail__c>();
        Set<Id> payExtensionIds = new Set<Id>();
        
        /* Get the CCC External Id from Incoming List of Cases.
* Map CCC External Id against List of AccountId.
* Map Account Id Vs List of Incoming Cases from the incoming cases.
* Set of Payment Detail records Id.
*/
        for(Case c : cases){
            if(!mCCCVsAccountIds.containsKey(c.CCC_External_Id__c)){
                mCCCVsAccountIds.put(c.CCC_External_Id__c, new Set<Id>());
            } 
            mCCCVsAccountIds.get(c.CCC_External_Id__c).add(c.AccountId);
            
            
            if(!mAccountIdVsCases.containsKey(c.AccountId)){
                mAccountIdVsCases.put(c.AccountId, new List<Case>());
            }
            mAccountIdVsCases.get(c.AccountId).add(c);
            
            payExtensionIds.add(c.PAY_Payment_Detail__c);
        }
        
        // Get Case Category Configuration. 
        caseCategoryConfigs = [SELECT ID,Nature__c,Type__c, Sub_Type__c,Is_Transaction_Related__c,CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c =: mCCCVsAccountIds.keySet()];
        
        for(ASF_Case_Category_Config__c ccc : caseCategoryConfigs){
            if(ccc.Is_Transaction_Related__c){
                /* Prepare Collection of TransactionRelated             
*/
                transactionRelatedCCC.add(ccc.CCC_External_Id__c);
            }
            else{
                /* Prepare Collection of NonTransactionRelated             
*/                
                nontransactionRelatedCCC.add(ccc.CCC_External_Id__c);
            }
        }
        
        /* Get the list of Cases for Accountids and with Closed = False i.e. take all the cases not resolved or rejected or cancelled or merged.            
* Check if this is transaction releated
* 		
*/
        
        for(Case dupeCase: [SELECT ID,CCC_External_Id__c,AccountId,Status,PAY_Payment_Detail__c,PAY_Payment_Detail__r.Txn_ref_no__c,CaseNumber FROM Case WHERE AccountId =: mAccountIdVsCases.keySet() AND CCC_External_Id__c =: mCCCVsAccountIds.keySet() AND isClosed = false]){
            if(transactionRelatedCCC.contains(dupeCase.CCC_External_Id__c )){
                if(mAccountIdVsCases.containsKey(dupeCase.AccountId)){
                    for(Case c : mAccountIdVsCases.get(dupeCase.AccountId)){
                        if(dupeCase.PAY_Payment_Detail__r.Txn_ref_no__c == transactionNo){
                            // Coming here if the Current Case Transaction Id equals Existing Not Closed Service Request with same transaction Id with the same type and subtype.
                            throw new AuraException('Duplicate Case found. Case # '+dupeCase.CaseNumber);
                        }
                    }
                }
            }
            else if(nontransactionRelatedCCC.contains(dupeCase.CCC_External_Id__c)){
                if(mAccountIdVsCases.containsKey(dupeCase.AccountId)){
                    for(Case c : mAccountIdVsCases.get(dupeCase.AccountId)){ 
                        throw new AuraException('Duplicate Case found. Case # '+dupeCase.CaseNumber);
                    }
                }
            }
        }
    }
}