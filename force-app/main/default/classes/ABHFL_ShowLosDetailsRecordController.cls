public with sharing class ABHFL_ShowLosDetailsRecordController {
   @AuraEnabled
    public static Id getLosDetaisRecord(Id leadId){
        try {
            LOS_Details__c losDetailObj = [SELECT Id From LOS_Details__c WHERE SF_Lead_ID__c =: leadId WITH SECURITY_ENFORCED LIMIT 1];
            Return losDetailObj.Id;
        } catch (Exception e) {
            return null;
            //throw new AuraHandledException(e.getMessage());
        }
    }
}