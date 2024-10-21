/******************************************************************************************
 * Class         :  RNWL_CreateRenewals
 * Author        :  Joshna
 * Created Date  :  06/10/2024
 * Description   :  Inbound custom REST service used by JARVIS to create ABHI Renewal Quotes
*******************************************************************************************/
@RestResource(urlMapping='/CreateRenewals/*')
global with sharing class RNWL_CreateRenewals {
    @HttpPost
    global static RenewalResponseWrapper doPost(List<RenewalRequestWrapper> renewalRequests) {
        List<Opportunity> opportunityRecordsToInsert = new List<Opportunity>();
        Map<String, Asset> assetMap = new Map<String, Asset>();
        Set<String> allPolicyIds = new Set<String>();
        RenewalResponseWrapper responseWrapper = new RenewalResponseWrapper();

        for (RenewalRequestWrapper each : renewalRequests) {
            allPolicyIds.add(each.policyNumber);
        }

        for (Asset each : [SELECT Id, LAN__c, AccountId, Account.Phone FROM Asset WHERE LAN__c IN :allPolicyIds]) {
            assetMap.put(each.LAN__c, each);
        }

        for (RenewalRequestWrapper each : renewalRequests) {
            opportunityRecordsToInsert.add(new Opportunity(
                Policy_Number__c = each.policyNumber,
                Policy_Inception_Date__c = getDate(each.policyInceptionDate),
                Proposal_Number__c = each.proposalNumber,
                Policy__c = assetMap.get(each.policyNumber) == null ? null : assetMap.get(each.policyNumber).Id,
                CloseDate = Date.today() + 60,
                AccountId = assetMap.get(each.policyNumber) == null ? null : assetMap.get(each.policyNumber).AccountId,
                StageName = 'Open',
                Name = 'RN-' + each.policyNumber,
                Mobile_Number__c = assetMap.get(each.policyNumber) == null ? null : assetMap.get(each.policyNumber).Account.Phone
            ));
        }

        List<Database.SaveResult> oppSaveResults = Database.insert(opportunityRecordsToInsert, false);
        responseWrapper.errorRecords = new List<IndividualResponse>();
        
        for (Integer i = 0; i < oppSaveResults.size(); i++) {
            if (!oppSaveResults[i].isSuccess()) {
                responseWrapper.errorRecords.add(new IndividualResponse(null, oppSaveResults[i].getErrors()[0].getMessage(), renewalRequests[i].proposalNumber));
                responseWrapper.hasErrors = true;
            }
        }
        return responseWrapper;
    }

    global class RenewalRequestWrapper {
        global String policyNumber;
        global String proposalNumber;
        global String policyInceptionDate;
    }

    global class RenewalResponseWrapper {
        global List<IndividualResponse> errorRecords;
        global Boolean hasErrors = false;
    }

    global class IndividualResponse {
        global String crmID;
        global String errorMessage;
        global String proposalNumber;

        global IndividualResponse(String crmID, String errorMessage, String proposalNumber) {
            this.crmID = crmID;
            this.errorMessage = errorMessage;
            this.proposalNumber = proposalNumber;
        }
    }

    static Date getDate(String dateValue) {
        try {
            return Date.valueOf(dateValue);
        } catch (Exception ex) {
            return null;
        }
    }
}