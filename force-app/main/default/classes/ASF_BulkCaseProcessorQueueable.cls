public with sharing class ASF_BulkCaseProcessorQueueable implements Queueable{
    private List<ASF_Bulk_Upload_Line_Item__c> lineItemsToProcess = new List<ASF_Bulk_Upload_Line_Item__c>();
    private Id headRowId;
    private String templateName;
    public ASF_BulkCaseProcessorQueueable(Id headRowId, String templateName) {
        this.headRowId = headRowId;
        this.templateName = templateName;
        this.lineItemsToProcess = [Select Id, Bulk_Upload_Header__c, JSON_Data__c, Status__c from ASF_Bulk_Upload_Line_Item__c where Bulk_Upload_Header__c = :headRowId and Status__c = 'Pending' order by Name LIMIT 1000];
    }

    public void execute(System.QueueableContext ctx){
        //Map<Id, String> headIdToTemplateNameMap = new Map<Id, String>{this.headRowId => this.templateName};
        //invoke Processor Utility
        // ASF_BulkCaseProcessorUtility utility = new ASF_BulkCaseProcessorUtility(this.lineItemsToProcess, headIdToTemplateNameMap);
        // utility.process();

        Integer index = 0;
        String recordIds = '';
        List<ASF_Bulk_Case_Processor__e> peList = new List<ASF_Bulk_Case_Processor__e>();
        List<ASF_Bulk_Upload_Line_Item__c> lineItemsToUpdate = new List<ASF_Bulk_Upload_Line_Item__c>();
        for(ASF_Bulk_Upload_Line_Item__c lineItem : this.lineItemsToProcess){
            recordIds += lineItem.Id+';';
            lineItem.Status__c = 'Event fired';
            lineItemsToUpdate.add(lineItem);
            if(index == 999){
                ASF_Bulk_Case_Processor__e chunkPE = new ASF_Bulk_Case_Processor__e();
                chunkPE.Template_Name__c = this.templateName;
                chunkPE.Record_IDs__c = recordIds;
                chunkPE.Header_Row_Id__c = this.headRowId;
                peList.add(chunkPE);
                recordIds = '';
                index = 0;
            }
            index++;
        }
        if(index != 0){
            //Few line items are left to be added to PE
            ASF_Bulk_Case_Processor__e chunkPE = new ASF_Bulk_Case_Processor__e();
            chunkPE.Template_Name__c = this.templateName;
            chunkPE.Record_IDs__c = recordIds;
            chunkPE.Header_Row_Id__c = this.headRowId;
            peList.add(chunkPE);
            index = 0;
        }
        
        if(!peList.isEmpty()){
            index = 0;
            List<Database.SaveResult> results = EventBus.publish(peList);
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    System.debug('Successfully published event.');
                } else {
                    lineItemsToUpdate[index].Status__c = 'Pending';
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error returned: ' +
                                    err.getStatusCode() +
                                    ' - ' +
                                    err.getMessage());
                    }
                }  
                index++;     
            }
            
        }

        if(!lineItemsToUpdate.isEmpty()){
            update lineItemsToUpdate; //Updates status to Event fired
        }
    }
}