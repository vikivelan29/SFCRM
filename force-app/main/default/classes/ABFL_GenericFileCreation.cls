/**
* @Name                : ABFL_GenericFileCreation
* @Author              : AC
* @Company             : Salesforce
* @Description         : This class contains method to craete File
* Test Class           : 
* @last modified on    : 12-20-2023
* @last modified by    : ChangeMeIn@UserSettingsUnder.SFDoc
*/
public with sharing class ABFL_GenericFileCreation {
        /*
        * @Method       : createFile
        * @Created by   : AC
        * @Description  : This method will return file
        * @Param         : 
        * @Return       : 
        */
        public static Id createDocument(ContentWrapper wrapper) {
            ContentVersion cVer = new ContentVersion();
            cVer.ContentLocation = wrapper.contentLocation != null?wrapper.contentLocation:'S';
            cVer.PathonClient = wrapper.fileName;
            cVer.Title = wrapper.title;
            cVer.VersionData = wrapper.data;

            insert cVer;

            Id ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cVer.Id].ContentDocumentId;
            
            ContentDocumentLink cdl = 
            new ContentDocumentLink(
                ContentDocumentId = ContentDocumentId,
                LinkedEntityId = wrapper.parentId
            );
            insert cdl;

            return ContentDocumentId;
        }   
        
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