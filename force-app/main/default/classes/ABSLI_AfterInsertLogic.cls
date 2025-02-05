public with sharing class ABSLI_AfterInsertLogic {
    public static void executeAfterInsertLogic(List<Case> newCases) {
        Map<Id, Case> mAbsliCases = new Map<Id, Case>();
        Map<Id, Case> mAbsliSurrenderWithdrawalCases = new Map<Id, Case>();
        for (Case caseRec : newCases) {
            if (caseRec.Business_Unit__c == ASF_Constants.ABSLI_BU) {
                mAbsliCases.put(caseRec.Id, caseRec);
            }
        }
        for (Case caseRec : newCases) {
            System.debug(caseRec.Business_Unit__c);
            if (caseRec.Business_Unit__c == ASF_Constants.ABSLI_BU && ABSLI_Constants.SURRENDER_WITHDRAWAL_CCC_IDs.contains(caseRec.CCC_External_Id__c)) {
                mAbsliSurrenderWithdrawalCases.put(caseRec.Id, caseRec);
            }
        }
        if(mAbsliCases.keySet().size()>0){
            populateEntityRefNumber(mAbsliCases);
        }
        if(mAbsliSurrenderWithdrawalCases.keySet().size()>0){
            ABSLI_AfterInsertLogic.populateTDSPAN(mAbsliSurrenderWithdrawalCases.values());
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
    
    //Dhinesh - To populate TDS identifier and PAN in Case Detail
     public static void populateTDSPAN(List<Case> AbsliSurrenderWithdrawalCases) {
        Set<String> caseDetailIds = new Set<String>();
        Set<String> accIds = new Set<String>();
        Set<String> assetIds = new Set<String>();
        for (Case caseRec : AbsliSurrenderWithdrawalCases) {
            if (caseRec.AccountId != null) {
                  accIds.add(caseRec.AccountId);
            }
            if (caseRec.ABSLI_Case_Detail__c != null) {
                  caseDetailIds.add(caseRec.ABSLI_Case_Detail__c);
            }
            if (caseRec.AssetId != null) {
                  assetIds.add(caseRec.AssetId);
            }
        }
        Map<Id, ABSLI_Case_Detail__c> caseDetailMap = new Map<Id, ABSLI_Case_Detail__c>();
        for (ABSLI_Case_Detail__c detail : [SELECT Id, PAN__c, TDS_Indicator__c,Policy_Identification__c FROM ABSLI_Case_Detail__c WHERE Id IN :caseDetailIds]) {
            caseDetailMap.put(detail.Id, detail);
        }
        Map<Id, Asset> casePolicyMap = new Map<Id, Asset>();
        for (Asset policy : [SELECT Id,TDS_Indicator__c, Policy_Identification__c FROM Asset WHERE Id IN :assetIds]) {
            casePolicyMap.put(policy.Id, policy);
        }
        Map<Id, Account> caseAccountMap = new Map<Id, Account>();
        for (Account customer : [SELECT Id,PAN__c,Customer_Segment__c FROM Account WHERE Id IN :accIds]) {
            caseAccountMap.put(customer.Id, customer);
        }
        List<ABSLI_Case_Detail__c> caseDetailsToUpdate = new List<ABSLI_Case_Detail__c>();
        for (Case caseRec : AbsliSurrenderWithdrawalCases) {
            ABSLI_Case_Detail__c caseDetail = caseDetailMap.get(caseRec.ABSLI_Case_Detail__c);
            Account customer = caseAccountMap.get(caseRec.AccountId);
            Asset policy = casePolicyMap.get(caseRec.AssetId);
            if (caseDetail != null && customer != null && policy != null) {
                caseDetail.PAN__c = customer.PAN__c;
                caseDetail.TDS_Indicator__c = policy.TDS_Indicator__c;
                //caseDetail.Policy_Identification__c = customer.Customer_Segment__c;
                caseDetail.Policy_Identification__c = policy.Policy_Identification__c;
                caseDetailsToUpdate.add(caseDetail);
            }
        }
        if (!caseDetailsToUpdate.isEmpty()) {
        	update caseDetailsToUpdate;
    	}
    }
}