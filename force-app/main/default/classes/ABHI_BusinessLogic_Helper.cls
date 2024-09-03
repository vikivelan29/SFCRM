/*********************************************************
*Class        :  ABHI_BusinessLogic_Helper
*Author       :  ABHI Team
*Created Date :  30/08/2024
*@description  :  Class for ABHI related Business Logic 
*********************************************************/

public with sharing class ABHI_BusinessLogic_Helper {
    
    public Map<String, List<Case>> mapOfBUToNewCase;
    public Map<Id, Case> mapOfIdToOldCase;
    public List<Case> abhiNewCaseList;

    /**
     * @description  Calling ABHI specific Business Logic method
     * @param mapOfBUToNewCs - map of BU to new cases
     * @param oldMapOfCases -  map of Id to old cases
     * @param triggerContext -  Trigger Context
     */
    public void abhiHandlerMethod(Map<String, List<Case>> mapOfBUToNewCs,  Map<Id, Case> oldMapOfCases, String triggerContext) {

        if(mapOfBUToNewCs.containsKey('ABHI') && mapOfBUToNewCs.get('ABHI').size() > 0) {
            mapOfBUToNewCase = mapOfBUToNewCs;
            mapOfIdToOldCase = oldMapOfCases;
            abhiNewCaseList = mapOfBUToNewCs.get('ABHI');

            if(triggerContext == 'AfterASFCodeBeforeUpdate') {
                policyIsMandatory();
            }
          /*  else if(triggerContext == 'AfterASFCodeAfterInsert') {
                updateCustomerOrPolicyOnExistCase();
            } */
        }
    }

    /**
    * Jira Story  - PR1030924-103
    * @description - Policy number is mandatory on customer tagging but not for Prospect.
    */
    public void policyIsMandatory(){
        
        for(Case cs : abhiNewCaseList) {
            if(String.isNotBlank(cs.AccountId) && String.isBlank(cs.AssetId)) {
                cs.addError(ABHI_Constants.POLICY_IS_MANDATORY_ON_CUSTOMER);
            }
        }
    }

    /**
    * Jira Story  - PR1030924-98
    * @description - Update customer or policy on existing case.
    *
    public void updateCustomerOrPolicyOnExistCase(){
        
        List<ABHI_Case_Detail__c> abhiCaseDetList = new List<ABHI_Case_Detail__c>();

        for(Case cs : abhiNewCaseList) {
            String abhiCaseDetId = cs?.ABHI_Case_Detail__c;

            if(String.isNotBlank(cs.ABHI_Case_Detail__c)) {
                ABHI_Case_Detail__c abhiCaseDet = new ABHI_Case_Detail__c();
                abhiCaseDet.Id = cs.ABHI_Case_Detail__c;
                abhiCaseDet.Policy_Id__c = cs?.AssetId;
                abhiCaseDetList.add(abhiCaseDet);
            }
        }

        if(abhiCaseDetList.size() > 0) {
            update abhiCaseDetList;
        }
    } */

}