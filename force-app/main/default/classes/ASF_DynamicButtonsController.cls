public class ASF_DynamicButtonsController {
    
    @AuraEnabled(cacheable=true)
    public static List<ASF_ButtonCardConfig__mdt> getButtonsConfig(String objApiName){
        return [SELECT Id,Order__c, ObjectApiName__c, Business_Unit__c, 
                Button_Label__c, On_Click_Invoke_LWC__c, 
                On_Click_Invoke_ApexClass__c,SLDS_Icon__c
                FROM ASF_ButtonCardConfig__mdt
                WHERE ObjectApiName__c = :objApiName
                ORDER BY Order__c ASC];
    }
}