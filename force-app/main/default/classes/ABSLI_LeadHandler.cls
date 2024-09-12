public with sharing class ABSLI_LeadHandler {
    public static void afterInsertLogic(List<Lead> leads){
        List<Lead> d2cLeads = new List<Lead>();
        
        for(Lead ld : leads){
            if(ABSLI_Constants.leadD2CTypeArr.Contains(ld.ABSLI_Lead_Type__c) ||
                   (ld.Asset__c != null && (ld.Policy_Channel__c == 'DM' || ld.Policy_Channel__c == 'Direct Marketing'))){
                d2cLeads.add(ld);
            }
        }
        if(d2cLeads.size()>0){
            ABSLI_DtoCLeadIntegration.invokeIntegration(d2cLeads);
        }
    }

}