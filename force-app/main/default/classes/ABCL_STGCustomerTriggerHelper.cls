public class ABCL_STGCustomerTriggerHelper {
    public static final string PAYMENT_LOB = 'Payments';
    
    public static void executePlatformEvent(Map<Id,STG_Customer__c> newMap){
        List<sObject> eventsTobePublished = new List<sObject>();
        List<STG_Customer__c> failedRecords = new List<STG_Customer__c>();
        
        
        for(STG_Customer__c customer : newMap.values()){
            if(customer.Line_of_Business__c == PAYMENT_LOB){
                eventsTobePublished.add(getPaymentPESchema(customer));
            }
        }
        
        
        if(eventsTobePublished.size()>0){
            Database.SaveResult[] result = EventBus.Publish(eventsTobePublished);
            System.debug('Published');
            for(integer i=0;i<result.size();i++){
                if(!result[i].isSuccess()){
                    if(eventsTobePublished[i].Id != null){
                        STG_Customer__c cust = new STG_Customer__c(Id = eventsTobePublished[i].Id);
                        cust.Status__c = 'Error';
                        cust.Error_Details__c = result[i].getErrors().get(0).getMessage();
                        failedRecords.add(cust);
                    }
                }
            }
            if(failedRecords.size()>0){
                Database.SaveResult[] cust_result = Database.update(failedRecords,false);
            }
        }
    }
    private static PAY_Staging_Customer_to_Account__e getPaymentPESchema(STG_Customer__c customer){
        // ********* Non-Individual Payment Customer ********* //        
        PAY_Staging_Customer_to_Account__e stgCustomerEvt = new PAY_Staging_Customer_to_Account__e ();
        stgCustomerEvt.Customer_Type__c = customer.Customer_Type__c;
        stgCustomerEvt.Doing_Business_As__c = customer.Doing_Business_As__c;
        stgCustomerEvt.Line_of_Business__c  = customer.Line_of_Business__c;
        stgCustomerEvt.Merchant_Id__c  = customer.Merchant_Id__c;
        stgCustomerEvt.Merchant_Name__c  = customer.Merchant_Name__c;
        stgCustomerEvt.Merchant_Contact_Payload__c = customer.Merchant_Contact_Payload__c;
        stgCustomerEvt.STG_Customer_Id__c = customer.Id;
        
        // ********* Individual Payment Customer ********* //
        stgCustomerEvt.First_Name__c = customer.First_Name__c;
        stgCustomerEvt.Last_Name__c = customer.Last_Name__c;
        stgCustomerEvt.Email__c = customer.Email__c;
        stgCustomerEvt.Mobile__c = customer.Mobile__c;
        stgCustomerEvt.ABC_Cust_Id__c = customer.ABC_Cust_Id__c;
        if(customer.Customer_Since__c != null)
	        stgCustomerEvt.Customer_Since__c = Date.ValueOf(customer.Customer_Since__c);
        
        
        return stgCustomerEvt;
    }
}