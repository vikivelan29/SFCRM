/**
 * @description       : 
 * @author            : virendra.patil@salesforce.com
 * @group             : 
 * @last modified on  : 05-14-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   05-13-2024   rsinghnagar@salesforce.com   Initial Version
**/
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts,PMD.StdCyclomaticComplexity,PMD.ClassNamingConventions')
public with sharing class ASF_CustomerAndProspectSearch {
    
    /**
    * @description 
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param searchString 
    * @return List<returnVal> 
    **/
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
                                          Lead (Id,Name,Email,MobilePhone)
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
        return cls;
    }

    /**
    * @description 
    **/
    public class returnVal{
        /**
        * @description : ApexProperty
        **/
        @AuraEnabled public string objectName{get;set;}
        /**
        * @description : ApexProperty
        **/
        @AuraEnabled public boolean showSeperate{get;set;}
        @AuraEnabled public List<sObject> objRecords = new List<sObject>();
        /**
        * @description 
        * @author rsinghnagar@salesforce.com | 05-13-2024 
        * @param objName 
        * @param records 
        **/
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
    
    /**
    * @description 
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param caseToInsert 
    * @param caseExtnRecord 
    * @param prospectRecord 
    * @return Map<String,sObject>
    **/
    @AuraEnabled
    public static Map<String,sObject> createProspectWithCaseExtnAndCase(Case caseToInsert, sObject caseExtnRecord, Lead prospectRecord)
    {
        Id salesProspectRTId = Schema.sObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Sales').getRecordTypeId();
        Id serviceProspectRTId = Schema.sObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Service').getRecordTypeId();
        Id abslamcSalesProspectRTId = Schema.sObjectType.Lead.getRecordTypeInfosByDeveloperName().get('ABSLAMC_Leads').getRecordTypeId(); //PR1030924-180
        
        Map<String,sObject> mObjectVsRecId = new Map<String,sObject>();
        
        User loggedInUser = [SELECT ID FROM User WHERE Id =: UserInfo.getUserId()];
        if(prospectRecord != null){
            // In case of Prospect Case, create Prospect first.
            Datacloud.FindDuplicatesResult[] results = Datacloud.FindDuplicates.findDuplicates(new List<Lead>{prospectRecord});
            for (Datacloud.FindDuplicatesResult findDupeResult : results) {
                for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
                    for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                        for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                            mObjectVsRecId.put('DuplicateLead',matchRecord.getRecord());
                            return mObjectVsRecId;
                        }
                    }
                }
            }
            prospectRecord.RecordTypeId = serviceProspectRTId;
            //PR1030924-180 Added new record type for ABSLAMC
            if(prospectRecord.Sales_Prospect__c == true){
                if(prospectRecord.Business_Unit__c == ABSLAMC_Constants.ABSLAMCBU) {
                    prospectRecord.RecordTypeId = abslamcSalesProspectRTId;
                }else {
                    prospectRecord.RecordTypeId = salesProspectRTId;
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
            String sObjectName = '';
            if(caseExtnRecord != null){
                sObjectName=String.ValueOf(caseExtnRecord.Id.getsObjectType());
                caseToInsert.put(sObjectName,caseExtnRecord.Id);
            }
            
            if(caseToInsert.Lead__c == null){
                if(prospectRecord != null){
                    // In case of Internal Case - No need to create prospect.
                    caseToInsert.put('Lead__c',prospectRecord.Id);
                }
                
            }
            
            insert caseToInsert;
            mObjectVsRecId.put('Case',caseToInsert);
        }
        
        return mObjectVsRecId;
    }
    
}