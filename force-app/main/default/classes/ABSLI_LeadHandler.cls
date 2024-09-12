public with sharing class ABSLI_LeadHandler {
    public static void afterInsertLogic(List<Lead> leads){
        //List<Lead> lsqLeads = new List<Lead>();
        List<Lead> d2cLeads = new List<Lead>();
        //List<Lead> oneABCLeads = new List<Lead>();
        
        for(Lead ld : leads){
            if(ABSLI_Constants.leadD2CTypeArr.Contains(ld.Lead_Type__c) ||
                   (ld.Asset__c != null && (ld.Policy_Channel__c == 'DM' || ld.Policy_Channel__c == 'Direct Marketing'))){
                d2cLeads.add(ld);
            }
           /* else if(ABSLI_Constants.leadLSQTypeArr.Contains(ld.Lead_Type__c)){
                lsqLeads.add(ld);
            }
            else if(ABSLI_Constants.leadOneABCLeadArr.Contains(ld.Lead_Type__c)){
                oneABCLeads.add(ld);
            } */
        }
        if(d2cLeads.size()>0){
            ABSLI_DtoCLeadIntegration.invokeIntegration(d2cLeads);
        }
        /*
        if(lsqLeads.size()>0){
            ABSLI_LSQLeadIntegration.invokeIntegration(lsqLeads);
        }
		if(oneABCLeads.size()>0){
            ABSLI_OneABCLeadIntegration.invokeIntegration(oneABCLeads);
        } */
        
    }

}