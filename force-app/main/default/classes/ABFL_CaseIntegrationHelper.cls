/*********************************************************
*Class        :  ABFL_CaseIntegrationHelper
*Author       :  Nikhil Patewar
*Created Date :  19/11/2024
*Last Modified:  
*Description  :  Case Integration Trigger Helper for ABFL LOB
*********************************************************/
public with sharing class ABFL_CaseIntegrationHelper {
    public static void unfydResponseHandler(String caseId, ABFL_UNFYDWrapper.UNFYDResponseWrapper unfydResponse){
        try{
            ASF_Case_Category_Config__c caseCatConfig = [Select Id, Type__c,Sub_Type__c,CCC_External_Id__c,Business_Unit__c,Nature__c from ASF_Case_Category_Config__c Where CCC_External_Id__c=:unfydResponse.ISSUECODE AND Business_Unit__c='ABFL' LIMIT 1];
            //create ABFL_Case_Detail__c record
            ABFL_Case_Detail__c caseDetails = new ABFL_Case_Detail__c();
            caseDetails.Intent__c=String.isNotBlank(unfydResponse.INTENT)? unfydResponse.INTENT : ''; // New field
            caseDetails.Correct_Call_Type__c= caseCatConfig.Type__c;
            caseDetails.Correct_Sub_Type__c=caseCatConfig.Sub_Type__c;
            //caseDetails.CustomerNo__c=String.isNotBlank(unfydResponse.CUSTOMERNO)? unfydResponse.CUSTOMERNO : '';
            caseDetails.IsSMT__c = ( String.isNotBlank(unfydResponse.ISSMT) && unfydResponse.ISSMT == 'Yes') ? true : false;
            caseDetails.IsMultipleintent__c = (String.isNotBlank(unfydResponse.ISMULTIPLEINTENT) && unfydResponse.ISMULTIPLEINTENT == 'Yes') ? true : false; // New field
            caseDetails.LOB__c=String.isNotBlank(unfydResponse.LOB)? unfydResponse.LOB : ''; // New field
            caseDetails.IsRegisteredCustomer__c=String.isNotBlank(unfydResponse.ISREGISTEREDCUSTOMER)? unfydResponse.ISREGISTEREDCUSTOMER : '';
            caseDetails.PayTmInteractionId__c=String.isNotBlank(unfydResponse.PAYTMINTERACTIONID)? unfydResponse.PAYTMINTERACTIONID : '';
            caseDetails.Priority__c=String.isNotBlank(unfydResponse.PRIORITY)? unfydResponse.PRIORITY : '';
            caseDetails.LAN__c=String.isNotBlank(unfydResponse.LAN)? unfydResponse.LAN : ''; // New field
            caseDetails.Moodstamp__c=String.isNotBlank(unfydResponse.MOODSTAMP)? unfydResponse.MOODSTAMP : '';
            //nature  - field is not present
            caseDetails.Is_Potential_Complaint__c=(String.isNotBlank(unfydResponse.POTENTIALCOMPLAINT) && unfydResponse.POTENTIALCOMPLAINT == 'Yes') ? true : false; // New field
            caseDetails.ConfidenceScore__c=unfydResponse.CONFIDENCESCORE != null ? unfydResponse.CONFIDENCESCORE : 0;
            caseDetails.IsTrailmail__c = (String.isNotBlank(unfydResponse.ISTRAILMAIL) && unfydResponse.ISTRAILMAIL == 'Yes') ? true : false;  // New field
            caseDetails.IsAttachmentFlag__c = (String.isNotBlank(unfydResponse.ISATTACHMENT) && unfydResponse.ISATTACHMENT == 'Yes') ? true : false;
            caseDetails.IsMultipleLAN__c = (String.isNotBlank(unfydResponse.ISMULTIPLELAN) && unfydResponse.ISMULTIPLELAN == 'Yes') ? true : false;
            caseDetails.Disposition__c=String.isNotBlank(unfydResponse.DISPOSITION)? unfydResponse.DISPOSITION : '';
            caseDetails.Comments__c=String.isNotBlank(unfydResponse.COMMENT)? unfydResponse.COMMENT : '';
            caseDetails.ABCOwner__c=String.isNotBlank(unfydResponse.OWNERFULLNAME)? unfydResponse.OWNERFULLNAME : '';
            caseDetails.Remarks__c=String.isNotBlank(unfydResponse.REMARKS)? unfydResponse.REMARKS : '';  // New field
            if(Schema.sObjectType.ABFL_Case_Detail__c.isCreateable()) {
                insert caseDetails;
            }
            //AutoResponse Logic
            if(unfydResponse.AUTORESPONSE=='No'){
                //Make a callout for email response
                //createExtUNFYDEvent(String caseId);
            }
            //Dedup Check
            if(String.isNotBlank(caseId) && caseCatConfig!= null && unfydResponse.DEDUPE=='Yes'){
                closeDuplicateCase(caseId,unfydResponse,caseCatConfig);
            }
        }catch(exception ex){
            System.debug('Exception caught: ' + ex.getMessage());
        }
        
    }
    
    public static void closeDuplicateCase(String caseId, ABFL_UNFYDWrapper.UNFYDResponseWrapper unfydResponse,ASF_Case_Category_Config__c caseCatConfig){
        try{
            Case parentCase= [SELECT Id,AccountId,Type_Text__c,Sub_Type_Text__c,Is_Duplicate__c,CaseNumber,ParentId from Case WHERE Type_Text__c=:caseCatConfig.Type__c AND Sub_Type_Text__c=:caseCatConfig.Sub_Type__c AND Status NOT IN ('Closed','Resolved','Closed Duplicate','Unresolved') AND LAN__c=:unfydResponse.LAN LIMIT 1];
            if(parentCase != null){
                Case caseUpdate = new Case();
                caseUpdate.Id = caseId;
                caseUpdate.ParentId= parentCase.Id;
                caseUpdate.CCC_External_Id__c=unfydResponse.ISSUECODE;
                caseUpdate.Nature__c=caseCatConfig.Nature__c;
                caseUpdate.LAN__c=String.isNotBlank(unfydResponse.LAN)? unfydResponse.LAN : '';
                caseUpdate.Client_Code_Text__c=String.isNotBlank(unfydResponse.CUSTOMERNO)? unfydResponse.CUSTOMERNO : '';
                //Update the status
                caseUpdate.Status='Closed Duplicate';
                Update caseUpdate;
                //Send email
            }
        }catch(exception ex){
            System.debug('Exception caught: ' + ex.getMessage());
        }
    }
    
    public static void createExtUNFYDEvent(String caseId){
        //1) Create case Integration record
        
        //2) Declare and Map Platform event for UNFYD call for email
        
        //3) Publish the Event
    }
}
