public class ASF_ContactTriggerHelper {
    
    public void updatePrimaryFlagOnContact(Map<Id,Contact> newMap){
        Set<Id> accountId = new Set<Id>();
        
        for(Contact con : newMap.values()){
            accountId.add(con.AccountID);
        }
        
        if(accountId.size()>0){
            List<Contact> existingPrimaryContactForAccount = [SELECT ID,Primary__c FROM Contact 
                                                              WHERE AccountId =:accountId 
                                                              AND Primary__c =:TRUE 
                                                              AND Id <> :newMap.KeySet()];
            if(existingPrimaryContactForAccount.size()>0){
                for(Contact c : existingPrimaryContactForAccount){
                    c.Primary__c = FALSE;
                }
                Database.SaveResult[] updToNonPrimary = Database.update(existingPrimaryContactForAccount,false);
            }
        }
    }
    
    /* This method is used to set the last Contact in case of multiple contact load in Dataload. If multiple contact
     * for the given Account getting loaded during the data load the last contact is marked as Primary Contact.
     */
    
    public void setLastContactInALoadAsPrimary(List<Contact> newList){
        Map<Id,List<Contact>> mAccIdVsContacts = new Map<Id,List<Contact>>();
        for(Contact con : newList){
            if(!mAccIdVsContacts.containsKey(con.AccountId)){
                mAccIdVsContacts.put(con.AccountId,new List<Contact>());
            }
            mAccIdVsContacts.get(con.AccountId).add(con);
        }
        for(Id accId : mAccIdVsContacts.keySet()){
            integer iContacts = mAccIdVsContacts.get(accId).size();
            for(integer i=0;i<iContacts;i++){
                if(i < (iContacts -1)){
                    mAccIdVsContacts.get(accId).get(i).Primary__c = False;
                }
            }
        }
    }

}