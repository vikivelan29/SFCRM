trigger ASF_BulkCaseProcessorTriggerSeven on ASF_Bulk_Case_Processor__e (after insert) {
    TriggerDispatcher.Run(new ASF_BulkCaseProcessorHandler('TriggerSeven'));
}