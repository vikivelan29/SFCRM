/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 05-05-2024
 * @last modified by  : rsinghnagar@salesforce.com 
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   05-05-2024   rsinghnagar@salesforce.com   Initial Version
**/
public with sharing class Asf_DmsViewDataTableController {
    @AuraEnabled
    public static List<Asf_Dynamic_Datatable_Child__mdt> getColumns(String configName) {
    return [SELECT MasterLabel,Order__c, DeveloperName ,Asf_Dynamic_Datatable_Parent__c , Api_Name__c, Data_Type__c
            FROM Asf_Dynamic_Datatable_Child__mdt
            WHERE Asf_Dynamic_Datatable_Parent__r.DeveloperName = :configName
            ORDER BY Order__c ASC]; 
}
    @AuraEnabled
    public static List<sObject> executeQuery(String caseId) {
        String dynamicQuery = getQuery() + '\'' + caseId + '\' ORDER BY Name';
        if(String.isNotBlank(dynamicQuery)) {
            try {
                return Database.query(dynamicQuery);
            } catch(Exception ex) {
                System.debug('Error executing query: ' + ex.getMessage());
                return null;
            }
        } 
        return null;
    }
     @AuraEnabled
    public static String getQuery() {
        Asf_Dynamic_Datatable_Parent__mdt  metadataRecord = [SELECT Query__c  FROM Asf_Dynamic_Datatable_Parent__mdt WHERE DeveloperName = 'Asf_DMS_File_Datatable'  LIMIT 1];
        return metadataRecord != null ? metadataRecord.Query__c : null;
    }
    @AuraEnabled
    public static String getUserBDid(String userBDid) {
        Cache.OrgPartition orgPartition = Cache.Org.getPartition('ABC');
        String cachedUserBDid = (String)orgPartition.get(userBDid);
        system.debug('cachedUserBDid '+cachedUserBDid);
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
    private static String makeApiCall(String userBDid) {
        //  API call logic will be added here
        
        // This is just a placeholder
        return 'UserBDid from API';
    }
}