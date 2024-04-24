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
}