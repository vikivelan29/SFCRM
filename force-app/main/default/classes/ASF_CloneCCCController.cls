public with sharing class ASF_CloneCCCController {
    
    public static String ignoreFieldsList = 'isdeleted,ownerid,createddate,createdbyid,lastmodifieddate,lastmodifiedbyid,systemmodstamp,lastvieweddate,lastreferenceddate';
    public static String nonQuotesDataType = 'DOUBLE,BOOLEAN,CURRENCY,INTEGER,LONG,PERCENT';
    public static List<String> fieldsToIgnore = ignoreFieldsList.split(',');
    public static List<Schema.DisplayType> nonQuotesJsonList = new List<Schema.DisplayType>();
    public static Map<String,Id> referenceRecordIdMap = new Map<String,Id>();
    public static Map<id,String> recordIdObjectNameMap = new Map<Id,String>();
    
    @AuraEnabled(cacheable = true)
    public static String searchConfig(String type, String subType) {
        String result = 'Success';
        List<ASF_Case_Category_Config__c > caseCategoryConfigList = [SELECT Id, Type__c, Sub_Type__c  
                                                               FROM ASF_Case_Category_Config__c  
                                                               WHERE Type__c = :type AND Sub_Type__c = :subType ];
        
        if(!caseCategoryConfigList.isEmpty()) {
            result = 'Error';
        }
        return result; 
    }

    @AuraEnabled(Cacheable = true)
    public static Map<String,String> cloneConfigData(String configId, String typeVal, String subType) {
        
        Map<String,String> resultMap = new Map<String,String>();
        String treeRequest = '';
        List<Id> stageIdList = new List<Id>();
        List<Id> caseRulesIdList = new List<Id>();
        Map<Id,List<ASF_Case_Rule__c>> stageIdCaseRulesMap = new Map<Id,List<ASF_Case_Rule__c>>();
        Map<Id,List<ASF_Work_Item__c>> ruleIdWorkItemsMap = new Map<Id,List<ASF_Work_Item__c>>();
        Map<Id,List<ASF_Case_Checklist_Master__c>> ruleIdCheckListItemsMap = new Map<Id,List<ASF_Case_Checklist_Master__c>>();
        Map<Id,List<ASF_Case_Rule_Entry__c>> ruleIdCaseRulesEntryMap = new Map<Id,List<ASF_Case_Rule_Entry__c>>();
        
        nonQuotesJsonList.add(Schema.DisplayType.DOUBLE);
        nonQuotesJsonList.add(Schema.DisplayType.BOOLEAN);
        nonQuotesJsonList.add(Schema.DisplayType.CURRENCY);
        nonQuotesJsonList.add(Schema.DisplayType.INTEGER);
        nonQuotesJsonList.add(Schema.DisplayType.LONG);
        nonQuotesJsonList.add(Schema.DisplayType.PERCENT);
        
		Map<String, Schema.SObjectField> cccFieldMap = Schema.SObjectType.ASF_Case_Category_Config__c.fields.getMap();
        Map<String, Schema.SObjectField> cscFieldMap = Schema.SObjectType.ASF_Case_Stage_Config__c.fields.getMap();
        Map<String, Schema.SObjectField> cfcFieldMap = Schema.SObjectType.ASF_Case_Field_Config__c.fields.getMap();
        Map<String, Schema.SObjectField> caseRuleFieldMap = Schema.SObjectType.ASF_Case_Rule__c.fields.getMap();
        Map<String, Schema.SObjectField> creFieldMap = Schema.SObjectType.ASF_Case_Rule_Entry__c.fields.getMap();
        Map<String, Schema.SObjectField> checklistFieldMap = Schema.SObjectType.ASF_Case_Checklist_Master__c.fields.getMap();
        Map<String, Schema.SObjectField> workItemFieldMap = Schema.SObjectType.ASF_Work_Item__c.fields.getMap();
        
        //Case Category Config
        List<ASF_Case_Category_Config__c> cccRecordList = Database.query(generateQuery('ASF_Case_Category_Config__c', cccFieldMap, 'Id', configId, null));

        //Case Stage Config
        List<ASF_Case_Stage_Config__c> stageList = Database.query(generateQuery('ASF_Case_Stage_Config__c', cscFieldMap, 'Case_Category_Config__c', configId, null));
 
        for(ASF_Case_Stage_Config__c stageRec : stageList ){
            stageIdList.add(stageRec.Id);
        }
        //Case Field Config
        List<ASF_Case_Field_Config__c> fieldConfigList = Database.query(generateQuery('ASF_Case_Field_Config__c', cfcFieldMap, 'Case_Main_Config__c', configId, null));
        //Case Rule
        List<ASF_Case_Rule__c> caseRuleList = Database.query(generateQuery('ASF_Case_Rule__c', caseRuleFieldMap,'Case_Stage_Config__c','', stageIdList));
        
        for(ASF_Case_Rule__c cr : caseRuleList){
            caseRulesIdList.add(cr.Id);
            if(stageIdCaseRulesMap.get(cr.Case_Stage_Config__c) != null){
                List<ASF_Case_Rule__c> currentRules = stageIdCaseRulesMap.get(cr.Case_Stage_Config__c);
                currentRules.add(cr);
                stageIdCaseRulesMap.put(cr.Case_Stage_Config__c,currentRules);
            }
            else{
                stageIdCaseRulesMap.put(cr.Case_Stage_Config__c,new List<ASF_Case_Rule__c>{cr});
            }
        }
        //Work Item
        List<ASF_Work_Item__c> workItemList = Database.query(generateQuery('ASF_Work_Item__c', workItemFieldMap,'Case_Rule__c','', caseRulesIdList));
        
        for(ASF_Work_Item__c wiRec: workItemList){
            if(ruleIdWorkItemsMap.get(wiRec.Case_Rule__c) != null){
                List<ASF_Work_Item__c> currentRules = ruleIdWorkItemsMap.get(wiRec.Case_Rule__c);
                currentRules.add(wiRec);
                ruleIdWorkItemsMap.put(wiRec.Case_Rule__c,currentRules);
            }
            else{
                ruleIdWorkItemsMap.put(wiRec.Case_Rule__c,new List<ASF_Work_Item__c>{wiRec});
            }
        }
        //Checklist
        List<ASF_Case_Checklist_Master__c> checklistList = Database.query(generateQuery('ASF_Case_Checklist_Master__c', checklistFieldMap,'Case_Rule__c','', caseRulesIdList));
        for(ASF_Case_Checklist_Master__c checklistRec : checklistList){
            if(ruleIdCheckListItemsMap.get(checklistRec.Case_Rule__c) != null){
                List<ASF_Case_Checklist_Master__c> currentRules = ruleIdCheckListItemsMap.get(checklistRec.Case_Rule__c);
                currentRules.add(checklistRec);
                ruleIdCheckListItemsMap.put(checklistRec.Case_Rule__c,currentRules);
            }
            else{
                ruleIdCheckListItemsMap.put(checklistRec.Case_Rule__c,new List<ASF_Case_Checklist_Master__c>{checklistRec});
            }
        }
        //Case Rule Entry
        List<ASF_Case_Rule_Entry__c> crEntryList = Database.query(generateQuery('ASF_Case_Rule_Entry__c', creFieldMap,'Case_Rule__c','', caseRulesIdList));
        for(ASF_Case_Rule_Entry__c cre : crEntryList){
            if(ruleIdCaseRulesEntryMap.get(cre.Case_Rule__c) != null){
                List<ASF_Case_Rule_Entry__c> currentRules = ruleIdCaseRulesEntryMap.get(cre.Case_Rule__c);
                currentRules.add(cre);
                ruleIdCaseRulesEntryMap.put(cre.Case_Rule__c,currentRules);
            }
            else{
                ruleIdCaseRulesEntryMap.put(cre.Case_Rule__c,new List<ASF_Case_Rule_Entry__c>{cre});
            }
        }
        
        //Create JSON body
        if(!cccRecordList.isEmpty()){
            treeRequest = populateCCCData(treeRequest, cccRecordList[0], typeVal, subType, cccFieldMap);
        }
        if(!stageList.isEmpty()){
            for(ASF_Case_Stage_Config__c stageRecord :stageList){
                String stageRef = 'refStageConfig' + stageRecord.Id;
                treeRequest = populateCaseStageConfig(treeRequest, stageRef, stageRecord, cscFieldMap);
                
                if(stageIdCaseRulesMap.containsKey(stageRecord.Id)){
                    for(ASF_Case_Rule__c ruleRecord :stageIdCaseRulesMap.get(stageRecord.Id)){
                        String stageRef1 = '"@{' +stageRef + '.id}"';
                        String ruleReference =  '"refRuleConfig' + ruleRecord.Id;
                        String ruleforReference =  'refRuleConfig' + ruleRecord.Id;
                        treeRequest = populateCaseRule(treeRequest, stageRef1, ruleReference, ruleforReference, ruleRecord, caseRuleFieldMap);
                        
                        if(ruleIdWorkItemsMap.containsKey(ruleRecord.Id)){
                            for(ASF_Work_Item__c workRecord :ruleIdWorkItemsMap.get(ruleRecord.Id)){
                                treeRequest = populateWorkItem(treeRequest, ruleforReference, workRecord, workItemFieldMap);
                            }
                        }
                        if(ruleIdCheckListItemsMap.containsKey(ruleRecord.Id)){
                            for(ASF_Case_Checklist_Master__c checkRecord :ruleIdCheckListItemsMap.get(ruleRecord.Id) ){
                                treeRequest = populateChecklist(treeRequest, ruleforReference, checkRecord, checklistFieldMap);
                            }
                        }
                        if(ruleIdCaseRulesEntryMap.containsKey(ruleRecord.Id)){
                            for(ASF_Case_Rule_Entry__c ruleEntryRecord :ruleIdCaseRulesEntryMap.get(ruleRecord.Id) ){
                                treeRequest = populateCaseRuleEntry(treeRequest, ruleforReference, ruleEntryRecord, creFieldMap);
                            }
                        }
                    }
                }
            }   
        }
        for(ASF_Case_Field_Config__c eachConfigRecord : fieldConfigList){
            treeRequest = populateCaseFieldConfig(treeRequest, eachConfigRecord, cfcFieldMap);
        }
        treeRequest += ']}]}';
		//resultMap.put('reqjson',treeRequest);
		String strFormattedJSON = String.isNotBlank(treeRequest) ? (treeRequest.replaceAll('\n','').replaceAll('\r','')) : '';
		resultMap = compositeCallout(strFormattedJSON);
        return resultMap;
    }
    
    public static Map<String,String> compositeCallout(String strFormattedJSON){
        Map<String,String> resultMap = new Map<String,String>();
        HttpRequest req = new HttpRequest();
        Boolean isSuccess; 
        String recordIdCreated;
        List<GraphErrors> errorList = new List<GraphErrors>(); 
        
     	req.setBody(strFormattedJSON) ;
     	req.setMethod('POST'); 
        String baseUrl = URL.getOrgDomainURL().toExternalForm();
        req.setEndpoint('callout:cloneconfig' + '/services/data/v57.0/composite/graph');	
        req.setHeader('Content-Type', 'application/json');
     	Http http = new Http();
     	HTTPResponse res = http.send(req);
        String errorResponse = res.getBody();
        system.debug('CloneFrameworkConfguration.getConfigData Reponse :>>' + errorresponse);

        if (!errorResponse.startsWith('[') && errorResponse.indexOf('PROCESSING_HALTED') == -1){
            Map <String,Object> outerGraph = (Map<String,Object>)JSON.deserializeUntyped(errorResponse);
            list<Object> graphNode = (List<Object>)outerGraph.get('graphs');
            for(Object r: graphNode){
                Map<String,Object> p = (Map<String,Object>)r;
                Map<String,Object> q = (Map<String,Object>)p.get('graphResponse');
                List<Object> composteList = (List<Object>)q.get('compositeResponse');
                for(Object r2: composteList){
                    Map<String,Object> compsiteRecord = (Map<String,Object>)r2;
                    Map<String,Object> bodyNode = (Map<String,Object>)compsiteRecord.get('body');
                    isSuccess = (boolean)bodyNode.get('success');
                    recordIdCreated = (String)bodyNode.get('id');
                    break;
                }    
             }
            if(isSuccess){
                resultMap.put('state','success');
                resultMap.put('recordId',recordIdCreated);
            }	
        }   
        else{
            errorList = getErrorList(errorResponse, errorList, referenceRecordIdMap, recordIdObjectNameMap);
        }

        if(errorList != null && errorList.size() > 0){
            resultMap.put('state','failure');
            resultMap.put('error',JSON.serialize(errorList));
        }  
        return resultMap;
    }
        
    public static String generateQuery(String objectName, Map<String, Schema.SObjectField> fieldMap, String whereField, String wherevalue, List<Id> whereList){
        String queryFields = 'SELECT ';
        for(String fieldName : fieldMap.keySet()) {
            // Exclude unnecessary fields
            if(!fieldsToIgnore.contains(fieldName)) {
                queryFields += fieldName + ', ';
            }
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
    
    public static String populateCCCData(String treeRequest, ASF_Case_Category_Config__c cccRec, String typeVal, String subType, Map<String, Schema.SObjectField> cccFieldMap) {
        referenceRecordIdMap.put('refCategoryConfig',cccRec.id);
        recordIdObjectNameMap.put(cccRec.id,'Case Category Config');
        List<String> ignoreFieldsList = new List<String>{'ccc_external_id__c','type__c','sub_type__c','id'};
        treeRequest = '{"graphs" : [{"graphId" : "1","compositeRequest" : [{"method" : "POST",';
        treeRequest += '"url" : "/services/data/v57.0/sobjects/ASF_Case_Category_Config__c",';
        treeRequest += '"referenceId" : "refCategoryConfig",';
        treeRequest += '"body" : { "Type__c" :' +  '"' + typeVal  + '"' + ',';
        treeRequest += '"Sub_Type__c" :' +  '"' + subType  + '"' + ',';
        treeRequest += '"ccc_external_id__c" :' +  '"' + generateUniqueString()  + '"' + ',';
        
        treeRequest += mapfields((SObject)cccRec, ignoreFieldsList, cccFieldMap, 'ASF_Case_Category_Config__c');
        
        return treeRequest;
    }
    
    public static String populateCaseStageConfig(String treeRequest, String stageRef, ASF_Case_Stage_Config__c stageRecord ,Map<String, Schema.SObjectField> cscFieldMap) {
        List<String> ignoreFieldsList = new List<String>{'stage_external_id__c','id'};
        referenceRecordIdMap.put(stageRef,stageRecord.id);
        recordIdObjectNameMap.put(stageRecord.id,'Case Stage Config');
        treeRequest += ',{"method" : "POST","url" : "/services/data/v57.0/sobjects/ASF_Case_Stage_Config__c",';
        treeRequest += '"referenceId" : "'+stageRef +'",';
        treeRequest += '"body" : { "Case_Category_Config__c" :' +  '"@{refCategoryConfig.id}"' +  + ',';
        treeRequest += '"Stage_External_Id__c" :' +  '"' + generateUniqueString()  + '"' + ',';
    	
        treeRequest += mapfields((SObject)stageRecord, ignoreFieldsList, cscFieldMap, 'ASF_Case_Stage_Config__c');
        
        return treeRequest;
    }
    
    public static String populateCaseRule(String treeRequest, String stageRef1, String ruleReference, String ruleForReference, ASF_Case_Rule__c ruleRecord ,Map<String, Schema.SObjectField> caseRuleFieldMap){
        List<String> ignoreFieldsList = new List<String>{'external_id__c','id'};
        //String ruleReference1 =  'refRuleConfig' + ruleRecord.Id;
        referenceRecordIdMap.put(ruleForReference,ruleRecord.id);
        recordIdObjectNameMap.put(ruleRecord.id,'Case Rule');
        
        treeRequest += ',{"method" : "POST","url" : "/services/data/v57.0/sobjects/ASF_Case_Rule__c",';
        treeRequest += '"referenceId" :' + ruleReference +'",';
        treeRequest += '"body" : { "Case_Stage_Config__c" :' +  stageRef1 +  + ',';
        treeRequest += '"External_ID__c" :' +  '"' + generateUniqueString()  + '"' + ',';
        
        treeRequest += mapfields((SObject)ruleRecord, ignoreFieldsList, caseRuleFieldMap, 'ASF_Case_Rule__c');
        
        return treeRequest;
    }
    
    public static String populateWorkItem(String treeRequest, String ruleReference, ASF_Work_Item__c workRecord ,Map<String, Schema.SObjectField> workItemFieldMap){
        List<String> ignoreFieldsList = new List<String>{'work_item_external_id__c','id'};
        referenceRecordIdMap.put('refWorkItemsConfig' + workRecord.Id ,workRecord.id);
        recordIdObjectNameMap.put(workRecord.id,'Work Items');
        
        treeRequest += ',{"method" : "POST","url" : "/services/data/v57.0/sobjects/ASF_Work_Item__c",';
        treeRequest += '"referenceId" : "refWorkItemsConfig' + workRecord.Id +'",';
        treeRequest += '"body" : { "Case_Rule__c" :' +  '"@{' +ruleReference + '.id}"'  + ',';
        treeRequest += '"Work_Item_External_ID__c" :' +  '"' + generateUniqueString()  + '"' + ',';
                
        treeRequest += mapfields((SObject)workRecord, ignoreFieldsList, workItemFieldMap, 'ASF_Work_Item__c');
        
        return treeRequest;
    }
    
    public static String populateChecklist(String treeRequest, String ruleReference, ASF_Case_Checklist_Master__c checkRecord ,Map<String, Schema.SObjectField> checklistFieldMap){
        List<String> ignoreFieldsList = new List<String>{'checklist_external_id__c','id'};
        referenceRecordIdMap.put('refCheckListMaster' + checkRecord.Id ,checkRecord.id);
        recordIdObjectNameMap.put(checkRecord.id,'Checklist Items');
        treeRequest += ',{"method" : "POST","url" : "/services/data/v57.0/sobjects/ASF_Case_Checklist_Master__c",';
        treeRequest += '"referenceId" : "refCheckListMaster' + checkRecord.Id +'",';
        treeRequest += '"body" : { "Case_Rule__c" :' +  '"@{' +ruleReference + '.id}"'  + ',';
        treeRequest += '"checklist_external_id__c" :' +  '"' + generateUniqueString()  + '"' + ',';
                
        treeRequest += mapfields((SObject)checkRecord, ignoreFieldsList, checklistFieldMap, 'ASF_Case_Checklist_Master__c');
        
        return treeRequest;
    }
    
    public static String populateCaseRuleEntry(String treeRequest, String ruleReference, ASF_Case_Rule_Entry__c ruleEntryRecord ,Map<String, Schema.SObjectField> creFieldMap){
        List<String> ignoreFieldsList = new List<String>{'external_id__c','id'};
        referenceRecordIdMap.put('refRuleConfig' + ruleEntryRecord.Id ,ruleEntryRecord.id);
        recordIdObjectNameMap.put(ruleEntryRecord.id,'Case Rule Entry');
        String ruleRef = '"@{' +ruleReference + '.id}"';
        treeRequest += ',{"method" : "POST","url" : "/services/data/v57.0/sobjects/ASF_Case_Rule_Entry__c",';
        treeRequest += '"referenceId" : "refRuleConfig' + ruleEntryRecord.Id +'",'; 
        treeRequest += '"body" : { "Case_Rule__c" :' +  ruleRef +  + ',';
        treeRequest += '"External_ID__c" :' +  '"' + generateUniqueString()  + '"' + ',';
        
        treeRequest += mapfields((SObject)ruleEntryRecord, ignoreFieldsList, creFieldMap, 'ASF_Case_Rule_Entry__c');
        
        return treeRequest;
    }
    
    public static String populateCaseFieldConfig(String treeRequest, ASF_Case_Field_Config__c eachConfigRecord ,Map<String, Schema.SObjectField> cfcFieldMap) {
        List<String> ignoreFieldsList = new List<String>{'field_external_id__c','id','field_external_id_c__c'};
        referenceRecordIdMap.put('ASF_Case_Field_Config__c' + eachConfigRecord.Id ,eachConfigRecord.id);
        recordIdObjectNameMap.put(eachConfigRecord.id,'Case Field Config');
        treeRequest += ',{"method" : "POST","url" : "/services/data/v57.0/sobjects/ASF_Case_Field_Config__c",';
        treeRequest += '"referenceId" : "ASF_Case_Field_Config__c' + eachConfigRecord.Id +'",';
        treeRequest += '"body" : { "Case_Main_Config__c" :' +  '"@{refCategoryConfig.id}"' +  + ',';
        treeRequest += '"Field_External_Id_c__c" :' +  '"' + generateUniqueString()  + '"' + ',';
        //treeRequest += '"Field_External_Id__c" :' +  '"' + 'staticString'  + '"' + ',';
        
        treeRequest += mapfields((SObject)eachConfigRecord, ignoreFieldsList, cfcFieldMap, 'ASF_Case_Field_Config__c');
        
        return treeRequest;
    }
    
    public static string mapfields(SObject configRec, List<String> ignoreFieldsList, Map<String, Schema.SObjectField> fieldMap, String objectName){
        String treeRequest = '';
        
        for(String fieldName : fieldMap.keySet()) {
            if(!fieldsToIgnore.contains(fieldName) && !ignoreFieldsList.contains(fieldName) && fieldMap.get(fieldName).getDescribe().getType() != Schema.DisplayType.REFERENCE &&
              !fieldMap.get(fieldName).getDescribe().isCalculated() && !fieldMap.get(fieldName).getDescribe().isAutoNumber()) {
                if(nonQuotesJsonList.contains(fieldMap.get(fieldName).getDescribe().getType()) && configRec.get(fieldName) != null){
                    treeRequest += '"'+fieldName+'" : '+ configRec.get(fieldName) +',';
                }
                else if(fieldMap.get(fieldName).getDescribe().getType() == Schema.DisplayType.DATETIME && configRec.get(fieldName) != null){
                    String strDateString = DateTime.valueOf(configRec.get(fieldName)).formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                    treeRequest += '"'+fieldName+'" : "' + strDateString + '"' + ',';
                }
                else if(configRec.get(fieldName) != null && configRec.get(fieldName) != ''){
                    String val = String.valueOf(configRec.get(fieldName));
                    val = val.replaceAll('"', '\'');
                    treeRequest += '"'+fieldName+'" :' +  '"' + val + '"' + ',';
                }
            }
        }
        treeRequest = treeRequest.substring(0, treeRequest.length() - 1);
        treeRequest  += '}';
        treeRequest  += '}';
        return treeRequest;
    }
    
    public static List<GraphErrors> getErrorList(String strErrorResponse, List<GraphErrors> errorList, 
                                               Map<String,Id> referenceRecordIdMap, Map<id,String> recordIdObjectNameMap){
        
    if(String.isnotBlank(strErrorResponse) &&  strErrorResponse.startsWith('[') && strErrorResponse.indexOf('message') > 0 &&
        strErrorResponse.indexOf('errorCode') > 0){
        List<ASF_GraphResponse.cls_body> lstErrorResponse = ( List<ASF_GraphResponse.cls_body>)System.JSON.deserialize(strErrorResponse, List<ASF_GraphResponse.cls_body>.class);
        GraphErrors objGraphError = new GraphErrors();
        objGraphError.errorMessages = '';
        if(lstErrorResponse != null && lstErrorResponse.size()>0){
            for(ASF_GraphResponse.cls_body objerror: lstErrorResponse){
                objGraphError.errorMessages+= objerror.message + '\n';
            }
        }
        else{
            objGraphError.errorMessages = 'An unexpected error occured. Please connect with System Administrator';
        }
        errorList.add(objGraphError);
    }   
    else {
        //json response of composite graph has \n and it creates problem in parsing.
        strErrorResponse = strErrorResponse.replace('\n','');
        ASF_GraphResponse j = (ASF_GraphResponse)System.JSON.deserialize(strErrorResponse, ASF_GraphResponse.class);
        system.debug(j.graphs[0].graphResponse.compositeResponse);
        ASF_GraphResponse.cls_compositeResponse[] compositeList = j.graphs[0].graphResponse.compositeResponse;
    
            for(ASF_GraphResponse.cls_compositeResponse eachRecord : compositeList){
                if (String.Valueof(eachRecord.httpStatusCode) != 'PROCESSING_HALTED'){
                    GraphErrors k = new GraphErrors();
                    k.referenceId = eachRecord.referenceId;
                    k.recordId = referenceRecordIdMap.get(k.referenceId);
                    k.objectName = recordIdObjectNameMap.get(k.recordId);
                    k.errorMessages = '';
                    ASF_GraphResponse.cls_body[] bodyList = eachRecord.body;
                    for(ASF_GraphResponse.cls_body b: bodyList){
                            k.errorMessages += b.message + '\n';
                    }
                    errorList.add(k);
                }
            }
        }
        return errorList;
    }
    
    public static string generateUniqueString(){
        UUID randomUUID = UUID.randomUUID();
        return randomUUID.toString();
        
    }
    
    public class GraphErrors {
        public String objectName;
        public String errorMessages;
        public Id recordId;
        public String referenceId;
	}
}