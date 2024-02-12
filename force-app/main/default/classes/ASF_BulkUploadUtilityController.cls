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
    public static ChunkLoadWrapper insertHeaderRowWithLineItems2(List<ASF_Bulk_Upload_Line_Item__c> lineItems, Integer totalRowCount, String templateName){
        ChunkLoadWrapper returnWrap = new ChunkLoadWrapper();
       
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
        //Initiate next step
        if(totalRowCount > 10000){
            //If num_rows is >10K, start Queueable Chain
            ASF_BulkCaseProcessorQueueable processor = new ASF_BulkCaseProcessorQueueable(headRowId, templateName);
            System.enqueueJob(processor);
            returnWrap.isSuccess = true;
            returnWrap.successMessageIfAny = 'Upload completed, processing started';
        }else{
            //else starts PE processing
            Integer index = 0;
            String recordIds = '';
            List<ASF_Bulk_Case_Processor__e> peList = new List<ASF_Bulk_Case_Processor__e>();
            List<ASF_Bulk_Upload_Line_Item__c> lineItemsToUpdate = new List<ASF_Bulk_Upload_Line_Item__c>();
            for(ASF_Bulk_Upload_Line_Item__c lineItem : [Select Id, Name from ASF_Bulk_Upload_Line_Item__c where Bulk_Upload_Header__c = :headRowId and Status__c = 'Pending' order by Name]){
                recordIds += lineItem.Id+';';
                lineItem.Status__c = 'Event fired';
                lineItemsToUpdate.add(lineItem);
                if(index == 999){
                    ASF_Bulk_Case_Processor__e chunkPE = new ASF_Bulk_Case_Processor__e();
                    chunkPE.Template_Name__c = templateName;
                    chunkPE.Record_IDs__c = recordIds;
                    chunkPE.Header_Row_Id__c = headRowId;
                    peList.add(chunkPE);
                    recordIds = '';
                    index = 0;
                }
                index++;
            }
            if(index != 0){
                //Few line items are left to be added to PE
                ASF_Bulk_Case_Processor__e chunkPE = new ASF_Bulk_Case_Processor__e();
                chunkPE.Template_Name__c = templateName;
                chunkPE.Record_IDs__c = recordIds;
                chunkPE.Header_Row_Id__c = headRowId;
                peList.add(chunkPE);
                index = 0;
            }
            if(!lineItemsToUpdate.isEmpty()){
                update lineItemsToUpdate; //Updates status to Event fired
            }
            if(!peList.isEmpty()){
                EventBus.publish(peList);
                returnWrap.isSuccess = true;
                returnWrap.successMessageIfAny = 'Upload completed, processing started';
            }else{
                returnWrap.isSuccess = false;
                returnWrap.errorMessage = 'No row pending for processing';
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