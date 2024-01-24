public with sharing class ABHFL_AssetFileUploader {

    @AuraEnabled
    public static String uploadFile(String base64, String filename, String recordId, String detailId){
        ContentVersion cv = createContentVersion(base64, filename);
        ContentDocumentLink cdl = createContentLink(cv.Id, new List<String>{recordId,detailId});
        if (cv == null || cdl == null) { return null; }
        return cdl.Id;
    }

    private static ContentVersion createContentVersion(String base64, String filename){
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = filename;
        cv.PathOnClient = filename;
        cv.IsSTP__c = true;
        try {
            if(Schema.sObjectType.ContentVersion.isCreateable()){
                insert cv;
            }
            return cv;
        } catch(DMLException e) {
            System.debug(e);
            return null;
        }
    }

    private static ContentDocumentLink createContentLink(String contentVersionId, List<String> entityIds) {
        
        if (contentVersionId == null || entityIds == null) { return null; }
        
        List<ContentDocumentLink> contentDocList = new List<ContentDocumentLink>();
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:contentVersionId].ContentDocumentId;
        for(String recId : entityIds){
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = ContentDocumentId;
            cdl.LinkedEntityId = recId;
            cdl.ShareType = 'V';
            contentDocList.add(cdl);
        }
        try {
            if(Schema.sObjectType.ContentDocumentLink.isCreateable()){
                insert contentDocList;
            }
            return contentDocList[0];
        } catch(DMLException e) {
            System.debug(e);
            return null;
        }
    }

    public class AssetDetailWrapper{
        @AuraEnabled
        public String lanNumber;

        @AuraEnabled
        public Decimal currentBalance;

        @AuraEnabled
        public Decimal amountOverdue;

        @AuraEnabled
        public String accountStatus;

        @AuraEnabled
        public String loanStatus;

    }

}