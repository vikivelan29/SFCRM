/**
* @File Name : opportunityDataController.cls
* @Description : Opportunity Bulk Upload, Updates opportunity records based on policy number.
* @Author : Suhana
* @Last Modified By :
* @Last Modified On : September 25, 2024
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | September 25, 2024 |   | Initial Version
**/

public class RNWL_OpportunityDataController {
    @AuraEnabled
    public static String updateOpportunityRecords(String oppData) {
    System.debug('@@oppData '+oppData);
    List<String> oppUpdateStatus = new List<String>();
    List<Object> listOfOppRecords = (List<Object>) JSON.deserializeUntyped(oppData.replace('\\', ''));
    System.debug('@@listOfOppRecords '+listOfOppRecords);
    Set<String> externalIdSet = new Set<String>();
    List<Opportunity> oppListToUpdate = new List<Opportunity>();
     
    for (Object each : listOfOppRecords) {
            Map<String, Object> eachOppRecord = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(each));
            
            String policyNo = String.valueOf(eachOppRecord.get('Policy Number'));
            externalIdSet.add(policyNo);
        }
        List<Opportunity> oppList = [Select Id,Policy_Number__c from Opportunity where Policy_Number__c IN:externalIdSet];
        Map<String,String> oppIdAndExternalId = new Map<String,String>();
        for(Opportunity opp : oppList){
            oppIdAndExternalId.put(opp.Policy_Number__c,opp.Id);
        }
        System.debug('@@oppIdAndExternalId '+oppIdAndExternalId);

        for(Object each : listOfOppRecords){
        Map<String, Object> eachOppRecord = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(each));
        String oppId = oppIdAndExternalId.get(String.valueOf(eachOppRecord.get('Policy Number')));
        oppListToUpdate.add(new Opportunity(
        Id = oppId,
        Upsell_Eligibility_Flag__c = String.valueOf(eachOppRecord.get('Upsell Eligibility Flag')),
        Propensity_to_Pay__c = String.valueOf(eachOppRecord.get('Propensity to Pay')),
        Renewal_Calling_Flag__c = String.valueOf(eachOppRecord.get('Renewal Calling Flag')),
        Calling_Source__c = String.valueOf(eachOppRecord.get('Calling Source'))
        ));
        }
        Database.SaveResult[] saveResult;
        if(!oppListToUpdate.isEmpty()){
            saveResult = Database.update(oppListToUpdate, false);
            System.debug('@@@saveResult' +saveResult);
        }
        for (Database.SaveResult each : saveResult) {
            if (each.isSuccess()) {
                oppUpdateStatus.add('Success!');
            } else {
                List<String> errorMessageList = new List<String>();
                for (Database.Error err : each.getErrors()) {
                    errorMessageList.add(err.getMessage());
                }
                oppUpdateStatus.add('Opportunity Update failed due to following reasons - ' + String.join(errorMessageList, ','));
            }
        }

    return JSON.serialize(oppUpdateStatus);


    }
}