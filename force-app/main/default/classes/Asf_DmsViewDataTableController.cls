/*********************************************************
*Class        :  Asf_DmsViewDataTableController
*Author       :  Shubham Sinha 
*Created Date :  30/04/2024
* @description - This class is created to show the datatable columns and records 
*********************************************************/
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.ExcessiveParameterList,PMD.NcssMethodCount,PMD.StdCyclomaticComplexity,PMD.ApexSOQLInjection,PMD.AvoidDeeplyNestedIfStmts')
public with sharing class Asf_DmsViewDataTableController {
/****************************************************************************************************************
* @param configName
* @return -  List<Asf_Dynamic_Datatable_Child__mdt> .
* @description - created to fetch the datatable columns
*****************************************************************************************************************/ 
    @AuraEnabled
    public static List<Asf_Dynamic_Datatable_Child__mdt> getColumns(String configName) {
    return [SELECT MasterLabel,Order__c, DeveloperName ,Asf_Dynamic_Datatable_Parent__c , Api_Name__c, Data_Type__c,
            Asf_Dynamic_Datatable_Parent__r.Page_Size__c
            FROM Asf_Dynamic_Datatable_Child__mdt
            WHERE Asf_Dynamic_Datatable_Parent__r.DeveloperName = :configName WITH SYSTEM_MODE
            ORDER BY Order__c ASC]; 
    }
    /****************************************************************************************************************
* @param   caseId
* @param   pageNumber
 @param pageSize
* @return -  List<sObject> 
* @description - created to build the query and fetch the records for datatable
*****************************************************************************************************************/ 
//    @AuraEnabled
//     public static PaginationResult executeQuery(String caseId, Integer pageNumber, Integer pageSize) {
//         PaginationResult result = new PaginationResult();
//         String dynamicQuery = getQuery() + '\'' + caseId + '\' ORDER BY Name';

//         if(String.isNotBlank(dynamicQuery)) {
//             try {
//                 Integer totalRecords = [SELECT COUNT() FROM DMS_Files__c  WHERE Case__c  = :caseId WITH SYSTEM_MODE];
//                 Integer startRowIndex = Math.max(0, (pageNumber - 1) * pageSize);
//                 dynamicQuery += ' LIMIT :pageSize OFFSET :startRowIndex';
//                 result.data = Database.query(dynamicQuery);
//                 result.totalRecords = totalRecords;

//                 return result;
//             } catch(Exception ex) {
//                 return null;
//             }
//         } 
//         return null;
//     }

    @AuraEnabled
    public static List<DMS_Files__c> executeQuery(String caseId) {
        List<DMS_Files__c> lDMSFiles ;
        String dynamicQuery = getQuery() + '\'' + caseId + '\' ORDER BY Name';
        if(String.isNotBlank(dynamicQuery)) {
            lDMSFiles = Database.query(dynamicQuery);
        } 
        return lDMSFiles;
    }
    
    /****************************************************************************************************************
* @param  - String
* @return -  List<sObject> 
* @description - created to build the query and fetch the records for datatable
*****************************************************************************************************************/ 
     @AuraEnabled
    public static string getQuery() {
        Asf_Dynamic_Datatable_Parent__mdt  metadataRecord = [SELECT Query__c  FROM Asf_Dynamic_Datatable_Parent__mdt WHERE DeveloperName = 'Asf_DMS_File_Datatable' WITH SYSTEM_MODE LIMIT 1];
        return metadataRecord != null ? metadataRecord.Query__c : null;
    }
    /****************************************************************************************************************
* @param userBDid
* @return   String 
* @@description - created to store the userBDid on org cache
*****************************************************************************************************************/ 
    @AuraEnabled
    public static string getUserBDid(string userBDid) {
        Cache.OrgPartition orgPartition = Cache.Org.getPartition('ABC');
        String cachedUserBDid = (String)orgPartition.get(userBDid);
        if (cachedUserBDid != null) {
            return cachedUserBDid;
        } 
        else {
            Asf_Dynamic_Datatable_Parent__mdt cacheSettings = Asf_Dynamic_Datatable_Parent__mdt.getInstance('Asf_DMS_File_Datatable');
            Integer cacheTimeoutSeconds = cacheSettings.Cache_Time__c.intValue();
            //String apiResponse = makeApiCall(userBDid);
            orgPartition.put(userBDid, 'ABCDEFGH', cacheTimeoutSeconds); 
            String cachedValue = (String)orgPartition.get(userBDid);
            return cachedValue;
           // return apiResponse;
        }
    }
/****************************************************************************************************************
* @param   userBDid
* @return   String 
* @description - api callout to get the userBdId
*****************************************************************************************************************/ 
    public static string makeApiCall(string userBDid) {
        //  API call logic will be added here
        // This is just a placeholder
        return 'UserBDid from API';
    }
/****************************************************************************************************************
* @description - wrapper to get the records details
*****************************************************************************************************************/ 
    public class PaginationResult {
        @AuraEnabled
/*********************************************************
*@description  :  data of DMS records
*********************************************************/
        public List<sObject> data { get; set; }
        @AuraEnabled
/*********************************************************
*@description  :  totalRecords user for pagination
*********************************************************/
        public Integer totalRecords { get; set; }
    }
}