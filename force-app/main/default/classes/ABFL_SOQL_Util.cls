/**
* @Class name:      ABFL_SOQL_Util
* @Description:
* @Group:
* Modification Log:
* ------------------------------------------------------------------------------------
* Developer                  Version     Date                Description
* ------------------------------------------------------------------------------------
* Aditee                     1.0       21/12/2023              #
*/
public with sharing class ABFL_SOQL_Util {
    /********************************************************************************************************
    * @author           Salesforce
    * @date             21/12/2023
    * @description      SOQL method for getting fiscal year
    * @Paramters        Integer
    * @return           List<FiscalYearSettings>
    *********************************************************************************************************/
    public static List<FiscalYearSettings> getFiscalYear(Integer startDate, Integer endDate) {
         String query = 'SELECT Id, PeriodId, StartDate, EndDate, Name FROM FiscalYearSettings WHERE '+
                'StartDate >= LAST_N_FISCAL_YEARS:'+startDate+' AND StartDate <= NEXT_N_FISCAL_YEARS:'+
             	endDate+' Order By StartDate ASC';
		return Database.query(query);
    }

    public static Map<String, ASF_Case_Category_Config__c> getCccIdToRecordMap(Set<String> cccIdSet) {
      Map<String, ASF_Case_Category_Config__c> cccIdToRecordsMap = new Map<String, ASF_Case_Category_Config__c>();

      if(cccIdSet?.size() > 0) {
        for (ASF_Case_Category_Config__c cccRecord :[SELECT Id, CCC_External_Id__c, Litmus_Trigger__c, Litmus_Project__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c IN :cccIdSet WITH SYSTEM_MODE]) {
          cccIdToRecordsMap.put(cccRecord.CCC_External_Id__c, cccRecord);
        }
      }
      return cccIdToRecordsMap;
    }

    private static List<User> userList;
    public static List<User> getUserInfo(String nickName) {
      if(userList == null) {
        userList = [SELECT Id
                      FROM User
                      WHERE CommunityNickname LIKE :nickName 
                      LIMIT 1];
      }
      return userList;
    }
}