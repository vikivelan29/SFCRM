/******************************************************************************************
 * Class         :  RNWL_HelpLinksController
 * Author        :  Joshna
 * Created Date  :  16/10/2024
 * Description   :  This class is used to get dynamic link for Auto Calculation quick link
*******************************************************************************************/
public with sharing class RNWL_HelpLinksController {
    @AuraEnabled(cacheable=true)
    public static String getAutoCalculationLink(Id recordId) {
        try{
            if(recordId == null) {
                return null;
            }
            Opportunity opp = [SELECT Id, Policy_Number__c, AccountId, Account.Phone FROM Opportunity WHERE Id = :recordId];
            String link = System.Label.RNWL_Auto_Calculation ;
            String algorithmName = 'AES128';
            Blob key = Blob.valueOf(System.Label.RNWL_Auto_Calculation_Private_Key);
            Blob ivParam = key;
            Blob policyValue = Blob.valueOf(opp.Policy_Number__c);
            Blob policyEncrypted = Crypto.encrypt(algorithmName, key, ivParam, policyValue);
            String policyEncryptedString = EncodingUtil.base64Encode(policyEncrypted);
            String mobileEncryptedString = '';
            if(opp.AccountId != null && opp.Account.Phone !=null) {
                Blob mobileValue = Blob.valueOf(opp.Account.Phone);
                Blob mobileEncrypted = Crypto.encrypt(algorithmName, key, ivParam, mobileValue);
                mobileEncryptedString = EncodingUtil.base64Encode(mobileEncrypted);
            } 
            Blob sourceValue = Blob.valueOf('Salesforce');
            Blob sourceEncrypted = Crypto.encrypt(algorithmName, key, ivParam, sourceValue);
            String sourceEncryptedString = EncodingUtil.base64Encode(sourceEncrypted);
            String finalLink = link + 'p=' + policyEncryptedString + '&m=' + mobileEncryptedString + '&d=&s=' + sourceEncryptedString;
            return finalLink;
        } catch (Exception e) {
            system.debug(e.getMessage());
            system.debug(e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }       
    }
}