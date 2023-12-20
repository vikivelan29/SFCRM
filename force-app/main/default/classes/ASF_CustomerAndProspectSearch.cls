public with sharing class ASF_CustomerAndProspectSearch {
    
    @AuraEnabled
    public static List<returnVal> getRecords(String searchString){
        
        List<Account> customerRecords = new List<Account>();
        List<Lead> prospectRecords = new List<Lead>();
        List<Contact> customerContactRecords = new List<Contact>();
        
        
        List<returnVal> cls = new List<returnVal>();
        cls.add(new returnVal('Account', new List<Account>()));
        cls.add(new returnVal('Contact', new List<Account>()));
        cls.add(new returnVal('Lead', new List<Account>()));
        
        List<List<SObject>> searchList = [FIND :searchString IN ALL FIELDS 
                                          RETURNING 
                                          Account (Id, Name,Business_Unit__c,Client_Code__c), 
                                          Contact (Id,Name,Email), 
                                          Lead (Id,Name)
                                          LIMIT 100];
        for(List<sObject> searchObject : searchList){
            if(searchObject.size()>0){
                String objName = String.ValueOf(searchObject[0].Id.getSObjectType());
                for(returnVal r : cls){
                    if(r.objectName == objName){
                        System.debug(' I am here...');
                        r.objRecords.addAll(searchObject);
                        break;
                    }
                }
            }
        }
        System.debug(cls);
        return cls;
    }
    
    public class returnVal{
        @AuraEnabled public string objectName{get;set;}
        @AuraEnabled public List<sObject> objRecords = new List<sObject>();
        
        public returnVal(String objName, List<sObject> records){
            this.objectName = objName;
            if(records.size()>0){
                this.objRecords.addAll(records);
            }
        }
    }
    
    @AuraEnabled
    public static Id createProspectWithCaseExtnAndCase(Case caseToInsert, 
                                                         sObject caseExtnRecord, 
                                                         Lead prospectRecord)
    {
        User loggedInUser = [SELECT ID FROM User WHERE Id =: UserInfo.getUserId()];
        if(prospectRecord != null){
            insert prospectRecord;
        }
        
        if(caseExtnRecord != null){
            insert caseExtnRecord;
        }
        if(caseToInsert != null){
            String sObjectName = String.ValueOf(caseExtnRecord.Id.getsObjectType());
            caseToInsert.put(sObjectName,caseExtnRecord.Id);
            caseToInsert.put('Lead__c',prospectRecord.Id);
            insert caseToInsert;
        }
        
        return caseToInsert.Id;
        
        
    }
    
    
}