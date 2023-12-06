public class ASF_QueueNotificationIterable implements Iterable<AggregateResult> {
    public Iterator<AggregateResult> iterator(){
        List<AggregateResult> results =
            [SELECT OwnerId Id,Count(Id) FROM Case WHERE isClosed = false AND owner.Type = 'Queue' Group By OwnerId];
        return new ASF_QueueNotificationIterator(results);
    }
    
}