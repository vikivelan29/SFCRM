/**
* @File Name : RNWL_RenewalCustomerPolicyInfo.cls
* @Description :
* @Author : Misbah
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 18, 2024 |   | Initial Version
**/

public with sharing class RNWL_RenewalCustomerPolicyInfo {

    @AuraEnabled(cacheable=true)
    public static Opportunity getOppRec(String recordId){
        return [SELECT Id, 
					Account.Id,
                	Account.FirstName, 
                	Account.LastName, 
					Account.MMI_Customer_ID__c,
					Account.PersonBirthdate,
					Account.PersonGenderIdentity,
					Account.PersonMobilePhone,
					Account.Office_Email__c,
					Account.BillingStreet,
					Account.BillingCity,
					Account.BillingState,
					Account.BillingPostalCode,
					Account.BillingAddress,
					Account.Customer_Segment__c,
					Account.CumulativeBonusEarned__c,
					Account.Rider_Opted__c,
					Account.Is_Chronic__c,
					Account.RecordType.Name,
					Policy__r.Policy_No__c,
					Policy__r.Cover_Type__c,
					Policy__r.Issue_Date__c,
					Policy__r.Maturity_Date__c,
					Policy__r.Policy_Term__c,
					Policy__r.ProductName__c,
					Policy__r.ZoneOfCover__c,
					Policy__r.Sum_Assured__c,
					Policy__r.CountOfLives__c,
					Policy__r.Plan_Name__c,
					Policy__r.Channel__c,
					Policy__r.Mode__c,
					Policy__r.SRMName__c,
					Policy__r.SRMCode__c,
					Policy__r.ServicingBranchName__c,
					Policy__r.IntermediaryName__c,
					Policy__r.IntermediaryMobileNumber__c,
                	Policy__r.Name, 
					Policy__r.Source__c,
					Policy__r.GoGreen__c,
					Policy__r.PolicySubStatus__c,
					Policy__r.GrossPremium__c,
					Policy__r.MasterPolicyNumber__c,
					Policy__r.IntermediaryCode__c, 
					Policy__r.Intermediary_Branch_Code__c,
					Policy__r.SerialNumber,
					Drop_off_Reason__c,
					Drop_off_URL__c,
					Policy_Inception_Date__c, 
					Proposal_Number__c,
					Grace_Period_End__c,
					Grace_Period_Start__c,
					Policy_Lapse_Date__c,
					Policy_Lapsed__c, Policy_Number__c,
					Policy_Renewal_Notice_Day__c,
					Status__c, Propensity_to_Pay__c,
					Preferred_Flag__c, Calling_Source__c,
					Renewal_Calling_Flag__c
                FROM Opportunity 
                WHERE Id = :Id.valueOf(recordId) 
                LIMIT 1];
    }

	@AuraEnabled
	public static Asset getNomineesClaims(String policyId) {
        return [SELECT Id,
               		Name, 
					(SELECT Id, Name, NomineeContactNumber__c FROM PolicyNumber__r),
					(SELECT Id FROM Claims__r WHERE Claim_Status__c != 'Rejected' AND Claim_Status__c != 'Settled')
				FROM Asset WHERE Id = :policyId];
	}
	
}