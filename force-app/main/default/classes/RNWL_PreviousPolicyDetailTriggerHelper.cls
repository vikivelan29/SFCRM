/***************************************************************************
*Class          :  RNWL_PreviousPolicyDetailTriggerHelper
*Author         :  Gaurav Sharma
*Created Date   :  07/10/2024
*Last Modified  :  07/10/2024
*@description   :  Helper for RNWL_PreviousPolicyDetailTriggerHandler class
****************************************************************************/

public with sharing class RNWL_PreviousPolicyDetailTriggerHelper {

    public static void updateRelatedOpportunities(List<Previous_Policy_Details__c> newRecList){
        try{
            Set<String> prevPolicyNumers = new Set<String>();

            for(Previous_Policy_Details__c policy : newRecList){
                if(policy.PreviousPolicyNumber__c != null) prevPolicyNumers.add(policy.PreviousPolicyNumber__c);
            }

            if(prevPolicyNumers.size() > 0){
                List<Opportunity> oppToUpdate = [SELECT ID FROM Opportunity 
                                                WHERE Policy_Number__c IN:prevPolicyNumers 
                                                LIMIT 50000];
                for(Opportunity opp : oppToUpdate){
                    opp.StageName = 'Closed Won';
                    opp.Status__c = 'Renewed';
                }  
                
                update oppToUpdate;
                system.debug('Successfully Updated Opportunities- '+oppToUpdate);
            }
        }catch(Exception ex){
            system.debug('Error in Process due to: '+ex.getMessage());
        }
    }
}