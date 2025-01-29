public with sharing class ABCD_LeadHandler {
    public static void afterInsertLogic(List<Lead> leads){
        List<Lead> sfLMS = new List<Lead>();
		Id salesRecId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Sales').getRecordTypeId();
        for(Lead ld : leads){
            if(ld.Prospect_Type__c == 'Sales' && ld.RecordTypeId == salesRecId){
                sfLMS.add(ld);
            }
        }
        if(sfLMS.size()>0){
            ABCD_SFLMSIntegration.invokeIntegration(sfLMS);
        }
    }

}