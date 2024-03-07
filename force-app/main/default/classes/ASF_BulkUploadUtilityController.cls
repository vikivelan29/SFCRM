public with sharing class ASF_BulkUploadUtilityController {
    @AuraEnabled
    public static ChunkLoadWrapper insertHeaderRowWithLineItems(List<ASF_Bulk_Upload_Line_Item__c> lineItems, Integer totalRowCount, String templateName){
        ChunkLoadWrapper returnWrap = new ChunkLoadWrapper();
        returnWrap = validateChunk(lineItems);
        if(String.isNotBlank(returnWrap.errorMessage)){
            returnWrap.isSuccess = false;
            return returnWrap;
        }
        ASF_Bulk_Upload_Header__c headObj = new ASF_Bulk_Upload_Header__c();
        headObj.Template_Name__c = templateName;
        headObj.Total_Rows__c = totalRowCount;
        headObj.Status__c = 'Pending';
        insert headObj;
        returnWrap.headRowId = headObj.Id;

        System.debug('total line items in this chunk'+lineItems.size());
        for(ASF_Bulk_Upload_Line_Item__c lineItem : lineItems){
            lineItem.Bulk_Upload_Header__c = headObj.Id;
        }
        insert lineItems;
        returnWrap.isSuccess = true;
        return returnWrap;
    }

    @AuraEnabled
    public static ChunkLoadWrapper insertLineItemsChunk(List<ASF_Bulk_Upload_Line_Item__c> lineItems){
        ChunkLoadWrapper returnWrap = new ChunkLoadWrapper();
        returnWrap = validateChunk(lineItems);
        if(String.isNotBlank(returnWrap.errorMessage)){
            returnWrap.isSuccess = false;
            return returnWrap;
        }
        System.debug('total line items in this chunk'+lineItems.size());
        insert lineItems;
        returnWrap.isSuccess = true;
        return returnWrap;
    }

    @AuraEnabled
    public static ChunkLoadWrapper insertLastLineItemsChunk(List<ASF_Bulk_Upload_Line_Item__c> lineItems, Id headRowId){
        ChunkLoadWrapper returnWrap = new ChunkLoadWrapper();
        returnWrap = insertLineItemsChunk(lineItems);
        if(returnWrap.isSuccess){
            //Update Header Row Status
            ASF_Bulk_Upload_Header__c headRow = new ASF_Bulk_Upload_Header__c();
            headRow.Id = headRowId;
            headRow.Status__c = 'Upload Completed';
            update headRow;
        }

        return returnWrap;
    }

    @AuraEnabled
    public static ChunkLoadWrapper markUploadCompleted(Id headRowId){
        ChunkLoadWrapper returnWrap = new ChunkLoadWrapper();
        //Update Header Row Status
        ASF_Bulk_Upload_Header__c headRow = new ASF_Bulk_Upload_Header__c();
        headRow.Id = headRowId;
        headRow.Status__c = 'Upload Completed';
        update headRow;
        returnWrap.isSuccess = true;
        return returnWrap;
    }

    @AuraEnabled
    public static ChunkLoadWrapper startProcessingChunks(Id headRowId, Integer totalRowCount, String templateName){
        ChunkLoadWrapper returnWrap = new ChunkLoadWrapper();
        ASF_Bulk_Upload_Header__c headRow;
        //Initiate next step
        if(totalRowCount > Integer.valueOf(Label.ASF_BulkThresholdForQueueable)){
            //If num_rows is >10K, start Queueable Chain
            ASF_BulkCaseProcessorQueueable processor = new ASF_BulkCaseProcessorQueueable(headRowId, templateName);
            System.enqueueJob(processor);
            returnWrap.isSuccess = true;
            returnWrap.successMessageIfAny = 'Upload completed, processing will start soon';
        }else{
            //else starts PE processing
            Integer index = 0;
            String recordIds = '';
            List<ASF_Bulk_Case_Processor__e> peList = new List<ASF_Bulk_Case_Processor__e>();
            Map<Id, ASF_Bulk_Upload_Line_Item__c> lineItemsToUpdate = new Map<Id, ASF_Bulk_Upload_Line_Item__c>();
            for(ASF_Bulk_Upload_Line_Item__c lineItem : [Select Id, Name from ASF_Bulk_Upload_Line_Item__c where Bulk_Upload_Header__c = :headRowId and Status__c = 'Pending' order by Name]){
                recordIds += lineItem.Id+';';
                lineItem.Status__c = 'Event fired';
                lineItem.Event_Fired_Date__c = System.now();
                lineItemsToUpdate.put(lineItem.Id, lineItem);
                if(index == Integer.valueOf(Label.ASF_BulkProcessorBatchSize)-1){
                    ASF_Bulk_Case_Processor__e chunkPE = new ASF_Bulk_Case_Processor__e();
                    chunkPE.Record_IDs__c = recordIds;
                    peList.add(chunkPE);
                    recordIds = '';
                    index = 0;
                }
                index++;
            }
            if(index != 0){
                //Few line items are left to be added to PE
                ASF_Bulk_Case_Processor__e chunkPE = new ASF_Bulk_Case_Processor__e();
                chunkPE.Record_IDs__c = recordIds;
                peList.add(chunkPE);
                index = 0;
            }
            
            if(!peList.isEmpty()){
                index = 0;
                Boolean anySuccess = false;
                List<Database.SaveResult> results = EventBus.publish(peList);
                for (Database.SaveResult sr : results) {
                    if (sr.isSuccess()) {
                        System.debug('Successfully published event.');
                        anySuccess = true;
                    } else {
                        recordIds = peList[index].Record_IDs__c;
                        for(String recordId : recordIds.split(';')){
                            lineItemsToUpdate.remove(recordId);
                        }
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('Error returned: ' +
                                        err.getStatusCode() +
                                        ' - ' +
                                        err.getMessage());
                        }
                    }  
                    index++;     
                }
                if(anySuccess){
                    returnWrap.isSuccess = true;
                    returnWrap.successMessageIfAny = 'Upload completed, processing started';
                    headRow = new ASF_Bulk_Upload_Header__c();
                    headRow.Id = headRowId;
                    headRow.Status__c = 'Processing';
                }else{
                    returnWrap.isSuccess = false;
                    returnWrap.errorMessage = 'Upload completed, processing could not start. System will try to restart the processing after sometime.';
                }
            }else{
                returnWrap.isSuccess = false;
                returnWrap.errorMessage = 'No row pending for processing';
            }

            if(!lineItemsToUpdate.isEmpty()){
                update lineItemsToUpdate.values(); //Updates status to Event fired
            }
            if(headRow != null){
                update headRow; //updates header's status to Processing
            }
        }
        return returnWrap;
    }

    private static ChunkLoadWrapper validateChunk(List<ASF_Bulk_Upload_Line_Item__c> lineItems) {
        ChunkLoadWrapper returnWrap = new ChunkLoadWrapper();
        if(lineItems == null || lineItems.size() == 0){
            returnWrap.errorMessage = 'No Line Items found';
        }
        else if(lineItems.size() > 1000){
            returnWrap.errorMessage = 'Chunk size should not exceed 1000 rows';
        }
        return returnWrap;
    }

    public class ChunkLoadWrapper{
        @AuraEnabled public Id headRowId{get;set;}
        @AuraEnabled public Boolean isSuccess{get;set;}
        @AuraEnabled public String errorMessage{get;set;}
        @AuraEnabled public String successMessageIfAny{get;set;}
    }

}