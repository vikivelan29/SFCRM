@isTest
private class ABSLAMC_OmniSerResSchedulerTest {

    static testMethod void myTestMethod() {        
         test.starttest();
         ABSLAMC_OmniServResBatchScheduler myClass = new ABSLAMC_OmniServResBatchScheduler ();   
         String chron = '0 0 23 * * ?';        
         system.schedule('Test Sched', chron, myClass);
         test.stopTest();
    }
}