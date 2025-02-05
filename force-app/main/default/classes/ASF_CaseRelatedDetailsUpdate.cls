public without sharing class ASF_CaseRelatedDetailsUpdate {
    
    public void beforeInsertUpdateCase(List<Case> caseList){
        Map<String, List<Case>> recordsByField = new Map<String, List<Case>>();
        Map<String,Case> cccMap = new Map<String,Case>();
        for(Case record : caseList) {
            if(record.CCC_External_Id__c != null){
                 
                if (recordsByField.containsKey(record.CCC_External_Id__c)){
                    recordsByField.get(record.CCC_External_Id__c).add(record);
                }
                else{
                    recordsByField.put(record.CCC_External_Id__c, new List<Case>{record});
                }
                cccMap.put(record.CCC_External_Id__c,record);
            }
        }
        if(cccMap.keySet().size()>0){
            List<ASF_Case_Category_Config__c> cccList = [Select Id,
                                                         Name,
                                                         Apex_Class_Name__c,
                                                         Apex_Method_Name__c,
                                                         Business_Unit__c,
                                                         Type__c, 
                                                         Sub_Type__c,
                                                         CCC_External_Id__c
                                                         from ASF_Case_Category_Config__c 
                                                         where
                                                         CCC_External_Id__c IN : cccMap.keySet() 
                                                         AND Apex_Class_Name__c != null
                                                         AND Apex_Method_Name__c != null];
            if( cccList != null && !cccList.isEmpty())
            {
                Map<String, ASF_Case_Category_Config__c> buClassMap = new Map<String, ASF_Case_Category_Config__c>();
                for(ASF_Case_Category_Config__c ccc : cccList) {
                    buClassMap.put(ccc.CCC_External_Id__c, ccc);
                }
                
                for(String fieldValue : recordsByField.keySet()) {
                    List<Case> ccList = recordsByField.get(fieldValue);
                    if(buClassMap.containsKey(fieldValue)){
                        ASF_Case_Category_Config__c ccc = buClassMap.get(fieldValue);
                        if(ccc.Apex_Class_Name__c == null && ccc.Apex_Method_Name__c == null ) {
                            System.debug('No class and method name');
                        }
                        else {
                            String className = ccc.Apex_Class_Name__c;
                            String methodName = ccc.Apex_Method_Name__c;
                            Type t = Type.forName(className);
                            ASF_SRHandlerInterface ins = (ASF_SRHandlerInterface)t.newInstance();
                            ins.beforeInsertUpdateCaseData(ccList);
                        }
                    }
                }
            }
            
        }
    }
    
    public void updateRelatedObjectDetailsBulk(List<Case> caseList){
        
        Map<String, List<Case>> recordsByField = new Map<String, List<Case>>();
        Map<String,Case> cccMap = new Map<String,Case>();
        List<SObject> objectList = new List<SObject>();
        for(Case record : caseList) {
            if(record.CCC_External_Id__c != null){
                if (recordsByField.containsKey(record.CCC_External_Id__c)){
                    recordsByField.get(record.CCC_External_Id__c).add(record);
                } 
                else{
                    recordsByField.put(record.CCC_External_Id__c, new List<Case>{record});
                }
                cccMap.put(record.CCC_External_Id__c,record);               
            }
        }
        
        try{
            if(cccMap.keySet().size()>0){
                List<ASF_Case_Category_Config__c> cccList = [Select Id,
                                                             Name,
                                                             Apex_Class_Name__c,
                                                             Apex_Method_Name__c,
                                                             Business_Unit__c,
                                                             Type__c, 
                                                             Sub_Type__c,
                                                             CCC_External_Id__c
                                                             from ASF_Case_Category_Config__c 
                                                             where
                                                             CCC_External_Id__c IN : cccMap.keySet() 
                                                             AND Apex_Class_Name__c != null
                                                             AND Apex_Method_Name__c != null];
                if( cccList != null && !cccList.isEmpty())
                {
                    
                    Map<String, ASF_Case_Category_Config__c> buClassMap = new Map<String, ASF_Case_Category_Config__c>();
                    for(ASF_Case_Category_Config__c ccc : cccList) {
                        buClassMap.put(ccc.CCC_External_Id__c, ccc);
                    }
                    
                    for(String fieldValue : recordsByField.keySet()) {
                        List<Case> ccList = recordsByField.get(fieldValue);
                        if(buClassMap.containsKey(fieldValue)){
                            ASF_Case_Category_Config__c ccc = buClassMap.get(fieldValue);
                            if(ccc.Apex_Class_Name__c == null && ccc.Apex_Method_Name__c == null ) {
                                System.debug('No class and method name');
                            }
                            else {
                                String className = ccc.Apex_Class_Name__c;
                                String methodName = ccc.Apex_Method_Name__c;
                                system.debug('className--'+className);
                                system.debug('methodName--'+methodName);
                                Type t = Type.forName(className);
                                ASF_SRHandlerInterface ins = (ASF_SRHandlerInterface)t.newInstance();
                                objectList.addAll(ins.processSRDataBulk(ccList,ccc));
                            }
                        }
                    }
                    //Database.update(objectList, false);
                    update objectList;
                }
                
            }
            
        }catch(Exception ex){
            throw ex;
        }
    }
    /****************************************************************************************************************
    * @Function - removeAccountIdBuMissMatch
    * @param oldCases 
    * @param newCases 
    * @description - remove AccountId from Case if Case BU is not matching with tagged Account' Business Unit.this is for all BUs
    *****************************************************************************************************************/
    public static void removeAccountIdBuMissMatch(map<Id, Case> oldCases,map<Id, Case> newCases){
        Set<Id> caseIdsToUpdate = new Set<Id>();
        List<Case> recordsToUpdate = new List<Case>();
        Map<Id,Id> mCaseIdAccountId = new Map<Id,Id>();
        
        for(Case recCase : newCases.values()){
            if (recCase.AccountId != null) {
                caseIdsToUpdate.add(recCase.AccountId);
                mCaseIdAccountId.put(recCase.Id,recCase.AccountId);
            }
         }
         if (!caseIdsToUpdate.isEmpty()) {
            // Querying related Accounts to fetch Business Unit
            Map<Id, Account> accountMap = new Map<Id, Account>([
                SELECT Id, Business_Unit__c
                FROM Account
                WHERE Id IN :caseIdsToUpdate]);
            // Checking Business Unit mismatch and clearing AccountId if needed
            for (Case cs :newCases.values()) {
            	String caseBu = cs.Business_Unit__c;
                String accountBu = accountMap.get(cs.AccountId).Business_Unit__c;
                Case objToUpdate = new Case();
                objToUpdate.Id = cs.Id;
                // Excluding logic if Case BU is ABFL or ABWM and Account BU is either ABFL or ABWM as both belong to same BU.
                if (!((caseBu == 'ABFL' || caseBu == 'ABWM') && (accountBu == 'ABFL' || accountBu == 'ABWM'))) {
                    if (caseBu != null && accountBu != null && caseBu != accountBu) {
                        objToUpdate.AccountId = null;
                        objToUpdate.ContactId = null;
                        if(mCaseIdAccountId.containsKey(cs.Id)){
                            mCaseIdAccountId.remove(cs.Id);
                        }
                    }
                }
                recordsToUpdate.add(objToUpdate);

            }
         }
        if (!recordsToUpdate.isEmpty()) {
            
            ASF_CasePreFrameworkTriggerHelper.findAndAssociateAssetToCase(newCases.values(),mCaseIdAccountId,recordsToUpdate);
            
            ASF_TriggerSkipperUtility.markTriggerRun('Case');
            update recordsToUpdate;
        }
    }
}