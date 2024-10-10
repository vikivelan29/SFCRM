/*********************************************************
*Class        :  ABSLAMC_BulkCreateCaseConverterUtility
*Author       :  Asmita Mathur
*Created Date :  24/09/2024
*Last Modified:  24/09/2024
*Description  :  Class for bulk case creation
*********************************************************/
@SuppressWarnings('PMD.ApexSOQLInjection')

public with sharing class ABSLAMC_BulkCreateCaseConverterUtility implements ASF_BulkCSVToRecordConverter{
    public ASF_BulkCaseProcessorUtility.ConvertionResult convertJSONRows(Map<Id, String> jsonRows){
        //Each row will be
        //{'LOB':'MF','Issue Code':'MF1234', 'Category': 'Nature', 'Type' : 'Dcreject', 'Sub-Type': 'dcreject-checkquepayment','CLIENT CODE (LOB + PAN/PEKRN)' : 'MF-22344',
        //'Folio':'1234566899','Owner Team': 'queue name', 'Owner AD ID': 'federation Id','Source':'Email','Channel': 'Social Media','Caller Type': 'Investor','Critical Request flag (Y/N)': 'Yes','PHD Compaint Source' : '', 'Description':'DescriptionXYZ', 'Send Auto Communication?':TRUE}

        ASF_BulkCaseProcessorUtility.ConvertionResult resultWrapper = new ASF_BulkCaseProcessorUtility.ConvertionResult();
        resultWrapper.resultJSONMapRows = new Map<Id, Map<String, String>>();
        resultWrapper.resultJSONRows = new Map<Id, String>();
        resultWrapper.resultRecords = new Map<Id, SObject>();

        Set<String> lans = new Set<String>();
        Set<String> cccExtIds = new Set<String>();
        Set<String> clientCodes = new Set<String>();
        Set<String> ownerTeamNames = new Set<String>();
        Set<String> ownerADIds = new Set<String>();
        Map<Id, Map<String, String>> rows = new Map<Id, Map<String, String>>();
        for(Id lineItemId : jsonRows.keySet()){
            String eachJSON = jsonRows.get(lineItemId);
            System.debug('eachJSON'+eachJSON);
            Map<String, String> keyValueMap = (Map<String, String>)JSON.deserialize(eachJSON, Map<String, String>.class);
            if(String.isNotBlank(keyValueMap.get('Folio'))){
                lans.add(keyValueMap.get('Folio').trim());
            }
            if(String.isNotBlank(keyValueMap.get('Issue Code'))){
                cccExtIds.add(keyValueMap.get('Issue Code').trim());
            }
            if(String.isNotBlank(keyValueMap.get('CLIENT CODE (LOB + PAN/PEKRN)'))){
                clientCodes.add(keyValueMap.get('CLIENT CODE (LOB + PAN/PEKRN)').trim());
            }
            if(String.isNotBlank(keyValueMap.get('Owner Team'))){
                ownerTeamNames.add(keyValueMap.get('Owner Team').trim());
            }
            if(String.isNotBlank(keyValueMap.get('Owner AD ID'))){
                ownerADIds.add(keyValueMap.get('Owner AD ID').trim());
            }
            rows.put(lineItemId, keyValueMap);
        }

        Map<String, Id> clientCodeToAccountIdMap = new Map<String,Id>();
        Map<String, Id> lanToAssetIdMap = new Map<String,Id>();
        Map<String, Id> queueUserNameIdMap = new Map<String, Id>();
        Map<String, Id> userAdIdMap = new Map<String, Id>();
        String ABSLAMCBU = ABSLAMC_Constants.ABSLAMCBU;
        for(Asset assetRec : [Select Id, LAN__c, AccountId from Asset where LAN__c IN :lans and Business_Unit__c=:ABSLAMCBU]){
            lanToAssetIdMap.put(assetRec.LAN__c, assetRec.Id);
        }
        
        for(Account accRec : [SELECT Id, LOB_Client_Code__c from Account where LOB_Client_Code__c IN: clientCodes and Business_Unit__c=:ABSLAMCBU]){
            clientCodeToAccountIdMap.put(accRec.LOB_Client_Code__c, accRec.Id);
        }

        Set<String> extIdFoundSet = new Set<String>();
        for(ASF_Case_Category_Config__c config : [SELECT Id, CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c IN :cccExtIds]){
            extIdFoundSet.add(config.CCC_External_Id__c);
        }
        for(Group queueRec : [select Id, name, DeveloperName from group where type='Queue' and DeveloperName LIKE 'ABSLAMC_%' and name IN: ownerTeamNames]){
            queueUserNameIdMap.put(queueRec.name, queueRec.Id);
        }
        for(User userRec : [select Id, FederationIdentifier from User where FederationIdentifier IN: ownerADIds AND  IsActive = true AND Business_Unit__c =:ABSLAMCBU]){
            userAdIdMap.put(userRec.FederationIdentifier, userRec.Id);
        }
        for(Id lineItemId : rows.keySet()){
            Map<String, String> keyValueMap = rows.get(lineItemId);
            String lob =  String.isNotBlank(keyValueMap.get('LOB'))?keyValueMap.get('LOB').trim():'';
            String issueTypeCode = keyValueMap.get('Issue Code').trim();
            String category =  String.isNotBlank(keyValueMap.get('Category'))?keyValueMap.get('Category').trim():'';
            String ctstType =  String.isNotBlank(keyValueMap.get('Type'))?keyValueMap.get('Type').trim():'';
            String ctstSubType =  String.isNotBlank(keyValueMap.get('Sub-Type'))?keyValueMap.get('Sub-Type').trim():'';
            String clientCode =  String.isNotBlank(keyValueMap.get('CLIENT CODE (LOB + PAN/PEKRN)'))?keyValueMap.get('CLIENT CODE (LOB + PAN/PEKRN)').trim():'';
            String folio = keyValueMap.get('Folio').trim();
            String OwnerTeam =  String.isNotBlank(keyValueMap.get('Owner Team'))?keyValueMap.get('Owner Team').trim():'';
            String OwnerAdId =  String.isNotBlank(keyValueMap.get('Owner AD ID'))?keyValueMap.get('Owner AD ID').trim():'';
            String source = String.isNotBlank(keyValueMap.get('Source'))?keyValueMap.get('Source').trim():'';
            String channel = String.isNotBlank(keyValueMap.get('Channel'))?keyValueMap.get('Channel').trim():'';
            String callerType = String.isNotBlank(keyValueMap.get('Caller Type'))?keyValueMap.get('Caller Type').trim(): '';
            String criticalRequest = String.isNotBlank(keyValueMap.get('Critical Request flag (Y/N)'))?keyValueMap.get('Critical Request flag (Y/N)').trim():'';
            String phdComplainSource = String.isNotBlank(keyValueMap.get('PHD Compaint Source'))?keyValueMap.get('PHD Compaint Source').trim(): '';
            String description = String.isNotBlank(keyValueMap.get('Description'))?keyValueMap.get('Description').trim(): '';
            String blockCommString = String.isNotBlank(keyValueMap.get('Send Auto Communication?'))?keyValueMap.get('Send Auto Communication?').trim():'';
            if(lob == null || lob.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'LOB is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(issueTypeCode == null || issueTypeCode.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Issue Code is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(clientCode == null || clientCode.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'CLIENT CODE (LOB + PAN/PEKRN) is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(folio == null || folio.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Folio is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(source == null || source.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Source is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(channel == null || channel.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Channel is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(callerType == null || callerType.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Caller Type is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(criticalRequest == null || criticalRequest.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Critical Request flag (Y/N) is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(description == null || description.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Description is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if((OwnerTeam == null || OwnerTeam.trim() == '') && (OwnerAdId == null || OwnerAdId.trim() == '')){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Owner Team OR Owner AD ID is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            
            if(!extIdFoundSet.contains(issueTypeCode)){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Issue Code is not valid');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            
            if(blockCommString == null || blockCommString.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Send Auto Communication is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(String.isNotBlank(blockCommString)){
                if(!blockCommString.equalsIgnoreCase('Yes') && !blockCommString.equalsIgnoreCase('No')){
                    keyValueMap.put('Result', 'FAILURE');
                    keyValueMap.put('Message', 'Invalid Send Auto Communication value provided - Accepted value - Yes/No');
                    resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                    resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                    continue;
                }
            }
            if(!lanToAssetIdMap.containsKey(folio)){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Folio is not found');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            Case caseRec = new Case();
            caseRec.AccountId = String.isNotBlank(clientCode) ? clientCodeToAccountIdMap.get(clientCode): NULL;
            caseRec.AssetId = String.isNotBlank(folio) ? lanToAssetIdMap.get(folio): NULL;
            caseRec.CCC_External_Id__c = issueTypeCode;
            caseRec.Nature__c = category;
            caseRec.Type_Text__c = ctstType;
            caseRec.Sub_Type_Text__c = ctstSubType;
            caseRec.Source__c = source;
            caseRec.Channel__c = channel;
            caseRec.Description = description;
            caseRec.No_Auto_Communication__c = (blockCommString.equalsIgnoreCase('Yes')) ? null : 'Email;SMS;WhatsApp';
            String ownerId = String.isNotBlank(userAdIdMap.get(ownerAdId)) ? userAdIdMap.get(ownerAdId) : queueUserNameIdMap.get(ownerTeam);
            caseRec.OwnerId = ownerId;
            caseRec.RecordTypeId = ASF_Constants.RT_FRAMEWORK;
            caseRec.Technical_Source__c = 'LWC';
            caseRec.Business_Unit__c = 'ABSLAMC';
            map<String, String> mapOfjsonStr = new map<String, String>();
            mapOfjsonStr.put('Caller_Type__c', callerType);
            mapOfjsonStr.put('Critical_Request__c', criticalRequest);
            mapOfjsonStr.put('PHD_Complaint_Source__c', phdComplainSource);
            caseRec.Case_Details_JSON__c = JSON.serialize(mapOfjsonStr);
            resultWrapper.resultRecords.put(lineItemId, caseRec);
            resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
        }
        
        return resultWrapper;
    }

    public List<Map<String,String>> prepareDownloadTemplate(List<String> columnNames, String objectName, Id listViewId, List<String> selectedRecordIds){
        List<Map<String, String>> listOfRecordsAsMap = new List<Map<String, String>>();
        Map<String, String> mapOfFieldApiToColumnName = new Map<String,String>{
            'LOB__c'=> 'LOB',
            'CCC_External_Id__c' => 'Issue Code',
            'Nature__c'=>'Category', 
            'Type_Text__c' => 'Type',
            'Sub_Type_Text__c' => 'Sub-Type',
            'Account.LOB_Client_Code__c'=> 'CLIENT CODE (LOB + PAN/PEKRN)',
            'LAN__c' =>'Folio',
            'OwnerTeam__c' => 'Owner Team', 
            'OwnerId'=>'Owner AD ID', 
            'Source__c'=>'Source', 
            'Channel__c'=> 'Channel',
           'ABSLAMC_Case_Detail__r.Caller_Type__c'=>'Caller Type',
           'ABSLAMC_Case_Detail__r.Critical_Request__c'=>'Critical Request flag (Y/N)',
            'ABSLAMC_Case_Detail__r.PHD_Complaint_Source__c'=>'PHD Compaint Source',
            'Description' => 'Description',
            'No_Auto_Communication__c'=>'Send Auto Communication?'                
        };
        Map<String, String> mapOfColumnNameToFieldApi = new Map<String,String>{
            'LOB'=> 'LOB__c',
            'Issue Code' => 'CCC_External_Id__c', 
            'Category'=>'Nature__c',
            'Type' =>'Type_Text__c',
            'Sub-Type'=>'Sub_Type_Text__c',
            'CLIENT CODE (LOB + PAN/PEKRN)'=>'Account.LOB_Client_Code__c',
            'Folio' =>'LAN__c',
            'Owner Team' =>'OwnerTeam__c',
            'Owner AD ID' =>'OwnerId',
            'Source'=>'Source__c',
            'Channel'=>'Channel__c',
           'Caller Type' =>'ABSLAMC_Case_Detail__r.Caller_Type__c',
           'Critical Request flag (Y/N)'=>'ABSLAMC_Case_Detail__r.Critical_Request__c',
            'PHD Compaint Source'=>'ABSLAMC_Case_Detail__r.PHD_Complaint_Source__c',
            'Description'=>'Description',
            'Send Auto Communication?'=>'No_Auto_Communication__c'
        };
        List<String> fieldNames = new List<String>();
        for(String columnName : columnNames){
            if(mapOfColumnNameToFieldApi.containsKey(columnName)){
                fieldNames.add(mapOfColumnNameToFieldApi.get(columnName));
            }
        }

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
            List<Id> listOfOwner = new List<Id>();
            for(SObject obj : recordsList){
                Map<String,String> fieldMap = new Map<String,String>();
                for(String fieldName : mapOfFieldApiToColumnName.keySet()){
                    String fieldValue;
                    if(fieldName.contains('.') && obj.getSobject((fieldName.split('\\.'))[0]) != null){
                        fieldValue = (String)obj.getSobject(fieldName.split('\\.')[0]).get(fieldName.split('\\.')[1]);
                    }else if(!fieldName.contains('.')){
                        fieldValue = (String)obj.get(fieldName);
                        if(fieldName == 'No_Auto_Communication__c'){
                            fieldValue = fieldValue == null ? 'Yes' : 'No';
                        }
                    }
                    fieldValue = fieldValue==null?' ':fieldValue;
                    fieldMap.put(mapOfFieldApiToColumnName.get(fieldName), fieldValue);
                    if(fieldName == 'OwnerId' && String.isNotBlank(fieldValue)){
                       listOfOwner.add(fieldValue);
                    }
                }
                listOfRecordsAsMap.add(fieldMap);
            }
            Map<Id, String> mapOfOwnerFedIden = new Map<Id, String>();
            for(User usr : [Select Id, FederationIdentifier from User where Id IN :listOfOwner]){
                mapOfOwnerFedIden.put(usr.Id, usr.FederationIdentifier);
             }
            
            for (Integer i = 0; i < listOfRecordsAsMap.size(); i++){
               Id usrId = listOfRecordsAsMap[i].get('Owner AD ID');
               String FedId = String.isNotBlank(mapOfOwnerFedIden.get(usrId)) ? mapOfOwnerFedIden.get(usrId) : '';
               listOfRecordsAsMap[i].put('Owner AD ID', FedId);
            }
        }

        return listOfRecordsAsMap;
    }
    
    public List<Map<String,String>> prepareCtstData(List<String> columnNames, String businessUnit){
        
        List<Map<String, String>> listOfRecordsAsMap = new List<Map<String, String>>();
        Map<String, String> mapOfFieldApiToColumnName = new Map<String,String>{
            'CCC_External_Id__c'=>'Issue Code',
            'Type__c'=>'Case Type',
            'Sub_Type__c'=>'Sub Type',
            'Nature__c'=>'Nature',
            'Activity__c'=>'Activity'
           
        };
        Map<String, String> mapOfColumnNameToFieldApi = new Map<String,String>{
            'Issue Code'=>'CCC_External_Id__c',
            'Case Type'=>'Type__c',
            'Sub Type'=>'Sub_Type__c',
            'Nature'=>'Nature__c',
            'Activity'=>'Activity__c'
            
        };
        List<String> fieldNames = new List<String>();
        for(String columnName : columnNames){
            if(mapOfColumnNameToFieldApi.containsKey(columnName)){
                fieldNames.add(mapOfColumnNameToFieldApi.get(columnName));
            }
        }

        String strFinalQuery;
        String strFields = String.join(fieldNames, ',');
        String strWhereClause = ' WHERE Business_Unit__c =: businessUnit';
        strFinalQuery = 'Select '+ strFields + ' FROM ASF_Case_Category_Config__c'+ strWhereClause;
        
        if(String.isNotBlank(strFinalQuery)){
            strFinalQuery = strFinalQuery + ' LIMIT 50000';
            System.debug('strFinalQuery'+strFinalQuery);
            List<SObject> recordsList = Database.query(strFinalQuery);
            for(SObject obj : recordsList){
                Map<String,String> fieldMap = new Map<String,String>();
                for(String fieldName : mapOfFieldApiToColumnName.keySet()){
                    String fieldValue;
                    if (obj.get(fieldName) instanceof Boolean) {
                        fieldValue = obj.get(fieldName) == True ? 'TRUE' : 'FALSE';
                    }else{
                        fieldValue = (String)obj.get(fieldName);
                    }
                    fieldValue = fieldValue==null?' ':fieldValue;
                    fieldMap.put(mapOfFieldApiToColumnName.get(fieldName), fieldValue);
                }
                listOfRecordsAsMap.add(fieldMap);
            }
        }

        return listOfRecordsAsMap;
    }
}