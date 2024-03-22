global without sharing class ASF_UbonaAccountRetrieval{

webService static String getAccount(String phone,String lob,String clientCode) {
   
    List<Account> accounts = new List<Account>();
    
    phone = '%'+phone+'%';
    phone = String.escapeSingleQuotes(phone);
    
    if(clientCode != null && clientCode != ''){
        accounts = [SELECT ID,Name,PersonMobilePhone,Phone FROM Account WHERE Client_Code__c = : clientCode AND Business_Unit__c = :lob];
    } 
    if(accounts.size()== 0){
        Set<Id> accIds = new Set<Id>();
        
        List<Contact> contacts = [SELECT ID,AccountId,Name,MobilePhone FROM Contact WHERE MobilePhone Like : phone AND Account.Business_Unit__c = : lob];
        for(Contact c : contacts){
            accIds.add(c.AccountId);
        }
        if(contacts.size()>0){
            System.debug('accIds --> '+accIds);
            accounts = [SELECT ID,Name,PersonMobilePhone,Phone FROM Account WHERE Id= :accIds AND Business_Unit__c = :lob];
        }

    }
   
       String JSONString = JSON.serialize(accounts);
       return JSONString;
   }
}