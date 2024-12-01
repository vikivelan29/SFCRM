public without sharing class ASF_CreateFTRCase {
    @AuraEnabled(cacheable= true)
    public static FieldConfigWrapper getCaseFieldsConfig(string cccId) {
        FieldConfigWrapper wrapper = new FieldConfigWrapper();

        Map<String, List<String>> objNameToFieldsListMap = new  Map<String, List<String>>();
        objNameToFieldsListMap.put('Case', new List<String>());

        List<ASF_Case_Field_Config__c> cfcList = [SELECT Id, Display_Order__c, ObjectAPIName__c,FieldAPIName__c, Case_Main_Config__r.CCC_External_Id__c
                                          FROM ASF_Case_Field_Config__c
                                          WHERE Case_Main_Config__c = :cccId
                                          Order BY Display_Order__c
                                         ];

        if(cfcList.size() > 0){
            wrapper.cccExternalId = cfcList[0].Case_Main_Config__r.CCC_External_Id__c;

            for(ASF_Case_Field_Config__c cfc :cfcList) {
                if(! objNameToFieldsListMap.containsKey(cfc.ObjectAPIName__c)) {
                    objNameToFieldsListMap.put(cfc.ObjectAPIName__c, new List<String> {cfc.FieldAPIName__c});
                } else {
                    objNameToFieldsListMap.get(cfc.ObjectAPIName__c).add(cfc.FieldAPIName__c);
                }
            }

            if(objNameToFieldsListMap.get('Case').size() == 0) {
                objNameToFieldsListMap.remove('Case');
            }
            wrapper.objectFieldMap = objNameToFieldsListMap;
        }

        return wrapper;
    }

    public class FieldConfigWrapper {
        @AuraEnabled public String cccExternalId { get; set; }
        @AuraEnabled public Map<String, List<String>> objectFieldMap { get; set; }
    }
}