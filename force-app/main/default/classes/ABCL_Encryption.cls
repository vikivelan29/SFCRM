/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 03-19-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   02-24-2024   rsinghnagar@salesforce.com   Initial Version
**/
public with sharing Class ABCL_Encryption{
    /*
    todo: Get key and IV details from custom metadata type
    1. Create new field on ABCL_Integrations__mdt to store key and IV. Fetch and use these values to encrypt/decrypt enach request/response.
    2. Create new fields as required for eNach Registration/Response use cases on case extension object.
    3. 
    */
	// EncodingUtil.base64Encode(Crypto.generateAesKey(256))
	// public static final String AES_KEY = 'QVyg0S3DZ3GuYsxECIe9iEo+NGsQL4hhB1T8ugPkz+A='; 
    private static ABCL_Integrations__mdt eNachInt;
    public static ABCL_Integrations__mdt getENachInt(){
        if(eNachInt==null){
            eNachInt = ABCL_Integrations__mdt.getInstance('ABFL_Enach');
        }
        return eNachInt;
    }
	public static final String AES_KEY = getENachInt().Int_Key__c; 
	// EncodingUtil.base64Encode(Crypto.generateAesKey(128))
  	// public static final String AES_IV = 'lKOvnQbveCQ09UcGGQREiA==';
  	public static final String AES_IV = getENachInt().Int_IV__c;
	public static String encrypt(String dataToEncrypt) {
        // Call Crypto.encryptWithManagedIV specifying the selected AES Algorithm
        Blob encryptedData = Crypto.encrypt(
        	'AES256',
            EncodingUtil.base64Decode(AES_KEY),
            EncodingUtil.base64Decode(AES_IV),
            Blob.valueOf(dataToEncrypt)
        );
        return EncodingUtil.base64Encode(encryptedData);
    }

    public static String decrypt(String dataToDecrypt) {
        // Call Crypto.encryptWithManagedIV specifying the selected AES Algorithm
        Blob decryptedData = Crypto.decrypt(
        	'AES256',
            EncodingUtil.base64Decode(AES_KEY),
            EncodingUtil.base64Decode(AES_IV),
            EncodingUtil.base64Decode(dataToDecrypt)
        );
        return decryptedData.toString();
    }
}

// // decrypt
// String AES_KEY = 'QVyg0S3DZ3GuYsxECIe9iEo+NGsQL4hhB1T8ugPkz+A='; 
// String AES_IV = 'lKOvnQbveCQ09UcGGQREiA==';
// System.debug(Crypto.decrypt(
//     'AES256',
//     EncodingUtil.base64Decode(AES_KEY),
//     EncodingUtil.base64Decode(AES_IV),
//     EncodingUtil.base64Decode('fUwyfCHRawV/vMmRy84N+g==') // decrypt this
// ).toString());