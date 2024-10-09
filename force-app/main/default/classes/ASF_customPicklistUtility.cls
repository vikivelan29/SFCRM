@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class ASF_customPicklistUtility {
    @AuraEnabled(cacheable = true)
    public static Map<String, List<picklistValues>> getDependentPicklistValues(String sObjectName,String fieldName) {
        
        Map<String,List<picklistValues>> dependentPicklistValues = new Map<String,List<picklistValues>>();
        
        
        Schema.sObjectField dependToken = Schema.getGlobalDescribe().get( sObjectName ).getDescribe().fields.getMap().get( fieldName );
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.sObjectField controlToken = depend.getController();
        if (controlToken == null) {
            dependentPicklistValues.put('SYS_DEFAULT',getPicklistValues(sObjectName,fieldName));
            return dependentPicklistValues;
        }
        
        
        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries;
        if(control.getType() != Schema.DisplayType.Boolean) {
            controlEntries = control.getPicklistValues();
        }
        
        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        
        for (Schema.PicklistEntry entry : depend.getPicklistValues()) {
            if (entry.isActive() && String.isNotEmpty(String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')))) {
                List<String> base64chars =
                    String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
                    Object controlValue =
                        (controlEntries == null
                         ?   (Object) (index == 1)
                         :   (Object) (controlEntries[index].isActive() ? controlEntries[index].getLabel() : null)
                        );
                    Integer bitIndex = index / 6;
                    if (bitIndex > base64chars.size() - 1) {
                        break;
                    }
                    Integer bitShift = 5 - Math.mod(index, 6);
                    if  (controlValue == null || (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0)
                        continue;
                    if (!dependentPicklistValues.containsKey((String) controlValue)) {
                        dependentPicklistValues.put((String) controlValue, new List<picklistValues>());
                    }
                    dependentPicklistValues.get((String) controlValue).add(new picklistValues(entry.getLabel(),entry.getValue()));
                }
            }
        }
        return dependentPicklistValues;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<picklistValues> getPicklistValues(String sObjectName,String fieldName){
        List<picklistValues> retVal = new List<PicklistValues>();
        
        Schema.SObjectType s = Schema.getGlobalDescribe().get(sObjectName);
        Schema.DescribesObjectResult r = s.getDescribe();
        Map<String,Schema.sObjectField> fields = r.fields.getMap();
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry picklistVal : ple){
            if(picklistVal.isActive()){
                retVal.add(new picklistValues(picklistVal.getLabel(),picklistVal.getValue()));   
            }
        }
        return retVal;
    }
    public class picklistValues implements Comparable  {
        @AuraEnabled
        public string label{get;set;}
        @AuraEnabled
        public string value{get;set;}
        
        public picklistValues(String lbl,String val){
            this.label = lbl;
            this.value = val;
        }
        public Integer compareTo(Object compareTo) {
            picklistValues compareToPickList = (picklistValues)compareTo;
            if (label == compareToPickList.label) return 0;
            if (label > compareToPickList.label) return 1;
            return -1;        
        }
        
    }
    
}