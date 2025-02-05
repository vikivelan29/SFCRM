global with sharing class RNWL_DocumentImagePreviewVfcController { 
    
    global String strDocumentName {get;set;}
    
    global String strImageURL {
        get {
            List<Document> lstDocument = new List<Document>(); 
            lstDocument = [SELECT Id FROM Document WHERE DeveloperName =: strDocumentName]; 
            
            if(!lstDocument.isEmpty()){  
                return URL.getOrgDomainURL().toExternalForm() + '/servlet/servlet.ImageServer?id=' +
                    lstDocument[0].Id + '&oid=' + UserInfo.getOrganizationId(); 
            }
            return '';
        }
        set;
    } 
}