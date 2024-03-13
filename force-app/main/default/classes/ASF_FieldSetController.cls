public without sharing class ASF_FieldSetController {
    
    public static Schema.FieldSet fieldSet = null;
    
    
    @AuraEnabled
    public static FieldSetForm getForm(Id recordId, String objectName, String fieldSetName) {
        FieldSetForm form = new FieldSetForm();        
        form.Fields = getFields(recordId, objectName, fieldSetName);
        
        System.debug(form);
        return form;
    }
    @AuraEnabled
    public static FieldSetForm getLOBSpecificForm(Id recordId,String objectName,String fieldSetName,Boolean salesProspect){
        Id loggedInUserId = UserInfo.getUserId();
        User loggedInUser = [SELECT ID,Business_Unit__c FROM User WHERE Id =: loggedInUserId];
        getFieldSetName(objectName,loggedInUser.Business_Unit__c,salesProspect);
        FieldSetForm form = new FieldSetForm();        
        form.Fields = getFields(recordId, objectName, fieldSetName);
        return form;
        
    }
    private static void getFieldSetName(String objectName,String businessUnit,Boolean salesProspect){
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
        List<Schema.FieldSetMember> fieldSetMembers = new List<Schema.FieldSetMember>();
        
        Map<String, Schema.FieldSet> fieldSetMap = objectDescribe.fieldSets.getMap();
        System.debug(fieldSetMap);
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
    
    private static List<Field> getFields(Id recordId, String objectName, String fieldSetName) {
        Schema.SObjectType objectType = null;
        
        if (recordId != null) {
            objectType = recordId.getSobjectType();
        }
        else if (String.isNotBlank(objectName)) {
            objectType = Schema.getGlobalDescribe().get(objectName);
        }
        System.debug(objectType);
        
        if(fieldSet == null){
            Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
            Map<String, Schema.FieldSet> fieldSetMap = objectDescribe.fieldSets.getMap();
            fieldSet = fieldSetMap.get(fieldSetName);
        }
        System.debug('fieldSet --> '+fieldSet); 
        List<Schema.FieldSetMember> fieldSetMembers = fieldSet.getFields();
        
        List<Field> fields = new List<Field>();
        for (Schema.FieldSetMember fsm : fieldSetMembers) {
            System.debug(fsm);
            fields.add(new Field(fsm.getFieldPath(),fsm.getRequired()));
        }
        
        return fields;
    }
    
    public class FieldSetForm {
        @AuraEnabled
        public List<Field> Fields { get; set; }
        
        public FieldSetForm() {
            Fields = new List<Field>();
        }
    }
    public class Field{
        @AuraEnabled
        public string FieldName{get;set;}
        @AuraEnabled
        public boolean required{get;set;}
        
        public Field(String fld, boolean rqd){
            this.FieldName = fld;
            this.required = rqd;
        }
    }
    
}