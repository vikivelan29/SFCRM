@SuppressWarnings('PMD.FormalParameterNamingConventions')
public class ASF_BulkRetryStuckLineItemsBatch implements Database.Batchable<SObject>, Schedulable{
    public Database.QueryLocator start(Database.BatchableContext BC){
        Datetime cutoffTime = System.now().addHours(-1);
        String query = 'SELECT Id, Bulk_Upload_Header__c, Bulk_Upload_Header__r.Status__c, Number_of_retries__c';
        query += ' , Bulk_Upload_Header__r.Template_Name__c';
        query += ' FROM ASF_Bulk_Upload_Line_Item__c';
        query += ' WHERE';
        query += ' Number_of_retries__c < 2';
        query += ' AND ((Status__c = \'Event fired\' AND Event_Fired_Date__c < :cutoffTime)';
        query += ' OR (Status__c = \'Pending\' AND CreatedDate < :cutoffTime))';
        query += ' ORDER BY Bulk_Upload_Header__r.Template_Name__c, Bulk_Upload_Header__c';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope){
        Integer index = 1;
        String recordIds = '';
        String currentTemplate = '';
        List<ASF_Bulk_Case_Processor__e> peList = new List<ASF_Bulk_Case_Processor__e>();
        Map<Id, ASF_Bulk_Upload_Line_Item__c> lineItemsToUpdate = new Map<Id, ASF_Bulk_Upload_Line_Item__c>();
        Map<Id, ASF_Bulk_Upload_Header__c> headersToUpdate = new Map<Id, ASF_Bulk_Upload_Header__c>();
        
        for(ASF_Bulk_Upload_Line_Item__c lineItem : (List<ASF_Bulk_Upload_Line_Item__c>)scope){
            if(index == Integer.valueOf(Label.ASF_BulkProcessorBatchSize)-1 || (currentTemplate != '' && lineItem.Bulk_Upload_Header__r.Template_Name__c != currentTemplate)){
                ASF_Bulk_Case_Processor__e chunkPE = new ASF_Bulk_Case_Processor__e();
                chunkPE.Record_IDs__c = recordIds;
                peList.add(chunkPE);
                recordIds = '';
                currentTemplate = '';
                index = 0;
            }

            recordIds += lineItem.Id+';';
            currentTemplate = lineItem.Bulk_Upload_Header__r.Template_Name__c;
            lineItem.Status__c = 'Event fired';
            lineItem.Event_Fired_Date__c = System.now();
            lineItem.Number_of_retries__c = lineItem.Number_of_retries__c == null?1:lineItem.Number_of_retries__c+1;
            lineItemsToUpdate.put(lineItem.Id, lineItem);
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
                recordIds = peList[index].Record_IDs__c;
                List<String> recordIdList = recordIds.split(';');
                if (sr.isSuccess()) {
                    System.debug('Successfully published event.');
                    for(String recordId : recordIdList){
                        Id headRowId = lineItemsToUpdate.get(recordId).Bulk_Upload_Header__c;
                        if(!headersToUpdate.containsKey(headRowId) && lineItemsToUpdate.get(recordId).Bulk_Upload_Header__r.Status__c != 'Processing'){
                            ASF_Bulk_Upload_Header__c headRow = new ASF_Bulk_Upload_Header__c();
                            headRow.Id = headRowId;
                            headRow.Status__c = 'Processing';
                            headersToUpdate.put(headRow.Id, headRow);
                        }
                    }
                } else {
                    for(String recordId : recordIdList){
                        lineItemsToUpdate.get(recordId).Error_Message__c = 'Error returned: '+sr.getErrors()[0].getStatusCode()+' - '+sr.getErrors()[0].getMessage();
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
        }

        if(!lineItemsToUpdate.isEmpty()){
            update lineItemsToUpdate.values(); //Updates status to Event fired
        }
        if(!headersToUpdate.isEmpty()){
            update headersToUpdate.values(); //updates header's status to Processing
        }
    }

    public void finish(Database.BatchableContext BC){

    }

    public void execute(SchedulableContext stx){
        ASF_BulkRetryStuckLineItemsBatch batch = new ASF_BulkRetryStuckLineItemsBatch(); 
        Database.executeBatch(batch);
    }
}