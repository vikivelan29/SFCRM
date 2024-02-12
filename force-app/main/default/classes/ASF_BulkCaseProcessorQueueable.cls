public with sharing class ASF_BulkCaseProcessorQueueable implements Queueable{
    private List<ASF_Bulk_Upload_Line_Item__c> lineItemsToProcess = new List<ASF_Bulk_Upload_Line_Item__c>();
    private Id headRowId;
    private String templateName;
    public ASF_BulkCaseProcessorQueueable(Id headRowId, String templateName) {
        this.headRowId = headRowId;
        this.templateName = templateName;
        lineItemsToProcess = [Select Id, Bulk_Upload_Header__c, JSON_Data__c, Status__c from ASF_Bulk_Upload_Line_Item__c where Bulk_Upload_Header__c = :headRowId and Status__c = 'Pending' order by Name LIMIT 1000];
    }

    public void execute(System.QueueableContext ctx){
        Map<Id, String> headIdToTemplateNameMap = new Map<Id, String>{this.headRowId => this.templateName};
        //invoke Processor Utility
        ASF_BulkCaseProcessorUtility utility = new ASF_BulkCaseProcessorUtility(this.lineItemsToProcess, headIdToTemplateNameMap);
        utility.process();
        
    }
}