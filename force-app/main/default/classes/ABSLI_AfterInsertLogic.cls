public with sharing class ABSLI_AfterInsertLogic {
    public static void executeAfterInsertLogic(List<Case> newCases) {
        Map<Id, Case> mAbsliCases = new Map<Id, Case>();
        
        for (Case caseRec : newCases) {
            if (caseRec.Business_Unit__c == ASF_Constants.ABSLI_BU) {
                mAbsliCases.put(caseRec.Id, caseRec);
            }
        }
        if(mAbsliCases.keySet().size()>0){
            populateEntityRefNumber(mAbsliCases);
        }
    }
    
    private static void populateEntityRefNumber(Map<Id, Case> mAbsliCases){
        for(Case c : mAbsliCases.values()){
            Case updCase = new Case(Id = c.Id);
            updCase.Entity_Reference_No__c = 'BSLI'+c.CaseNumber; 
            ASF_CaseTriggerModularHelper.addTocaseFinalDMLMap(updCase);
            System.debug(c);
        }
    }
    
    //AM-PR970457-2039-Method to validate case creation for specific CTSTs based on certain conditions
    public static void checkCreateCaseValidations(List<Case> cases){
        Set<String> issueCodes = new Set<String>();
        List<Case> validCases = new List<Case>();
        Map<Id,Asset> caseIdVsPolicy = new Map<Id,Asset>();
        Set<Id> policyIds = new Set<Id>();
        for(Case c: cases){
            if(c.Business_Unit__c=='ABSLI' && c.Technical_Source__c=='LWC'){
            	issueCodes.add(c.CCC_External_Id__c);
                validCases.add(c);
                policyIds.add(c.AssetId);
            }
        }
        
        Map<Id, Asset> policyMap = new Map<Id, Asset>([SELECT Id, Status FROM Asset WHERE Id IN :policyIds]);
        for(Case c: validCases){
            if(policyMap.containsKey(c.AssetId)){
                caseIdVsPolicy.put(c.Id,policyMap.get(c.AssetId));
            }
        }
        if(issueCodes.size()>0 && !caseIdVsPolicy.isEmpty()){
            Map<String, ABSLI_Create_Case_Validations__mdt> issueCodeVsMdt = new Map<String, ABSLI_Create_Case_Validations__mdt>();
            List<ABSLI_Create_Case_Validations__mdt> validationMdtList = [SELECT Label,Business_Unit__c,Issue_Code__c,
                                             							   Operator__c,Asset_Values__c,Error_Message__c
                                                                         FROM ABSLI_Create_Case_Validations__mdt
                                                                         WHERE Business_Unit__c ='ABSLI'
                                                                         AND Issue_Code__c IN :issueCodes];
            for (ABSLI_Create_Case_Validations__mdt record : validationMdtList) {
                issueCodeVsMdt.put(record.Issue_Code__c, record);
            }
            
            for(Case cs: validCases){
                if(issueCodeVsMdt.containsKey(cs.CCC_External_Id__c) &&
                   issueCodeVsMdt.get(cs.CCC_External_Id__c).Business_Unit__c=='ABSLI')
                {
                	List<String> policyStatuses = issueCodeVsMdt.get(cs.CCC_External_Id__c).Asset_Values__c.split(':');
                    String oprtr = issueCodeVsMdt.get(cs.CCC_External_Id__c).Operator__c;
                    switch on oprtr{
                        when 'IN'{
                            if((caseIdVsPolicy.get(cs.Id).Status!=null) && (!policyStatuses.contains(caseIdVsPolicy.get(cs.Id).Status.replaceAll('\\s*,\\s*', ',')))){
                                cs.addError(issueCodeVsMdt.get(cs.CCC_External_Id__c).Error_Message__c);
                            }
                        }
                        when 'NOT IN'{
                            if((caseIdVsPolicy.get(cs.Id).Status!=null) && (policyStatuses.contains(caseIdVsPolicy.get(cs.Id).Status.replaceAll('\\s*,\\s*', ',')))){
                                cs.addError(issueCodeVsMdt.get(cs.CCC_External_Id__c).Error_Message__c);
                            }
                        }
                    }
                }
            }
            
        }
    }

}