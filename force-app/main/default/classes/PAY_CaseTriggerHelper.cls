public with sharing class PAY_CaseTriggerHelper {

    public static final Schema.SObjectField ACCOUNT_EXTERNAL_ID = Account.Fields.LOB_Client_Code__c;
    public static final List<String> lineOfBusinesses = new List<String>{'Payments'};

    public static void createCustomerForCreateCaseAPI(List<SObject> newItems){

        Map<String,String> clientCodeCustomerPayloadMap = new Map<String,String>();
        List<Account> accountsToInsert = new List<Account>();
        List<Contact> contactsToInsert = new List<Contact>();
        Map<String,String> accountIdToClientCodeMap = new Map<String,String>();

        for(Case individualCase :(List<Case>)newItems){
            if(individualCase.AccountId == null && String.isNotBlank(individualCase.Customer_Payload__c) && individualCase.Business_Unit__c == 'Payments' && individualCase.Technical_Source__c == 'API'){
                CustomerWrapper customWrapper = (CustomerWrapper)JSON.deserialize(individualCase.Customer_Payload__c,CustomerWrapper.class);
                Account customer = new Account();
                if(String.isNotBlank(customWrapper.ClientCode)){
                    if (String.isNotBlank(customWrapper.CompanyName)) {
                        customer.RecordTypeId = getRecordTypeId('Non-Individual');
                        customer.PAY_Doing_Business_As__c = customWrapper.DBA;
                        customer.Client_Code__c = customWrapper.ClientCode;
                        
                        String customerKey = individualCase.Business_Unit__c + '_'+customWrapper.ClientCode;
                        customer.LOB_Client_Code__c = customerKey;
                        
                        customer.Name = customWrapper.CompanyName;
                        customer.Line_of_Business__c = individualCase.Business_Unit__c;
                        customer.Business_Unit__c = individualCase.Business_Unit__c;
                        Contact newContact = new Contact();
                        newContact.Account = New Account(Client_Code__c=customWrapper.ClientCode); 
                        newContact.Line_of_Business__c = individualCase.Business_Unit__c;
                        newContact.FirstName = customWrapper.PrimContactFirstName;
                        newContact.LastName = customWrapper.PrimContactLastName;
                        newContact.MobilePhone = customWrapper.PrimContactPhone;
                        newContact.Email = customWrapper.PrimContactEmail;
                        contactsToInsert.add(newContact);
                    } else {
                        customer.RecordTypeId = getRecordTypeId('Individual');
                        customer.Client_Code__c = customWrapper.ClientCode;
                        
                        String customerKey = individualCase.Business_Unit__c + '_'+customWrapper.ClientCode;
                        customer.LOB_Client_Code__c = customerKey;
                        
                        if(String.isNotBlank(customWrapper.PersonMobilePhone)){
                            customer.PersonMobilePhone = customWrapper.PersonMobilePhone;
                        }
                        
                        if(String.isNotBlank(customWrapper.PersonEmail)){
                            customer.PersonEmail = customWrapper.PersonEmail;
                        }
                        
                        customer.FirstName = customWrapper.PersonFirstName;
                        customer.LastName = customWrapper.PersonLastName;
                        customer.Line_of_Business__c = individualCase.Business_Unit__c;
                        customer.Business_Unit__c = individualCase.Business_Unit__c;
                    }
                    accountsToInsert.add(customer);      
                }
            }        
        }

        if (!accountsToInsert.isEmpty()) {
            Database.UpsertResult[] accountList= Database.upsert(accountsToInsert,ACCOUNT_EXTERNAL_ID,false);
        }
        
        if (!contactsToInsert.isEmpty()) {
            Database.UpsertResult[] contactList = Database.upsert(contactsToInsert,false);
        }

        for(Account customer : accountsToInsert){
            accountIdToClientCodeMap.put(customer.Client_Code__c,customer.Id);
        }
        for(Case individualCase :(List<Case>)newItems){
            if(String.isBlank(individualCase.AccountId) && String.isNotBlank(individualCase.Customer_Payload__c)){
                CustomerWrapper customWrapper = (CustomerWrapper)JSON.deserialize(individualCase.Customer_Payload__c,CustomerWrapper.class);
                if(String.isNotBlank(customWrapper.ClientCode)){
                    if(accountIdToClientCodeMap.containsKey(customWrapper.ClientCode)){
                        individualCase.AccountId = accountIdToClientCodeMap.get(customWrapper.ClientCode);
                    }
                }
            }
        }
    }

    public static void fetchCustomerInfoExt(List<SObject> newItems){
        Set<String> accountsClientCode = new Set<String>();
        Map<String,List<Id>> accClientCodeVsCaseIds = new Map<String,List<Id>>();
        
        for(Case individualCase :(List<Case>)newItems){
            if(individualCase.Technical_Source__c == 'API' && individualCase.AccountId == null && individualCase.Business_Unit__c =='Payments'){
                if(individualCase.Client_Code_Text__c != null){
                    List<Id> caseIdList = new List<Id>();
                    if(accClientCodeVsCaseIds.containsKey(individualCase.Client_Code_Text__c)){
						caseIdList = accClientCodeVsCaseIds.get(individualCase.Client_Code_Text__c);
                    }
                    caseIdList.add(individualCase.Id);
                    accClientCodeVsCaseIds.put(individualCase.Client_Code_Text__c,caseIdList);   
                }
            }
        }
        if(accClientCodeVsCaseIds.size()>0){
            ID jobID = System.enqueueJob(new PAY_FetchCustomerDetails(accClientCodeVsCaseIds));
        }
        
    }
    
    private static Id getRecordTypeId(String recordTypeName) {
        Schema.RecordTypeInfo recordTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordTypeName);
        return recordTypeInfo != null ? recordTypeInfo.getRecordTypeId() : null;
    }

    public class CustomerWrapper{
        public string LineOfBusiness;
        public string ClientCode;
        public string CompanyName;
        public string CompanyPhone;
        public string CompanyEmail;
        public string DBA;
        public string PersonFirstName;
        public string PersonLastName;
        public string PersonMobilePhone;
        public string PersonEmail;
        public string PrimContactFirstName;
        public string PrimContactLastName;
        public string PrimContactPhone;
        public string PrimContactEmail;
    }
}