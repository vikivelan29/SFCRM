/******************************************************  
* Author           - Salesforce
* Date             - 14-Dec-2023
* Description      - This controller is called from asf_CaseEditPage 
                   lwc component to display the case fields for edit
********************************************************
*/
public with sharing class ASF_CaseEditPageController {
  
    @AuraEnabled(cacheable=true)
    public static Map<String,String> getfieldSetFieldsWithValues(String fieldSetName, String ObjectName, Id recordId) {
        Map<String,String> fieldNames = new Map<String,String>();
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(ObjectName);

        for (Schema.FieldSetMember fsm : objectType.getDescribe().fieldSets.getMap().get(fieldSetName).getFields()) {
            fieldNames.put(fsm.getFieldPath(),fsm.getLabel());
        }
        return fieldNames;
    } 
}