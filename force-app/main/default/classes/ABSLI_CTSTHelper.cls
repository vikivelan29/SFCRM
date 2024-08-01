/**
 * @description       : ABSLI CTST Helper
 * @author            : dhinesh.t@salesforce.com
 * @group             : 
 * @last modified on  : 07-11-2024
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
        for(Case caseRec : caseRecs){
            FieldValidationResult validation = new FieldValidationResult();
            validation.result = false;
            validation.blankFields = new Set<String>();
            resultsMap.put(caseRec.Id, validation);
        }

    	Map<String, Schema.SObjectField> caseDetailFields = Schema.SObjectType.ABSLI_Case_Detail__c.fields.getMap();
        Schema.DescribeFieldResult caseOutcomeField = caseDetailFields.get('Outcome__c').getDescribe();
    	Schema.DescribeFieldResult caseResolutionField = caseDetailFields.get('Resolution__c').getDescribe();
        for(Case caseR : caseRecs){
            FieldValidationResult validation = resultsMap.get(caseR.Id);
            if(String.isBlank(caseR.ABSLI_Case_Detail__r.Outcome__c)) {
                validation.blankFields.add(caseOutcomeField.getLabel());
                validation.result = true;
            }
            if(String.isBlank(caseR.ABSLI_Case_Detail__r.Resolution__c)) {
                validation.blankFields.add(caseResolutionField.getLabel());
                validation.result = true;
            }
            System.debug(caseR.ABSLI_Case_Detail__r.Outcome__c);
            if (caseR.ABSLI_Case_Detail__r.Outcome__c == 'Unresolved') {
            	validation.result = true;
            	validation.message = 'Team Resolution Status cannot be "Unresolved" to resolve a Case.';
        	}
            
            // Set the message within the wrapper
            if(validation.result && !validation.blankFields.isEmpty()) {
                String message = 'The following fields are mandatory to Resolve Requests : ';
                for(String fieldLabel : validation.blankFields) {
                    message += fieldLabel + ', ';
                }
                message = message.removeEnd(', ');
                validation.message = message;
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
}