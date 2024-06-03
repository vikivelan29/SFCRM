/**
 * @description       : 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 05-14-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   05-13-2024   rsinghnagar@salesforce.com   Initial Version
**/
@SuppressWarnings('PMD.PropertyNamingConventions')
public without sharing class ASF_FieldSetController {
    public static Schema.FieldSet fieldSet = null;
    
    /**
    * @description 
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param recordId 
    * @param objectName 
    * @param fieldSetName 
    * @return FieldSetForm 
    **/
    @AuraEnabled
    public static FieldSetForm getForm(Id recordId, String objectName, String fieldSetName) {
        FieldSetForm form = new FieldSetForm();        
        form.Fields = getFields(recordId, objectName, fieldSetName);
        
        return form;
    }
    
    /**
    * @description 
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param recordId 
    * @param objectName 
    * @param fieldSetName 
    * @param salesProspect 
    * @return FieldSetForm 
    **/
    @AuraEnabled
    public static FieldSetForm getLOBSpecificForm(Id recordId,String objectName,String fieldSetName,Boolean salesProspect){
        Id loggedInUserId = UserInfo.getUserId();
        User loggedInUser = [SELECT ID,Business_Unit__c FROM User WHERE Id =: loggedInUserId];
        getFieldSetName(objectName,loggedInUser.Business_Unit__c,salesProspect);
        FieldSetForm form = new FieldSetForm();        
        form.Fields = getFields(recordId, objectName, fieldSetName);
        return form;
        
    }

    /**
    * @description 
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param objectName 
    * @param businessUnit 
    * @param salesProspect 
    **/
    private static void getFieldSetName(String objectName,String businessUnit,Boolean salesProspect){
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
        List<Schema.FieldSetMember> fieldSetMembers = new List<Schema.FieldSetMember>();
        
        Map<String, Schema.FieldSet> fieldSetMap = objectDescribe.fieldSets.getMap();
        for(String fsName : fieldSetMap.keySet()){
            if(salesProspect && fsName.startsWithIgnoreCase(businessUnit+'_Sales')){
                fieldSet = fieldSetMap.get(fsName);
                break;
            }
            else if(salesProspect && !fsName.startsWithIgnoreCase(businessUnit+'_Sales')){
                continue;
            }
            else if(fsName.startsWithIgnoreCase(businessUnit)){
                fieldSet = fieldSetMap.get(fsName);
                break;
            }
        }
        if(fieldSet != null){
            fieldSetMembers = fieldSet.getFields();
        }
        
    }
    
    /**
    * @description 
    * @author rsinghnagar@salesforce.com | 05-13-2024 
    * @param recordId 
    * @param objectName 
    * @param fieldSetName 
    * @return List<Field> 
    **/
    private static List<Field> getFields(Id recordId, String objectName, String fieldSetName) {
        Schema.SObjectType objectType = null;
        
        if (recordId != null) {
            objectType = recordId.getSobjectType();
        }
        else if (String.isNotBlank(objectName)) {
            objectType = Schema.getGlobalDescribe().get(objectName);
        }
        
        if(fieldSet == null){
            Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
            Map<String, Schema.FieldSet> fieldSetMap = objectDescribe.fieldSets.getMap();
            fieldSet = fieldSetMap.get(fieldSetName);
        }
        List<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields();
        
        List<Field> fields = new List<Field>();
        for (Schema.FieldSetMember fsm : fieldSetMembers) {
            fields.add(new Field(fsm.getFieldPath(),fsm.getRequired()));
        }
        
        return fields;
    }
    
    /**
     * @description inner class
     */
    public class FieldSetForm {
        /**
        * @description : Apex Property
        **/
        @AuraEnabled
        public List<Field> Fields { get; set; }
        
        /**
        * @description 
        * @author rsinghnagar@salesforce.com | 05-13-2024 
        **/
        public FieldSetForm() {
            Fields = new List<Field>();
        }
    }

    /**
     * @description inner class
     */
    public class Field{
        /**
        * @description : Apex Property
        **/
        @AuraEnabled
        public string FieldName{get;set;}
        /**
        * @description : Apex Property
        **/
        @AuraEnabled
        public boolean required{get;set;}
        
        /**
        * @description 
        * @author rsinghnagar@salesforce.com | 05-13-2024 
        * @param fld 
        * @param rqd 
        **/
        public Field(String fld, boolean rqd){
            this.FieldName = fld;
            this.required = rqd;
        }
    }
    
}