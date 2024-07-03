/**
* @Name                : ABFL_GenericFileCreation
* @Author              : AC
* @Company             : Salesforce
* @description         : This class contains method to craete File
* Test Class           : 
* @last modified on    : 12-20-2023
* @last modified by    : ChangeMeIn@UserSettingsUnder.SFDoc
*/
public with sharing class ABFL_GenericFileCreation {

        /**
         * @method createDocument
         * @createdBy AC
         * @description This method will return file
         * @param wrapper document to be created
         * @return ID of content document
         */
        public static Id createDocument(ContentWrapper wrapper) {
            ContentVersion cVer = new ContentVersion();
            cVer.ContentLocation = wrapper.contentLocation != null?wrapper.contentLocation:'S';
            cVer.PathonClient = wrapper.fileName;
            cVer.Title = wrapper.title;
            cVer.VersionData = wrapper.data;

            insert cVer;

            Id contentDocumentId = [SELECT contentDocumentId FROM ContentVersion WHERE Id = :cVer.Id].contentDocumentId;
            
            ContentDocumentLink cdl = 
            new ContentDocumentLink(
                contentDocumentId = contentDocumentId,
                LinkedEntityId = wrapper.parentId
            );
            insert cdl;

            return contentDocumentId;
        }  

        /**
         * @description Wrapper class to hold information about a document to be created.
         */
        public class ContentWrapper {
            /*s: Document in SF  E: Document outside SF L: Document on social media  
            Default S*/
            public String contentLocation; 
            //name of file with extension
            public String fileName;
            //title of file
            public String title;
            //File content
            public Blob data;
            //Id on which file will be associated
            public Id parentId;

        }
}