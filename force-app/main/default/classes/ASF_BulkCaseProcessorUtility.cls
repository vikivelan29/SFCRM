public with sharing class ASF_BulkCaseProcessorUtility {

    public static Boolean isBulkProcessing = false;

    private List<ASF_Bulk_Upload_Line_Item__c> lineItemsToProcess = new List<ASF_Bulk_Upload_Line_Item__c>();
    private Map<Id, String> headIdToTemplateNameMap = new Map<Id,String>();
    //private Boolean isQueueableProcessing = false;
    //Constructor for handling platform events
    public ASF_BulkCaseProcessorUtility(List<ASF_Bulk_Case_Processor__e> peRecords) {
        Set<Id> recordIds = new Set<Id>();
        for(ASF_Bulk_Case_Processor__e peRecord : peRecords){
            recordIds.addAll((List<Id>)peRecord.Record_IDs__c.split(';'));
        }
        if(!recordIds.isEmpty()){
            this.lineItemsToProcess = [Select Id, Bulk_Upload_Header__c, JSON_Data__c, Status__c, OwnerId, Bulk_Upload_Header__r.Template_Name__c from ASF_Bulk_Upload_Line_Item__c where Id IN :recordIds];
            for(ASF_Bulk_Upload_Line_Item__c lineItem : this.lineItemsToProcess){
                if(!this.headIdToTemplateNameMap.containsKey(lineItem.Bulk_Upload_Header__c)){
                    this.headIdToTemplateNameMap.put(lineItem.Bulk_Upload_Header__c, lineItem.Bulk_Upload_Header__r.Template_Name__c);
                }
            }
        }
    }

    //Constructor for handling Queueable apex
    // public ASF_BulkCaseProcessorUtility(List<ASF_Bulk_Upload_Line_Item__c> lineItemsToProcess, Map<Id, String> headIdToTemplateNameMap) {
    //     this.isQueueableProcessing = true;
    //     this.lineItemsToProcess = lineItemsToProcess;
    //     this.headIdToTemplateNameMap = headIdToTemplateNameMap;
    // }

    public void process(String triggerName) {
        Map<String, String> templateNameToApexClassMap = new Map<String,String>();
        for(ASF_Bulk_Row_to_Record_Converter_Config__mdt converterMDT : [Select Id,Apex_Class_Name__c, Template_Name__c, Active__c from ASF_Bulk_Row_to_Record_Converter_Config__mdt where Template_Name__c IN :headIdToTemplateNameMap.values() AND Active__c = true]){
            templateNameToApexClassMap.put(converterMDT.Template_Name__c, converterMDT.Apex_Class_Name__c); 
        }

        Map<Id, SObject> newCaseRecords = new Map<Id, SObject>();
        Map<Id, Map<String, String>> jsonMapResults = new Map<Id, Map<String, String>>();
        Map<Id, String> jsonResults = new Map<Id, String>();
        Map<String, Map<Id, String>> templateNameToJSONRows = new Map<String, Map<Id, String>>();
        Map<Id, Id> lineItemToOwnerId = new Map<Id, Id>();
        Map<Id, User> ownerIdToUserMap = new Map<Id,User>();

        for(ASF_Bulk_Upload_Line_Item__c lineItem : lineItemsToProcess){
            lineItemToOwnerId.put(lineItem.Id, lineItem.OwnerId);
            String templateName = headIdToTemplateNameMap.get(lineItem.Bulk_Upload_Header__c);
            if(!templateNameToJSONRows.containsKey(templateName)){
                templateNameToJSONRows.put(templateName, new Map<Id, String>());
            }
            templateNameToJSONRows.get(templateName).put(lineItem.Id, lineItem.JSON_Data__c);
        }

        if(!lineItemToOwnerId.isEmpty()){
            Set<Id> ownerIds = new Set<Id>(lineItemToOwnerId.values());
            for(User user : [Select Id, Business_Unit__c, Name from User where Id IN :ownerIds]){
                ownerIdToUserMap.put(user.Id, user);
            }
            ownerIds = null;
        }

        for(String templateName : templateNameToJSONRows.keySet()){
            Type customType = Type.forName(templateNameToApexClassMap.get(templateName));
            ASF_BulkCSVToRecordConverter converter = (ASF_BulkCSVToRecordConverter)customType.newInstance();
            ConvertionResult result = converter.convertJSONRows(templateNameToJSONRows.get(templateName));
            newCaseRecords.putAll(result.resultRecords);
            jsonResults.putAll(result.resultJSONRows); // Serialized JSON, for already error encountered rows
            jsonMapResults.putAll(result.resultJSONMapRows); //Deserialized JSON, for the insert results.
        }
        Map<Integer, Id> indexToLineItemIdMap = new Map<Integer,Id>();
        List<SObject> recordsForDML = new List<SObject>();
        Integer index = 0;
        for(Id lineItemId : newCaseRecords.keySet()){
            indexToLineItemIdMap.put(index, lineItemId);
            SObject record = newCaseRecords.get(lineItemId);
            if(record.Id == null){
                record.put('OwnerId', lineItemToOwnerId.get(lineItemId));
                record.put('Business_Unit__c', ownerIdToUserMap.get(lineItemToOwnerId.get(lineItemId)).Business_Unit__c);
            }
            record.put('PlatformEventInitiatedBy__c', ownerIdToUserMap.get(lineItemToOwnerId.get(lineItemId)).Name);
            recordsForDML.add(record);
            index++;
        }

        try{
            ASF_BulkCaseProcessorUtility.isBulkProcessing = true;
            List<Database.UpsertResult> srList = Database.upsert(recordsForDML, false);
            ASF_BulkCaseProcessorUtility.isBulkProcessing = false;

            Set<Id> caseIds = new Set<Id>();
            Map<Id, String> caseNumberMap = new Map<Id, String>();
            for(Database.UpsertResult sr : srList){
                if(sr.isSuccess() && sr.isCreated()){
                    caseIds.add(sr.getId());
                }
            }

            if(!caseIds.isEmpty()){
                for(Case caseRec : [Select Id, CaseNumber from Case where Id IN :caseIds]){
                    caseNumberMap.put(caseRec.Id, caseRec.CaseNumber);
                }
            }
            index = 0;
            for(Database.UpsertResult sr : srList){
                Id lineItemId = indexToLineItemIdMap.get(index);
                Map<String, String> jsonMap = jsonMapResults.get(lineItemId);
                if(sr.isSuccess()){
                    System.debug('Success case number'+recordsForDML[index]);
                    jsonMap.put('Result', 'SUCCESS');
                    jsonMap.put('Message', sr.isCreated()?caseNumberMap.get(sr.getId()):'Case Updated');
                }else{
                    jsonMap.put('Result', 'FAILURE');
                    String errorMessage = '';
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        errorMessage += err.getStatusCode() + ': ' + err.getMessage();
                        errorMessage += ' : ' +err.getFields();
                    }
                    jsonMap.put('Message', errorMessage);
                }
                System.debug('jsonMap'+jsonMap);
                System.debug('jsonMap Serialized'+ JSON.serialize(jsonMap));
                jsonResults.put(lineItemId, JSON.serialize(jsonMap));
                index++;
            }
        }
        catch(Exception err){
            //Any generic exception or
            //since its processing 2 or more different headers, same case can be under 2 different headers, trying to close
            //System.ListException: Before Insert or Upsert list must not have two identically equal elements
            for(Integer lineItemIndex : indexToLineItemIdMap.keySet()){
                Id lineItemId = indexToLineItemIdMap.get(lineItemIndex);
                Map<String, String> jsonMap = jsonMapResults.get(lineItemId);
                jsonMap.put('Result', 'FAILURE');
                jsonMap.put('Message', err.getMessage());
                jsonResults.put(lineItemId, JSON.serialize(jsonMap));
            }
        }


        List<ASF_Bulk_Upload_Line_Item__c> lineItemsToUpdate = new List<ASF_Bulk_Upload_Line_Item__c>();
        for(Id lineItemId : jsonResults.keySet()){
            ASF_Bulk_Upload_Line_Item__c lineItem = new ASF_Bulk_Upload_Line_Item__c();
            lineItem.Id = lineItemId;
            lineItem.Result_JSON_Data__c = jsonResults.get(lineItemId);
            String errorMessage = jsonMapResults.get(lineItemId).get('Message');
            errorMessage = errorMessage.length() > 255 ? errorMessage.substring(0,255):errorMessage;
            lineItem.Error_Message__c = errorMessage;
            lineItem.Status__c = jsonMapResults.get(lineItemId).get('Result') == 'SUCCESS'?'Success':'Failure';
            lineItemsToUpdate.add(lineItem);
        }

        update lineItemsToUpdate;


        Set<Id> headIds = headIdToTemplateNameMap.keySet();
        List<ASF_Bulk_Upload_Header__c> headersToUpdate = new List<ASF_Bulk_Upload_Header__c>();
        List<ASF_Bulk_Upload_Header__c> fetchedHeaders = [Select Id, Status__c, (Select Id, Status__c from Bulk_Upload_Line_Items__r where Status__c = 'Pending' OR Status__c = 'Event fired') from ASF_Bulk_Upload_Header__c where Id IN :headIdToTemplateNameMap.keySet() FOR UPDATE];
        System.debug('fetchedHeaders'+fetchedHeaders);
        for(ASF_Bulk_Upload_Header__c head : fetchedHeaders){
            if(head.Bulk_Upload_Line_Items__r.size() > 0){
                headIds.remove(String.valueOf(head.Id));
                break;
            }
        }


        // for(ASF_Bulk_Upload_Line_Item__c remainingLineItem : [Select Id, Bulk_Upload_Header__c from ASF_Bulk_Upload_Line_Item__c where Bulk_Upload_Header__c IN :headIdToTemplateNameMap.keySet() AND (Status__c = 'Pending' OR Status__c = 'Event fired') FOR UPDATE]){
        //     if(!headerToRemainingLineItemCount.containsKey(remainingLineItem.Bulk_Upload_Header__c)){
        //         headerToRemainingLineItemCount.put(remainingLineItem.Bulk_Upload_Header__c, 0);
        //     }
        //     headerToRemainingLineItemCount.put(remainingLineItem.Bulk_Upload_Header__c, headerToRemainingLineItemCount.get(remainingLineItem.Bulk_Upload_Header__c) + 1);
        // }
        /*List<AggregateResult> arList = [Select Bulk_Upload_Header__c, count(Id) from ASF_Bulk_Upload_Line_Item__c where Bulk_Upload_Header__c IN :headIdToTemplateNameMap.keySet() AND (Status__c = 'Pending' OR Status__c = 'Event fired') group by Bulk_Upload_Header__c FOR UPDATE];
        System.debug(triggerName+' arList '+arList);
        
        if(!arList.isEmpty()){
            for(AggregateResult ar : arList){
                //result returned in Aggregate Query means atleat one pending record found
                headIds.remove(String.valueOf(ar.get('Bulk_Upload_Header__c')));
            }
        }
        */
        
        for(Id headId : headIds){
            ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
            headObj.Id = headId;
            headObj.Status__c = 'Processed';
            headersToUpdate.add(headObj);
        }
        update headersToUpdate;
        //TODO: For completed headers, send email
    }

    public class ConvertionResult{
        public Map<Id, Map<String, String>> resultJSONMapRows;
        public Map<Id, String> resultJSONRows;
        public Map<Id, SObject> resultRecords;

    }

}