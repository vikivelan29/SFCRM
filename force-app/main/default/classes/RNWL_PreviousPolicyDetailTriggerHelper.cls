/***************************************************************************
*Class          :  RNWL_PreviousPolicyDetailTriggerHelper
*Author         :  Gaurav Sharma
*Created Date   :  07/10/2024
*Last Modified  :  04/11/2024 
*Last ModifiedBy:  Raj Raghuwanshi
*Modify Comments:  Added logic to update Renewed_Policy__c on Opportunity
*@description   :  Helper for RNWL_PreviousPolicyDetailTriggerHandler class
****************************************************************************/

public with sharing class RNWL_PreviousPolicyDetailTriggerHelper {

    public static void updateRelatedOpportunities(List<Previous_Policy_Details__c> newRecList){
        Map<String, Id> mapOf_PolicyNum_To_Id = new Map<String, Id>(); 
        
        for(Previous_Policy_Details__c policy : newRecList){
            if(policy.PreviousPolicyNumber__c != null) mapOf_PolicyNum_To_Id.put(policy.PreviousPolicyNumber__c, policy.Policy__c);
        }
        
        if(mapOf_PolicyNum_To_Id.size() > 0){
            List<Opportunity> oppToUpdate = [SELECT ID, StageName, Status__c, Renewed_Policy__c, Policy_Number__c
                                             FROM Opportunity 
                                             WHERE Policy_Number__c IN:mapOf_PolicyNum_To_Id.keySet() 
                                             LIMIT 50000];
            
            for(Opportunity opp : oppToUpdate){
                opp.StageName = 'Closed Won';
                opp.Status__c = 'Renewed';
                if(mapOf_PolicyNum_To_Id.get(opp.Policy_Number__c) != null) {
                    opp.Renewed_Policy__c = mapOf_PolicyNum_To_Id.get(opp.Policy_Number__c);
                }     
            }   
            update oppToUpdate; 
        }
    }
}