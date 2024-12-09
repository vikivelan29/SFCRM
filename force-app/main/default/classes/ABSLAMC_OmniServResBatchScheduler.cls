public class ABSLAMC_OmniServResBatchScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        ABSLAMC_OmniChannelServResBatchCtrl batch = new ABSLAMC_OmniChannelServResBatchCtrl();
        Database.executeBatch(batch, 200); 
    }
}