/*********************************************************
*Class        :  RNWL_StoredResponseUtility
*Author       :  Raj Raghuwanshi 
*Created Date :  12/09/2024
*Last Modified:  12/09/2024
*@description  : This class is used for Get/Set Response on opp files
*********************************************************/
public class RNWL_StoredResponseUtility {
    
    public static Map<String, String> mapOfFileNameToResponse = new Map<String, String>();
    
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getResponseFromFiles(String ObjId, List<String> lstFileSrcAPI){
        
        List<ContentDocumentLink> cdlinks = [SELECT ContentDocumentId, LinkedEntityId 
                                             FROM ContentDocumentLink 
                                             WHERE LinkedEntityId =: ObjId 
                                             AND LinkedEntity.Type = 'Opportunity'];
        
        Map<String, String> mapOfDNameToContent = new Map<String, String>();
        
        Set<Id> documentIds = new Set<Id>();    
        for(ContentDocumentLink cd : cdlinks){
            documentIds.add(cd.ContentDocumentId);
        }    
        
        if(documentIds.size() > 0){
            List<ContentVersion> cvList = [SELECT Id ,Content_Source_API__c, VersionData
                                           FROM ContentVersion 
                                           WHERE CreatedDate = TODAY
                                           AND ContentDocumentId IN: documentIds
                                           AND Content_Source_API__c IN:lstFileSrcAPI ];
            
            for(ContentVersion objCV : cvList){
                mapOfDNameToContent.put(objCV.Content_Source_API__c, objCV.VersionData.toString());                 
            } 
        }

        return mapOfDNameToContent;                                   
    }
    
    public static void uploadFileToOpportunity(Id objId) {
        
        try{ 
            if(!mapOfFileNameToResponse.isEmpty()){
                List<ContentVersion> lstCV = new List<ContentVersion>(); 
                List<ContentVersion> lstUpdatedCV = new List<ContentVersion>(); 
                Set<Id> setCVId = new Set<Id>();
                List<ContentDocumentLink> lstCDL = new List<ContentDocumentLink>(); 
                
                for(String strAPIName : mapOfFileNameToResponse.keySet()){ 
                    Blob fileBodyBlob = Blob.valueof(mapOfFileNameToResponse.get(strAPIName));
                    ContentVersion contentVersion = new ContentVersion();
                    contentVersion.Title = strAPIName + '-' + Date.today();
                    contentVersion.PathOnClient = strAPIName + '-' + Date.today();
                    contentVersion.VersionData = fileBodyBlob;
                    contentVersion.Content_Source_API__c = strAPIName;
                    lstCV.add(contentVersion); 
                }
                
                insert lstCV;
                
                for(ContentVersion objCV : lstCV){
                    setCVId.add(objCV.Id);
                }
                
                lstUpdatedCV = [Select Id,ContentDocumentId From ContentVersion Where Id IN : setCVId];
                
                for(contentVersion objcontentVersion : lstUpdatedCV){
                    ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
                    contentDocumentLink.ContentDocumentId = objcontentVersion.ContentDocumentId;
                    contentDocumentLink.LinkedEntityId = objId;
                    contentDocumentLink.ShareType = 'V'; 
                    lstCDL.add(contentDocumentLink);
                }
                
                insert lstCDL;   
            } 
        }
        catch(DmlException e){
            system.debug('Failed to save : '+e.getMessage()+' '+e.getLineNumber());
        }
    }
    
    public static string getResponseFromCallout(String payload, String APIName, String metaDataName){  
        
        ABCL_IntegrationCallout.IntegrationResponseWrapper responseWrapper = ABCL_IntegrationCallout.executeCallout(metaDataName, payload, null);
        String responseBody = responseWrapper.responseBody; 
        
        if(String.isNotBlank(responseBody) && (responseWrapper.statusCode == 200 || responseWrapper.statusCode == 201 || responseWrapper.statusCode == 1000)){
            mapOfFileNameToResponse.put(APIName, responseBody); 
        } 
        return responseWrapper.responseBody;
    }
    
    public static string getRenewalDetails(String policyNumber, String APIName){ 
        string payload;
        String metaDataName;
        if(APIName == 'Renewal Group Check'){
            payload = '{"lead_Id":"","master_policy_number":"","certificate_number":"' + policyNumber + '","dob":"","proposer_mobileNumber":""}';
            metaDataName = 'RNWL_Non_Ind_Account';
        }else{
            payload = '{"Policy_Number":"' + policyNumber + '","Source":"CRON-JOB"}'; 
            metaDataName = 'RNWL_RenewalDetail';
        } 
        return getResponseFromCallout(payload, APIName, metaDataName);
    }
    
    public static ABHI_HealthAssesmentDetails.IntegrationResponseWrapper getFitnessAssessmentDetails(String assetId){
        ABHI_HealthAssesmentDetails.IntegrationResponseWrapper objWrapper = ABHI_HealthAssesmentDetails.GetHealthDetails(assetId);   
        
        if(objWrapper.StatusCode == 1000){
            mapOfFileNameToResponse.put('Fitness Assessment', JSON.serialize(objWrapper)); 
            return objWrapper;
        }else{
            objWrapper.Message = 'API Failed';
            objWrapper.StatusCode = 400;
            return objWrapper;
        }
    } 
    
    public static Abhi_HealthReturnController.ResponseWrapper getHealthDetails(String policyNo, String proposalNo){
        Abhi_HealthReturnController.ResponseWrapper objWrapper = Abhi_HealthReturnController.healthReturnCallout(policyNo, proposalNo);
        
        system.debug('objWrapper'+objWrapper);
        
        if(objWrapper.StatusCode == 1000){
            mapOfFileNameToResponse.put('Health Return', JSON.serialize(objWrapper)); 
            return objWrapper;
        }else{
            objWrapper.Message = 'API Failed';
            objWrapper.StatusCode = 400;
            return objWrapper;
        }  
    } 
    
    public static ABHI_ViewPolicyInformation_Controller.ResponseWrapper getAppRegDeatils(String accId){
        ABHI_ViewPolicyInformation_Controller.ResponseWrapper objWrapper = ABHI_ViewPolicyInformation_Controller.viewPolicyInformationApiCallout(accId);
       
        if(objWrapper.StatusCode != null && 
           (objWrapper.StatusCode == 200 || objWrapper.StatusCode == 201 || objWrapper.StatusCode == 1000)){
            mapOfFileNameToResponse.put('AppRegDetails', JSON.serialize(objWrapper)); 
            return objWrapper;
        }else{
            objWrapper.Message = 'API Failed' + String.valueOf(objWrapper.StatusCode);
            return objWrapper;
        }
    }
}