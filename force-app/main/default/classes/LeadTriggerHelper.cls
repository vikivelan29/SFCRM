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
    ABHFL_LeadCreationAPI.executeSendLeadToCRM(newLeadMap.keySet());  
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