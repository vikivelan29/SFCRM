public with sharing class ABSLI_UploadIGMSComplaintsIntegration {
    public static Set<String> allowedFileTypeForIGMS = new Set<String>{'jpeg', 'pdf', 'jpg', 'png'};
    /****************************************************************************************************************
    * @param caseId
    * @return List<IGMSDocumentWrapper> 
    * @description - created to build the query and fetch the records for datatable
    *****************************************************************************************************************/ 
    @AuraEnabled
    public static List<IGMSDocumentWrapper> executeQuery(String caseId, List<String> clickedIds) {
        List<IGMSDocumentWrapper> igmsDocumentList = new List<IGMSDocumentWrapper>();
        List<ContentDocumentLink> contentLinks = [Select ContentDocumentId from ContentDocumentLink where LinkedEntityId =: caseId];
        if(contentLinks.size() > 0){
            Set<Id> contentDocumentIds = new Set<Id>();
            for(ContentDocumentLink conLink : contentLinks){
                 contentDocumentIds.add(conLink.ContentDocumentId);
            }
            List<ContentVersion> contentVersion = [Select Id, ContentDocumentId, Title,FileExtension,PathonClient,ContentSize
                                                    from ContentVersion where ContentDocumentId in: contentDocumentIds];

            List<ABSLI_IGMS_Document__c> igmsDocuments = [Select id,ContentDocumentId__c,Status__c
                                                         from ABSLI_IGMS_Document__c where Case__c =: caseId order by createddate asc];

            List<Case> caseRecords = [Select id,IsClosed from case where id =: caseId];

            Map<String,ABSLI_IGMS_Document__c> contentDocumentIdIGMSDocumentMap = new Map<String,ABSLI_IGMS_Document__c>();
            for(ABSLI_IGMS_Document__c doc : igmsDocuments){
                 contentDocumentIdIGMSDocumentMap.put(doc.ContentDocumentId__c, doc);
            }
            
            for(ContentVersion content : contentVersion){
                integer fileSize = content.contentSize/1024/1024;
                if(allowedFileTypeForIGMS.contains(content.FileExtension) && fileSize < ABSLI_Constants.IGMS_MAX_FILE_SIZE){
                IGMSDocumentWrapper docWrapper = new IGMSDocumentWrapper();
                docWrapper.fileName = content.Title +'.' + content.FileExtension;
                docWrapper.contentDocumentId = content.ContentDocumentId;
                docWrapper.Status = contentDocumentIdIGMSDocumentMap.containsKey(content.ContentDocumentId) ? contentDocumentIdIGMSDocumentMap.get(content.ContentDocumentId).Status__c : docWrapper.Status;
                if(docWrapper.Status == ABSLI_Constants.SUCCESS || caseRecords[0].IsClosed || (clickedIds.contains(content.contentDocumentId) && docWrapper.Status != ABSLI_Constants.FAILURE)){
                    docWrapper.allowUpload = true;
                }
                docWrapper.contentVersionID = content.Id;
                docWrapper.igmsDocumentId = contentDocumentIdIGMSDocumentMap.containsKey(content.ContentDocumentId) ? contentDocumentIdIGMSDocumentMap.get(content.ContentDocumentId).Id : null;
                igmsDocumentList.add(docWrapper);
            }
        }
        }
        return igmsDocumentList;
    }

    @AuraEnabled
    public static ResponseWrapper uploadAttachment(string recId, string rowWrapper){
        try {
            Boolean isSuccess = true;
            String errorResponse = '';
            IGMSDocumentWrapper docWrapper = new IGMSDocumentWrapper();
            List<Case> caseRecord = [Select id,CaseNumber,IRDAI_Token_Number__c,Business_Unit__c,Asset.Policy_No__c,
                                     ABSLI_Case_Detail__r.Resolved_Date__c
                                    from Case where id =: recId limit 1];

            if(String.isNotBlank(rowWrapper)){
                docWrapper = (IGMSDocumentWrapper)JSON.deserialize(rowWrapper, IGMSDocumentWrapper.class);
            }                                    
            if(caseRecord.size() > 0 && docWrapper != null){
                ABSLI_IGMS_Document__c igmsDocument = new ABSLI_IGMS_Document__c();
                igmsDocument.Status__c = ABSLI_Constants.PENDING;
                igmsDocument.ContentDocumentId__c = docWrapper.contentDocumentId;
                igmsDocument.Case__c = caseRecord[0].Id;
                igmsDocument.File_Name__c = docWrapper.fileName;
                igmsDocument.IRDA_Token_Number__c = caseRecord[0].IRDAI_Token_Number__c;
                igmsDocument.Attachment_Source__c = 'CRM to IRDA';
                igmsDocument.Policy_No_Text__c = caseRecord[0].Asset.Policy_No__c;
                igmsDocument.RecordTypeId = Schema.sObjectType.ABSLI_IGMS_Document__c.getRecordTypeInfosByDeveloperName().get('Upload').getRecordTypeId();
                IGMSUploadDocumentWrapper downloadWrapper = new IGMSUploadDocumentWrapper();
                downloadWrapper.caseId = caseRecord[0].CaseNumber;
                downloadWrapper.IRDA_Token_Number = caseRecord[0].IRDAI_Token_Number__c;
                downloadWrapper.fileName = docWrapper.fileName;
                if(caseRecord[0].ABSLI_Case_Detail__r.Resolved_Date__c != null){
                    downloadWrapper.isFRRDoc = true;
                }else{
                    downloadWrapper.isFRRDoc = false;
                }
                downloadWrapper.contentVersionID = docWrapper.contentVersionId;
                igmsDocument.Request__c = JSON.serialize(downloadWrapper);
                Database.SaveResult result = Database.insert(igmsDocument);
                if(result.isSuccess()){
                    Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e();
                    caseIntOut.Business_Unit__c = caseRecord[0].Business_Unit__c;
                    caseIntOut.Request_Payload__c = JSON.serialize(downloadWrapper);
                    caseIntOut.Integration_Name__c = ABSLI_Constants.IGMS_UPDATECOMPLAINT_UPLOAD_SRV_NAME;
                    caseIntOut.ServiceName__c = ABSLI_Constants.IGMS_UPDATECOMPLAINT_UPLOAD_SRV_NAME;
                    caseIntOut.Case_Integration_ID__c = igmsDocument.Id;
                    Database.SaveResult publishResults = EventBus.publish(caseIntOut);
                    if(!publishResults.isSuccess()){
                        isSuccess = false;
                        errorResponse = publishResults.getErrors()[0].getMessage();
                    }
                }else{
                    isSuccess = false;
                    errorResponse = result.getErrors()[0].getMessage();
                }
            }

            return new ResponseWrapper(isSuccess,errorResponse,docWrapper.contentDocumentId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    public class IGMSDocumentWrapper{
        @AuraEnabled
        public String fileName;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String contentDocumentId;
        @AuraEnabled
        public Boolean allowUpload; 
        @AuraEnabled
        public String uploadFileLabel;
        @AuraEnabled
        public string contentVersionID;
        @AuraEnabled
        public string igmsDocumentId;
        IGMSDocumentWrapper(){
            this.status = 'Not Started';
            this.allowUpload = false;
            this.uploadFileLabel = 'Upload File';
        }
    }

    public class IGMSUploadDocumentWrapper{
        public string IRDA_Token_Number;
        public string fileName;
        public boolean isFRRDoc;
        public string contentVersionID;
        public string caseId;
    }

    public Class ResponseWrapper{
        @AuraEnabled
        public Boolean isSuccess;
        @AuraEnabled
        public String errorMsg;
        @AuraEnabled
        public String contentDocumentId;
        /**
         * @description Custom constructor for the wrapper class
         * @param isSuccess
         * @param errorMsg
         **/
        public ResponseWrapper(Boolean isSuccess, String errorMsg, String contentDocumentId){
            this.isSuccess = isSuccess;
            this.errorMsg = errorMsg;
            this.contentDocumentId = contentDocumentId;
        }
    }
}