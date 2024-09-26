public with sharing class ABSLI_PolicyDynamicButtonsController {
    @AuraEnabled(cacheable = false)
    public static String getReadyReckUrl(String policyId){
        Asset asst = [SELECT ID,Policy_No__c FROM Asset WHERE Id =: policyId AND Business_Unit__c =: ABSLI_Constants.BUSINESS_UNIT];
        User usr = [SELECT ID,FederationIdentifier,Business_Unit__c FROM User WHERE Id =: UserInfo.getUserId()];
        if(usr.Business_Unit__c == ABSLI_Constants.BUSINESS_UNIT){
            String staticUrl = System.Label.ABSLI_Ready_Reck_URL;//http://10.155.8.204:94/rtpWS/
            String policyNum = asst.Policy_No__c;
            String usrADID = Label.ABSLI_READY_RECK_USR;
            String IV = Label.ABSLI_READY_RECK_IV;
            String KEY = Label.ABSLI_READY_RECK_KEY;
            String toBeEncrypted = usrADID +':'+policyNum;
            String encryptedPolicyNum = getEncryptedValue(toBeEncrypted,IV,KEY,'AES256');
            if(encryptedPolicyNum != null)
                staticUrl += encryptedPolicyNum;
            
            return staticUrl;
        }
        return '';
        
        
    }
    @AuraEnabled(cacheable =false)
    public static String getServAceUrl(String policyId){
        Asset asst = [SELECT ID,Policy_No__c FROM Asset WHERE Id =: policyId AND Business_Unit__c =: ABSLI_Constants.BUSINESS_UNIT];
        User usr = [SELECT ID,FederationIdentifier,Business_Unit__c FROM User WHERE Id =: UserInfo.getUserId()];
        if(usr.Business_Unit__c == ABSLI_Constants.BUSINESS_UNIT){
            String staticUrl = System.Label.ABSLI_ARS_URL;//'https://ikshauat.adityabirlasunlifeinsurance.com/App/CustomerDataScreen.cshtml?';
            String policyNum = asst.Policy_No__c;
            String usrADID = usr.FederationIdentifier;
            String IV = Label.ABSLI_ARS_IV_VALUE;
            String KEY = Label.ABSLI_ARS_IV_KEY;
            String encryptedPolicyNum = getEncryptedValue(policyNum,IV,KEY,'AES256');
            String encryptedUsrADID = 'DEFAULT';
            if(usrADID != null)
                encryptedUsrADID = getEncryptedValue(usrADID,IV,KEY,'AES256');
            if(string.isnotBlank(usrADID)){
                staticUrl += 'uid='+encryptedUsrADID;
            }
            else{
                staticUrl += 'uid=NA';
            }
            
            staticUrl += '&policyno='+encryptedPolicyNum;
            return staticUrl;
        }
        return '';
        
    }
    public static String getEncryptedValue(String toEncrypt, String IV,String KeyVal,String algoVal){
        Blob exampleIv = Blob.valueOf(IV);
        Blob key = Blob.ValueOf(KeyVal);
        Blob data = Blob.valueOf(toEncrypt);
        Blob encrypted = Crypto.encrypt(algoVal, key, exampleIv, data);
        String encyrptedString = EncodingUtil.base64Encode (encrypted);
        return encyrptedString;
    }
    @AuraEnabled(cacheable =false) 
    public static String getCommunicationLink(String policyId){
        Asset asst = [SELECT ID,Policy_No__c FROM Asset WHERE Id =: policyId AND Business_Unit__c =: ABSLI_Constants.BUSINESS_UNIT];
        String baseUrl = Label.ABSLI_Communication_Link;
        baseUrl += '?PolicyNo='+asst.Policy_No__c;
        return baseUrl;
    }
    
}