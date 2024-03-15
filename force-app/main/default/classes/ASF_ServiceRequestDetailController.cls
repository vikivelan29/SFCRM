public without sharing class ASF_ServiceRequestDetailController {
    
    
    @AuraEnabled(cacheable=true)
    public static List<String> fetchSRStages(String type, String subType){
        List<String> stageLst = new List<String>();
        type = String.escapeSingleQuotes(type);
        subType = String.escapeSingleQuotes(subType);
        for(ASF_Case_Stage_Config__c config: [SELECT Id, Case_Category_Config__r.Type__c,Case_Category_Config__r.Sub_Type__c , StageName__c, Order__c 
                                        FROM ASF_Case_Stage_Config__c 
                                        WHERE Case_Category_Config__r.Type__c =: type
                                        AND Case_Category_Config__r.Sub_Type__c =: subType
                                        AND Case_Category_Config__r.Technical_Source__c = 'LWC'
                                        WITH SECURITY_ENFORCED ORDER BY Order__c])
        {
            
            stageLst.add(config.StageName__c);
        }
        
        return stageLst;
    }
    
    @AuraEnabled
    public static Boolean isChecklistCompleted(String caseId){
        caseId = String.escapeSingleQuotes(caseId);
        Boolean isChecklistComplete = true;
        for(ASF_Checklist__c chk : [SELECT Case__c, Id, Status__c FROM ASF_Checklist__c WHERE Case__c =:caseId WITH SECURITY_ENFORCED]){
            if(chk.Status__c != 'Success'){
                isChecklistComplete = false;
            }
        }
        return isChecklistComplete;
    }
}