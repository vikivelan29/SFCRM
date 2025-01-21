/**
 * @description       Kavach Policies
 * @author            : achuriwala@salesforce.com
 * @group             : 
 * @last modified on  : 01-11-2024
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   01-11-2024   achuriwala@salesforce.com   Initial Version
**/
public without sharing class ABHI_KavachPolicies {
    /* @LOB - ABHI
    * @Function - getPolicyData
    * @param policyNo
    * @param lanNumber
    * @param lob
    * @return  ResponseWrapper 
    * @description  This method will get legacy date and display in SF
    *****************************************************************************************************************/
    @AuraEnabled(cacheable = true)
    public static List<KavachResponseWrapper> getPolicyData(String policyNo){
       List<KavachResponseWrapper> listKavachResponse = new List<KavachResponseWrapper>();
       try{
           KavachResponseWrapper kavach = null;
           System.debug('@@@kavach1'+policyNo);
           for(Asset policyData : [SELECT ID,LAN__c,Account.Name, Account.Client_Code__c, Account.Phone,Account.PersonMobilePhone,
                                  Account.PersonEmail, Account.Office_Email__c, Account.IsPersonAccount,MasterPolicyNumber__r.LAN__c 
                                  FROM Asset WHERE LAN__c != null AND LAN__c = :policyNo]) {
                                      kavach = new KavachResponseWrapper(policyData);
                                              System.debug('@@@kavach'+kavach);

                                      listKavachResponse.add(kavach);
           }
           
        }
        catch(Exception e) {
            
        }
        System.debug('@@@listKavachResponse'+listKavachResponse);
        return listKavachResponse;
    }
    
    /* @LOB - ABHI
    * @Function - getPolicyData
    * @param policyNo
    * @param lanNumber
    * @param lob
    * @return  ResponseWrapper 
    * @description  This method will get legacy date and display in SF
    *****************************************************************************************************************/
    @AuraEnabled
    public static List<KavachResponseWrapper> getPolicyExternalData(String policyNo, String selectedSystem){
       List<KavachResponseWrapper> listKavachResponse = new List<KavachResponseWrapper>();
       ABHI_CreatePolicyWrapper.ResponseWrapper response = null;
      // try{
           String integrationName = 'ABHI_Kavach_Policy';
           String conPayload =  JSON.serialize(new KavachRequest(policyNo, null , selectedSystem));
           ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResponse = ABCL_IntegrationCallout.executeCallout(integrationName,conPayload,null);
           System.debug('@@@@response.integrationResponse'+integrationResponse);
           KavachResponse kavchResponse = (KavachResponse)JSON.deserialize(integrationResponse.responseBody, KavachResponse.class);
           Map<String, Object> kavchResponses = (Map<String, Object>)JSON.deserializeUntyped(integrationResponse.responseBody);
           if(kavchResponse.StatusCode.equals('1002')) {
                throw new AuraHandledException(kavchResponse.Message);
           }
           String createPolicyWrapper = JSON.serialize(kavchResponse.CustomerDetails[0]);
           System.debug('@@@@response.createPolicyWrapper'+createPolicyWrapper);
           response = ABHI_CreatePolicy.createPolicy(createPolicyWrapper);
           listKavachResponse = getPolicyData(policyNo);
           return listKavachResponse;
       // }
       /* catch(Exception e) {
            System.debug('@@ec'+e.getMessage()+e.getLineNumber());
           //throw new AuraHandledException(response.StatusMessage); 
        }*/
    }
    /*********************************************************
    * @Class           KavachRequest
    * @Author          Aditee Churiwala 
    * @Created Date    24/10/2024
    * @Last Modified   24/10/2024
    * @description     KavachRequest */
    public class KavachRequest {
        String PolicyNumber;
        String MasterPolicyNumber;
        String TargetSystem;
        KavachRequest(String policyNumber, String masterPolicyNumber, String selectedSystem){
            this.PolicyNumber = policyNumber;
            this.MasterPolicyNumber = masterPolicyNumber;
            this.TargetSystem = selectedSystem;
        }
    }
   /*********************************************************
    * @Class           KavachResponse
    * @Author          Aditee Churiwala 
    * @Created Date    24/10/2024
    * @Last Modified   24/10/2024
    * @description     KavachResponse */
    public class KavachResponse {
        public String StatusCode;
	    public String Message;
        List<ABHI_CreatePolicyWrapper> CustomerDetails;        
    }
	/*********************************************************
    * @Class           KavachResponseWrapper
    * @Author          Aditee Churiwala 
    * @Created Date    11/10/2024
    * @Last Modified   21/10/2024
    * @description     KavachResponseWrapper */
    public class KavachResponseWrapper {
        @AuraEnabled public String name {get;set;}
        @AuraEnabled public String accountName {get;set;}
        @AuraEnabled public String clientCode {get;set;}
        @AuraEnabled public String phone {get;set;}
        @AuraEnabled public String email {get;set;}
        @AuraEnabled public String policyNo {get;set;}
        public KavachResponseWrapper(Asset policy) {
            accountName = policy.Account.Name;
            name = policy.LAN__c;
            policyNo = '/'+policy.Id;
            clientCode = policy.Account.Client_Code__c;
            phone = policy.Account.isPersonAccount?policy.Account.PersonMobilePhone:policy.Account.Phone;
            email = policy.Account.isPersonAccount?policy.Account.PersonEmail:policy.Account.Office_Email__c;
        }
    }
}