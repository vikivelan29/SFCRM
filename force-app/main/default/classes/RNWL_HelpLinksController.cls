/*****************************************************************************************
*Class        :  RNWL_HelpLinksController
*Author       :  Joshna
*Created Date :  16/10/2024
*Last Modified:  16/10/2024
*@description  : This class is used to get dynamic link for Auto Calculation quick link
*****************************************************************************************/
public class RNWL_HelpLinksController {
    
    @AuraEnabled(cacheable=true)
    public static String getAutoCalculationLink(Id recordId){
        try{
            if(recordId != null){
                Opportunity opp = [SELECT ID,Policy_Number__c ,AccountId,Account.Phone FROM Opportunity WHERE ID =: recordId];
                String link = System.Label.RNWL_Auto_Calculation ;
                String algorithmName = 'AES128';
                String exampleIV = 'Example of IV24';
                Blob key = Blob.valueOf(System.Label.RNWL_Auto_Calculation_Private_Key);
                Blob policyValue = Blob.valueOf(opp.Policy_Number__c);
                Blob policyEncrypted = Crypto.encryptWithManagedIV(algorithmName, key, policyValue);
                String policyEncryptedString = EncodingUtil.base64Encode(policyEncrypted);
                String mobileEncryptedString = '';
                if(opp.AccountId != null && opp.Account.Phone !=null){
                    Blob mobileValue = Blob.valueOf(opp.Account.Phone);
                	Blob mobileEncrypted = Crypto.encryptWithManagedIV(algorithmName, key, mobileValue);
                    mobileEncryptedString = EncodingUtil.base64Encode(mobileEncrypted);
                } 
                Blob sourceValue = Blob.valueOf('Salesforce');
                Blob sourceEncrypted = Crypto.encryptWithManagedIV(algorithmName, key, sourceValue);
                String sourceEncryptedString = EncodingUtil.base64Encode(sourceEncrypted);
                String finalLink = link + 'p=' + policyEncryptedString + '&m=' + mobileEncryptedString + '&d=&s=' + sourceEncryptedString;
                system.debug('***** finalLink ' + finalLink);
                return finalLink;
            }
            return null;
        }catch (Exception e) {
            system.debug(e.getMessage());
            system.debug(e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }       
    }

}