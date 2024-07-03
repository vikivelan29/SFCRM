/*********************************************************
*Class        :  Asf_DmsViewDataTableController
*Author       :  Shubham Sinha 
*Created Date :  30/04/2024
* @description - This class is created to show the datatable columns and records 
*********************************************************/
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.ExcessiveParameterList,PMD.NcssMethodCount,PMD.StdCyclomaticComplexity,PMD.ApexSOQLInjection,PMD.AvoidDeeplyNestedIfStmts')
public with sharing class Asf_DmsViewDataTableController {
/****************************************************************************************************************
* @param configName
* @return -  List<Asf_Dynamic_Datatable_Child__mdt> .
* @description - created to fetch the datatable columns
*****************************************************************************************************************/ 
    @AuraEnabled
    public static List<Asf_Dynamic_Datatable_Child__mdt> getColumns(String configName) {
    return [SELECT MasterLabel,Order__c, DeveloperName ,Asf_Dynamic_Datatable_Parent__c , Api_Name__c, Data_Type__c,
            Asf_Dynamic_Datatable_Parent__r.Page_Size__c
            FROM Asf_Dynamic_Datatable_Child__mdt
            WHERE Asf_Dynamic_Datatable_Parent__r.DeveloperName = :configName WITH SYSTEM_MODE
            ORDER BY Order__c ASC]; 
    }

    /****************************************************************************************************************
    * @param caseId
    * @return List<DMS_Files__c> 
    * @description - created to build the query and fetch the records for datatable
    *****************************************************************************************************************/ 
    @AuraEnabled
    public static List<DMS_Files__c> executeQuery(String caseId) {
        Map<String, DMS_Files__c> mConvDMSFiles = new Map<String, DMS_Files__c>();
        String dynamicQuery = getQuery() + '\'' + caseId + '\' ORDER BY createddate desc';
        if(String.isNotBlank(dynamicQuery)) {
            // logic to get only latest DMS record for a file
            for(DMS_Files__c rec: Database.query(dynamicQuery)){
                if(!mConvDMSFiles.containsKey(rec.ContentVersionId__c)){
                    mConvDMSFiles.put(rec.ContentVersionId__c, rec);
                }
            }
        } 
        return mConvDMSFiles.values();
    }
    
    /****************************************************************************************************************
    * @param  - String
    * @return -  List<sObject> 
    * @description - created to build the query and fetch the records for datatable
    *****************************************************************************************************************/ 
     @AuraEnabled
    public static string getQuery() {
        Asf_Dynamic_Datatable_Parent__mdt  metadataRecord = [SELECT Query__c  FROM Asf_Dynamic_Datatable_Parent__mdt WHERE DeveloperName = 'Asf_DMS_File_Datatable' WITH SYSTEM_MODE LIMIT 1];
        return metadataRecord != null ? metadataRecord.Query__c : null;
    }

    /****************************************************************************************************************
    * @param documentId
    * @return String
    * @description - function used to get userdbid and encrypted document id
    *****************************************************************************************************************/ 
    @AuraEnabled
    public static string generateLinkParams(string documentId) {

        Map<String, String> requestPayload = new Map<String, String>();

        if(documentId != null) {
            requestPayload.put('DocId',documentId);
            ABCL_IntegrationCallout.IntegrationResponseWrapper intResponseWrapper = new ABCL_IntegrationCallout.IntegrationResponseWrapper();
            intResponseWrapper = (ABCL_IntegrationCallout.executeCallout(ABFL_Constants.DMS_ENCRYPT_DOC_ID, JSON.serialize(requestPayload), null));

            if(intResponseWrapper.statusCode == 200) {
                return intResponseWrapper.responseBody;
            } else {
                return  null;
            }
        } else{
            return null;
        }
    }

    /****************************************************************************************************************
    * @description Wrapper class to send the response to LWC
    *****************************************************************************************************************/
    public Class ResponseWrapper{
        @AuraEnabled
        public Integer statusCode;
        @AuraEnabled
        public String response;

         /****************************************************************************************************************
        * @description Custom constructor of ResponseWrapper class
        * @param statusCode
        * @param res
        *****************************************************************************************************************/
        public ResponseWrapper(Integer statusCode, String res){
            this.statusCode = statusCode;
            this.response = res;
        }
    }
}