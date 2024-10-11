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
    List<String> oppUpdateStatus = new List<String>();
    List<Object> listOfOppRecords = (List<Object>) JSON.deserializeUntyped(oppData.replace('\\', ''));
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

        for(Object each : listOfOppRecords){
        Map<String, Object> eachOppRecord = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(each));
        String oppId = oppIdAndExternalId.get(String.valueOf(eachOppRecord.get('Policy Number')));
        oppListToUpdate.add(new Opportunity(
        Id = oppId,
        Upsell_Eligibility_Flag__c = String.valueOf(eachOppRecord.get('Upsell Eligibility Flag')),
        Propensity_to_Pay__c = String.valueOf(eachOppRecord.get('Propensity to Pay')),
        Renewal_Calling_Flag__c = String.valueOf(eachOppRecord.get('Renewal Calling Flag')),
        Calling_Source__c = String.valueOf(eachOppRecord.get('Calling Source')),
        Upsell_SI_1__c = Integer.valueOf(eachOppRecord.get('Upsell SI 1')),
        Upsell_SI_2__c = Integer.valueOf(eachOppRecord.get('Upsell SI 2')),
        Upsell_SI_3__c = Integer.valueOf(eachOppRecord.get('Upsell SI 3')),
        Upsell_SI_4__c = Integer.valueOf(eachOppRecord.get('Upsell SI 4')),
        Upsell_SI_5__c = Integer.valueOf(eachOppRecord.get('Upsell SI 5')),
        Max_Upsell__c  = Integer.valueOf(eachOppRecord.get('Max Upsell')),
        Bucket__c  = String.valueOf(eachOppRecord.get('Bucket'))
        ));
        }
        Database.SaveResult[] saveResult;
        if(!oppListToUpdate.isEmpty()){
            saveResult = Database.update(oppListToUpdate, false);
        }
        Integer i=0;
        for (Database.SaveResult each : saveResult) {
            if (each.isSuccess()) {
                oppUpdateStatus.add('Success!: Renewal Request Id - ' + each.getId());
            } else {
                List<String> errorMessageList = new List<String>();
                for (Database.Error err : each.getErrors()) {
                    errorMessageList.add('Renewal Request Id : '+oppListToUpdate.get(i).Id + ': ' + err.getMessage());
                }
                oppUpdateStatus.add('Opportunity Update failed due to following reasons : ' + String.join(errorMessageList, ','));
            }
            i++;
        }

    return JSON.serialize(oppUpdateStatus);


    }
}