public with sharing class ABHI_IntegrationQueryHelper {
 /* public static List<Case> getCaseForMobileUpdateIntegration(Id caseId) {
    return [
      SELECT Id, Stage__c, ABSLI_Case_Detail__r.Status_Valid_For_STP__c
      FROM Case
      WHERE Id = :caseId
    ];
  }
*/
  /**
   * @description Query method to fetch Case records used in process Response
   *
   * @author Abinash Panigrahi
   * @date 2024-05-28
   *
   * @param configExternalID
   * @return Case
   */
  public static Case getCaseInfo(Id caseId) {
    return [
      SELECT
        Id,
        CCC_External_Id__c,
        MoveToNext__c,
        AccountId,
        ContactId,
        No_Auto_Communication__c,
        Attachment_Status__c,
        OwnerId,
        Source__c,
        CreatedById,
        ABHI_Case_Detail__c,
        Stage__c
      FROM Case
      WHERE Id = :caseId
      FOR UPDATE
    ];
  }
public static List<ASF_Case_Integration__c> getCaseIntegrations1(List<Case> caseRecs, Set<String> intgIds) {
		return [
			SELECT Id, Name, Status__c, Case__c, Integration_Ext_Id__c
			FROM ASF_Case_Integration__c
			WHERE Case__c IN :caseRecs AND Integration_Ext_Id__c IN :intgIds
		];
	}

  /*
  public static List<ASF_Case_Category_Config__c> getCaseCategoryConfigs(String configExternalID) {
    return [
      SELECT
        Id,
        CCC_External_Id__c,
        Resolved_Case_Email_Template__c,
        Additional_Email_Templates__c,
        Additional_SMS_Metadata__c,
        Resolved_Case_SMS_Metadata__c
      FROM ASF_Case_Category_Config__c
      WHERE CCC_External_Id__c = :configExternalID
    ];
  }

  /**
   * @description Query method to fetch related Case Integration records based on parent Case ID and Integration ID
   *
   * @author Abinash Panigrahi
   * @date 2024-05-28
   *
   * @param caseRecs, intgIds
   * @return List<ASF_Case_Integration__c>
   */
 /*public static List<ASF_Case_Integration__c> getCaseIntegrations(List<Case> caseRecs, Set<String> intgIds) {
    return [
      SELECT Id, Name, Status__c, Case__c, Integration_Ext_Id__c
      FROM ASF_Case_Integration__c
      WHERE Case__c IN :caseRecs AND Integration_Ext_Id__c IN :intgIds
    ];
  }
*/
     public static List<ASF_Case_Integration__c> getCaseIntegrations(List<ASF_Case_Integration__c> intgRecs) {
        return [
            SELECT Name, Case__c
            FROM ASF_Case_Integration__c
            WHERE Id IN :intgRecs
        ];
    }
  /*
   * @description Query method to fetch related Case Integration records based on IDs
   *
   * @author Abinash Panigrahi
   * @date 2024-05-28
   *
   * @param intgRecs
   * @return List<ASF_Case_Integration__c>
   */
 /* public static List<ASF_Case_Integration__c> getCaseIntegrations(List<ASF_Case_Integration__c> intgRecs) {
    return [
      SELECT Name, Case__c
      FROM ASF_Case_Integration__c
      WHERE Id IN :intgRecs
    ];
  }*/

  /**
   * @description Query method to fetch Case Integration records based on ClassName
   *
   * @author Abinash Panigrahi
   * @date 2024-05-28
   *
   * @param Set<String> className
   * @return Map<String, ASF_Integration__c>
   */
 /* public static Map<String, ASF_Integration__c> getIntegrationInfo(Set<String> className) {
    Map<String, ASF_Integration__c> integrationInfo = new Map<String, ASF_Integration__c>();
    for (ASF_Integration__c integration : [
      SELECT
        Id,
        STP_API_Identifier__c,
        STP_Processing_Class__c,
        Processing_Class__c,
        External_Id__c,
        STP_Config_External_Id__c,
        STP_Template__c,
                Query_Fields__c,
                Priority__c
      FROM ASF_Integration__c
      WHERE Processing_Class__c = :className
    ]) {
      integrationInfo.put(integration.Processing_Class__c, integration);
    }
    return integrationInfo;
  }*/

  /*public static Map<Id, Case> getCases(Set<Id> caseIdSet) {
        Map<Id, Case> caseMapToReturn = new Map<Id, Case>();

        if(caseIdSet?.size() > 0) {
            Map<Id, Case> caseIdToRecordMap = new Map<Id, Case> ([SELECT Id, Status, IsClosed, FTR__c,
                                                                  CaseNumber, AccountId, AssetId, LAN__c,CreatedDate,LastModifiedDate,
                                                                  ClosedDate, Business_Unit__c, Stage__c,
                                                                  Nature__c, Type_Text__c, Sub_Type_Text__c,
                                                                  CCC_External_Id__c, LOB__c, Source__c,Channel__c,
                                                                  Owner.Name,
                                                                  ABSLI_Case_Detail__r.Source_Request_submitted_by__c,
                                                                  Account.RecordType.Name, Account.IsPersonAccount,
                                                                  Account.Name, Account.Full_Name__pc,
                                                                  Account.PersonMobilePhone, Account.Phone,
                                                                  Account.PersonEmail, Account.Office_Email__c,
                                                                  Account.City__c, Account.Client_Code__c,
                                                                  Asset.Product2.Name, Asset.LAN__c,Asset.Policy_No__c,
                                                                  Asset.Issue_Date__c,Asset.Status,Asset.Type__c,Asset.Channel__c,
                                                                  Asset.Advisor__c,Asset.Advisor__r.Advisor_Code__c,Asset.Advisor__r.Advisor_Status__c,
                                                                  Asset.Advisor__r.Agent_Sub_Category__c,
                                                                  Account.Nationality__pc,Account.Customer_Segment__c,
                                                                  Account.PersonBirthdate,Account.Occupation__c,Account.PersonGenderIdentity
                                                                  FROM Case
                                                                  WHERE Id
                                                                  IN :caseIdSet
                                                                  WITH SYSTEM_MODE]);
            caseMapToReturn = caseIdToRecordMap;
        }
        return caseMapToReturn;
    }
    public static Map<String, ASF_Case_Category_Config__c> getCccIdToRecordMap(Set<String> cccIdSet) {
      Map<String, ASF_Case_Category_Config__c> cccIdToRecordsMap = new Map<String, ASF_Case_Category_Config__c>();

      if(cccIdSet?.size() > 0) {
        for (ASF_Case_Category_Config__c cccRecord :[SELECT Id, CCC_External_Id__c, Litmus_Trigger__c, Litmus_Project__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c IN :cccIdSet WITH SYSTEM_MODE]) {
          cccIdToRecordsMap.put(cccRecord.CCC_External_Id__c, cccRecord);
        }
      }
      return cccIdToRecordsMap;
    }
    public static Map<Id, ASF_Case_Integration__c> getCaseIdsToIntegrationRecordsMap(Set<Id> caseIdSet, String type) {
        Map<Id, ASF_Case_Integration__c> caseIdToCaseIntMap = new Map<Id, ASF_Case_Integration__c>();

        List<ASF_Case_Integration__c> caseIntRecordsList = [SELECT Name, Case__c
                                                            FROM ASF_Case_Integration__c
                                                            WHERE Case__c IN :caseIdSet
                                                            AND Status__c = :ABFL_Constants.PENDING
                                                            AND Type__c = :type];

        for(ASF_Case_Integration__c caseIntRecord :caseIntRecordsList) {
            caseIdToCaseIntMap.put(caseIntRecord.Case__c, caseIntRecord);
        }

        return caseIdToCaseIntMap;
    }*/
}