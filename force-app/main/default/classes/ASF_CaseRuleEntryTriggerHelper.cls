public class ASF_CaseRuleEntryTriggerHelper {
    
    public void updateCaseStageQueryCache(map<id,ASF_Case_Rule_Entry__c> newRulesMap){
        list<ASF_Case_Rule_Entry__c> creList = [select Id,Field_Api_Name__c,Case_Rule__r.Case_Stage_Config__c, Case_Rule__r.Case_Stage_Config__r.Query_Fields__c FROM ASF_Case_Rule_Entry__c where Id IN :newRulesMap.keyset()];
        map<Id,String> cscQueryMap = new map<Id,string>();
        list<ASF_Case_Stage_Config__c> caseStagesUpdate = new list<ASF_Case_Stage_Config__c>();
        if(creList.size() > 0){
            for(ASF_Case_Rule_Entry__c cre: creList){
                if(!cre.Case_Rule__r.Case_Stage_Config__r.Query_Fields__c.contains(cre.Field_Api_Name__c)){
                    if(!cscQueryMap.containsKey(cre.Case_Rule__r.Case_Stage_Config__c)){
                        list<string> queryFields = cre.Case_Rule__r.Case_Stage_Config__r.Query_Fields__c.split('\\,');
                        if(!queryFields.contains(cre.Field_Api_Name__c)){
                            queryFields.add(cre.Field_Api_Name__c);
                            cscQueryMap.put(cre.Case_Rule__r.Case_Stage_Config__c,String.join(queryFields,','));
                        }
                        
                    }else{
                        list<string> queryFields = cre.Case_Rule__r.Case_Stage_Config__r.Query_Fields__c.split('\\,');
                        if(!queryFields.contains(cre.Field_Api_Name__c)){
                            queryFields.add(cre.Field_Api_Name__c);
                            cscQueryMap.put(cre.Case_Rule__r.Case_Stage_Config__c,String.join(queryFields,','));
                        }
                    }
                }
                
            }
        }
        
        if(cscQueryMap.keyset().size() > 0){
            for(Id i: cscQueryMap.keyset()){
                ASF_Case_Stage_Config__c csc=new ASF_Case_Stage_Config__c();
                csc.Id = i;
                csc.Query_Fields__c = cscQueryMap.get(i);
                caseStagesUpdate.add(csc);
            }
        }
        
        
        if(caseStagesUpdate.size() > 0){
            update caseStagesUpdate;
        }
    }
}