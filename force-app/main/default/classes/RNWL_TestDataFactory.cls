@isTest
public with sharing class RNWL_TestDataFactory {
    public static Opportunity createOpportunityRecords(Id accId,Id assetId){
        Opportunity oppRec = new Opportunity();
        oppRec.Name = 'Testabc' ;
        oppRec.AccountId = accId;
        oppRec.Policy__c = assetId;
        oppRec.CloseDate = Date.today();
        oppRec.StageName = 'In Progress';
        oppRec.Policy_Number__c = '12456';
        oppRec.RecordTypeId = Schema.sObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('HI_Renewals').getRecordTypeId();
     
        insert oppRec;
        return oppRec;
    }
     
    public static Opportunity createOpportunityRecords(String strName, Id accId){
        Opportunity oppRec = new Opportunity();
        oppRec.Name =  strName;
        oppRec.AccountId = accId; 
        oppRec.CloseDate = Date.today();
        oppRec.StageName = 'In Progress';
        oppRec.Policy_Number__c = String.valueOf(Math.random() * 100);
        oppRec.Schedule_Request_Response__c =  '';         
        oppRec.Cancel_Call_Response__c =  '';   
        oppRec.RecordTypeId = Schema.sObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('HI_Renewals').getRecordTypeId();

        insert oppRec;
        return oppRec;
    }
}