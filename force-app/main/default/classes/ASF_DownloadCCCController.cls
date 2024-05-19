public class ASF_DownloadCCCController {
    
    public Id cccId {get;set;}
    
    public ASF_DownloadCCCController(ApexPages.StandardController stdController) {
        ASF_Case_Category_Config__c casecategoryRecord = (ASF_Case_Category_Config__c)stdController.getRecord();
        cccId = casecategoryRecord.Id;
    }
    
    @RemoteAction
    public static List<Map<String,Object>> getConfigData(String configId) {
        List<Map<String,Object>> resultMap = new List<Map<String,Object>>();
        List<Id> stageIdList = new List<Id>();
        List<Id> caseRulesIdList = new List<Id>();
        Map<String, Schema.SObjectField> cccFieldMap = Schema.SObjectType.ASF_Case_Category_Config__c.fields.getMap();
        Map<String, Schema.SObjectField> cscFieldMap = Schema.SObjectType.ASF_Case_Stage_Config__c.fields.getMap();
        Map<String, Schema.SObjectField> cfcFieldMap = Schema.SObjectType.ASF_Case_Field_Config__c.fields.getMap();
        Map<String, Schema.SObjectField> caseRuleFieldMap = Schema.SObjectType.ASF_Case_Rule__c.fields.getMap();
        Map<String, Schema.SObjectField> creFieldMap = Schema.SObjectType.ASF_Case_Rule_Entry__c.fields.getMap();
        Map<String, Schema.SObjectField> checklistFieldMap = Schema.SObjectType.ASF_Case_Checklist_Master__c.fields.getMap();
        Map<String, Schema.SObjectField> workItemFieldMap = Schema.SObjectType.ASF_Work_Item__c.fields.getMap();
        
        //Case Category Config
        List<ASF_Case_Category_Config__c> cccRecordList = Database.query(generateQuery('ASF_Case_Category_Config__c', cccFieldMap, 'Id', configId, null));
        resultMap.add(new Map<String, Object>{'name' => 'ASF_Case_Category_Config__c','data' => cccRecordList});

        //Case Stage Config
        List<ASF_Case_Stage_Config__c> stageList = Database.query(generateQuery('ASF_Case_Stage_Config__c', cscFieldMap, 'Case_Category_Config__c', configId, null));
        resultMap.add(new Map<String, Object>{'name' => 'ASF_Case_Stage_Config__c','data' => stageList});
        for(ASF_Case_Stage_Config__c stageRec : stageList){
            stageIdList.add(stageRec.Id);
        }
        
        //Case Field Config
        List<ASF_Case_Field_Config__c> fieldConfigList = Database.query(generateQuery('ASF_Case_Field_Config__c', cfcFieldMap, 'Case_Main_Config__c', configId, null));
        resultMap.add(new Map<String, Object>{'name' => 'ASF_Case_Field_Config__c','data' => fieldConfigList});
        
        //Case Rule
        List<ASF_Case_Rule__c> caseRuleList = Database.query(generateQuery('ASF_Case_Rule__c', caseRuleFieldMap,'Case_Stage_Config__c','', stageIdList));
        resultMap.add(new Map<String, Object>{'name' => 'ASF_Case_Rule__c','data' => caseRuleList});
        for(ASF_Case_Rule__c cr : caseRuleList){
            caseRulesIdList.add(cr.Id);
        }
        //Work Item
        List<ASF_Work_Item__c> workItemList = Database.query(generateQuery('ASF_Work_Item__c', workItemFieldMap,'Case_Rule__c','', caseRulesIdList));
        resultMap.add(new Map<String, Object>{'name' => 'ASF_Work_Item__c','data' => workItemList});
        
        //Checklist
        List<ASF_Case_Checklist_Master__c> checklistList = Database.query(generateQuery('ASF_Case_Checklist_Master__c', checklistFieldMap,'Case_Rule__c','', caseRulesIdList));
        resultMap.add(new Map<String, Object>{'name' => 'ASF_Case_Checklist_Master__c','data' => checklistList});
        
        //Case Rule Entry
        List<ASF_Case_Rule_Entry__c> crEntryList = Database.query(generateQuery('ASF_Case_Rule_Entry__c', creFieldMap,'Case_Rule__c','', caseRulesIdList));
        resultMap.add(new Map<String, Object>{'name' => 'ASF_Case_Rule_Entry__c','data' => crEntryList});
       
        return resultMap;
    }
    
    public static String generateQuery(String objectName, Map<String, Schema.SObjectField> fieldMap, String whereField, String wherevalue, List<Id> whereList){
        String queryFields = 'SELECT ';
        for(String fieldName : fieldMap.keySet()) {
            queryFields += fieldName + ', ';
        }
        queryFields = queryFields.substring(0, queryFields.length() - 2); // Remove the trailing comma and space
        if(whereList != null){
			String parentIds = '\'' + String.join(whereList, '\',\'') + '\'';
            queryFields += ' FROM ' + objectName + ' WHERE '+whereField+ ' IN (' + parentIds + ')';
        }else{
            queryFields += ' FROM '+objectName+' WHERE '+whereField+ ' = \'' + wherevalue + '\'';
        }
        return queryFields;
    }
 
}