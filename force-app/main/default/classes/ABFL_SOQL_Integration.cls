/**
* @Class name       :      ABFL_SOQL_Integration
* @description      :      SOQL Util class for ASF_Case_Integration__c Obj
* @Group            :
* Modification Log  :
* ------------------------------------------------------------------------------------
* Developer                  Version     Date                Description
* ------------------------------------------------------------------------------------
* Aditee                     1.0       13/12/2023              #
*/
public with sharing class ABFL_SOQL_Integration {
	/****************************************************************************************************************
     * @function - getCaseIntegrationInfo
     * @description - SOQL method for getting integration details
     * @param caseid
     * @param type
     * @return Map<Id, Case>
     *****************************************************************************************************************/
    public static List<ASF_Case_Integration__c> getCaseIntegrationInfo(String caseid, String type){
        return [SELECT Name FROM ASF_Case_Integration__c 
                WHERE Case__c = :caseid 
                AND Status__c = :ABFL_Constants.PENDING
                AND Type__c = :type
                WITH SECURITY_ENFORCED];
    } 
    /****************************************************************************************************************
     * @function        getCaseIntegrationInfos
     * @description     SOQL method for getting integration details
     * @param ciIds
     * @param status
     * @return List<ASF_Case_Integration__c>
     *****************************************************************************************************************/
    public static List<ASF_Case_Integration__c> getCaseIntegrationInfos(List<Id> ciIds, String status){
        return [SELECT Name,Case__c FROM ASF_Case_Integration__c 
                WHERE Id IN :ciIds 
                AND Status__c = :status
                WITH SECURITY_ENFORCED];
    } 
    /********************************************************************************************************
    * @function         getIntegrationInfo 
    @author             Salesforce
    * @date             13/12/2023
    * @description      SOQL method for getting integration details
    * @param            externalId
    * @return           case
    *********************************************************************************************************/
    public static ASF_Integration__c getIntegrationInfo(string externalId){
        return [SELECT id, STP_API_Identifier__c, STP_Processing_Class__c, 
                External_Id__c,STP_Config_External_Id__c, STP_Template__c 
                FROM ASF_Integration__c 
                WHERE External_Id__c = :externalId
                WITH SECURITY_ENFORCED];
    } 

    /********************************************************************************************************
    * @function         getCaseIdsToIntegrationRecordsMap 
    * @author           Salesforce
    * @date             13/12/2023
    * @description      SOQL method for getting integration details
    * @param            caseIdSet
    * @param            type
    * @return           Map<Id, ASF_Case_Integration__c>
    *********************************************************************************************************/
    public static Map<Id, ASF_Case_Integration__c> getCaseIdsToIntegrationRecordsMap(Set<Id> caseIdSet, String type) {
        Map<Id, ASF_Case_Integration__c> caseIdToCaseIntMap = new Map<Id, ASF_Case_Integration__c>();

        List<ASF_Case_Integration__c> caseIntRecordsList = [SELECT Name, Case__c
                                                            FROM ASF_Case_Integration__c 
                                                            WHERE Case__c IN :caseIdSet 
                                                            AND Status__c = :ABFL_Constants.PENDING
                                                            AND Type__c = :type
                                                            WITH SECURITY_ENFORCED];

        for(ASF_Case_Integration__c caseIntRecord :caseIntRecordsList) {
            caseIdToCaseIntMap.put(caseIntRecord.Case__c, caseIntRecord);
        }

        return caseIdToCaseIntMap;
    }
}