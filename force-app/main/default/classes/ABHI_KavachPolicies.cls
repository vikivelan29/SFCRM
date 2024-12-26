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
    @AuraEnabled
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
           //Check on Integration record if request to Jarvis is in pending stage
           if(listKavachResponse.isEmpty()) {
               System.debug('@@@kavach1'+kavach);
              for(ASF_Case_Integration__c caseIntg: [SELECT Policy_Number__c, Status__c,Response__c  FROM ASF_Case_Integration__c
                                                     WHERE Policy_Number__c = :policyNo AND Type__c = 'Kavach'
                                                     ORDER BY CreatedDate DESC LIMIT 1]) {
                                                      	 System.debug('@@@kavach1'+kavach);
                                                         kavach = new KavachResponseWrapper(caseIntg.Response__c, caseIntg.Status__c);
                                                         
                                                         listKavachResponse.add(kavach);
                                                     }
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
    public static void getPolicyExternalData(String policyNo, String selectedSystem){
       List<KavachResponseWrapper> listKavachResponse = new List<KavachResponseWrapper>();
       ABHI_CreatePolicyWrapper.ResponseWrapper response = null;
       try{
           String integrationName = 'JARVIS_KAVACH';
         //  String conPayload =  JSON.serialize(new KavachRequest(policyNo, null , selectedSystem));
         //  ABCL_IntegrationCallout.IntegrationResponseWrapper integrationResponse = ABCL_IntegrationCallout.executeCallout(integrationName,conPayload,null);
           List<ASF_Case_Integration__c> aciPending = new List<ASF_Case_Integration__c>();
           aciPending = [SELECT Policy_Number__c, Status__c,Response__c  
                                                           FROM ASF_Case_Integration__c
                                                           WHERE Policy_Number__c = :policyNo AND Type__c = 'Kavach'
                                                           AND Status__c = 'Pending'];

           for(ASF_Case_Integration__c aci: aciPending){
                aci.Status__c = 'Canceled';
           }
           
           ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
           caseInt.Policy_Number__c  = policyNo;
           caseInt.Integration_Ext_Id__c = integrationName;
           caseInt.Status__c = ABFL_Constants.PENDING;
           caseInt.Type__c = 'Kavach';
           caseInt.Response__c = ABFL_Constants.WAITING_API_RESPONSE;

           aciPending.add(caseInt);
           
           upsert aciPending;
           Map<String, Object> payloadWrap = new Map<String, Object>{ 
                                                                'PolicyNumber' => policyNo, 
                                                                'MasterPolicyNumber' => null,
                                                                'TargetSystem' => selectedSystem
                                                            };

            // publish event
           EventBus.publish(
               new Case_Integration_Outbound__e (
                   Business_Unit__c  = ABHI_Constants.ABHI,
                   Case_Integration_ID__c = caseInt.Name,
                   ServiceName__c = integrationName,
                   Integration_Name__c  = integrationName,
                   Request_Payload__c  =  JSON.serialize(payloadWrap)
               ) 
           );
        }
        catch(Exception e) {
            System.debug('@@ec'+e.getMessage()+e.getLineNumber());
            //throw new AuraHandledException(response.StatusMessage); 
        }
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
        @AuraEnabled public String message {get;set;}
        @AuraEnabled public String status {get;set;}
        public KavachResponseWrapper(String message, String status) {
            this.message = message;
            this.status = status;
        }
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