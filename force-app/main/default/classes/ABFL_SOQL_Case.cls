/**
* @Class name  :     ABFL_SOQL_Case
* @description :     SOQL Util class for Case Obj
* @Group:
* Modification Log:
* ------------------------------------------------------------------------------------
* Developer                  Version     Date                Description
* ------------------------------------------------------------------------------------
* Aditee                     1.0       13/12/2023              #
*/
public with sharing class ABFL_SOQL_Case {
    private static Case caseRec;
    private static List<Case> caseDetailRecs;
    Private static ASF_Case_Stage_Config__c stageConfig;

    /****************************************************************************************************************
     * @function - getCaseInfo
     * @description - SOQL method for getting case details for an given Case Id
     * @param caseid
     * @return Case
     *****************************************************************************************************************/
    public static Case getCaseInfo(string caseid){
        if(caseRec==null){
            caseRec = [SELECT Id, Winning_Email__c, ABFL_Case_Detail__c, ABFL_Case_Detail__r.Autoclosure_IN_RR__c, ABFL_Case_Detail__r.IsRegisteredCustomer__c,
            ABFL_Case_Detail__r.Autoclosed__c, ABFL_Case_Detail__r.Closure_Time__c,CCC_External_Id__c,ContactId,No_Auto_Communication__c,
            ABFL_Case_Detail__r.Document_URL__c ,LAN__c, Account.IsPersonAccount,Asset.Loan_Start_Date__c,
             Account.PersonEmail, Account.Office_Email__c, Account.PersonMobilePhone,
             Account.Name, Client_Code__c, Description,
             Account.Phone, ABFL_Case_Detail__r.Bank_IFSC_Code__c,
             ABFL_Case_Detail__r.Bank_Account_No__c, ABFL_Case_Detail__r.Frequency__c,
             ABFL_Case_Detail__r.Emi_Amount__c, ABFL_Case_Detail__r.New_Bank_Account_No__c,
             ABFL_Case_Detail__r.Amount__c, ABFL_Case_Detail__r.Debit_Type__c ,
             Technical_Source__c, AccountId, AssetId, Source__c, MoveToNext__c,
             CaseNumber,Business_Unit__c,ContactEmail,ContactMobile,
             ABFL_Case_Detail__r.From_Date__c, ABFL_Case_Detail__r.To_Date__c,
             BRE_Source__c, SuppliedEmail, Origin, ABFL_Case_Detail__r.IsSMT__c,Created_by_ONEABC__c,OwnerId
             FROM Case
             WHERE Id =: caseid];
        }
        return caseRec;
    }
    
    /****************************************************************************************************************
     * @function - getCasesFromCaseDetailIds
     * @description - SOQL method for getting case details from set of abflCaseDetailId
     * @param abflCaseDetailIdSet
     * @return Map<Id, Case>
     *****************************************************************************************************************/
    public static Map<Id, Case> getCasesFromCaseDetailIds(Set<Id> abflCaseDetailIdSet){
        Map<Id, Case> caseMapToReturn = new Map<Id, Case>();

        if(abflCaseDetailIdSet?.size() > 0) {
            Map<Id, Case> caseIdToRecordMap = new Map<Id, Case> ([SELECT Id, RecordTypeId, Status, IsClosed, CaseNumber, AccountId, CreatedDate, ClosedDate, Business_Unit__c, Stage__c, Nature__c, Type_Text__c, Sub_Type_Text__c, CCC_External_Id__c, LOB__c, Source__c, Owner.Name, ABFL_Case_Detail__c, ABFL_Case_Detail__r.Lock_in_Period__c, Account.RecordType.Name, Account.IsPersonAccount, Account.Name, Account.Full_Name__pc, Account.PersonMobilePhone, Account.Phone, Account.PersonEmail, Account.Office_Email__c, Account.City__c, Account.Client_Code__c, Asset.Product2.Name, Asset.LAN__c
                       FROM Case 
                       WHERE ABFL_Case_Detail__c 
                       IN :abflCaseDetailIdSet
                       WITH SYSTEM_MODE]);
            caseMapToReturn = caseIdToRecordMap;
        }
        return caseMapToReturn;
    }  
    
    /****************************************************************************************************************
     * @function - getCases
     * @description - SOQL method for getting cases for an given Case Id Set
     * @param caseIdSet
     * @return Map<Id, Case>
     *****************************************************************************************************************/
    public static Map<Id, Case> getCases(Set<Id> caseIdSet) {
        Map<Id, Case> caseMapToReturn = new Map<Id, Case>();

        if(caseIdSet?.size() > 0) {
            Map<Id, Case> caseIdToRecordMap = new Map<Id, Case> ([SELECT Id, Status, IsClosed, CaseNumber, AccountId, CreatedDate, ClosedDate, Business_Unit__c, Stage__c, Nature__c, Type_Text__c, Sub_Type_Text__c, CCC_External_Id__c, LOB__c, Source__c, Owner.Name, ABFL_Case_Detail__c, ABFL_Case_Detail__r.Lock_in_Period__c, Account.RecordType.Name, Account.IsPersonAccount, Account.Name, Account.Full_Name__pc, Account.PersonMobilePhone, Account.Phone, Account.PersonEmail, Account.Office_Email__c, Account.City__c, Account.Client_Code__c, Asset.Product2.Name, Asset.LAN__c
                       FROM Case 
                       WHERE Id 
                       IN :caseIdSet
                       WITH SYSTEM_MODE]);
            caseMapToReturn = caseIdToRecordMap;
        }
        return caseMapToReturn;
    }

    /****************************************************************************************************************
     * @function - getCaseOrginInfo
     * @description - SOQL method for getting cases for an given Case Id Set
     * @param idSet
     * @return List<Case>
     *****************************************************************************************************************/
    public static List<Case> getCaseOrginInfo(Set<Id> idSet){
        return [SELECT Id, origin FROM Case WHERE ID IN : idSet WITH USER_MODE]; // this is invoked by E2C, hence can't use with_security_enforced
    }

    /**
    * @description : Fetch case details info
    * @author rsinghnagar@salesforce.com | 01-02-2024 
    * @param idSet 
    * @return List<Case> 
    **/
    public static List<Case> getCasedetails(Set<Id> idSet){
        if(caseDetailRecs==null){
            caseDetailRecs = [SELECT Business_Unit__c,
                    ABFL_Case_Detail__r.Case_Categorisation__c,
                    ABFL_Case_Detail__r.Correct_Category__c,
                    ABFL_Case_Detail__r.Correct_Call_Type__c,
                    ABFL_Case_Detail__r.Correct_Sub_Type__c,
                    ABFL_Case_Detail__r.Voice_of_Customer__c,
                    ABFL_Case_Detail__r.Primary_Erring_Unit__c,
                    ABFL_Case_Detail__r.Financial_Impact__c,
                    ABFL_Case_Detail__r.Diputed_Amount__c,
                    ABFL_Case_Detail__r.Refund_Amount__c,
                    ABFL_Case_Detail__r.Action_Taken__c,
                    ABFL_Case_Detail__r.Grievance_Type__c,
                    CCC_External_Id__c
                    FROM Case 
                    WHERE Id = :idSet WITH SECURITY_ENFORCED];
        }
        return caseDetailRecs;
    }
    
    /**
    * @description : Fetch case stage info
    * @author dhinesh.t@salesforce.com | 12-24-2024 
    * @param idSet 
    * @return List<Case> 
    **/
    public static ASF_Case_Stage_Config__c getStageConfig(String CCC_ExternalID){
        if(stageConfig==null){
            stageConfig = [SELECT Default_Queue__c
                    FROM ASF_Case_Stage_Config__c 
                    WHERE Case_Category_Config__r.CCC_External_Id__c =: CCC_ExternalID AND StageName__c = 'Open' WITH SECURITY_ENFORCED];
        }
        return stageConfig;
    }
    
    public static String getOnwerBU(Id ownerID){
        User UserRecord = new User();
        UserRecord = [SELECT Business_Unit__c
                    FROM User 
                    WHERE Id = : ownerID];
        return UserRecord.Business_Unit__c;
    }
}