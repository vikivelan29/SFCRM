/*********************************************************
*Class        :  ABSLAMC_BulkCreateLeadConverterUtility
*Author       :  Asmita Mathur
*Created Date :  24/09/2024
*Last Modified:  24/09/2024
*Description  :  Class for bulk lead creation
*********************************************************/
@SuppressWarnings('PMD.ApexSOQLInjection')

public with sharing class ABSLAMC_BulkCreateLeadConverterUtility implements ASF_BulkCSVToRecordConverter{
    public ASF_BulkCaseProcessorUtility.ConvertionResult convertJSONRows(Map<Id, String> jsonRows){
        //Each row will be
        //{'LOB':'MF',Folio':'1234566899', 'CLIENT CODE (LOB + PAN/PEKRN)' : 'MF-22344', 'PAN' : 'EH12458590', 'PERKN': 'EhG78794','Customer Type - Prospect / Existing customer' : 'Existing Customer',
        //'First Name':'TestLead','Last Name': 'TestlastName', 'Lead Category': 'Winback','Lead Type':'MF Transaction Related Outcall','Lead Sub-Type': 'Activity - TRO SIP Expiry','Comments/Remarks': 'someComments','Lead Status': 'Open','Assigned User - AD ID' : '12345'}
       ASF_BulkCaseProcessorUtility.ConvertionResult resultWrapper = new ASF_BulkCaseProcessorUtility.ConvertionResult();
        resultWrapper.resultJSONMapRows = new Map<Id, Map<String, String>>();
        resultWrapper.resultJSONRows = new Map<Id, String>();
        resultWrapper.resultRecords = new Map<Id, SObject>();

        Set<String> lans = new Set<String>();
        Set<String> clientCodes = new Set<String>();
        Set<String> federationIds = new Set<String>();
        Map<Id, Map<String, String>> rows = new Map<Id, Map<String, String>>();
        Set<String> leadStatus = ABSLAMC_Constants.LEADSTATUS;
        String ABSLAMCBU = ABSLAMC_Constants.ABSLAMCBU;
        for(Id lineItemId : jsonRows.keySet()){
            String eachJSON = jsonRows.get(lineItemId);
            System.debug('eachJSON'+eachJSON);
            Map<String, String> keyValueMap = (Map<String, String>)JSON.deserialize(eachJSON, Map<String, String>.class);
            System.debug('keyValueMap'+keyValueMap);
            if(String.isNotBlank(keyValueMap.get('Folio'))){
                lans.add(keyValueMap.get('Folio').trim());
            }
            if(String.isNotBlank(keyValueMap.get('CLIENT CODE - LOB +PAN/PERKN'))){
                clientCodes.add(keyValueMap.get('CLIENT CODE - LOB +PAN/PERKN').trim());
            }
            if(String.isNotBlank(keyValueMap.get('Assigned User - AD ID'))){
                federationIds.add(keyValueMap.get('Assigned User - AD ID').trim());
            }
            rows.put(lineItemId, keyValueMap);
        }

        Map<String, Id> lanToAssetIdMap = new Map<String,Id>();
        Map<String, Id> clientCodeToAccountIdMap = new Map<String,Id>();
        Map<String, Id> userFedIdToUserMap = new Map<String,Id>();
        for(Asset assetRec : [Select Id, LAN__c, AccountId from Asset where LAN__c IN :lans and Business_Unit__c = 'ABSLAMC']){
            lanToAssetIdMap.put(assetRec.LAN__c, assetRec.Id);
        }
        for(Account accRec : [SELECT Id, LOB_Client_Code__c from Account where LOB_Client_Code__c IN: clientCodes AND Business_Unit__c = 'ABSLAMC' ]){
            clientCodeToAccountIdMap.put(accRec.LOB_Client_Code__c, accRec.Id);
        }
        for(User usr :[Select Id, FederationIdentifier from User where FederationIdentifier IN :federationIds AND  IsActive = true AND Business_Unit__c =:ABSLAMCBU]){
            userFedIdToUserMap.put(usr.FederationIdentifier, usr.Id);
        }
        for(Id lineItemId : rows.keySet()){
            Map<String, String> keyValueMap = rows.get(lineItemId);
            String lob = keyValueMap.get('LOB').trim();
            String folio = keyValueMap.get('Folio').trim();
            String clientCode = keyValueMap.get('CLIENT CODE - LOB +PAN/PERKN').trim();
            String pan = String.isNotBlank(keyValueMap.get('PAN'))?keyValueMap.get('PAN').trim(): '';
            String perkn = String.isNotBlank(keyValueMap.get('PERKN'))?keyValueMap.get('PERKN').trim(): '';
            String mobile = String.isNotBlank(keyValueMap.get('Mobile No'))?keyValueMap.get('Mobile No').trim(): '';
            String customerType = String.isNotBlank(keyValueMap.get('Customer Type - Prospect / Existing customer'))?keyValueMap.get('Customer Type - Prospect / Existing customer').trim(): '';
            String firstName = String.isNotBlank(keyValueMap.get('First Name'))?keyValueMap.get('First Name').trim():'';
            String lastName = String.isNotBlank(keyValueMap.get('Last Name'))?keyValueMap.get('Last Name').trim(): '';
            String leadCatg = String.isNotBlank(keyValueMap.get('Lead Category'))?keyValueMap.get('Lead Category').trim(): '';
            String leadType = String.isNotBlank(keyValueMap.get('Lead Type'))?keyValueMap.get('Lead Type').trim(): '';
            String leadSubType = String.isNotBlank(keyValueMap.get('Lead Sub-Type'))?keyValueMap.get('Lead Sub-Type').trim(): '';
            String comments = String.isNotBlank(keyValueMap.get('Comments/Remarks'))?keyValueMap.get('Comments/Remarks').trim(): '';
            String status = String.isNotBlank(keyValueMap.get('Lead Status'))?keyValueMap.get('Lead Status').trim(): '';
            String assignedUser = String.isNotBlank(keyValueMap.get('Assigned User - AD ID'))?keyValueMap.get('Assigned User - AD ID').trim(): '';
            
            if(lob == null || lob.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'lob is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(mobile == null || mobile.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'mobile no is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(customerType == null || customerType.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Customer Type is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(leadCatg == null || leadCatg.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Lead Category is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(leadType == null || leadType.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Lead Type is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(leadSubType == null || leadSubType.trim() == ''){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'leadSubType is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if((clientCode == null || clientCode.trim() == '') && (customerType == 'Existing Customer')){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'CLIENT CODE - LOB +PAN/PERKN  is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if((lastName == null || lastName.trim() == '') && (customerType == 'Prospect')){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Last Name is required');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            if(!leadStatus.contains(status)){
                keyValueMap.put('Result', 'FAILURE');
                keyValueMap.put('Message', 'Invalid Lead Status');
                resultWrapper.resultJSONRows.put(lineItemId, JSON.serialize(keyValueMap));
                resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
                continue;
            }
            Lead leadRec = new Lead();
            leadRec.Account__c = String.isNotBlank(clientCode) ? clientCodeToAccountIdMap.get(clientCode): NULL;
            leadRec.LOB__c = lob;
            leadRec.Line_Of_Business__c = lob;
            leadRec.Folio_for_existing_customer__c = String.isNotBlank(folio) ? lanToAssetIdMap.get(folio): NULL;
            leadRec.PANNO__c = pan;
            leadRec.PEKRN__c = perkn;
            leadRec.MobilePhone = mobile;
            leadRec.FirstName = firstName;
            leadRec.LastName = lastName;
            leadRec.Lead_Category__c = leadCatg;
            leadRec.Lead_Type__c = leadType;
            leadRec.Lead_Subtype__c = leadSubType;
            leadRec.Comments_Remarks__c = comments;
            leadRec.Status = status;
            leadRec.OwnerId = userFedIdToUserMap.get(assignedUser);
            resultWrapper.resultRecords.put(lineItemId, leadRec);
            resultWrapper.resultJSONMapRows.put(lineItemId, keyValueMap);
        }
        return resultWrapper;
    }

    public List<Map<String,String>> prepareDownloadTemplate(List<String> columnNames, String objectName, Id listViewId, List<String> selectedRecordIds){
        List<Map<String, String>> listOfRecordsAsMap = new List<Map<String, String>>();
        Map<String, String> mapOfFieldApiToColumnName = new Map<String,String>{
            'LOB__c'=>'LOB',
            'Folio_for_existing_customer__r.LAN__c'=>'Folio',
            'Account__r.LOB_Client_Code__c'=> 'CLIENT CODE - LOB +PAN/PERKN',
            'PANNO__c'=> 'PAN',
            'PEKRN__c'=> 'PERKN',
            'MobilePhone'=>'Mobile No',
            'Customer Type - Prospect / Existing customer' => 'Customer Type - Prospect / Existing customer',
            'FirstName'=>'First Name',
            'LastName'=>'Last Name',
            'Lead_Category__c'=> 'Lead Category',
            'Lead_Type__c'=> 'Lead Type',
            'Lead_Subtype__c'=> 'Lead Sub-Type',
            'Comments_Remarks__c'=>'Comments/Remarks',
            'OwnerId' => 'Assigned User - AD ID',
            'Status'=>'Lead Status'
                
        };
        Map<String, String> mapOfColumnNameToFieldApi = new Map<String,String>{
            'LOB'=>'LOB__c', 
            'Folio'=>'Folio_for_existing_customer__r.LAN__c',
            'CLIENT CODE - LOB +PAN/PERKN'=> 'Account__r.LOB_Client_Code__c',
            'PAN'=>'PANNO__c',
            'PERKN'=> 'PEKRN__c',
            'Mobile No'=>'MobilePhone',
            'Customer Type - Prospect / Existing customer' => 'Dummy',
            'First Name'=>'FirstName',
            'Last Name'=>'LastName',
            'Lead Category'=>'Lead_Category__c',
            'Lead Type'=>'Lead_Type__c',
            'Lead Sub-Type'=>'Lead_Subtype__c',
            'Comments/Remarks'=>'Comments_Remarks__c',
            'Assigned User - AD ID' => 'OwnerId',
            'Lead Status'=>'Status'
        };
        List<String> fieldNames = new List<String>();
        for(String columnName : columnNames){
            if(mapOfColumnNameToFieldApi.containsKey(columnName)){
                if(columnName == 'Customer Type - Prospect / Existing customer'){
                    continue;
                }
                fieldNames.add(mapOfColumnNameToFieldApi.get(columnName));
            }
        }

        String strFinalQuery;
        String strFields = String.join(fieldNames, ',');
        if(selectedRecordIds != null && !selectedRecordIds.isEmpty()){
            String strWhereClause = ' WHERE ID IN:selectedRecordIds';
            strFinalQuery = 'Select '+ strFields + ' FROM ' + objectName + strWhereClause;
        }
        else if(listViewId != null){
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
        system.debug('strFinalQuery'+strFinalQuery);
        if(String.isNotBlank(strFinalQuery)){
            strFinalQuery = strFinalQuery + ' LIMIT 50000';
            List<SObject> recordsList = Database.query(strFinalQuery);
            List<Id> listOfOwner = new List<Id>();
            for(SObject obj : recordsList){
                Map<String,String> fieldMap = new Map<String,String>();
                String customerType = 'Prospect';
                for(String fieldName : mapOfFieldApiToColumnName.keySet()){
                    String fieldValue;
                    if(fieldName == 'Customer Type - Prospect / Existing customer'){
                        fieldValue = customerType;
                    }
                    else if(fieldName == 'Folio_for_existing_customer__r.LAN__c' || fieldName == 'Account__r.LOB_Client_Code__c'){
                         if(String.isNotBlank((String)obj.get('Folio_for_existing_customer__c'))){
                        	fieldValue = (String)obj.getSObject('Folio_for_existing_customer__r').get('LAN__c'); 
                         }
                         if(String.isNotBlank((String)obj.get('Account__c'))){
                        	fieldValue = (String)obj.getSObject('Account__r').get('LOB_Client_Code__c');
                            customerType = fieldValue !=null ? 'Existing Customer' : 'Prospect'; 
                        }
                    }
                    else{
                        fieldValue = (String)obj.get(fieldName);
                        
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
               Id usrId = listOfRecordsAsMap[i].get('Assigned User - AD ID');
               listOfRecordsAsMap[i].put('Assigned User - AD ID', mapOfOwnerFedIden.get(usrId));
            }           
            
        }
        system.debug('listOfRecordsAsMap'+listOfRecordsAsMap);
        return listOfRecordsAsMap;
    }
    public List<Map<String,String>> prepareCtstData(List<String> columnNames, String businessUnit){
        return new List<Map<String,String>>();
    }
}