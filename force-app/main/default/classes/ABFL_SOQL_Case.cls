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
    public static Case getCaseInfo(string caseid){
        return [SELECT Id, ABFL_Case_Detail__c, ABFL_Case_Detail__r.Autoclosure_IN_RR__c, ABFL_Case_Detail__r.IsRegisteredCustomer__c,
		    ABFL_Case_Detail__r.Autoclosed__c, ABFL_Case_Detail__r.Closure_Time__c,CCC_External_Id__c,ContactId,No_Auto_Communication__c,
		    ABFL_Case_Detail__r.Document_URL__c ,LAN__c, Account.IsPersonAccount,
		    Account.PersonEmail, Account.Office_Email__c, Account.PersonMobilePhone,
		    Account.Phone,
		    Technical_Source__c, AccountId, AssetId, Source__c, MoveToNext__c,
		    CaseNumber,Business_Unit__c,ContactEmail,ContactMobile,
		    ABFL_Case_Detail__r.From_Date__c, ABFL_Case_Detail__r.To_Date__c,
		    BRE_Source__c, SuppliedEmail, Origin, ABFL_Case_Detail__r.IsSMT__c
		    FROM Case
		    WHERE Id =: caseid]];
    } 
    /********************************************************************************************************
    * @author           Salesforce
    * @date             13/12/2023
    * @description      SOQL method for getting count of LAN on customer
    * @Paramters        String
    * @return           Integer
    *********************************************************************************************************/
    /*public static Integer getLANCount(string accountId){
        return [SELECT count() FROM Asset WHERE AccountID = :accountId
                WITH SECURITY_ENFORCED];
    } */
    /********************************************************************************************************
    * @author           Salesforce
    * @date             13/12/2023
    * @description      SOQL method for getting contact on account
    * @Paramters        String
    * @return           Integer
    *********************************************************************************************************/
    public static List<Contact> getContact(string accountId) {
        return [SELECT id, Email, Mobile_Phone_2__c,AccountId, Phone, MobilePhone, Account.name FROM 
                Contact WHERE AccountId = :accountId];
    }
}
