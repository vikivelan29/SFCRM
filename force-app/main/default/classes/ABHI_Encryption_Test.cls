/**
 * @description       : Test Class for ABHI_Encryption
 * @author            : Amrit Preet Singh
 * @group             : 
 * @last modified on  : 19/08/2024
 * @last modified by  : Amrit Preet Singh 1
 * Modifications Log
 * Ver   Date         Author                            Modification
 * 1.0   19-06-2024   amritpreet.singh@salesforce.com   Initial Version
**/
@isTest
public class ABHI_Encryption_Test {
    
    @isTest
    static void testEncryption(){
        String dataToEncrypt = 'Testing';
        Test.startTest();
        String encryptedData = ABHI_Encryption.encrypt(dataToEncrypt, 'ABHI_DeviceDetails');
        Test.stopTest();
        System.assertNotEquals(encryptedData, dataToEncrypt);
        System.assertEquals('CY7vI4BsCVyNp9kGeUckcw==', encryptedData);
    }

    @isTest
    static void testDecryption(){
        String dataToDecrypt = 'CY7vI4BsCVyNp9kGeUckcw==';
        Test.startTest();
        String DecryptedData = ABHI_Encryption.decrypt(dataToDecrypt, 'ABHI_DeviceDetails');
        Test.stopTest();
        System.assertNotEquals(DecryptedData, dataToDecrypt);
        System.assertEquals('Testing', DecryptedData);
    }
}