/*********************************************************
*Class        :  ABCL_CasePlatformEventHandler
*Author       :  Salesforce
*Created Date :  26/12/2023
*Last Modified:  15/05/2024
*@description :  Handler class for PE
*********************************************************/
public with sharing class ABCL_CasePlatformEventHandler {
    
    /*********************************************************
    * @description method to publish plateform event from the given parameters
    * @param    objectApiName
    * @param    fieldsMap
    * @return   Database.SaveResult
    *********************************************************/
    public static Database.SaveResult publishPlatformEvent(String objectApiName, Map<String, String> fieldsMap){
        sObject obj = Schema.getGlobalDescribe().get(objectApiName).newSObject();
        for(String fieldName: fieldsMap.keySet()){
            obj.put(fieldName, fieldsMap.get(fieldName));
        }
        Database.SaveResult eventResult = EventBus.publish(obj);
        return eventResult;
    }
    
}