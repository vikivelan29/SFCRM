/**
* @description       ABCD Customer Info 
* @author            : aditya.mehrotra@salesforce.com
* @group             : 
* @last modified on  : 18-11-2024
* @last modified by  : aditya.mehrotra@salesforce.com
* Modifications Log
* Ver   Date         Author                       Modification
* 1.0   18-11-2024   aditya.mehrotra@salesforce.com   Initial Version
**/
public without sharing class ABCD_CustomerInfoController {
    public static Map<String,String> mFieldDefinitions = new Map<String,String>();
    
    @AuraEnabled
    public static List<CustomerInfo> searchCustomerExternal(string searchTerm, string searchBasedOn){
        try{        
            return searchCustomerExt(searchTerm,searchBasedOn);
        } catch (Exception e) {
            system.debug(e);
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<CustomerInfo> searchCustomerExt(string searchTerm, string searchBasedOn){
        try {
            CustomerInfoResponseWrapper customerInfoResWrapper;
            List<CustomerInfo> searchResultWrapper = new List<CustomerInfo>();
            String payload;
            if(searchBasedOn == 'Phone'){
                payload = JSON.serialize(new CustomerInfoRequest('','',searchTerm));
            } else if(searchBasedOn == 'Email'){
                payload = JSON.serialize(new CustomerInfoRequest('',searchTerm,''));
            }else{
                payload = JSON.serialize(new CustomerInfoRequest(searchTerm,'',''));
            }
            String integrationName = 'ABCD_Get_Customer_Info';
            ABCL_IntegrationCallout.IntegrationResponseWrapper custInfoResponse = ABCL_IntegrationCallout.executeCallout(integrationName,payload,null);
            if(custInfoResponse.statusCode == 200 && String.isNotBlank(custInfoResponse.responseBody)){
                customerInfoResWrapper = (CustomerInfoResponseWrapper)JSON.deserialize(custInfoResponse.responseBody,CustomerInfoResponseWrapper.class);
                if(customerInfoResWrapper.basicInfo != null){
                    CustomerInfo baseInfo = new CustomerInfo();
                    baseInfo = customerInfoResWrapper.basicInfo;
                    baseInfo.lob = System.Label.ABCD_Business_Unit;
                    searchResultWrapper.add(baseInfo);
                }
            }
            return searchResultWrapper;
        } catch (Exception e) {
            throw new AuraHandledException('Error : '+e.getMessage()+' '+e.getLineNumber());
        }
    }
    
    @AuraEnabled
    public static Account createCustomer(CustomerInfo customerData){
        try{
            
            List<CustomerInfo> customerDataList = new List<CustomerInfo>();
            customerDataList.add(customerData);
            List<Account> accountList = createCustomerList(customerDataList);
            return accountList[0];
        }catch(Exception e){
            throw e;
        }
    }
    
    public static List<Account> createCustomerList(List<CustomerInfo> customerDataList){
        try {
            String abclIntegrationUserNm = '%'+System.Label.ABCL_Integration_User_Nickname +'%';
            List<User> systemUser = [SELECT ID FROM User WHERE CommunityNickname Like : abclIntegrationUserNm];
            List<Account> accountList = new List<Account>();
            for(CustomerInfo customerData : customerDataList){
                Account accountToInsert = new Account();
                if(customerData != null){
                    accountToInsert.LastName = customerData.customerName;
                    accountToInsert.PersonMobilePhone = customerData.mobileNumber;
                    accountToInsert.PersonEmail = customerData.emailId;
                    accountToInsert.PAN__c = customerData.pan;
                    accountToInsert.PersonBirthdate = String.isNotBlank(customerData.dob)?Date.valueof(customerData.dob):null;
                    accountToInsert.Line_of_Business__c = System.Label.ABCD_Business_Unit;
                    accountToInsert.Business_Unit__c = System.Label.ABCD_Business_Unit;
                    accountToInsert.Line_of_Business__pc = System.Label.ABCD_Business_Unit;
                    accountToInsert.Business_Unit__pc = System.Label.ABCD_Business_Unit;
                    if(systemUser.size()>0){
                        accountToInsert.OwnerId = systemUser[0].Id;
                    }
                    accountToInsert.Client_Code__c = customerData.customerId;
                    accountToInsert.LOB_Client_Code__c = System.Label.ABCD_Business_Unit+'_'+customerData.customerId;
                    List<RecordType> recordType = [SELECT Id FROM RecordType where SObjectType = 'Account' and DeveloperName ='Individual'];
                    if(recordType.size() > 0){
                        accountToInsert.RecordTypeId = recordType[0].Id;
                    }
                    accountList.add(accountToInsert);
                }
            }
            
            if (!accountList.isEmpty()) {
                upsert accountList LOB_Client_Code__c;
            }
            return accountList;
        } catch (Exception e) {
            throw e;
        }
    }  
    
    @AuraEnabled
    public static String getTabData(String tabLabel, String recordId){
        string response;
        Account accRec = [SELECT Id, Name, PersonMobilePhone, PersonEmail, Client_Code__c FROM Account WHERE Id=:recordId LIMIT 1];
        String payload = JSON.serialize(new CustomerInfoRequest(accRec.Client_Code__c, accRec.PersonEmail, accRec.PersonMobilePhone));
        if (tabLabel == 'Asset Holdings'){
            ABCL_IntegrationCallout.IntegrationResponseWrapper assetHoldingsResponse = ABCL_IntegrationCallout.executeCallout('ABCD_Customer_Asset_Holdings',payload,null);
            if(assetHoldingsResponse.statusCode == 200 && String.isNotBlank(assetHoldingsResponse.responseBody)){
                response = assetHoldingsResponse.responseBody;
            }
        } else if(tabLabel == 'Liabilities'){
            ABCL_IntegrationCallout.IntegrationResponseWrapper liabilitiesResponse = ABCL_IntegrationCallout.executeCallout('ABCD_Customer_Liabilities_Holdings',payload,null);
            if(liabilitiesResponse.statusCode == 200 && String.isNotBlank(liabilitiesResponse.responseBody)){
                response = liabilitiesResponse.responseBody;
            }
        } else if(tabLabel == 'Protection'){
            ABCL_IntegrationCallout.IntegrationResponseWrapper protectionResponse = ABCL_IntegrationCallout.executeCallout('ABCD_Customer_Protection_Holdings',payload,null);
            if(protectionResponse.statusCode == 200 && String.isNotBlank(protectionResponse.responseBody)){
                response = protectionResponse.responseBody;
            }
        } else if(tabLabel == 'VAS'){
            ABCL_IntegrationCallout.IntegrationResponseWrapper vasResponse = ABCL_IntegrationCallout.executeCallout('ABCD_Customer_VAS_Holdings',payload,null);
            if(vasResponse.statusCode == 200 && String.isNotBlank(vasResponse.responseBody)){
                response = vasResponse.responseBody;
            }
        }
        return response;
    }

    public class CustomerInfoRequest{
        String customerId;
        String emailId ;
        String mobileNumber;
        public CustomerInfoRequest(String custId, String email, String mob){
            this.customerId = custId;
            this.emailId = email;
            this.mobileNumber = mob;
        }
    }
    
    public class CustomerInfoResponseWrapper{
        @AuraEnabled
        public String code{get;set;}
        @AuraEnabled
        public String message{get;set;}
        @AuraEnabled
        public String status{get;set;}
        @AuraEnabled
        public CustomerInfo basicInfo{get;set;}
    }
    
    public class CustomerInfo{
        @AuraEnabled
        public String customerName{get;set;}
        @AuraEnabled
        public String mobileNumber{get;set;}
        @AuraEnabled
        public String customerId{get;set;}
        @AuraEnabled
        public String emailId{get;set;}
        @AuraEnabled
        public String age{get;set;}
        @AuraEnabled
        public String dob{get;set;}
        @AuraEnabled
        public String pan{get;set;}
        @AuraEnabled
        public String lob{get;set;}
    }
}