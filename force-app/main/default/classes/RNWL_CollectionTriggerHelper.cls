/********************************************************************************
*Class          :  RNWL_CollectionTriggerHelper
*Author         :  Gaurav Sharma
*Created Date   :  21/10/2024
*Last Modified  :  21/10/024
*@description   :  This helper class is use to update opportunity/Renewal Request
                   status on Collection__C creation.
********************************************************************************/

public without sharing class RNWL_CollectionTriggerHelper {
    
    private static Set<String> stageNames = new Set<String>{'Paid' , 'Closed Won' , 'Closed Lost'};

    public static void updateRenewalRequest(List<Collections__c> newRecords){
        Set<Id> oppIdSet = new Set<Id>();

        for(Collections__c rec : newRecords){
            if(rec.Renewal_Request__c != null){
                oppIdSet.add(rec.Renewal_Request__c);
            }
        }

        if(oppIdSet.size() > 0){
            try{
                List<Opportunity> oppToUpdate = [SELECT Id ,StageName 
                                             FROM Opportunity
                                             WHERE Id IN:oppIdSet AND StageName NOT IN: stageNames
                                             LIMIT 50000];
                if(oppToUpdate != null && oppToUpdate.size() > 0){
                    for(Opportunity opp : oppToUpdate){
                        opp.StageName = 'Paid';
                    }   
                    
                    update oppToUpdate;
                } 
            }catch(Exception e){
                system.debug(e.getMessage());
            }
        }
    }
}