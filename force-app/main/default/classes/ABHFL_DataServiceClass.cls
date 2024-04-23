/*********************************************************
*Class        :  ABHFL_DataServiceClass
*Author       :  Aditya Mehrotra
*Created Date :  09/01/2024
*Last Modified:  30/01/2024
*Description  :  Controller class for Data Service Details
*********************************************************/
public with sharing class ABHFL_DataServiceClass {

    public static List<DataServiceWrapper> wrapperList = new List<DataServiceWrapper>();

    public static void traverseJson(Map<String, Object> jsonMap) {
        List<String> allowedSections = Label.ABHFL_Data_Service_Sections.split(',');
        for (String key : jsonMap.keySet()) {
            Object value = jsonMap.get(key);
            if(allowedSections.contains(key)){
                DataServiceWrapper serviceWrapper = new DataServiceWrapper();
                serviceWrapper = processSection(key,value);
                wrapperList.add(serviceWrapper);
            }
            if (value instanceof Map<String, Object>) {
                // If the value is another JSON object, recursively traverse it
                traverseJson((Map<String, Object>) value);
            } else if (value instanceof List<Object>) {
                // If the value is a JSON array, recursively traverse each element
                traverseJsonArray((List<Object>) value);
            }
        }
    }

    private static void traverseJsonArray(List<Object> jsonArray) {
        for (Object arrayElement : jsonArray) {
            if (arrayElement instanceof Map<String, Object>) {
                // If the array element is a JSON object, recursively traverse it
                traverseJson((Map<String, Object>) arrayElement);
            } else if (arrayElement instanceof List<Object>) {
                // If the array element is a JSON array, recursively traverse it
                traverseJsonArray((List<Object>) arrayElement);
            }
        }
    }

    private static DataServiceWrapper processSection(String key, Object sectionValue){
        Data_Service_Details__mdt rec = Data_Service_Details__mdt.getInstance(key);
        DataServiceWrapper serviceWrapper;
        if(rec.Section_Fields__c!=NULL && rec.Visible__c){
            serviceWrapper = new DataServiceWrapper(rec.Section_Name__c, 
                    rec.Section_Label__c, rec.Type__c, rec.isTabular__c);
            serviceWrapper.sectionTabularData = (List<Object>)((Map<String, Object>)sectionValue).get('rows');
            List<SectionColumn> cList = new List<SectionColumn>();
            for(String field: rec.Included_Fields__c.split(',')){
                cList.add(new SectionColumn(field.split(':')[1],field.split(':')[0],'String',true));    
            }
            serviceWrapper.sectionTabularColumns = cList;
        }
        return serviceWrapper;
    }

    @AuraEnabled(cacheable=true)
    public static List<DataServiceWrapper> fetchSections(String assetId) {
        Asset at = [SELECT Id, Client_Code__c, LAN__c FROM Asset WHERE Id=:assetId LIMIT 1];
        DataServiceRequestWrapper dataServiceRequest = new DataServiceRequestWrapper(at.Client_Code__c,at.LAN__c);
        String dataServiceRequestBody = JSON.serialize(dataServiceRequest);
        ABCL_IntegrationCallout.IntegrationResponseWrapper dataServiceResponse = ABCL_IntegrationCallout.executeCallout(ABHFL_Constants.DATASERVICE_INTEGRATION_METADATA,dataServiceRequestBody,null);
        Map<String, Object> jsonMap = new Map<String, Object>();
        if(dataServiceResponse.statusCode == 200 && String.isNotBlank(dataServiceResponse.responseBody)){
            jsonMap = (Map<String, Object>)JSON.deserializeUntyped(dataServiceResponse.responseBody);
        }
        // Traverse the JSON
        ABHFL_DataServiceClass.traverseJson(jsonMap);
        if(wrapperList!=null){
            return wrapperList;
        }else{
            return null;
        }
    }

    public class DataServiceRequestWrapper{

        public String CLIENT_CODE;
        public String LAN;

        public DataServiceRequestWrapper(String clientCode, String lan){
            this.CLIENT_CODE = clientCode;
            this.LAN = lan;
        }
    }

    public class SectionColumn{
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String fieldName;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public Boolean wrapText;
        public SectionColumn(String l, String f, String t, Boolean w){
            this.label = l;
            this.fieldName = f;
            this.type = t;
            this.wrapText = w;
        }
        public SectionColumn(){

        }
    }

    public class DataServiceWrapper{
        @AuraEnabled
        public String sectionName;
        @AuraEnabled
        public String sectionLabel;
        @AuraEnabled
        public Map<String, String> sectionFieldsMap;
        @AuraEnabled
        public List<Object> sectionTabularData;
        @AuraEnabled
        public List<SectionColumn> sectionTabularColumns;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public Boolean tabular;
        
        public DataServiceWrapper(String secName, String secLabel, String tp, Boolean table){
            this.sectionName = secName;
            this.sectionLabel = secLabel;
            this.type = tp;
            this.sectionFieldsMap = new Map<String, String>();
            this.sectionTabularData = new List<Object>();
            this.sectionTabularColumns = new List<SectionColumn>();
            this.tabular = table;
        }

        public DataServiceWrapper(){

        }
    }

}