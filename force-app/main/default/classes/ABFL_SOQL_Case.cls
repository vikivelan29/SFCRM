/**
* @Class name:      ABFL_SOQL_Case
* @Description:
* @Group:
* Modification Log:
* ------------------------------------------------------------------------------------
* Developer                  Version     Date                Description
* ------------------------------------------------------------------------------------
* Aditee                     1.0       13/12/2023              #
*/
public with sharing class ABFL_SOQL_Case {
	/********************************************************************************************************
    * @author           Salesforce
    * @date             13/12/2023
    * @description      SOQL method for getting case details for an given Case Id
    * @Paramters        String
    * @return           case
    *********************************************************************************************************/
    private static Case caseRec;
    public static Case getCaseInfo(string caseid){
        if(caseRec==null){
            caseRec = [SELECT Id, ABFL_Case_Detail__c, ABFL_Case_Detail__r.Autoclosure_IN_RR__c, ABFL_Case_Detail__r.IsRegisteredCustomer__c,
            ABFL_Case_Detail__r.Autoclosed__c, ABFL_Case_Detail__r.Closure_Time__c,CCC_External_Id__c,ContactId,No_Auto_Communication__c,
            ABFL_Case_Detail__r.Document_URL__c ,LAN__c, Account.IsPersonAccount,
             Account.PersonEmail, Account.Office_Email__c, Account.PersonMobilePhone,
             Account.Phone,
             Technical_Source__c, AccountId, AssetId, Source__c, MoveToNext__c,
             CaseNumber,Business_Unit__c,ContactEmail,ContactMobile,
             ABFL_Case_Detail__r.From_Date__c, ABFL_Case_Detail__r.To_Date__c,
             BRE_Source__c, SuppliedEmail, Origin, ABFL_Case_Detail__r.IsSMT__c
             FROM Case
             WHERE Id =: caseid];
        }
        return caseRec;
    } 
}