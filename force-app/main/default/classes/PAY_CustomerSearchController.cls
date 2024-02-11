public without sharing class PAY_CustomerSearchController {
    public static final Schema.SObjectField clientCodeField = Account.Fields.Client_Code__c;
    
    @AuraEnabled
    public static List<CustomerDetailsWrapper> searchCustomerExternal(string searchTerm, string searchBasedOn){
        try{        
            return searchCustomerExt(searchTerm,searchBasedOn);
        } catch (Exception e) {
            system.debug(e);
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static List<CustomerDetailsWrapper> searchCustomerExt(string searchTerm, string searchBasedOn){
        try {
            List<CustomerDetailsWrapper> searchResultWrapper = new List<CustomerDetailsWrapper>();
            CustomerSearchRequestWrapper custSearchReqWrapper = new CustomerSearchRequestWrapper();
            custSearchReqWrapper.source_app_id = 'APP001'; 
            if(searchBasedOn == 'Phone'){
                custSearchReqWrapper.mobile_no = searchTerm;
            } else {
                custSearchReqWrapper.abc_cust_id = searchTerm;
            }
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:AWS_API_Gateway/crm-abcdpay/search');
            request.setMethod('POST');
            string requestStr = JSON.serialize(custSearchReqWrapper);
            request.setBody(requestStr);
            system.debug(requestStr);
            system.debug(request);
            Http http = new Http();
            HTTPResponse response = http.send(request);
            system.debug(response.getBody());
            string responseStr;
            if(response.getStatusCode() == 200){
                responseStr = response.getBody();
                CustomerDetailsWrapper customerSearch = new CustomerDetailsWrapper();
                CustomerSearchResponseWrapper responseWrapper = (CustomerSearchResponseWrapper)System.JSON.deserialize(responseStr,CustomerSearchResponseWrapper.class);
                system.debug(responseWrapper);
                if(responseWrapper.customer_info != null){
                    customerSearch.Name = responseWrapper.customer_info.name;
                    customerSearch.ClientCode = responseWrapper.customer_info.abc_cust_id;
                    customerSearch.Phone = responseWrapper.customer_info.mobile;
                    customerSearch.Id = responseWrapper.customer_info.abc_cust_id;
                    customerSearch.CustomerType = responseWrapper.customer_info.customer_type;
                    customerSearch.CustomerExistsInSFDC = false;
                    customerSearch.LineOfBusiness = responseWrapper.customer_info.LineOfBusiness;
                    customerSearch.CustomerSince = responseWrapper.customer_info.created;
                    searchResultWrapper.add(customerSearch);
                } else if(responseWrapper.merchant_info != null){
                    customerSearch.Name = responseWrapper.merchant_info.merchant_name;
                    customerSearch.ClientCode = responseWrapper.merchant_info.merchant_id;
                    customerSearch.Phone = responseWrapper.merchant_info.mobile;
                    customerSearch.Email = responseWrapper.merchant_info.email;
                    customerSearch.Id = responseWrapper.merchant_info.merchant_id;
                    customerSearch.ContactFirstName = responseWrapper.merchant_info.first_name;
                    customerSearch.ContactLastName = responseWrapper.merchant_info.last_name;
                    customerSearch.DoingBusinessAs = responseWrapper.merchant_info.dba;
                    customerSearch.CustomerExistsInSFDC = false;
                    customerSearch.CustomerType = responseWrapper.merchant_info.customer_type;
                    customerSearch.LineOfBusiness = responseWrapper.merchant_info.LineOfBusiness;
                    searchResultWrapper.add(customerSearch);
                }
            }
            return searchResultWrapper;
        } catch (Exception e) {
            system.debug(e);
            throw e;
        }
    }
    
    @AuraEnabled
    public static Account createCustomer(CustomerDetailsWrapper customerData){
        try{
            
            List<CustomerDetailsWrapper> customerDataList = new List<CustomerDetailsWrapper>();
            customerDataList.add(customerData);
            List<Account> accountList = createCustomerList(customerDataList);
            return accountList[0];
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static List<Account> createCustomerList(List<CustomerDetailsWrapper> customerDataList){
        try {
            String abclIntegrationUserNm = '%'+System.Label.ABCL_Integration_User_Nickname +'%';
            List<User> systemUser = [SELECT ID FROM User WHERE CommunityNickname Like : abclIntegrationUserNm];
            List<Account> accountList = new List<Account>();
            List<Contact> contactList = new List<Contact>();
            system.debug('customerDataList'+customerDataList);
            for(CustomerDetailsWrapper customerData : customerDataList){
                Account accountToInsert = new Account();
                system.debug('customerData'+customerData);
                if(customerData != null){
                    if(customerData.CustomerType == 'Individual'){
                        accountToInsert.LastName = customerData.Name;
                        accountToInsert.PersonMobilePhone = customerData.Phone;
                        accountToInsert.Line_of_Business__c = customerData.LineOfBusiness;
                        accountToInsert.Business_Unit__c = customerData.LineOfBusiness;
                        accountToInsert.Line_of_Business__pc = customerData.LineOfBusiness;
                        if(systemUser.size()>0){
                            accountToInsert.OwnerId = systemUser[0].Id;
                        }
                        if(String.isNotBlank(customerData.CustomerSince)){
                            accountToInsert.Customer_Since__pc = Date.valueof(customerData.CustomerSince);
                        }
                    } else {
                        accountToInsert.Name = customerData.Name;
                        accountToInsert.PAY_Doing_Business_As__c  = customerData.DoingBusinessAs;
                        accountToInsert.Phone = customerData.Phone;
                        accountToInsert.Line_of_Business__c = customerData.LineOfBusiness;
                        accountToInsert.Business_Unit__c = customerData.LineOfBusiness;
                        if(systemUser.size()>0){
                            accountToInsert.OwnerId = systemUser[0].Id;
                        }
                        
                    }
                    accountToInsert.Client_Code__c = customerData.ClientCode;
                    system.debug(customerData);
                    List<RecordType> recordType = [SELECT Id FROM RecordType where SObjectType = 'Account' and DeveloperName =: customerData.CustomerType];
                    if(recordType.size() > 0){
                        accountToInsert.RecordTypeId = recordType[0].Id;
                    }
                    accountList.add(accountToInsert);
                    
                    if(customerData.CustomerType != 'Individual'){
                        Id existingContactId = getCustomerContact(accountToInsert.Id,customerData);
                        Contact contactToInsert = new Contact();
                        if(existingContactId != null){
                            contactToInsert.Id = existingContactId;
                        }
                        contactToInsert.FirstName = customerData.ContactFirstName;
                        contactToInsert.LastName = customerData.ContactLastName;
                        contactToInsert.MobilePhone = customerData.Phone;
                        contactToInsert.Email = customerData.Email;
                        contactToInsert.Account = New Account(Client_Code__c=customerData.ClientCode);
                        contactList.add(contactToInsert);
                    } 
                }
            }
            
            if (!accountList.isEmpty()) {
                upsert accountList Client_Code__c;
            }
            
            if (!contactList.isEmpty()) {
                upsert contactList;
            }
            return accountList;
        } catch (Exception e) {
            throw e;
        }
    }
    private static Id getCustomerContact(Id accId,CustomerDetailsWrapper customerData){
        Id returnContactId = null;
        List<Contact> contacts = [SELECT ID FROM Contact WHERE AccountId =: accId];
        for(Contact c : contacts ){
            if(customerData.Phone != null){
                if(c.MobilePhone == customerData.Phone){
                    returnContactId = c.Id;
                    break;
                } 
            }
        }
        return returnContactId;
    }
    
    public class CustomerDetailsWrapper{
        @AuraEnabled
        public string Name{get;set;}
        @AuraEnabled
        public string Id{get;set;}
        @AuraEnabled
        public string Phone{get;set;}
        @AuraEnabled
        public string ClientCode{get;set;}
        @AuraEnabled
        public string CustomerType{get;set;}
        @AuraEnabled
        public string Email{get;set;}
        @AuraEnabled
        public string DoingBusinessAs{get;set;}
        @AuraEnabled
        public boolean CustomerExistsInSFDC{get;set;}
        @AuraEnabled
        public string ContactFirstName{get;set;}
        @AuraEnabled
        public string ContactLastName{get;set;}
        @AuraEnabled
        public string LineOfBusiness{get;set;}
        @AuraEnabled
        public string CustomerSince{get;set;}
    }
    
    public class CustomerSearchRequestWrapper{
        public string mobile_no;
        public string abc_cust_id;
        public string source_app_id;
    }
    
    public class CustomerSearchResponseWrapper{
        public MerchantInformationWrapper merchant_info;
        public CustomerInformationWrapper customer_info;
    }
    
    public class MerchantInformationWrapper {
        public string merchant_id;
        public string dba;
        public string merchant_name;
        public string first_name;
        public string last_name;
        public string mobile;
        public string email;
        public string customer_type;
        public string LineOfBusiness;
    }
    
    public class CustomerInformationWrapper {
        public string abc_cust_id;
        public string mobile;
        public string name;
        public string device_id;
        public string created;
        public string customer_type;
        public string LineOfBusiness;
    }
}