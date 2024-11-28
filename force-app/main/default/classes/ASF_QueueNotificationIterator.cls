public class ASF_QueueNotificationIterator implements Iterator<AggregateResult>{ 
    
    private List<AggregateResult> results;
    private Integer currentIndex;
    
    public ASF_QueueNotificationIterator(List<AggregateResult> results){
        this.results = results;
        this.currentIndex = 0;
    }
    
    public Boolean hasNext(){ 
        return currentIndex < results.size();
    }    
    
    public AggregateResult next(){
        if(hasNext()) {
            return results[currentIndex++];
        } else {
            throw new NoSuchElementException('Iterator has no more elements.');
        }
    } 
}