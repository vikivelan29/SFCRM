public class RNWL_AccountTriggerHelper {
    
    
    /****************************************************************************************************************
	* @Function - updateOppsUponAccountDataChange
	* @param accs ,oldAccsMap -  map of Accounts from trigger.newMap and trigger.oldMap.
	* @return - void .
	* @Description - Invoked from after Update this method populates fields on Opps upon Account field update.
	*****************************************************************************************************************/
    Public static void updateOppsUponAccountDataChange(Map<Id, Account> accs, Map<Id, Account> oldAccsMap){
        Set<Id> updatedAccsIds = new Set<Id>();
		List<Opportunity> oppsUpdateList = new List<Opportunity>();
        for(Account acc : accs.values()){
            if(acc.Phone != null && 
               acc.Phone != oldAccsMap.get(acc.Id).Phone){
                updatedAccsIds.add(acc.Id);
            }
        }
        
        if(updatedAccsIds.size() == 0){ return; }
        
        for(Opportunity opp : [SELECT Id, Mobile_Number__c, AccountId FROM Opportunity WHERE AccountId IN : updatedAccsIds]){
            if(opp.Mobile_Number__c != accs.get(opp.AccountId)?.Phone){
                opp.Mobile_Number__c = accs.get(opp.AccountId)?.Phone;
                oppsUpdateList.add(opp);
            }
        }
        
        if(oppsUpdateList.size() > 0){
           update oppsUpdateList; 
        }
        
    }
    

}