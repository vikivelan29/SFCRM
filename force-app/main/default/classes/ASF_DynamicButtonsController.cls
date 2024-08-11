public class ASF_DynamicButtonsController {
    
    @AuraEnabled(cacheable=true)
    public static List<ASF_ButtonCardConfig__mdt> getButtonsConfig(String objApiName,String recId){
        String dynamicQuery = 'SELECT ID,Business_Unit__c FROM '+objApiName+' WHERE Id =:recId';
        List<SObject> objs = Database.Query(dynamicQuery);
        String busUnit = (String)objs[0].get('Business_Unit__c');
        return [SELECT Id,Order__c, ObjectApiName__c, Business_Unit__c, 
                Button_Label__c, On_Click_Invoke_LWC__c, 
                On_Click_Invoke_ApexClass__c,SLDS_Icon__c
                FROM ASF_ButtonCardConfig__mdt
                WHERE ObjectApiName__c = :objApiName
                AND Business_Unit__c =: busUnit
                ORDER BY Order__c ASC];
    }
}