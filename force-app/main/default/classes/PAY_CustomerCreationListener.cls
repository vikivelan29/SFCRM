public without sharing class PAY_CustomerCreationListener {
    public static final Schema.SObjectField clientCodeField = Account.Fields.Client_Code__c;
    
    public static void processEvents(List<PAY_Staging_Customer_to_Account__e> newEvents) {
        List<Account> accountsToInsert = new List<Account>();
        List<Contact> contactsToInsert = new List<Contact>();
        Set<String> clientCodes = new Set<String>();
        List<merchantContact> contactDataList = new List<merchantContact>();
        String abclIntegrationUserNm = '%'+System.Label.ABCL_Integration_User_Nickname +'%';
        List<User> systemUser = [SELECT ID FROM User WHERE CommunityNickname Like : abclIntegrationUserNm];
        
        Map<String,List<Contact>> clientCodeVsContacts = new Map<String,List<Contact>>();
        for (PAY_Staging_Customer_to_Account__e event : newEvents) {
            clientCodes.add(event.Merchant_Id__c);
        }
        
        for(Contact c : [SELECT ID,FirstName,LastName,Line_Of_Business__c,MobilePhone,Email,Account.Client_Code__c FROM Contact WHERE Account.Client_Code__c =: clientCodes]){
            if(!clientCodeVsContacts.containsKey(c.Account.Client_Code__c)){
                clientCodeVsContacts.put(c.Account.Client_Code__c,new List<Contact>());
            }
            clientCodeVsContacts.get(c.Account.Client_Code__c).add(c);
        }
        
        for (PAY_Staging_Customer_to_Account__e event : newEvents) {
            if (event.Merchant_Contact_Payload__c != null) {
                
                try{
                    contactDataList = parsePAY_ContactData(event.Merchant_Contact_Payload__c);
                }
                catch(Exception e){
                    System.debug(e.getMessage());
                }
            }
            
            Account newAccount = new Account();
            newAccount.Line_Of_Business__c = event.Line_of_Business__c;
            newAccount.Business_Unit__c = event.Line_of_Business__c;
            if(systemUser.size()>0){
                newAccount.OwnerId = systemUser[0].Id;
            }
            
            if (event.Customer_Type__c == 'Individual') {
                newAccount.RecordTypeId = getRecordTypeId('Individual');
                newAccount.Client_Code__c = event.ABC_Cust_Id__c;
                if(event.Mobile__c != null)
                    newAccount.PersonMobilePhone = event.Mobile__c;
                if(event.Email__c != null)
                    newAccount.PersonEmail = event.Email__c;
                if(event.Customer_Since__c != null)
                    newAccount.Customer_Since__pc = event.Customer_Since__c;
                
                newAccount.FirstName = event.First_Name__c;
                newAccount.LastName = event.Last_Name__c;
                newAccount.Line_Of_Business__pc = event.Line_of_Business__c;
                
            } else if (event.Customer_Type__c == 'Non-Individual') {
                newAccount.RecordTypeId = getRecordTypeId('Non-Individual');
                newAccount.PAY_Doing_Business_As__c = event.Doing_Business_As__c;
                newAccount.Client_Code__c = event.Merchant_Id__c;
                newAccount.Name = event.Merchant_Name__c;
            }
            
            for (merchantContact contactData : contactDataList) {
                Contact newContact = new Contact();
                newContact.Account = New Account(Client_Code__c=event.Merchant_Id__c); 
                newContact.Line_of_Business__c = event.Line_of_Business__c;
                newContact.FirstName = contactData.FirstName;
                newContact.LastName = contactData.LastName;
                if(systemUser.size()>0){
                    newContact.OwnerId = systemUser[0].Id;
                }
                
                if(clientCodeVsContacts.containsKey(event.Merchant_Id__c)){
                    // Check if the Customer Contact is already present in System.
                    for(Contact c : clientCodeVsContacts.get(event.Merchant_Id__c)){
                        if(c.MobilePhone == contactData.MobilePhone){
                            newContact.Id = c.Id;
                        }
                    } 
                }
                newContact.MobilePhone = contactData.MobilePhone;
                newContact.Email = contactData.Email;
                contactsToInsert.add(newContact);
            }
            accountsToInsert.add(newAccount);
        }
        
        Database.UpsertResult[] accountList = new List<Database.UpsertResult>();
        List<STG_Customer__c> updateStgStatus = new List<STG_Customer__c>();
        
        
        if (!accountsToInsert.isEmpty()) {
            accountList = Database.upsert(accountsToInsert,clientCodeField,false);
        }
        
        if (!contactsToInsert.isEmpty()) {
            Database.UpsertResult[] contactList = Database.upsert(contactsToInsert,false);
        }
        if(accountList.size()>0){
            for(integer i=0;i<accountList.size();i++){
                if(accountList[i].isSuccess()){
                    if(newEvents[i].STG_Customer_Id__c != null){
                        STG_Customer__c stgCustomer = getSTGRecordFormatted(newEvents[i],'Success');
                        if(stgCustomer != null){
                            updateStgStatus.add(stgCustomer);
                        }
                    }
                }
                else if(!accountList[i].isSuccess()){
                    String errMsg = '';
                    for(Database.Error err : accountList[i].getErrors()){
                        errMsg =+ err.getMessage()+' \n';
                    }
                    STG_Customer__c stgCustomer = getSTGRecordFormatted(newEvents[i],'Error',errMsg);
                    if(stgCustomer != null){
                        updateStgStatus.add(stgCustomer);
                    }
                }
            }
        }
        if(updateStgStatus.size()>0){
            Database.SaveResult[] updStatusResult = Database.update(updateStgStatus,false);
        }
    }
    
    private static Id getRecordTypeId(String recordTypeName) {
        Schema.RecordTypeInfo recordTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordTypeName);
        return recordTypeInfo != null ? recordTypeInfo.getRecordTypeId() : null;
    }
    
    private static List<merchantContact> parsePAY_ContactData(String payload) {
        List<merchantContact> merchantContacts = (List<merchantContact>) JSON.deserialize (payload, List<merchantContact>.class);
        
        return merchantContacts;
    }
    private static STG_Customer__c getSTGRecordFormatted(PAY_Staging_Customer_to_Account__e evt,String status){
        if(evt.STG_Customer_Id__c != null){
            Id tempId = Id.valueOf(evt.STG_Customer_Id__c);
            STG_Customer__c stgCustomer = new STG_Customer__c(Id = tempId);
            stgCustomer.Status__c = status;
            return stgCustomer;
        }
        return null;
    }
    private static STG_Customer__c getSTGRecordFormatted(PAY_Staging_Customer_to_Account__e evt,String status,String errorMessage){
        if(evt.STG_Customer_Id__c != null){
            STG_Customer__c stgCustomer = getSTGRecordFormatted(evt,status);
            stgCustomer.Error_Details__c = errorMessage;
            return stgCustomer;
        }
        return null;
    }
    public class merchantContact{
        public string FirstName{get;set;}
        public string LastName{get;set;}
        public string MobilePhone{get;set;}
        public string Email{get;set;}
        public string lineOfBusiness{get;set;}
    }
}