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
        
        searchString = '*'+String.escapeSingleQuotes(searchString)+'*';
        List<List<SObject>> searchList = [FIND :searchString IN ALL FIELDS 
                                          RETURNING 
                                          Account (Id, Name,Business_Unit__c,Client_Code__c), 
                                          Contact (Id,Name,Email,Mobile__c WHERE IsPersonAccount=false), 
                                          Lead (Id,Name)
                                          LIMIT 100];
        for(List<sObject> searchObject : searchList){
            if(searchObject.size()>0){
                String objName = String.ValueOf(searchObject[0].Id.getSObjectType());
                for(returnVal r : cls){
                    if(r.objectName == objName){
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
        @AuraEnabled public boolean showSeperate{get;set;}
        @AuraEnabled public List<sObject> objRecords = new List<sObject>();
        
        public returnVal(String objName, List<sObject> records){
            this.objectName = objName;
            this.showSeperate = false;
            if(records.size()>0){
                this.objRecords.addAll(records);
            }
            if(objName =='Lead'){
                this.showSeperate = true;
            }
        }
    }
    
    @AuraEnabled
    public static Map<String,sObject> createProspectWithCaseExtnAndCase(Case caseToInsert, 
                                                                   sObject caseExtnRecord, 
                                                                   Lead prospectRecord)
    {
        Map<String,sObject> mObjectVsRecId = new Map<String,sObject>();
        
        User loggedInUser = [SELECT ID FROM User WHERE Id =: UserInfo.getUserId()];
        if(prospectRecord != null){
            Datacloud.FindDuplicatesResult[] results = Datacloud.FindDuplicates.findDuplicates(new List<Lead>{prospectRecord});
            for (Datacloud.FindDuplicatesResult findDupeResult : results) {
                for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
                    for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                        for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                            System.debug(matchRecord.getRecord());
                            mObjectVsRecId.put('DuplicateLead',matchRecord.getRecord());
                            return mObjectVsRecId;
                        }
                    }
                }
            }
            
            
            insert prospectRecord;
            mObjectVsRecId.put('Lead',prospectRecord);
        }
        
        if(caseExtnRecord != null){
            insert caseExtnRecord;
            mObjectVsRecId.put('CaseExt',caseExtnRecord);
        }
        if(caseToInsert != null){
            String sObjectName = String.ValueOf(caseExtnRecord.Id.getsObjectType());
            caseToInsert.put(sObjectName,caseExtnRecord.Id);
            if(caseToInsert.Lead__c == null){
                caseToInsert.put('Lead__c',prospectRecord.Id);
            }
            
            insert caseToInsert;
            mObjectVsRecId.put('Case',caseToInsert);
        }
        
        return mObjectVsRecId;
        
        
    }
    
}