// Renewals LOB test factor class
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
        oppRec.Proposal_Number__c = '1122233';
        oppRec.RecordTypeId = Schema.sObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('HI_Renewals').getRecordTypeId();
     
        insert oppRec;
        return oppRec;
    }
     
    public static Opportunity createOpportunityRecords(String strName, Id accId){
        Asset asset = ASF_TestDataFactory.createAsset(accId,'');
        Opportunity oppRec = new Opportunity();
        oppRec.Name =  strName;
        oppRec.AccountId = accId; 
        oppRec.Policy__c = asset.Id;
        oppRec.CloseDate = Date.today();
        oppRec.StageName = 'In Progress';
        oppRec.Policy_Number__c = String.valueOf(Math.random() * 100);
        oppRec.Schedule_Request_Response__c =  '';         
        oppRec.Cancel_Call_Response__c =  '';   
        oppRec.RecordTypeId = Schema.sObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('HI_Renewals').getRecordTypeId();

        insert oppRec;
        return oppRec;
    }
    
    /****************************************************
     * @Description - Insert Business Account
     * @param strCompanyName -  Contains CompanyName
     * @param strCRN -  Contains CRN Number
     * @return - Account       
    *****************************************************/
    
    public static Account insertBusinessAccount(String strCompanyName, String strCRN) {
        //Id recordTypeId =Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Business_Account').getRecordTypeId();
        Account objAccount = new Account();
        objAccount.Name = String.isNotBlank(strCompanyName) ? strCompanyName:'TestCompanyName';
        //objAccount.CRN__c =  String.isNotBlank(strCRN)? strCRN: String.valueOf( Integer.valueof((Math.random() * 100)));
        //objAccount.RecordTypeId = recordTypeId;
        if(Schema.sObjectType.Account.isCreateable()){
            insert objAccount;
        }
        
        return objAccount;
     }
    
    /****************************************************
     * @Description - Create Asset record 
     * @param accountId -  Contain Account Id for which asset is created
     * @param strType -  Contain Type
     * @return - Asset
    *****************************************************/

    public static Asset createAsset(Id accountId,String strType) {
        Asset asset = new Asset();
        //Id recordTypeId =Schema.Sobjecttype.Asset.getRecordTypeInfosByDeveloperName().get('Credit_Cards').getRecordTypeId();
        asset.Name = 'Test Asset';
        //asset.recordTypeId = recordTypeId;
        //asset.Financial_Account_Number__c = ASF_UtilityClass.generateTransactionId();
        asset.AccountId =accountId;
        asset.Type__c = strType;
        if(Schema.sObjectType.Asset.isCreateable()){
            insert asset;
        }
        return asset;
    }
    
    public static Case createCase(Id accountId, Id asstId){
        Case caseRec = new Case();
        caseRec.AccountId = accountId;
        caseRec.AssetId = asstId;
        if(Schema.sObjectType.Asset.isCreateable()){
            insert caseRec;
        } 
        return caseRec;
    }

    public static Account createAccount() {
        Account accRec = new Account(Name = 'Test' + (Math.random() * 10000), Phone = '9052437031');
        insert accRec;
        return accRec;
    }
}