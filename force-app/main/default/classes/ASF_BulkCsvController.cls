public with sharing class ASF_BulkCsvController {
   
    @AuraEnabled(cacheable=true)
    public static MetadataWrapper getMetadataDetails() {
        MetadataWrapper resultWrapper = new MetadataWrapper();

        String businessUnit = [select Id, Business_Unit__c from User where Id=: userInfo.getUserId()].Business_Unit__c;
        List<ASF_Bulk_Row_to_Record_Converter_Config__mdt> configMetaRec = new List<ASF_Bulk_Row_to_Record_Converter_Config__mdt>();

        configMetaRec = [Select Id, MasterLabel,DeveloperName, Display_Label__c, SObject_Name__c,
                Order__c,Apex_Class_Name__c, Template_Name__c, Max_File_Size__c, Fields_Name__c
                FROM ASF_Bulk_Row_to_Record_Converter_Config__mdt
                WHERE Active__c = true AND SObject_Name__c = 'Case' AND Business_Unit__c =:businessUnit ORDER BY Order__c];

        resultWrapper.allMetadata =  configMetaRec;
        resultWrapper.hasCustomPermission = FeatureManagement.checkPermission('Bulk_Case_Access');
        
        return resultWrapper;  
    }  

    @AuraEnabled
    public static string getCSVTemplate(String strConfigName){
        String strCSVFields = '';
        ASF_Bulk_Row_to_Record_Converter_Config__mdt configMetaRec = ASF_Bulk_Row_to_Record_Converter_Config__mdt.getInstance(strConfigName);
        if(String.isNotBlank(configMetaRec.Fields_Name__c)){
            strCSVFields = configMetaRec.Fields_Name__c;
        }
        else{
            strCSVFields = 'No Relevant Fields Found';
        }
        return strCSVFields;       
    }
    
    @AuraEnabled(cacheable=false)
    public static Object generateCSVFileWithData(String strConfigName, String strURL, String strSelectedRecords, String listViewId) {
     	return ASF_BulkCsvDownloadHelper.generateCSVFileWithData(strConfigName,strURL,strSelectedRecords,listViewId);  
    }
    
    @AuraEnabled(cacheable=false)
    public static CSVProgressWrapper fetchCSVUploadProgress(Id bulkHeaderId) {
        CSVProgressWrapper resultWrapper = new CSVProgressWrapper();
        system.debug('fetch progress');
        ASF_Bulk_Upload_Header__c headerObj = [select Id, Total_Rows__c, Status__c from ASF_Bulk_Upload_Header__c where id=: bulkHeaderId LIMIT 1];

        for(ASF_Bulk_Upload_Line_Item__c bulkItemRec : [select Id, Error_Message__c, Row_Number__c, Status__c from ASF_Bulk_Upload_Line_Item__c
        where Bulk_Upload_Header__c=: bulkHeaderId]){
            if(bulkItemRec.Status__c == 'Failure'){
                resultWrapper.failedRecords ++;
            }
            if(bulkItemRec.Status__c == 'Failure' || bulkItemRec.Status__c == 'Success'){
                resultWrapper.processedRecords ++;
            }
        }
        resultWrapper.totalRecords = headerObj.Total_Rows__c;

     	return resultWrapper;  
    }

    @AuraEnabled(cacheable=true)
    public static Object downloadUploadResults(Id bulkHeaderId) {
        return ASF_BulkCsvDownloadHelper.downloadUploadResults(bulkHeaderId);
    }

    public class CSVProgressWrapper {
        @AuraEnabled public Decimal totalRecords;
        @AuraEnabled public Decimal failedRecords;
        @AuraEnabled public Decimal processedRecords;

        public CSVProgressWrapper(){
            totalRecords = 0.0;
            failedRecords = 0.0;
            processedRecords = 0.0;
        }
    }    
    public class MetadataWrapper {
        @AuraEnabled public List<ASF_Bulk_Row_to_Record_Converter_Config__mdt> allMetadata;
        @AuraEnabled public Boolean hasCustomPermission;

        public MetadataWrapper(){
            allMetadata = new List<ASF_Bulk_Row_to_Record_Converter_Config__mdt>();
            hasCustomPermission = false;
        }
    }    
}