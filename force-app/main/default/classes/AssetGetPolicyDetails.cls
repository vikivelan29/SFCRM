/*********************************************************
*Class        :  AssetGetPolicyDetails 
*Author       :  Zahed
*Created Date :  18/10/2024
*Last Modified:  
*Description  :  This class will invoke from Mcrm_getPolicyDetails LWC. 
*Test Class    : AssetGetPolicyDetails_Test
*********************************************************/
public with sharing  class AssetGetPolicyDetails {
    /****************************************************************************************************************
    * @LOB - Wellness
    * @Function - getAsset Policy Details
    * @param - Asset Id.
    * @return - List<Map<String, String>> Collection list of asset policy Label with Value.
    * @description - Invoked from the Mcrm_getPolicyDetails Lwc components to send asset policy details.
    *****************************************************************************************************************/
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAssetData(Id recordId) {
        List<Map<String, String>> resultData = new List<Map<String, String>>();
        try{
            List<string> policyIds = new List<string>();
            Map<String,String> fieldAPIWithLabel = new Map<String,String>();
            
            // Query the Asset record with its associated Person Account
            Asset assetRecord = [SELECT Id, Customer__r.HealthIDCardNumber__pc FROM Asset  WHERE Id = :recordId LIMIT 1];
            
            // Check if the HealthIDCardNumber__pc field is not null or empty
            if (assetRecord.Customer__c != null && String.isNotEmpty(assetRecord.Customer__r.HealthIDCardNumber__pc)) {
                // Split the comma-separated values into a List of Strings
                policyIds = assetRecord.Customer__r.HealthIDCardNumber__pc.split(',');
            }
            
            Asf_Dynamic_Datatable_Parent__mdt parentConfigs = [SELECT Id, DeveloperName FROM Asf_Dynamic_Datatable_Parent__mdt 
                                                               WHERE DeveloperName = 'MCRM_PolicyDetails'];
            
            List<Asf_Dynamic_Datatable_Child__mdt> fieldConfigs = [SELECT Id,MasterLabel, Api_Name__c
                                                                   FROM Asf_Dynamic_Datatable_Child__mdt WHERE Asf_Dynamic_Datatable_Parent__c = :parentConfigs.Id ORDER BY Order__c ASC];
            
            for (Asf_Dynamic_Datatable_Child__mdt fieldConfig : fieldConfigs) {
                fieldAPIWithLabel.put(fieldConfig.Api_Name__c,fieldConfig.MasterLabel);
            }
            
            String queryString = 'SELECT ' + String.join(fieldAPIWithLabel.keyset(), ', ') + ' FROM Asset WHERE ABHI_Policy_Id__c IN :policyIds';
            List<Asset> assetRecords = Database.query(queryString);
            system.debug('assetRecords-->'+assetRecords.size());        
            for (Asset asset : assetRecords) {
                Map<String, String> assetData = new Map<String, String>();
                for (String fieldName : fieldAPIWithLabel.keyset()) {
                    String fieldValue = String.valueOf(asset.get(fieldName)); // Dynamically get the field value
                    assetData.put(fieldAPIWithLabel.get(fieldName), fieldValue != null ? fieldValue : 'N/A');
                }
                
                resultData.add(assetData);
            }
            system.debug('resultData-->'+resultData);            
        }catch(exception e){
            system.debug('Error=='+e.getMessage());            
        }
        return resultData;
    }
}