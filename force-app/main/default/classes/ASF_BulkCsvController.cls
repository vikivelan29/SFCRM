/**
* @description       : This is the controller method for aSF_BulkCsvUploadDownload lwc
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 23-Feb-24
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class ASF_BulkCsvController {

    /**
     * Description : This method is called during the component load to fetch the access
     * and operation details based on the logged In user's business Unit
     * Input : NA
     * Output : Wrapper class with access and metadata details
     */
    @AuraEnabled(cacheable=true)
    public static List<ASF_Bulk_Row_to_Record_Converter_Config__mdt> getMetadataDetails() {
        List<ASF_Bulk_Row_to_Record_Converter_Config__mdt> allMetadata = new List<ASF_Bulk_Row_to_Record_Converter_Config__mdt>();

        String businessUnit = [select Id, Business_Unit__c from User where Id=: userInfo.getUserId()].Business_Unit__c;
        List<ASF_Bulk_Row_to_Record_Converter_Config__mdt> configMetaRec = new List<ASF_Bulk_Row_to_Record_Converter_Config__mdt>();

        configMetaRec = [Select Id, MasterLabel,DeveloperName, Display_Label__c, SObject_Name__c,
                Order__c,Apex_Class_Name__c, Template_Name__c, Max_File_Size__c, Fields_Name__c, Custom_Permission_for_Access__c, CTST_Query_Fields__c
                FROM ASF_Bulk_Row_to_Record_Converter_Config__mdt
                WHERE Active__c = true AND SObject_Name__c != null AND Business_Unit__c =:businessUnit ORDER BY Order__c];
        for(ASF_Bulk_Row_to_Record_Converter_Config__mdt config : configMetaRec){
            if(String.isBlank(config.Custom_Permission_for_Access__c) || FeatureManagement.checkPermission(config.Custom_Permission_for_Access__c)){
                allMetadata.add(config);
            }
        }
        return allMetadata;  
    }  
    
    /**
     * Description : This method returns the fields that is required for the selected template
     * Input : Config Row metadata name that user has chosen
     * Output : field names that needs to be added to chosen the template
     */
    @AuraEnabled
    public static string getCSVTemplate(String strConfigName){
        String strCSVFields = '';
        ASF_Bulk_Row_to_Record_Converter_Config__mdt configMetaRec = ASF_Bulk_Row_to_Record_Converter_Config__mdt.getInstance(strConfigName);
        if(configMetaRec != null && String.isNotBlank(configMetaRec.Fields_Name__c)){
            strCSVFields = configMetaRec.Fields_Name__c;
        }
        else{
            strCSVFields = 'No Relevant Fields Found';
        }
        return strCSVFields;       
    }

    /**
     * Description : This method is called when user clicks on the Download CSV for upload button
     * Input : operation name that user wishes to perform, current page url passed from VF, list of selected case IDs from list view,
     * 		   User's current list view ID
     * Output : List of case field with values as per the chosen template to generate the csv file
     */
    @AuraEnabled(cacheable=false)
    public static Object generateCSVFileWithData(String strConfigName, String strURL, String strSelectedRecords, String listViewId) {
     	return ASF_BulkCsvDownloadHelper.generateCSVFileWithData(strConfigName,strURL,strSelectedRecords,listViewId);  
    }
    
    /**
     * Description : This method is called when user clicks on the Download CTST button
     * Input : operation name that user wishes to perform
     * Output : List of case field with values as per the BU to generate the csv file
     */
    @AuraEnabled(cacheable=false)
    public static Object generateCSVFileWithCtst(String strConfigName) {
     	return ASF_BulkCsvDownloadHelper.generateCSVFileWithCtst(strConfigName);  
    }

    /**
     * Description : This method is called from the asfProgressComponent component and is polled every 3 seconds 
     * 				 until success to show the upload progress
     * Input : current header ID
     * Output : Wrapper class with Success and Progress count Details
     */
    @AuraEnabled(cacheable=false)
    public static CSVProgressWrapper fetchCSVUploadProgress(Id bulkHeaderId, List<Id> processedRecIds, Boolean checkHeaderStatus) {
        CSVProgressWrapper resultWrapper = new CSVProgressWrapper();
        processedRecIds = processedRecIds == null ? new List<Id>() : processedRecIds;

        for(ASF_Bulk_Upload_Line_Item__c bulkItemRec : [SELECT Id, Error_Message__c, Row_Number__c, Status__c FROM ASF_Bulk_Upload_Line_Item__c
        WHERE Bulk_Upload_Header__c=: bulkHeaderId AND Id NOT IN: processedRecIds AND (Status__c = 'Success' OR Status__c = 'Failure')
        ORDER BY createddate ASC LIMIT 49999]){
            if(bulkItemRec.Status__c == 'Failure'){
                resultWrapper.failedRecords ++;
            }
            resultWrapper.processedRecords ++;
            resultWrapper.processedRecIds.add(bulkItemRec.Id);
        }
        if(checkHeaderStatus){
            ASF_Bulk_Upload_Header__c headerRec = [SELECT Id, Status__c FROM ASF_Bulk_Upload_Header__c where Id =: bulkHeaderId FOR UPDATE];
            if(headerRec.Status__c != 'Processed'){
                headerRec.Status__c = 'Processed';
            }
            update headerRec;
            resultWrapper.processComplete = true;
        }
     	return resultWrapper;  
    }
    
    /**
     * Description : This method is used to display the final upload result
     * Input : current header ID
     * Output : List of bulk header line items results to generate the csv file
     */
    @AuraEnabled(cacheable=true)
    public static Object downloadUploadResults(Id bulkHeaderId) {
        return ASF_BulkCsvDownloadHelper.downloadUploadResults(bulkHeaderId);
    }
    
    /**
     * Description : This method is used to fetch the metadata details from header object
     * Input : current header ID
     * Output : Display fields details
     */
    @AuraEnabled(cacheable=true)
    public static String fetchfieldNames(Id bulkHeaderId) {
        String result = 'Error';
        if(bulkHeaderId != null){
            ASF_Bulk_Upload_Header__c  headerRec = [SELECT Id, Template_Name__c FROM ASF_Bulk_Upload_Header__c where Id =: bulkHeaderId];
            ASF_Bulk_Row_to_Record_Converter_Config__mdt configMetaRec = [SELECT Id, Fields_Name__c from ASF_Bulk_Row_to_Record_Converter_Config__mdt 
                                                                          WHERE Template_Name__c =: headerRec.Template_Name__c];
            result = configMetaRec.Fields_Name__c;
        }
        return result;
    }
    
    /**
     * Description : This method is used to refresh the Header Record
     * Input : current header ID
     * Output : String
     */
    @AuraEnabled(cacheable=false)
    public static String refreshHeader(Id bulkHeaderId) {
        String result = 'Error';
        if(bulkHeaderId != null){
            List<ASF_Bulk_Upload_Line_Item__c> bulkItemList = new List<ASF_Bulk_Upload_Line_Item__c>();
            bulkItemList= [SELECT Id, Status__c FROM ASF_Bulk_Upload_Line_Item__c
        				   WHERE Bulk_Upload_Header__c=: bulkHeaderId AND (Status__c = 'Pending' OR Status__c = 'Event fired')
        				   ORDER BY createddate ASC LIMIT 50000];
            if(bulkItemList.isEmpty()){
                ASF_Bulk_Upload_Header__c headerRec = new ASF_Bulk_Upload_Header__c();
                headerRec = [SELECT Id, Status__c FROM ASF_Bulk_Upload_Header__c where Id =: bulkHeaderId FOR UPDATE];
                if(headerRec.Status__c != 'Processed'){
                    headerRec.Status__c = 'Processed';
                }
                update headerRec;
                result = 'Records has been Processed. Please click on the \'Download Result\' button to view the result file';
            }else{
                result = 'Records are still under process. Please check after sometime';
            }
        }
        return result;
    }

    public class CSVProgressWrapper {
        @AuraEnabled public Decimal failedRecords;
        @AuraEnabled public Decimal processedRecords;
        @AuraEnabled public List<Id> processedRecIds;
        @AuraEnabled public Boolean processComplete;

        public CSVProgressWrapper(){
            failedRecords = 0.0;
            processedRecords = 0.0;
            processedRecIds = new List<Id>();
            processComplete = false;
        }
    }    
       
}