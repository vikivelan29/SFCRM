/*********************************************************
*Class        :  LeadTriggerHelper
*Author       :  Vishal Gangwar
*Created Date :  27/02/2024
*Description  :  Trigger helper for Lead
*********************************************************/
public class LeadTriggerHelper {
    /****************************************************************************************************************
* @LOB - ABHFL
* @Function - sendLeadToCRM
* @return - void.
* @Description - Sending Lead to Lead management system
*****************************************************************************************************************/
    public static void sendLeadToCRM(Map<Id,Lead> newLeadMap){
        /* Ticket: INC000000034556
Modified by: Vikas Kore
Description :To resrict the creation of leads of other LOB's
*/
        
        Map<Id,Lead> ABHFLNewLeadMap = new Map<Id,Lead>();
        Map<Id,Lead> absliNewLeadMap = new Map<Id,Lead>();
		Map<Id,Lead> abcdNewLeadMap = new Map<Id,Lead>();
        for(lead lTest: newLeadMap.values()){
            if(lTest.Business_Unit__c == 'ABHFL'){
                ABHFLNewLeadMap.put(lTest.Id,lTest);
            }
            else if(lTest.Business_Unit__c == 'ABSLI'){
                absliNewLeadMap.put(lTest.Id,lTest);
            }
            else if(lTest.Business_Unit__c == 'ABCD'){
                abcdNewLeadMap.put(lTest.Id,lTest);
            }
        }
        if(ABHFLNewLeadMap.keySet().size() > 0) {
            ABHFL_LeadCreationAPI.executeSendLeadToCRM(ABHFLNewLeadMap.keySet());  
        }
        if(absliNewLeadMap.keySet().size()>0){
            ABSLI_LeadHandler.afterInsertLogic(absliNewLeadMap.values());
        }
        if(abcdNewLeadMap.keySet().size()>0){
            ABCD_LeadHandler.afterInsertLogic(abcdNewLeadMap.values());
        }
        //ABHFL_LeadCreationAPI.executeSendLeadToCRM(newLeadMap.keySet());     
    }
    
    /****************************************************************************************************************
* @Function - populateLeadFields
* @param - newLeadList
* @return - void.
* @Description - Sending Lead to ABSLIG_BusinessLogic_HelperClass
***********************************************************/
    public void populateLeadFields(List<Lead> newLeadList){
        
        ABSLIG_BusinessLogic_HelperClass absligBusinessLogicHelperClassObj = new ABSLIG_BusinessLogic_HelperClass();
        absligBusinessLogicHelperClassObj.prePopulateFields(newLeadList);
    }
}