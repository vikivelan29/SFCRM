@SuppressWarnings('PMD.ApexSOQLInjection')

public with sharing class ABHFL_BulkCaseUpdateUtility implements ASF_BulkCSVToRecordConverter{
    public ASF_BulkCaseProcessorUtility.ConvertionResult convertJSONRows(Map<Id, String> jsonRows){
        //Each row will be
        //{'Case Number':'00005150','Issue Type Code':'', 'Description':''}
        
        ASF_BulkCaseProcessorUtility.ConvertionResult resultWrapper = new ASF_BulkCaseProcessorUtility.ConvertionResult();
        resultWrapper.resultJSONMapRows = new Map<Id, Map<String, String>>();
        resultWrapper.resultJSONRows = new Map<Id, String>();
        resultWrapper.resultRecords = new Map<Id, SObject>();

        Set<String> caseNumbers = new Set<String>();
        Map<Id, Map<String, String>> rows = new Map<Id, Map<String, String>>();
        for(Id lineItemId : jsonRows.keySet()){
            String eachJSON = jsonRows.get(lineItemId);
            Map<String, String> keyValueMap = (Map<String, String>)JSON.deserialize(eachJSON, Map<String, String>.class);
            if(String.isNotBlank(keyValueMap.get('Case number'))){
                caseNumbers.add(keyValueMap.get('Case number').trim());
            }
            rows.put(lineItemId, keyValueMap);
        }
        
        Map<String, Case> caseNumberToCaseMap = new Map<String,Case>();
        List<User> userList = new List<User>();
        Map<String, ASF_Case_Category_Config__c> caseExternalIdToCaseCategoryConfigMap = new Map<String,ASF_Case_Category_Config__c>();
        for(Case caseRec : [Select Id, CaseNumber,Status, IsClosed, Stage__c, RecordTypeId, CCC_External_Id__c, AccountId, Description, Business_Unit__c from Case where CaseNumber IN :caseNumbers]){
            caseNumberToCaseMap.put(caseRec.CaseNumber, caseRec);
        }
       
        Map<id,ASF_Bulk_Upload_Line_Item__c> lineItemMap = new Map<id,ASF_Bulk_Upload_Line_Item__c>([select id, ownerId from ASF_Bulk_Upload_Line_Item__c where id in :rows.keySet()]);
        Map<String,String> lineItemIdToBusinessMap = new Map<String,String>();
        Map<String,String> lineItemIdToOwnerIdMap = new Map<String,String>();
        if(lineItemMap.values().size()>0){
			for(ASF_Bulk_Upload_Line_Item__c lineItem : lineItemMap.values()){
            	lineItemIdToOwnerIdMap.put(lineItem.id , lineItem.ownerId);
        	}            
        }
        
        Map<id,User> ownerMap = new Map<id,User>([Select id,Business_Unit__c from user where id in :lineItemIdToOwnerIdMap.values()]);
		Map<String,String> ownerIdToBusinessUnitMap = new Map<String,String>();
        if(ownerMap.values().size()>0){
        	for(User owner : ownerMap.values()){
            	ownerIdToBusinessUnitMap.put(owner.id , owner.Business_Unit__c);
        	}    
        }
        
        if(lineItemIdToOwnerIdMap.keySet().size()>0){
        	for(String lineItem : lineItemIdToOwnerIdMap.keySet()){
            	if(lineItemIdToOwnerIdMap.containsKey(lineItem) && ownerIdToBusinessUnitMap.containsKey(lineItemIdToOwnerIdMap.get(lineItem)))
            	lineItemIdToBusinessMap.put(lineItem , ownerIdToBusinessUnitMap.get(lineItemIdToOwnerIdMap.get(lineItem)));
        	}    
        }
        
        Set<String> cccExternalId = New Set<String>();
        for(Id lineItemId : rows.keySet()){           
            Map<String, String> keyValueMap = rows.get(lineItemId);           
            String issueTypeCode = String.isNotBlank(keyValueMap.get('Issue type code'))?keyValueMap.get('Issue type code').trim():keyValueMap.get('Issue type code');
        	cccExternalId.add(issueTypeCode);
        }    
        
        //Fetch user business unit and Case Category Config business unit
        List<ASF_Case_Category_Config__c> caseCategoryConfigList = [Select id,CCC_External_Id__c,Business_Unit__c from ASF_Case_Category_Config__c where CCC_External_Id__c in :cccExternalId];
        for(ASF_Case_Category_Config__c caseExternalIdRec : caseCategoryConfigList){
            caseExternalIdToCaseCategoryConfigMap.put(caseExternalIdRec.CCC_External_Id__c , caseExternalIdRec);
        }
        
        
        for(Id lineItemId : rows.keySet()){
            
            Map<String, String> keyValueMap = rows.get(lineItemId);
            
            String caseNumber = String.isNotBlank(keyValueMap.get('Case number'))?keyValueMap.get('Case number').trim():keyValueMap.get('Case number');
            String issueTypeCode = String.isNotBlank(keyValueMap.get('Issue type code'))?keyValueMap.get('Issue type code').trim():keyValueMap.get('Issue type code');
            String description = String.isNotBlank(keyValueMap.get('Description'))?keyValueMap.get('Description').trim():keyValueMap.get('Description');
            
            if(caseNumber == null || caseNumber.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Case number is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }

            if(issueTypeCode == null || issueTypeCode.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Issue type code is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            
            if(!caseExternalIdToCaseCategoryConfigMap.containsKey(issueTypeCode)){
            	keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message','Please enter valid data');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;    
            }

            if(caseNumberToCaseMap.containsKey(caseNumber) && lineItemIdToBusinessMap.containsKey(lineItemId) && caseExternalIdToCaseCategoryConfigMap.containsKey(issueTypeCode)){
                if(caseNumberToCaseMap.get(caseNumber).Business_Unit__c != lineItemIdToBusinessMap.get(lineItemId) || caseNumberToCaseMap.get(caseNumber).Business_Unit__c != caseExternalIdToCaseCategoryConfigMap.get(issueTypeCode).Business_Unit__c){
                    keyValueMap.put('Result', 'FAILURE');
                    keyValueMap.put('Message','Please enter valid data');
                    resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                    resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                    continue;
            	}    
            }

            if(!caseNumberToCaseMap.containsKey(caseNumber)){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Invalid Case Number');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }

            if(caseNumberToCaseMap.get(caseNumber).RecordTypeId == ASF_Constants.RT_INTERACTION 
            && (caseNumberToCaseMap.get(caseNumber).AccountId == null)){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Case does not have Account tagged');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            
            if(caseNumberToCaseMap.get(caseNumber).IsClosed == true){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Case is already '+caseNumberToCaseMap.get(caseNumber).Stage__c);
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }

            Case caseRec = new Case();
            if(caseNumberToCaseMap.containsKey(caseNumber)){
            	caseRec = caseNumberToCaseMap.get(caseNumber);          
                if(issueTypeCode != null)
                caseRec.CCC_External_Id__c = issueTypeCode;
                if(description != null)
                caseRec.Description = description; 
            }
            
            //Any other BU specific checks - add here
            resultWrapper.resultRecords.put(lineItemId, caseRec);
            resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
        }

        return resultWrapper;
    }

    public List<Map<String,String>> prepareDownloadTemplate(List<String> columnNames, String objectName, Id listViewId, List<String> selectedRecordIds){
        List<Map<String, String>> listOfRecordsAsMap = new List<Map<String, String>>();
        Map<String, String> mapOfFieldApiToColumnName = new Map<String,String>{
            'CaseNumber'=>'Case number',
            'CCC_External_Id__c'=>'Issue type code',
            'Description'=>'Description'
        };
        Map<String, String> mapOfColumnNameToFieldApi = new Map<String,String>{
            'Case number'=>'CaseNumber',
            'Issue type code'=>'CCC_External_Id__c',
            'Description'=>'Description'
        };
        List<String> fieldNames = new List<String>();
        for(String columnName : columnNames){
            if(mapOfColumnNameToFieldApi.containsKey(columnName)){
                fieldNames.add(mapOfColumnNameToFieldApi.get(columnName));
            }
        }
        System.debug('fieldNames'+fieldNames);
        String strFinalQuery;
        if(selectedRecordIds != null && !selectedRecordIds.isEmpty()){
            String strFields = String.join(fieldNames, ',');
            String strWhereClause = ' WHERE ID IN:selectedRecordIds';
            strFinalQuery = 'Select '+ strFields + ' FROM ' + objectName + strWhereClause;
        }
        else if(listViewId != null){
            String strFields = String.join(fieldNames, ',');
            String listViewQuery = ASF_BulkCsvDownloadHelper.getListViewSOQL(objectName, listViewId);
            System.debug('listViewQuery'+listViewQuery);
            String strWhere = '';
            if(listViewQuery.contains('WHERE')){
                strWhere = ' WHERE '+listViewQuery.substringAfter('WHERE');
            }
            
            String strScope = '';
            if(listViewQuery.contains('USING SCOPE')){
                strScope = ' USING SCOPE ' + listViewQuery.substringBetween('SCOPE ',' ') + ' ';
            }
            strFinalQuery = 'Select '+ strFields + ' FROM ' + objectName + strScope + strWhere ;     
        }

        if(String.isNotBlank(strFinalQuery)){
            strFinalQuery = strFinalQuery + ' LIMIT 50000';
            System.debug('strFinalQuery'+strFinalQuery);
            List<SObject> recordsList = Database.query(strFinalQuery);
            for(SObject obj : recordsList){
                Map<String,String> fieldMap = new Map<String,String>();
                for(String fieldName : mapOfFieldApiToColumnName.keySet()){
                    String fieldValue = (String)obj.get(fieldName);
                    fieldValue = fieldValue==null?' ':fieldValue;
                    fieldMap.put(mapOfFieldApiToColumnName.get(fieldName), fieldValue);
                }
                listOfRecordsAsMap.add(fieldMap);
            }
        }

        return listOfRecordsAsMap;
    }
}