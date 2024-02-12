public with sharing class ABHFL_AssetFileUploader {

    @AuraEnabled
    public static String uploadFile(String base64, String lan, String recordId, String detailId, string extension){
        ContentDocumentLink cdl = new ContentDocumentLink();
        if(String.isBlank(lan)){
            cdl = createContentLinkDirect(base64,recordId,extension);
        } else {
            ContentVersion cv = createContentVersion(base64, detailId,lan,extension);
            cdl = createContentLink(cv.Id, new List<String>{recordId,detailId});
            if (cv == null || cdl == null) { return null; }
        }

        return cdl.Id;
    }

    private static ContentVersion createContentVersion(String base64, String detailId, string lan, string extension){
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.IsSTP__c = true;
        string searchTerm = lan + '%';
        List<ContentDocumentLink> docLinkList = [Select id from ContentDocumentLink 
                                                 where LinkedEntityId =: detailId and contentDocument.Title like :searchTerm ];
        integer docCount = 1;
        if(docLinkList.size() > 0){
            docCount = docLinkList.size() + 1;
        }
        cv.Title = lan + '_FCL_Letter_' + docCount + '.'+ extension;
        cv.PathOnClient = lan + '_FCL_Letter_' + docCount+ '.'+ extension;
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

    public static ContentDocumentLink createContentLinkDirect(String base64, string recordId, string extension){
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.IsSTP__c = true;
        List<Case> caseRecord = [Select id,CCC_External_Id__c from Case where ABHFL_Case_Detail__c =: recordId];
        string fileSearchTerm = '';
        if(caseRecord[0].CCC_External_Id__c == 'HFCRARGI'){
            fileSearchTerm = 'GST_Invoice_';
        } else if(caseRecord[0].CCC_External_Id__c == 'hfl029'){
            fileSearchTerm = 'Escrow_Statement_';
        } else if(caseRecord[0].CCC_External_Id__c == 'AC123470'){
            fileSearchTerm = 'DSRA_Liquidation_Lien_Removal_';
        }
        string searchTerm = fileSearchTerm+'%';
        
        List<ContentDocumentLink> docLinkList = [Select id from ContentDocumentLink 
                                                 where LinkedEntityId =: caseRecord[0].Id and contentDocument.Title like :searchTerm ];
        integer docCount = 1;
        if(docLinkList.size() > 0){
            docCount = docLinkList.size() + 1;
        }
        cv.Title = fileSearchTerm + docCount + '.'+ extension;
        cv.PathOnClient = fileSearchTerm + docCount+ '.'+ extension;
        try {
            if(Schema.sObjectType.ContentVersion.isCreateable()){
                insert cv;
            }
        } catch(DMLException e) {
            System.debug(e);
            return null;
        }
        
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = ContentDocumentId;
        cdl.LinkedEntityId = caseRecord[0].Id;
        cdl.ShareType = 'V';
        try {
            if(Schema.sObjectType.ContentDocumentLink.isCreateable()){
                insert cdl;
            }
            return cdl;
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