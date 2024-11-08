public class ABHI_CaseCreationValidation {
    
    public static void checkCreateCaseValidations(List<Case> cases, Map<Id, Case> mapOfIdToOldCase, String triggerContext){
        Set<String> issueCodes = new Set<String>();
        List<Case> validCases = new List<Case>();
        Map<Id,Asset> caseIdVsPolicy = new Map<Id,Asset>();
        Set<Id> policyIds = new Set<Id>();
        Map<id,Case> caseIdVsCase = new Map<Id,Case>();
        List<String> plan = new List<String>{'Premier Plan', 'Classic Plan', 'Standard Plan'};
        for(Case c: cases){
            if(c.Business_Unit__c=='ABHI' && c.Technical_Source__c=='LWC'){
            	issueCodes.add(c.CCC_External_Id__c);
                validCases.add(c);
                policyIds.add(c.AssetId);
            }
        }
        
        Map<Id, Asset> policyMap = new Map<Id, Asset>([SELECT Id, Status, Plan_Name__c FROM Asset WHERE Id IN :policyIds]);
        for(Case c: validCases){
            if(policyMap.containsKey(c.AssetId)){
                caseIdVsPolicy.put(c.Id,policyMap.get(c.AssetId));
                caseIdVsCase.put(c.Id,c);
            }
        }
        
        for(Case c: validCases){
            if(caseIdVsCase.containskey(c.Id) && caseIdVsCase.get(c.Id).CCC_External_Id__c == 'ABHI_Endorsement_Request17' && caseIdVsPolicy.containskey(c.Id) && plan.contains(caseIdVsPolicy.get(c.Id).Plan_Name__c)){
                c.addError('Addition of new born member is not allowed as per policy T&C');
            }
        }
        if(issueCodes.size()>0 && !caseIdVsPolicy.isEmpty()){
            Map<String, ABHI_Create_Case_Validations__mdt> issueCodeVsMdt = new Map<String, ABHI_Create_Case_Validations__mdt>();
            List<ABHI_Create_Case_Validations__mdt> validationMdtList = [SELECT Label,Business_Unit__c,Issue_Code__c,
                                             							   Operator__c,Asset_Status__c,Error_Message__c
                                                                         FROM ABHI_Create_Case_Validations__mdt
                                                                         WHERE Business_Unit__c ='ABHI'
                                                                         AND Issue_Code__c IN :issueCodes];
            for (ABHI_Create_Case_Validations__mdt record : validationMdtList) {
                issueCodeVsMdt.put(record.Issue_Code__c, record);
            }
            
            for(Case cs: validCases){
                if(issueCodeVsMdt.containsKey(cs.CCC_External_Id__c) &&
                   issueCodeVsMdt.get(cs.CCC_External_Id__c).Business_Unit__c=='ABHI')
                {
                	List<String> policyStatuses = issueCodeVsMdt.get(cs.CCC_External_Id__c)?.Asset_Status__c?.split(',');
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