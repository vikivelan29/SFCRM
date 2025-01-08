public without sharing class ASF_QueueNotificationIterable implements Iterable<AggregateResult> {
    public Iterator<AggregateResult> iterator(){
        
        String ExcludeSubtype = System.label.Exclude_subtype;
        List<AggregateResult> results =
            [SELECT OwnerId Id,Count(Id) FROM Case WHERE isClosed = false AND CCC_External_Id__c != :ExcludeSubtype AND owner.Type = 'Queue'  Group By OwnerId];
        return new ASF_QueueNotificationIterator(results);
    }
    
}