/**
* @description       : This is the controller method for aSF_BulkCsvUploadDownload lwc
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 23-Feb-24
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@SuppressWarnings('PMD.ApexSuggestUsingNamedCred')
public without sharing class ASF_BulkCsvDownloadHelper {

    public static List<String> selectedRecIdList = new List<String>();
    public static ASF_Bulk_Row_to_Record_Converter_Config__mdt configMetaRec = new ASF_Bulk_Row_to_Record_Converter_Config__mdt();
    
    /**
     * Description : This method is called when user clicks on the Download CSV for upload button
     * Input : operation name that user wishes to perform, current page url passed from VF, list of selected case IDs from list view,
     * 		   User's current list view ID
     * Output : List of case field with values as per the chosen template to generate the csv file
     */
    public static Object generateCSVFileWithData(String strConfigName, String strURL, String strSelectedRecords, String strListViewId) {
       
        String strCSVFields = '';
        List<Map<String,String>> resultSobjectList = new List<Map<String,String>>();
        List<String> columnNames = new List<String>();
        if(String.isNotBlank(strSelectedRecords) && strSelectedRecords.length() > 2){
            strSelectedRecords = strSelectedRecords.replace('[','').replace(']','').replace(' ','');
            selectedRecIdList = strSelectedRecords.split(',');
        }      
        configMetaRec = ASF_Bulk_Row_to_Record_Converter_Config__mdt.getInstance(strConfigName);
        strCSVFields = String.isNotBlank(configMetaRec.Fields_Name__c)? configMetaRec.Fields_Name__c:'';
        columnNames = strCSVFields.split(',');

        if(strListViewId.contains('__Recent')){
            strListViewId = 'RecentlyViewed%';
            strListViewId = getRecentViewID(configMetaRec.SObject_Name__c,strListViewId);
        }else if(!strListViewId.startsWith('00B')){
            strListViewId = getRecentViewID(configMetaRec.SObject_Name__c,strListViewId);
        }
        Type customType = Type.forName(configMetaRec.Apex_Class_Name__c);
        ASF_BulkCSVToRecordConverter converter = (ASF_BulkCSVToRecordConverter)customType.newInstance();
        resultSobjectList = converter.prepareDownloadTemplate(columnNames, configMetaRec.SObject_Name__c, strListViewId, selectedRecIdList);
        


        // returns on field names if no data is present
        if(resultSobjectList == null || resultSobjectList.isEmpty()){
            return strCSVFields;
        } 
       
        return resultSobjectList; 
    }

    /**
     * Description : This method is called when user clicks on the Download CTST button
     * Input : operation name that user wishes to perform
     * Output : List of case field with values as per the BU to generate the csv file
     */
    public static Object generateCSVFileWithCtst(String strConfigName) {
        String strCSVFields = '';
        List<Map<String,String>> resultSobjectList = new List<Map<String,String>>();
        List<String> columnNames = new List<String>();
        configMetaRec = ASF_Bulk_Row_to_Record_Converter_Config__mdt.getInstance(strConfigName);
        strCSVFields = String.isNotBlank(configMetaRec.CTST_Query_Fields__c)? configMetaRec.CTST_Query_Fields__c:'';
        columnNames = strCSVFields.split(',');
        String businessUnit = String.isNotBlank(configMetaRec.Business_Unit__c)? configMetaRec.Business_Unit__c:'';

        Type customType = Type.forName(configMetaRec.Apex_Class_Name__c);
        ASF_BulkCSVToRecordConverter converter = (ASF_BulkCSVToRecordConverter)customType.newInstance();
        resultSobjectList = converter.prepareCtstData(columnNames, businessUnit);
        
        // returns on field names if no data is present
        if(resultSobjectList == null || resultSobjectList.isEmpty()){
            return strCSVFields;
        }

        return resultSobjectList;
    }

    /**
     * Description : Returns the SOQL query for a given List view and Object Name
     * Input : Object API name and List View ID
     * Output : Returns the SOQL query for a given List view
     */
    public static String getListViewSOQL(String strObjectName, String strListViewId){
        String query;
        List<Sobject> resultSobjectList = new List<Sobject>();
        HttpRequest req = new HttpRequest();
        String baseUrl = URL.getOrgDomainURL().toExternalForm();
        String endPoinURL = baseUrl+'/services/data/v50.0/sobjects/'+ strObjectName +'/listviews/'+ strListViewId +'/describe';
        req.setEndpoint(endPoinURL);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        Http http = new Http();
        HttpResponse response = http.send(req);
        if( response.getStatusCode() == 200 ) {
            Map<String, Object> tokenResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            query = (String) tokenResponse.get('query');
        }
        return query;
    }
	
    /**
     * Description : This method is used to display the final upload result
     * Input : current header ID
     * Output : List of bulk header line items results to generate the csv file
     */
    public static List<Sobject> downloadUploadResults(Id bulkHeaderId) {
        List<Sobject> resultSobjectList = new List<Sobject>();
        if(bulkHeaderId != null){
            resultSobjectList = [select Result_JSON_Data__c, JSON_Data__c from ASF_Bulk_Upload_Line_Item__c where 
                                Bulk_Upload_Header__c =: bulkHeaderId and Bulk_Upload_Header__r.Status__c = 'Processed' order by name asc LIMIT 50000];
        }
        return resultSobjectList;
    }
    
    /**
     * Description : This method returns the 'Recent' listView ID
     * Input : Object API name
     * Output : List View ID
     */
    public static String getRecentViewID(String strSobjectName, String listViewName){
        String strListViewId = '';
        List<ListView> lstRecentView = [SELECT Id, DeveloperName, SobjectType FROM ListView Where SobjectType =: strSobjectName 
                                       AND DeveloperName LIKE :listViewName];
        if(lstRecentView!=null && !lstRecentView.isEmpty()){
            strListViewId = lstRecentView[0].Id;
        }
        return strListViewId;
    }
    
}