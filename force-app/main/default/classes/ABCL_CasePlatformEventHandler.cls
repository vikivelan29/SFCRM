public with sharing class ABCL_CasePlatformEventHandler {
    
    public static Database.SaveResult publishPlatformEvent(String objectApiName, Map<String, String> fieldsMap){
        sObject obj = Schema.getGlobalDescribe().get(objectApiName).newSObject();
        for(String fieldName: fieldsMap.keySet()){
            obj.put(fieldName, fieldsMap.get(fieldName));
        }
        system.debug('New object/event test:: '+obj);
        Database.SaveResult eventResult = EventBus.publish(obj);
        system.debug('Published event:: '+eventResult);
        return eventResult;
    }
    
}