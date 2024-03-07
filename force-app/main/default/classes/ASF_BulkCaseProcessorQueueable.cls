public with sharing class ASF_BulkCaseProcessorQueueable implements Queueable{
    private List<ASF_Bulk_Upload_Line_Item__c> lineItemsToProcess = new List<ASF_Bulk_Upload_Line_Item__c>();
    private Id headRowId;
    private String templateName;
    public ASF_BulkCaseProcessorQueueable(Id headRowId, String templateName) {
        this.headRowId = headRowId;
        this.templateName = templateName;
        Integer limitLineItem = Integer.valueOf(Label.ASF_BulkThresholdForQueueable);
        this.lineItemsToProcess = [Select Id, Bulk_Upload_Header__c, JSON_Data__c, Status__c, Bulk_Upload_Header__r.Status__c from ASF_Bulk_Upload_Line_Item__c where Bulk_Upload_Header__c = :headRowId and Status__c = 'Pending' order by Name LIMIT :limitLineItem];
    }

    public void execute(System.QueueableContext ctx){
        //Map<Id, String> headIdToTemplateNameMap = new Map<Id, String>{this.headRowId => this.templateName};
        //invoke Processor Utility
        // ASF_BulkCaseProcessorUtility utility = new ASF_BulkCaseProcessorUtility(this.lineItemsToProcess, headIdToTemplateNameMap);
        // utility.process();

        Integer index = 0;
        String recordIds = '';
        ASF_Bulk_Upload_Header__c headRow;
        List<ASF_Bulk_Case_Processor__e> peList = new List<ASF_Bulk_Case_Processor__e>();
        Map<Id, ASF_Bulk_Upload_Line_Item__c> lineItemsToUpdate = new Map<Id, ASF_Bulk_Upload_Line_Item__c>();
        String currentHeadStatus;
        for(ASF_Bulk_Upload_Line_Item__c lineItem : this.lineItemsToProcess){
            if(currentHeadStatus == null){
                currentHeadStatus = lineItem.Bulk_Upload_Header__r.Status__c;
            }
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
            
            if(anySuccess && currentHeadStatus != 'Processing'){
                headRow = new ASF_Bulk_Upload_Header__c();
                headRow.Id = this.headRowId;
                headRow.Status__c = 'Processing';
            }
            if(!lineItemsToUpdate.isEmpty()){
                update lineItemsToUpdate.values(); //Updates status to Event fired
            }
            if(headRow != null){
                update headRow; //updates header's status to Processing
            }

            Integer limitLineItem = Integer.valueOf(Label.ASF_BulkThresholdForQueueable);
            List<ASF_Bulk_Upload_Line_Item__c> remainingLineItemsToProcess = [Select Id, Bulk_Upload_Header__c, JSON_Data__c, Status__c from ASF_Bulk_Upload_Line_Item__c where Bulk_Upload_Header__c = :this.headRowId and Status__c = 'Pending' LIMIT :limitLineItem];
            if(!remainingLineItemsToProcess.isEmpty()){
                ASF_BulkCaseProcessorQueueable processor = new ASF_BulkCaseProcessorQueueable(headRowId, templateName);
                AsyncOptions asyncOptions = new AsyncOptions();
                //some or all PE were successfully fired, PE channel is ok, fire next Queueable now
                asyncOptions.MinimumQueueableDelayInMinutes = 0;
                if(!anySuccess){
                    //no success on PE firing, means some issue with PE channels, try after 10 mins
                    asyncOptions.MinimumQueueableDelayInMinutes = 10;
                }
                
                System.enqueueJob(processor, asyncOptions);
            }
        }
    }
}