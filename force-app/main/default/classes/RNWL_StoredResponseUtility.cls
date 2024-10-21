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
    public static Map<String, String> getResponseFromFiles(String objId, List<String> lstFileSrcAPI) {
        Map<String, String> mapOfDNameToContent = new Map<String, String>(); 

        List<ContentDocumentLink> cdlinks = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :objId AND LinkedEntity.Type = 'Opportunity'
        ];

        if (!cdlinks.isEmpty()) {
            Set<Id> documentIds = new Set<Id>();
            for (ContentDocumentLink cd : cdlinks) {
                documentIds.add(cd.ContentDocumentId);
            }
 
            List<ContentVersion> cvList = [
                SELECT Content_Source_API__c, VersionData
                FROM ContentVersion
                WHERE CreatedDate = TODAY
                AND ContentDocumentId IN :documentIds
                AND Content_Source_API__c IN :lstFileSrcAPI
            ];

            for (ContentVersion objCV : cvList) {
                mapOfDNameToContent.put(objCV.Content_Source_API__c, objCV.VersionData.toString());
            }
        }

        return mapOfDNameToContent;
    }

    public static void uploadFileToOpportunity(Id objId) {
        if (mapOfFileNameToResponse.isEmpty()) return;

        try {
            List<ContentVersion> lstCV = new List<ContentVersion>();
            List<ContentDocumentLink> lstCDL = new List<ContentDocumentLink>();

            for (String strAPIName : mapOfFileNameToResponse.keySet()) {
                Blob fileBodyBlob = Blob.valueOf(mapOfFileNameToResponse.get(strAPIName));
                ContentVersion contentVersion = new ContentVersion(
                    Title = strAPIName + '-' + Date.today(),
                    PathOnClient = strAPIName + '-' + Date.today(),
                    VersionData = fileBodyBlob,
                    Content_Source_API__c = strAPIName
                );
                lstCV.add(contentVersion);
            }

            insert lstCV;

            Map<Id, Id> cvToDocMap = new Map<Id, Id>();
            for (ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :lstCV]) {
                cvToDocMap.put(cv.Id, cv.ContentDocumentId);
            }

            for (Id cvId : cvToDocMap.keySet()) {
                ContentDocumentLink cdl = new ContentDocumentLink(
                    ContentDocumentId = cvToDocMap.get(cvId),
                    LinkedEntityId = objId,
                    ShareType = 'V'
                );
                lstCDL.add(cdl);
            }

            insert lstCDL;

        } catch (DmlException e) {
            system.debug('DML Exception: ' + e.getMessage());
        }
    }

    // Generic method to handle API callouts and store responses
    public static string getResponseFromCallout(String payload, String APIName, String metaDataName){  
        
        ABCL_IntegrationCallout.IntegrationResponseWrapper responseWrapper = ABCL_IntegrationCallout.executeCallout(metaDataName, payload, null);
        String responseBody = responseWrapper.responseBody; 
        
        if(String.isNotBlank(responseBody) && (responseWrapper.statusCode == 200 || responseWrapper.statusCode == 201 || responseWrapper.statusCode == 1000)){
            mapOfFileNameToResponse.put(APIName, responseBody); 
        } 
        return responseWrapper.responseBody;
    }
 
    // Method to retrieve renewal details with dynamic payload based on API
    public static String getRenewalDetails(String policyNumber, String APIName, String metaDataName) {
        String payload = APIName ==  RNWL_Constants.RENEWAL_GROUP_API_NAME 
            ? '{"lead_Id":"","master_policy_number":"","certificate_number":"' + policyNumber + '","dob":"","proposer_mobileNumber":""}'
            : '{"Policy_Number":"' + policyNumber + '","Source":"CRON-JOB"}';
       
        return getResponseFromCallout(payload, APIName, metaDataName);
    }

   public static ABHI_HealthAssesmentDetails.IntegrationResponseWrapper getFitnessAssessmentDetails(String assetId){
        ABHI_HealthAssesmentDetails.IntegrationResponseWrapper objWrapper = ABHI_HealthAssesmentDetails.GetHealthDetails(assetId);   
        
        if(objWrapper.StatusCode != null && 
           (objWrapper.StatusCode == 200 || objWrapper.StatusCode == 201 || objWrapper.StatusCode == 1000)){
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
        
        if(objWrapper.StatusCode != null && 
           (objWrapper.StatusCode == 200 || objWrapper.StatusCode == 201 || objWrapper.StatusCode == 1000)){
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