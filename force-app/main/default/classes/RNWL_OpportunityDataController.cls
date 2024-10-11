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

public without sharing class RNWL_OpportunityDataController {
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
    }

    public class OpportunityDataWrapper{
        @AuraEnabled public String policyNumber;
        @AuraEnabled public String oppName;
        @AuraEnabled public String oppId;
        @AuraEnabled public String finalEligibilityFlag;
        @AuraEnabled public String propensityToPay;
        @AuraEnabled public String renewalCallingFlag;
        @AuraEnabled public String callingSource;
        @AuraEnabled public Decimal upsellSI1;
        @AuraEnabled public Decimal upsellSI2;
        @AuraEnabled public Decimal upsellSI3;
        @AuraEnabled public Decimal upsellSI4;
        @AuraEnabled public Decimal upsellSI5;
        @AuraEnabled public Decimal maxUpsell;
        @AuraEnabled public String bucket;
        @AuraEnabled public String status;
        @AuraEnabled public String response;

        public OpportunityDataWrapper(String oppId,String oppName,String policyNumber,String finalEligibilityFlag,String propensityToPay,String renewalCallingFlag,String callingSource,Decimal upsellSI1, Decimal upsellSI2,Decimal upsellSI3,
        Decimal upsellSI4,Decimal upsellSI5,Decimal maxUpsell,String bucket,String status,String response){

            this.oppId = '/'+oppId;
            this.oppName = oppName;
            this.policyNumber = policyNumber;
            this.finalEligibilityFlag = finalEligibilityFlag;
            this.propensityToPay = propensityToPay;
            this.renewalCallingFlag = renewalCallingFlag;
            this.callingSource = callingSource;
            this.upsellSI1 = upsellSI1;
            this.upsellSI2 = upsellSI2;
            this.upsellSI3 = upsellSI3;
            this.upsellSI4 = upsellSI4;
            this.upsellSI5 = upsellSI5;
            this.maxUpsell = maxUpsell;
            this.bucket = bucket;
            this.status = status;
            this.response = response;
        }

    }
}