/**
 * @description       : This class will invoke from Mcrm_getPolicyDetails LWC. Used to query ABHI records (Hence without sharing)
 * @author            : Zahed
 * @group             : 
 * @last modified on  : 18/10/2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author  Modification
 * 1.0   18/10/2024   Zahed   Initial Version
**/
public without sharing  class MCRM_AssetGetPolicyDetails {
    /****************************************************************************************************************
    * @LOB - Wellness
    * @Function - getAsset Policy Details
    * @param recordId
    * @return - List<Map<String, String>>
    * @description - Invoked from the Mcrm_getPolicyDetails Lwc components to send asset policy details. 
    */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAssetData(Id recordId) {
        List<Map<String, String>> resultData = new List<Map<String, String>>();
        try{
            List<string> policyIds = new List<string>();
            Map<String,String> fieldAPIWithLabel = new Map<String,String>();
            
            // Query the Asset record with its associated Person Account
            Asset assetRecord = [SELECT Id, Account.HealthIDCardNumber__pc FROM Asset  WHERE Id = :recordId LIMIT 1];
            // Check if the HealthIDCardNumber__pc field is not null or empty
            if (assetRecord.Account != null && String.isNotEmpty(assetRecord.Account.HealthIDCardNumber__pc)) {
                // Split the comma-separated values into a List of Strings
                policyIds = assetRecord.Account.HealthIDCardNumber__pc.split(',');
            }
            
            Asf_Dynamic_Datatable_Parent__mdt parentConfigs = [SELECT Id, DeveloperName FROM Asf_Dynamic_Datatable_Parent__mdt 
                                                               WHERE DeveloperName = 'MCRM_PolicyDetails'];
            
            List<Asf_Dynamic_Datatable_Child__mdt> fieldConfigs = [SELECT Id,MasterLabel, Api_Name__c
                                                                   FROM Asf_Dynamic_Datatable_Child__mdt WHERE Asf_Dynamic_Datatable_Parent__c = :parentConfigs.Id ORDER BY Order__c ASC];
            
            for (Asf_Dynamic_Datatable_Child__mdt fieldConfig : fieldConfigs) {
                fieldAPIWithLabel.put(fieldConfig.Api_Name__c,fieldConfig.MasterLabel);
            }
            
            String queryString = 'SELECT ' + String.escapeSingleQuotes(String.join(fieldAPIWithLabel.keyset(), ', ')) + ' FROM Asset WHERE ABHI_Policy_Id__c IN :policyIds';
            List<Asset> assetRecords = Database.query(queryString);
            for (Asset asset : assetRecords) {
                Map<String, String> assetData = new Map<String, String>();
                for (String fieldName : fieldAPIWithLabel.keyset()) {
                    String fieldValue = String.valueOf(asset.get(fieldName)); // Dynamically get the field value
                    assetData.put(fieldAPIWithLabel.get(fieldName), fieldValue != null ? fieldValue : 'N/A');
                }
                
                resultData.add(assetData);
            }
        }catch(exception ex){
            ABCL_Logger.logException('MCRM_AssetGetPolicyDetails.getAssetData',ex.getMessage());
            throw new AuraHandledException('Error : '+ex.getMessage());
        }
        return resultData;
    }
}