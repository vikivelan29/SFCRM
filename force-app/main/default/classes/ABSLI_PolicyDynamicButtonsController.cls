public with sharing class ABSLI_PolicyDynamicButtonsController {
    @AuraEnabled(cacheable =false)
    public static String getServAceUrl(String policyId){
        Asset asst = [SELECT ID,Policy_No__c FROM Asset WHERE Id =: policyId AND Business_Unit__c =: ABSLI_Constants.BUSINESS_UNIT];
        User usr = [SELECT ID,FederationIdentifier,Business_Unit__c FROM User WHERE Id =: UserInfo.getUserId()];
        if(usr.Business_Unit__c == ABSLI_Constants.BUSINESS_UNIT){
            String staticUrl = System.Label.ABSLI_ARS_URL;//'https://ikshauat.adityabirlasunlifeinsurance.com/App/CustomerDataScreen.cshtml?';
            String policyNum = asst.Policy_No__c;
            String usrADID = usr.FederationIdentifier;
            String encryptedPolicyNum = getEncryptedValue(policyNum);
            String encryptedUsrADID = 'DEFAULT';
            if(usrADID != null)
	            encryptedUsrADID = getEncryptedValue(usrADID);
            if(string.isnotBlank(usrADID)){
                staticUrl += 'uid='+usrADID;
            }
            else{
                staticUrl += 'uid=NA';
            }
            
            staticUrl += '&policyno='+encryptedPolicyNum;
            return staticUrl;
        }
        return '';
        
    }
    public static String getEncryptedValue(String toEncrypt){
        Blob exampleIv = Blob.valueOf(Label.ABSLI_ARS_IV_VALUE);
        Blob key = Blob.ValueOf(Label.ABSLI_ARS_IV_KEY);
        Blob data = Blob.valueOf(toEncrypt);
        Blob encrypted = Crypto.encrypt('AES128', key, exampleIv, data);
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