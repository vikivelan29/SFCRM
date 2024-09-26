/**
* @Class name       : ABFL_SOQL_Util
* @description      : ABFL SOQL Util Class    
* @Group            :
* Modification Log  :
* ------------------------------------------------------------------------------------
* Developer                  Version     Date                Description
* ------------------------------------------------------------------------------------
* Aditee                     1.0       21/12/2023              #
*/
public with sharing class ABFL_SOQL_Util {
    private static List<User> userList;
    private static Asset assetRec;

    /********************************************************************************************************
    * @author           Salesforce
    * @date             21/12/2023
    * @description      SOQL method for getting fiscal year
    * @param            startDate
    * @param            endDate
    * @return           List<FiscalYearSettings>
    *********************************************************************************************************/
    public static List<FiscalYearSettings> getFiscalYear(Integer startDate, Integer endDate) {
         String query = 'SELECT Id, PeriodId, StartDate, EndDate, Name FROM FiscalYearSettings WHERE '+
                'StartDate >= LAST_N_FISCAL_YEARS:'+startDate+' AND StartDate <= NEXT_N_FISCAL_YEARS:'+
             	endDate+' Order By StartDate ASC';
		return Database.query(String.escapeSingleQuotes(query));
    }

    /********************************************************************************************************
    * @author           Udit Singhal
    * @date             09/02/2023
    * @description      SOQL method to return cccId to cccRecord map from a given set if Id's
    * @param            cccIdSet
    * @return           Map<String, ASF_Case_Category_Config__c>
    *********************************************************************************************************/
    public static Map<String, ASF_Case_Category_Config__c> getCccIdToRecordMap(Set<String> cccIdSet) {
      Map<String, ASF_Case_Category_Config__c> cccIdToRecordsMap = new Map<String, ASF_Case_Category_Config__c>();

      if(cccIdSet?.size() > 0) {
        for (ASF_Case_Category_Config__c cccRecord :[SELECT Id, CCC_External_Id__c, Litmus_Trigger__c, Litmus_Project__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c IN :cccIdSet WITH SYSTEM_MODE]) {
          cccIdToRecordsMap.put(cccRecord.CCC_External_Id__c, cccRecord);
        }
      }
      return cccIdToRecordsMap;
    }

    /********************************************************************************************************
    * @author           Udit Singhal
    * @date             21/02/2024
    * @description      SOQL method for getting Asset details for an given asset Id
    * @param            assetid
    * @return           Asset
    *********************************************************************************************************/
    public static Asset getAssetInfo(string assetid) {
      if(assetRec ==  null) {
        assetRec = [SELECT Id, LAN__c, Account.PAN__c, Application_Number__c
                    FROM Asset 
                    WHERE Id =:assetid 
                    WITH SYSTEM_MODE
                    LIMIT 1];
      }
      return assetRec;
    }
}