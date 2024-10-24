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
            ABHI_CaseDetailHelper abhiCsDetHelperObj = new ABHI_CaseDetailHelper();
            mapOfBUToNewCase = mapOfBUToNewCs;
            mapOfIdToOldCase = oldMapOfCases;
            abhiNewCaseList = mapOfBUToNewCs.get('ABHI');

            if(triggerContext == 'AfterASFCodeBeforeUpdate') {
                policyIsMandatory();
            }
            else {
                abhiCsDetHelperObj.populateCaseOnABHICaseDet(abhiNewCaseList, mapOfIdToOldCase, triggerContext);
            }
        }
    }

    /**
    * Jira Story  - PR1030924-103
    * @description - Policy number is mandatory on customer tagging but not for Prospect.
    */
    public void policyIsMandatory(){
        
        for(Case cs : abhiNewCaseList) {
            if(String.isNotBlank(cs.AccountId) && String.isBlank(cs.AssetId)&& cs.Source__c != 'IGMS') {
                cs.addError(ABHI_Constants.POLICY_IS_MANDATORY_ON_CUSTOMER);
            }
        }
    }
    
    /**
     * @description  Calling ABHI specific case validations before case creation
     * @param caseRecord - the case that is created from create case page
     * @param Called from lwc component
     */
    @AuraEnabled
    public static String abhiCaseValidation(String caseRecord){
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped((caseRecord));
        Map<String,List<String>> natureToGroupMap = new Map<String,List<String>>(); 
        String result = System.label.ABHI_Create_Case_Validation;
        try{
            Map<String, ABHI_Create_Case_Validations__mdt> metadataRecords = ABHI_Create_Case_Validations__mdt.getAll();
            if (!metadataRecords.isEmpty()) {
                Set<String> groupNames = new Set<String>();
                
                //Fetch all metadata values and store it in map
                for (String key : metadataRecords.keySet()) {
                    ABHI_Create_Case_Validations__mdt metadataRecord = metadataRecords.get(key);
                    if(!natureToGroupMap.containsKey(metadataRecord.Nature__c)){
                        natureToGroupMap.put(metadataRecord.Nature__c, new List<String>());
                    }
                    natureToGroupMap.get(metadataRecord.Nature__c).addAll(metadataRecord.Public_Groups__c.split(';'));
                    groupNames.addAll(metadataRecord.Public_Groups__c.split(';'));
                }
                //validate if user is part of the queue
                if(natureToGroupMap.containsKey(String.valueOf(jsonMap.get('Nature__c')))){
                    Map<Id,Group> publicGroupIds = new Map<Id,Group>([SELECT Id,DeveloperName FROM Group WHERE DeveloperName IN: groupNames AND Type = 'Regular']);
                    List<GroupMember> groupMembers = [
                        SELECT Id, GroupId, Group.DeveloperName
                        FROM GroupMember 
                        WHERE GroupId IN: publicGroupIds.keySet() 
                        AND UserOrGroupId = :UserInfo.getUserId()
                    ];
                    if(!groupMembers.isEmpty()){
                        for(GroupMember member : groupMembers){
                            if(natureToGroupMap.get(String.valueOf(jsonMap.get('Nature__c'))).contains(member.Group.DeveloperName)){
                                return 'Success';
                            }
                        }
                    }
                 // return success if there is no entry for the current Case's nature in the metadata
                }else{
                    return 'Success';
                }
            }
                  
        }catch(Exception e){
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('abhiCaseValidation Case creation validation');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
            throw new AuraHandledException(e.getMessage());
        }        
        return result;
    }
}
