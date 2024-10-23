public with sharing class ASF_TriggerSkipperUtility {

    //This static map will contain 2 entries for each object with a trigger. 
    //Format of the key - ObjectApiName-TriggerEvent, value is by default true 
    //which indicates that trigger is allowed to run. 
    //Use the below methods to skip the trigger which will update the value to false.
    private static Map<String, boolean> skipperMap = new Map<String, boolean>{
        'Case-Before'=>true,
        'Case-After'=>true,
        'User-After'=>true,
        'ASF_Case_Integration__c-After'=>true
    };
    
    
    //Example code to invoke
    //ASF_TriggerSkipperUtility.markTriggerRun('Case');
    //update caseObj;
    //In case you want to open the trigger for further DMLs or you are already in a trigger context, 
    //dont want next methods to be skipped, reset the flags
    //ASF_TriggerSkipperUtility.resetTriggerRun('Case');

    //Skips both events
    public static void markTriggerRun(String objectName){
        skipperMap.put(objectName+'-Before', false);
        skipperMap.put(objectName+'-After', false);
    }

    //Skips specified event
    public static void markTriggerRun(String objectName, String eventName){
        skipperMap.put(objectName+'-'+eventName, false);
    }

    //Resets the trigger skipper to allowed again.
    public static void resetTriggerRun(String objectName){
        skipperMap.put(objectName+'-Before', true);
        skipperMap.put(objectName+'-After', true);
    }

    //Resets the trigger skipper to specified value again.
    public static void resetTriggerRun(String objectName, String eventName, boolean value){
        skipperMap.put(objectName+'-'+eventName, value);
    }
    
    public static boolean isAllowedToRun(String objectName, String eventName){
        return skipperMap.get(objectName+'-'+eventName);
    }
}