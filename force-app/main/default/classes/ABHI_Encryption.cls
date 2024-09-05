/*********************************************************
*Class        :  ABHI_Encryption
*Author       :  Amrit Preet Singh
*Created Date :  19/08/2024
*Last Modified:  19/08/2024
*@description  :  This class is a util class to encrypt or decrypt the data
*@description  :  This will use the metadata to get the Key and IV for encyptiona nd decryption.
*********************************************************/
public with sharing class ABHI_Encryption {
    /* @description get Enach Int
    *****************************************************************************************************************/
    private static ABCL_Integrations__mdt eNachInt;
     /****************************************************************************************************************
    * @Function - getENachInt
    * @param metadataName - Name of the metadata
    * @return ABCL_Integrations__mdt
    * @description get Enach
    *****************************************************************************************************************/
    public static ABCL_Integrations__mdt getENachInt(String metadataName){
        if(eNachInt==null){
            eNachInt = ABCL_Integrations__mdt.getInstance(metadataName);
        }
        return eNachInt;
    }
    /****************************************************************************************************************
    * @Function - encrypt
    * @return String
    * @param dataToEncrypt 
    * @param metadataName - Name of the metadata
    * @description encrypt
    *****************************************************************************************************************/
	public static String encrypt(String dataToEncrypt, String metadataName) {
        // Call Crypto.encryptWithManagedIV specifying the selected AES Algorithm
        String AES_KEY = getENachInt(metadataName).Int_Key__c;
        String AES_IV = getENachInt(metadataName).Int_IV__c;
        Blob encryptedData = Crypto.encrypt(
        	'AES256',
            EncodingUtil.base64Decode(AES_KEY),
            EncodingUtil.base64Decode(AES_IV),
            Blob.valueOf(dataToEncrypt)
        );
        return EncodingUtil.base64Encode(encryptedData);
    }
     /****************************************************************************************************************
    * @Function - decrypt
    * @return String
    * @param dataToDecrypt 
    * @param metadataName - Name of the metadata
    * @description decrypt
    *****************************************************************************************************************/
    public static String decrypt(String dataToDecrypt, String metadataName) {
        // Call Crypto.encryptWithManagedIV specifying the selected AES Algorithm
        String AES_KEY = getENachInt(metadataName).Int_Key__c;
        String AES_IV = getENachInt(metadataName).Int_IV__c;
        Blob decryptedData = Crypto.decrypt(
        	'AES256',
            EncodingUtil.base64Decode(AES_KEY),
            EncodingUtil.base64Decode(AES_IV),
            EncodingUtil.base64Decode(dataToDecrypt)
        );
        return decryptedData.toString();
    }
}