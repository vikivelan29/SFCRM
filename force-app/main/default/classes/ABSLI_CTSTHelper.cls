/**
* @description       : ABSLI CTST Helper
* @author            : dhinesh.t@salesforce.com
* @group             : 
* @last modified on  : 08-28-2024
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
* Modifications Log
* Ver   Date         Author                       Modification
* 1.0   06-05-2024   dhinesh.t@salesforce.com   Initial Version
**/
public with sharing class ABSLI_CTSTHelper {
    /****************************************************************************************************************
* @LOB - ABSLI
* @class - WrapperClass
*****************************************************************************************************************/
    public class FieldValidationResult {
        public Boolean result { get; set; }
        public Set<String> blankFields { get; set; }
        public String message { get; set; }
    }
    /****************************************************************************************************************
* @LOB - ABSLI
* @Function validateResolutionfields - Requests
* @param List<Case> caseRecs  
* @return Map<Id, FieldValidationResult>
* @description - To validate Resolution Fields
*****************************************************************************************************************/
    public static Map<Id, FieldValidationResult> validateResolutionfields(List<Case> caseRecs){
        //Id caseId = caseRec.Id;
        Map<Id, FieldValidationResult> resultsMap = new Map<Id, FieldValidationResult>();
        // VIRENDRA - 30 Jul 2024 - Added below code for 
        List<Case> survialCases = new List<Case>();
        Set<Id> surrednerWithdrawalcaseIds = new Set<Id>();
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMapIntr = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
            
            
        for(Case caseRec : caseRecs){
            FieldValidationResult validation = new FieldValidationResult();
            validation.result = false;
            validation.blankFields = new Set<String>();
            resultsMap.put(caseRec.Id, validation);
            if(caseRec.CCC_External_Id__c == ABSLI_Constants.SURVIVALCTST){
            	survialCases.add(caseRec);                
            }
            /*if(ABSLI_Constants.SURRENDER_WITHDRAWAL_CCC_IDs.contains(caseRec.CCC_External_Id__c)){
            	surrednerWithdrawalcaseIds.add(caseRec.Id);                
            }*/

        }
        
        Map<String, Schema.SObjectField> caseDetailFields = Schema.SObjectType.ABSLI_Case_Detail__c.fields.getMap();
        Schema.DescribeFieldResult caseOutcomeField = caseDetailFields.get('Outcome__c').getDescribe();
        Schema.DescribeFieldResult caseResolutionField = caseDetailFields.get('Resolution__c').getDescribe();
        
        // VIRENDRA - 30 Jul 2024 - For Survival Case Validation before Resolve.
        if(survialCases.size()>0){
            checkIfOpenBankUpdateCase(survialCases,resultMapIntr);
        }
        
        //Dhinesh - Surrender Withdrawal
        /*Map<Id,Boolean> caseSignatureMatchedMap = new Map<Id,Boolean>();
        if(surrednerWithdrawalcaseIds.size()>0){
            List<ASF_Checklist__c> checklistRecords = [SELECT Id, Description__c, Label__c,Case__c, Status__c FROM ASF_Checklist__c where case__c in: surrednerWithdrawalcaseIds and Status__c =: ABSLI_Constants.CHECKLIST_SIGNATURE_MATCHED];
            for(ASF_Checklist__c checklist : checklistRecords){
                caseSignatureMatchedMap.put(checklist.Case__c,true);
            }
        }*/
        
        for(Case caseR : caseRecs){
            FieldValidationResult validation = resultsMap.get(caseR.Id);
            if(String.isBlank(caseR.ABSLI_Case_Detail__r.Outcome__c) && !(ASF_BulkCaseProcessorUtility.isBulkProcessing == TRUE && ABSLI_BulkUpdateCaseConverterUtility.requestFromBulkUpdate == TRUE)) {
                validation.blankFields.add(caseOutcomeField.getLabel());
                validation.result = true;
            }
            if(String.isBlank(caseR.ABSLI_Case_Detail__r.Resolution__c) && !(ASF_BulkCaseProcessorUtility.isBulkProcessing == TRUE && ABSLI_BulkUpdateCaseConverterUtility.requestFromBulkUpdate == TRUE)) {
                validation.blankFields.add(caseResolutionField.getLabel());
                validation.result = true;
            }
            System.debug(caseR.ABSLI_Case_Detail__r.Outcome__c);
            if (caseR.ABSLI_Case_Detail__r.Outcome__c == 'Unresolved') {
                validation.result = true;
                validation.message = 'Team Resolution Status cannot be "Unresolved" to resolve a Case.';
            }
            List<Task> openTasks = [SELECT id,Status FROM Task WHERE WhatId =: caseR.Id];
            for(Task relatedtask : openTasks){
                if(relatedtask.Status != 'Completed'){
                    validation.result = true;
                    validation.message = 'Please complete required tasks to resolve the case.';  
                }
            }
            
            //Validation for Surrender and withrdrawal APIs
            /*if(caseSignatureMatchedMap.containsKey(caseR.Id) && caseSignatureMatchedMap.get(caseR.Id)) {
                String apiName;
                if (caseR.CCC_External_Id__c == 'PPAY001') {
                    apiName = 'Surrender API';
                } else if (caseR.CCC_External_Id__c == 'PPAY008') {
                    apiName = 'Withdrawal API';
                }
                if (!String.isEmpty(caseR.ABSLI_Case_Detail__r.PAN_Number__c)) {
                    // If both APIs (Surrender/Withdrawal and PAN Update) are unsuccessful
                    if (!caseR.ABSLI_Case_Detail__r.Is_Surrender_Withdrawal_Successful__c &&
                           !caseR.ABSLI_Case_Detail__r.Is_PAN_Update_Successful__c) {
                           validation.result = true;
                           validation.message = 'PAN Update and ' + apiName + ' need to be successful to close the case.';
                    }
                    // If only the PAN Update API is unsuccessful
                    else if (caseR.ABSLI_Case_Detail__r.Is_Surrender_Withdrawal_Successful__c &&
                           !caseR.ABSLI_Case_Detail__r.Is_PAN_Update_Successful__c) {
                           validation.result = true;
                           validation.message = 'PAN Update API needs to be successful to close the case.';
                    }
                    else if (!caseR.ABSLI_Case_Detail__r.Is_Surrender_Withdrawal_Successful__c &&
                           caseR.ABSLI_Case_Detail__r.Is_PAN_Update_Successful__c) {
                           validation.result = true;
                           validation.message =  apiName +' API needs to be successful to close the case.';
                        }
                } else {
                        // If PAN Number is empty and the Surrender/Withdrawal API is unsuccessful
                        if (!caseR.ABSLI_Case_Detail__r.Is_Surrender_Withdrawal_Successful__c) {
                            validation.result = true;
                            validation.message = apiName + ' needs to be successful to close the case.';
                        }
                }  
            }*/
            
            // Set the message within the wrapper
            if(validation.result && !validation.blankFields.isEmpty()) {
                String message = 'The following fields are mandatory to Resolve Requests : ';
                for(String fieldLabel : validation.blankFields) {
                    message += fieldLabel + ', ';
                }
                message = message.removeEnd(', ');
                validation.message = message;
            }
            if(resultMapIntr.containskey(caseR.Id)){
                validation.result = true;
                validation.message = resultMapIntr.get(caseR.Id).response;
            }
               
            resultsMap.put(caseR.Id, validation);
        }
        
        return resultsMap;
    }
    /****************************************************************************************************************
* @LOB - ABSLI
* @Function validateResolutionfieldComplaints
* @param List<Case> caseRecs  
* @return Map<Id, FieldValidationResult>
* @description - To validate Resolution Fields
*****************************************************************************************************************/
    public static Map<Id, FieldValidationResult> validateResolutionfieldComplaints(List<Case> caseRecs){
        //Id caseId = caseRec.Id;
        Map<Id, FieldValidationResult> resultsMap = new Map<Id, FieldValidationResult>();
        for(Case caseRec : caseRecs){
            FieldValidationResult validation = new FieldValidationResult();
            validation.result = false;
            validation.blankFields = new Set<String>();
            resultsMap.put(caseRec.Id, validation);
        }
        
        Map<String, Schema.SObjectField> caseDetailFields = Schema.SObjectType.ABSLI_Case_Detail__c.fields.getMap();
        Schema.DescribeFieldResult resolveCaseField = caseDetailFields.get('Resolve_case__c').getDescribe();
        Schema.DescribeFieldResult resolutionCommentsField = caseDetailFields.get('Resolution_Comments__c').getDescribe();
        Schema.DescribeFieldResult investigationCommentsField = caseDetailFields.get('Investigation_Comment__c').getDescribe();
        Schema.DescribeFieldResult acknowledgementConField = caseDetailFields.get('Acknowledgement_contacted__c').getDescribe();
        
        //IGMS Documents 
        Map<Id, List<ABSLI_IGMS_Document__c>> documentMap = new Map<Id, List<ABSLI_IGMS_Document__c>>();
        for (ABSLI_IGMS_Document__c doc : [
            SELECT Id, Case__c, RecordType.Name, Status__c 
            FROM ABSLI_IGMS_Document__c 
            WHERE Case__c IN :caseRecs
        ]) {
            if (!documentMap.containsKey(doc.Case__c)) {
                documentMap.put(doc.Case__c, new List<ABSLI_IGMS_Document__c>());
            }
            documentMap.get(doc.Case__c).add(doc);
        }
        
        for(Case caseR : caseRecs){
            FieldValidationResult validation = resultsMap.get(caseR.Id);
            if(caseR.ABSLI_Case_Detail__r.Is_Auto_Escalated__c != 'Y'){
                if(String.isBlank(caseR.ABSLI_Case_Detail__r.Resolve_case__c)) {
                    validation.blankFields.add(resolveCaseField.getLabel());
                    validation.result = true;
                }
                if(String.isBlank(caseR.ABSLI_Case_Detail__r.Resolution_Comments__c)) {
                    validation.blankFields.add(resolutionCommentsField.getLabel());
                    validation.result = true;
                }
                if(String.isBlank(caseR.ABSLI_Case_Detail__r.Investigation_Comment__c)) {
                    validation.blankFields.add(investigationCommentsField.getLabel());
                    validation.result = true;
                }
                if(String.isBlank(caseR.ABSLI_Case_Detail__r.Acknowledgement_contacted__c)) {
                    validation.blankFields.add(acknowledgementConField.getLabel());
                    validation.result = true;
                }
            }
            List<Task> openTasks = [SELECT id,Status FROM Task WHERE WhatId =: caseR.Id];
            for(Task relatedtask : openTasks){
                if(relatedtask.Status != 'Completed'){
                    validation.result = true;
                    validation.message = 'Please complete required tasks to resolve the case.';  
                }
            }
            // Set the message within the wrapper
            if(validation.result && !validation.blankFields.isEmpty()) {
                String message = 'Below Resolution Fields are mandatory to close Complaints : ';
                for(String fieldLabel : validation.blankFields) {
                    message += fieldLabel + ', ';
                }
                message = message.removeEnd(', ');
                validation.message = message;
            }
            
            Boolean showDocError = false;
            if (caseR.ABSLI_Case_Detail__r.IGMS_Complaint_Status__c == '5' || caseR.ABSLI_Case_Detail__r.IGMS_Complaint_Status__c == '6') {
                showDocError = true;
                if(documentMap.containsKey(caseR.Id)){
                    for (ABSLI_IGMS_Document__c doc : documentMap.get(caseR.Id)) {
                        System.debug('hasValidDoc'+doc.RecordType.Name);
                        System.debug('prevStage'+caseR.ABSLI_Case_Detail__r.IGMS_Complaint_Status__c);
                        if (doc.RecordType.Name == 'Upload' && doc.Status__c == 'Success') {
                            showDocError = false;
                            break;
                        }
                    }
                }
            }
            if (showDocError) {
                validation.result = true;
                validation.message = 'Please upload at least one document to IGMS to resolve an escalated case.';
            }
            resultsMap.put(caseR.Id, validation);
        }
        
        return resultsMap;
    }
    /****************************************************************************************************************
* @LOB - ABSLI
* @Function validateOpenStageFieldForReinstatement
* @param List<Case> caseRecs  
* @return Map<Id, FieldValidationResult>
* @description - To validate Resolution Fields
*****************************************************************************************************************/
    public static Map<Id, FieldValidationResult> validateOpenStageFieldForReinstatement(List<Case> caseRecs){
        Map<Id, FieldValidationResult> resultsMap = new Map<Id, FieldValidationResult>();
        for(Case caseRec : caseRecs){
            FieldValidationResult validation = new FieldValidationResult();
            validation.result = false;
            validation.blankFields = new Set<String>();
            resultsMap.put(caseRec.Id, validation);
        }
        Map<String, Schema.SObjectField> caseDetailFields = Schema.SObjectType.ABSLI_Case_Detail__c.fields.getMap();
        Schema.DescribeFieldResult pxResponseField = caseDetailFields.get('PX_Response__c').getDescribe();
        for(Case caseR : caseRecs){
            FieldValidationResult validation = resultsMap.get(caseR.Id);
            if(String.isBlank(caseR.ABSLI_Case_Detail__r.PX_Response__c)) {
                validation.blankFields.add(pxResponseField.getLabel());
                validation.result = true;
            }
        }
        return resultsMap;
        
    }
    /****************************************************************************************************************
* @LOB - ABSLI
* @Function checkIfOpenBankUpdateCase
* @param List<Case> caseRecs  
* @return Map<Id, FieldValidationResult>
* @description - To validate Resolution Fields
*****************************************************************************************************************/
    public static void checkIfOpenBankUpdateCase(List<Case> caseRecs,
                                                 Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap)
    {
        Set<Id> assetIds = new Set<Id>();
    	
        List<CaseComment> commentsToInsert = new List<CaseComment>();
        String newCommentBody = 'Bank Update case is open for this policy.';
        
        for(Case caseRecord : caseRecs){
            assetIds.add(caseRecord.AssetId);
        }
        if(assetIds.size()>0){
            Map<Id,AggregateResult> mAggregateResults = new Map<Id,AggregateResult>([SELECT AssetID Id, COUNT(ID) FROM Case
                                                                                     WHERE CCC_External_Id__c ='PNFT034' AND
                                                                                     IsClosed = False AND AssetId =:assetIds
                                                                                     GROUP BY AssetID]);

            Map<Id, List<CaseComment>> existingCommentsMap = new Map<Id, List<CaseComment>>();
            List<CaseComment> existingComments = [SELECT ParentId, CommentBody 
                                                  FROM CaseComment 
                                                  WHERE ParentId IN :caseRecs];
            if(existingComments.size() > 0){
              for (CaseComment comment : existingComments) {
                if (!existingCommentsMap.containsKey(comment.ParentId)) {
                    existingCommentsMap.put(comment.ParentId, new List<CaseComment>());
                }
                existingCommentsMap.get(comment.ParentId).add(comment);
             }  
            }
            

            for(Case caseRecord : caseRecs){
                if(mAggregateResults.containsKey(caseRecord.AssetID)){ // &&  resultMap.get(caseRecord.Id).status == ABSLI_Constants.SUCCESS){
                    Boolean hasDuplicateComment = false;
                    if(caseRecord.Technical_Source__c == 'API'){
                     	if (existingCommentsMap.containsKey(caseRecord.Id)) {
                        for (CaseComment existingComment : existingCommentsMap.get(caseRecord.Id)) {
                            if (existingComment.CommentBody == newCommentBody) {
                                hasDuplicateComment = true;
                                break;
                            }
                        }
                   	 	}
                        if (!hasDuplicateComment) {
                            CaseComment newComment = new CaseComment();
                            newComment.ParentId = caseRecord.Id;
                            newComment.CommentBody = newCommentBody;
                            commentsToInsert.add(newComment);
                        }   
                    }
                    
                    ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
                    result.status = ABSLI_Constants.ERROR;
                    result.response = Custom_Messages__mdt.getInstance('ABSLI_SurvivalUpdateIntegration_ERR3').Message__c;
                    resultMap.put(caseRecord.Id, result);
                    continue;
                }
            }
            if (!commentsToInsert.isEmpty()) {
                insert commentsToInsert;
            }
        }
    }
}