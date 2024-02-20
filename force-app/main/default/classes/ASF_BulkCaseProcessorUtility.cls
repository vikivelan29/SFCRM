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
            this.headIdToTemplateNameMap.put(peRecord.Header_Row_Id__c, peRecord.Template_Name__c);
        }
        if(!recordIds.isEmpty()){
            this.lineItemsToProcess = [Select Id, Bulk_Upload_Header__c, JSON_Data__c, Status__c, OwnerId from ASF_Bulk_Upload_Line_Item__c where Id IN :recordIds];
        }
    }

    //Constructor for handling Queueable apex
    // public ASF_BulkCaseProcessorUtility(List<ASF_Bulk_Upload_Line_Item__c> lineItemsToProcess, Map<Id, String> headIdToTemplateNameMap) {
    //     this.isQueueableProcessing = true;
    //     this.lineItemsToProcess = lineItemsToProcess;
    //     this.headIdToTemplateNameMap = headIdToTemplateNameMap;
    // }

    public void process() {
        Map<String, String> templateNameToApexClassMap = new Map<String,String>();
        for(ASF_Bulk_Row_to_Record_Converter_Config__mdt converterMDT : [Select Id,Apex_Class_Name__c, Template_Name__c, Active__c from ASF_Bulk_Row_to_Record_Converter_Config__mdt where Template_Name__c IN :headIdToTemplateNameMap.values() AND Active__c = true]){
            templateNameToApexClassMap.put(converterMDT.Template_Name__c, converterMDT.Apex_Class_Name__c); 
        }

        Map<Id, SObject> newCaseRecords = new Map<Id, SObject>();
        Map<Id, Map<String, String>> jsonMapResults = new Map<Id, Map<String, String>>();
        Map<Id, String> jsonResults = new Map<Id, String>();
        Map<String, Map<Id, String>> templateNameToJSONRows = new Map<String, Map<Id, String>>();
        Map<Id, Id> lineItemToOwnerId = new Map<Id, Id>();

        for(ASF_Bulk_Upload_Line_Item__c lineItem : lineItemsToProcess){
            lineItemToOwnerId.put(lineItem.Id, lineItem.OwnerId);
            String templateName = headIdToTemplateNameMap.get(lineItem.Bulk_Upload_Header__c);
            if(!templateNameToJSONRows.containsKey(templateName)){
                templateNameToJSONRows.put(templateName, new Map<Id, String>());
            }
            templateNameToJSONRows.get(templateName).put(lineItem.Id, lineItem.JSON_Data__c);
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
            }
            recordsForDML.add(record);
            index++;
        }

        ASF_BulkCaseProcessorUtility.isBulkProcessing = true;
        List<Database.UpsertResult> srList = Database.upsert(recordsForDML, false);
        ASF_BulkCaseProcessorUtility.isBulkProcessing = false;
        index = 0;
        for(Database.UpsertResult sr : srList){
            Id lineItemId = indexToLineItemIdMap.get(index);
            Map<String, String> jsonMap = jsonMapResults.get(lineItemId);
            if(sr.isSuccess()){
                jsonMap.put('Result', 'SUCCESS');
                jsonMap.put('Message', sr.isCreated()?sr.getId():'Case Updated');
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
            jsonResults.put(lineItemId, JSON.serialize(jsonMap));
            index++;
        }
        
        List<ASF_Bulk_Upload_Line_Item__c> lineItemsToUpdate = new List<ASF_Bulk_Upload_Line_Item__c>();
        for(Id lineItemId : jsonResults.keySet()){
            ASF_Bulk_Upload_Line_Item__c lineItem = new ASF_Bulk_Upload_Line_Item__c();
            lineItem.Id = lineItemId;
            lineItem.Result_JSON_Data__c = jsonResults.get(lineItemId);
            lineItem.Error_Message__c = jsonMapResults.get(lineItemId).get('Message');
            lineItem.Status__c = jsonMapResults.get(lineItemId).get('Result') == 'SUCCESS'?'Success':'Failure';
            lineItemsToUpdate.add(lineItem);
        }

        update lineItemsToUpdate;


        Boolean areLineItemsPending = true;
        Set<Id> headIds = headIdToTemplateNameMap.keySet();
        List<AggregateResult> arList = [Select Bulk_Upload_Header__c, count(Id) from ASF_Bulk_Upload_Line_Item__c where Bulk_Upload_Header__c IN :headIdToTemplateNameMap.keySet() AND (Status__c = 'Pending' OR Status__c = 'Event fired') group by Bulk_Upload_Header__c];
        List<ASF_Bulk_Upload_Header__c> headersToUpdate = new List<ASF_Bulk_Upload_Header__c>();
        if(!arList.isEmpty()){
            for(AggregateResult ar : arList){
                //result returned in Aggregate Query means atleat one pending record found
                headIds.remove(String.valueOf(ar.get('0')));
            }
        }
        for(Id headId : headIds){
            ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
            headObj.Id = headId;
            headObj.Status__c = 'Processed';
            headersToUpdate.add(headObj);
            //areLineItemsPending = false;
        }
        update headersToUpdate;
        //TODO: For completed headers, send email

        /*
        if(this.isQueueableProcessing == true && areLineItemsPending){
            for(Id headId : headIdToTemplateNameMap.keySet()){
                //Only one head row Id and template name is passed for Queueable mode, so this loop will execute only one and enqueue only one Queueable.
                ASF_BulkCaseProcessorQueueable processor = new ASF_BulkCaseProcessorQueueable(headId, headIdToTemplateNameMap.get(headId));
                System.enqueueJob(processor);
            }
        }
        */
    }

    public class ConvertionResult{
        public Map<Id, Map<String, String>> resultJSONMapRows;
        public Map<Id, String> resultJSONRows;
        public Map<Id, SObject> resultRecords;

    }

}