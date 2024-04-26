public with sharing class Asf_DmsViewDataTableController {
    @AuraEnabled(cacheable=true)
    public static List<ASF_DMSView_Configurtion__mdt> getColumns() {
    return [SELECT MasterLabel,Order__c, DeveloperName, Api_Name__c, Data_Type__c
            FROM ASF_DMSView_Configurtion__mdt
            WHERE DeveloperName != 'Query'
            ORDER BY Order__c ASC];
}
    @AuraEnabled(cacheable=true)
    public static List<sObject> executeQuery(String caseId) {
        String dynamicQuery = getQuery() + '\'' + caseId + '\'';
        if(String.isNotBlank(dynamicQuery)) {
            try {
                return Database.query(dynamicQuery);
            } catch(Exception ex) {
                // Handle any exceptions here
                System.debug('Error executing query: ' + ex.getMessage());
                return null;
            }
        } 
        return null;
    }
     @AuraEnabled(cacheable=true)
    public static String getQuery() {
        ASF_DMSView_Configurtion__mdt metadataRecord = [SELECT Api_Name__c FROM ASF_DMSView_Configurtion__mdt WHERE DeveloperName = 'Query'  LIMIT 1];
        return metadataRecord != null ? metadataRecord.Api_Name__c : null;
    }
    @AuraEnabled(cacheable=true)
    public static String getUserBDid(String userBDid) {
        Cache.OrgPartition orgPartition = Cache.Org.getPartition('ABC');
        String cachedUserBDid = (String)orgPartition.get(userBDid);
        system.debug('cachedUserBDid '+cachedUserBDid);
        if (cachedUserBDid != null) {
            return cachedUserBDid;
        } 
        else {
        	ASF_DMSView_Configurtion__mdt cacheSettings = ASF_DMSView_Configurtion__mdt.getInstance('Query');
			Integer cacheTimeoutSeconds = cacheSettings.Order__c.intValue();
            //String apiResponse = makeApiCall(userBDid);
            orgPartition.put(userBDid, 'ABCDEFGH', cacheTimeoutSeconds); 
            String cachedValue = (String)orgPartition.get(userBDid);
        	return cachedValue;
           // return apiResponse;
        }
    }
    private static String makeApiCall(String userBDid) {
        //  API call logic goes here
        // This is just a placeholder
        return 'UserBDid from API';
    }
}