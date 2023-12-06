public class PAY_FetchCustomerDetails implements Queueable, Database.AllowsCallouts {
	public Map<String,List<Id>> accClientCodeVsCaseIds;
    
    public PAY_FetchCustomerDetails(Map<String,List<Id>> accClientCodeVsCaseIds){
        this.accClientCodeVsCaseIds = accClientCodeVsCaseIds;
    }
    
    public void execute(QueueableContext context) {
        Map<String,Id> accClientCodeVsAccIds = new Map<String,Id>();
        List<Case> caseInsertList = new List<Case>();
        List<PAY_CustomerSearchController.CustomerDetailsWrapper> customerList = new List<PAY_CustomerSearchController.CustomerDetailsWrapper>();
        for(String customerId : accClientCodeVsCaseIds.keySet()){
            List<PAY_CustomerSearchController.CustomerDetailsWrapper> customerDetailsWrapper = PAY_CustomerSearchController.searchCustomerExt(customerId,'Customer ID');
            if(customerDetailsWrapper.size() > 0){
                customerList.add(customerDetailsWrapper[0]);
            }
        }
        
        List<Account> customerDetails = PAY_CustomerSearchController.createCustomerList(customerList);
        
        for(Account acc : customerDetails){
            if(!accClientCodeVsAccIds.containsKey(acc.Client_Code__c))
                accClientCodeVsAccIds.put(acc.Client_Code__c,acc.Id);
        }
        
        for(String customerId : accClientCodeVsCaseIds.keySet()){
            for(Id caseId : accClientCodeVsCaseIds.get(customerId)){
                Case individualCase = new Case();
                individualCase.Id = caseId;
                individualCase.AccountId = accClientCodeVsAccIds.get(customerId);
                caseInsertList.add(individualCase);
            }
        }
        
        if(caseInsertList.size() > 0){
            ASF_TriggerSkipperUtility.markTriggerRun('Case');
        	Database.update(caseInsertList,false);
        }
    } 

}