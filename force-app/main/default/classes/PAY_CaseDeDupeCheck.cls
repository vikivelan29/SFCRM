public without sharing class PAY_CaseDeDupeCheck {

    public static void runDuplicateCheck(List<Case> cases)
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
        
        System.debug(cases);
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
        
        /* If there is Payment Detail records present in Incoming List of Cases, query and get the transaction Id for the same.
         */
        
        if(payExtensionIds.size()>0){
            mPayExtension = new Map<Id,PAY_Payment_Detail__c>([SELECT ID,Txn_ref_no__c FROM PAY_Payment_Detail__c WHERE Id =: payExtensionIds]);
            System.debug(mPayExtension);
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
                System.debug('I am here....'+dupeCase.Id);
                if(mAccountIdVsCases.containsKey(dupeCase.AccountId)){
                                    System.debug('I am here....2'+dupeCase.Id);
                    if(mAccountIdVsCases.containsKey(dupeCase.AccountId)){
                                                            System.debug('I am here....3'+dupeCase.Id);
                        for(Case c : mAccountIdVsCases.get(dupeCase.AccountId)){
                                                                System.debug('I am here....4'+dupeCase.Id);
                            if(mPayExtension.containsKey(c.PAY_Payment_Detail__c)){
                                                                    System.debug('I am here....5');
                                PAY_Payment_Detail__c currentCasePaymentRecord = mPayExtension.get(c.PAY_Payment_Detail__c);
                                System.debug(dupeCase.PAY_Payment_Detail__r.Txn_ref_no__c +' == '+ currentCasePaymentRecord.Txn_ref_no__c);
                                if(dupeCase.PAY_Payment_Detail__r.Txn_ref_no__c == currentCasePaymentRecord.Txn_ref_no__c){
                                    System.debug('Finally Here....');
                                    // Coming here if the Current Case Transaction Id equals Existing Not Closed Service Request with same transaction Id with the same type and subtype.
                                        c.addError('Duplicate Case found. Case # '+dupeCase.CaseNumber);
                                }
                            }
                        }
                    }
                }
                
            }
            else if(nontransactionRelatedCCC.contains(dupeCase.CCC_External_Id__c)){
                if(mAccountIdVsCases.containsKey(dupeCase.AccountId)){
                    for(Case c : mAccountIdVsCases.get(dupeCase.AccountId)){
                        c.addError('Duplicate Case found. Case # '+dupeCase.CaseNumber);
                    }
                }
            }
        }
        
        
        
    }
    
}