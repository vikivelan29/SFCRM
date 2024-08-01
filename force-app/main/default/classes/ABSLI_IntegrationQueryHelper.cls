public with sharing class ABSLI_IntegrationQueryHelper {
	public static List<Case> getCaseForMobileUpdateIntegration(Id caseId) {
		return [
			SELECT Id, Stage__c, ABSLI_Case_Detail__r.Status_Valid_For_STP__c
			FROM Case
			WHERE Id = :caseId
		];
	}

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
				ABSLI_Case_Detail__c,
				Stage__c
			FROM Case
			WHERE Id = :caseId
			WITH SECURITY_ENFORCED
			FOR UPDATE
		];
	}

	/**
	 * @description Query method to fetch Case Category Config record based on EXTERNAL ID
	 *
	 * @author Abinash Panigrahi
	 * @date 2024-05-28
	 *
	 * @param configExternalID
	 * @return List<ASF_Case_Category_Config__c>
	 */
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
			WITH SECURITY_ENFORCED
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
	public static List<ASF_Case_Integration__c> getCaseIntegrations(List<Case> caseRecs, Set<String> intgIds) {
		return [
			SELECT Id, Name, Status__c, Case__c, Integration_Ext_Id__c
			FROM ASF_Case_Integration__c
			WHERE Case__c IN :caseRecs AND Integration_Ext_Id__c IN :intgIds
			WITH SECURITY_ENFORCED
		];
	}

	/**
	 * @description Query method to fetch related Case Integration records based on IDs
	 *
	 * @author Abinash Panigrahi
	 * @date 2024-05-28
	 *
	 * @param intgRecs
	 * @return List<ASF_Case_Integration__c>
	 */
	public static List<ASF_Case_Integration__c> getCaseIntegrations(List<ASF_Case_Integration__c> intgRecs) {
		return [
			SELECT Name, Case__c
			FROM ASF_Case_Integration__c
			WHERE Id IN :intgRecs
			WITH SECURITY_ENFORCED
		];
	}

	/**
	 * @description Query method to fetch Case Integration records based on ClassName
	 *
	 * @author Abinash Panigrahi
	 * @date 2024-05-28
	 *
	 * @param Set<String> className
	 * @return Map<String, ASF_Integration__c>
	 */
	public static Map<String, ASF_Integration__c> getIntegrationInfo(Set<String> className) {
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
			WITH SECURITY_ENFORCED
		]) {
			integrationInfo.put(integration.Processing_Class__c, integration);
		}
		return integrationInfo;
	}
}