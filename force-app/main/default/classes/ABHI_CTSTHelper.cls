public with sharing class ABHI_CTSTHelper {
    
     public class FieldValidationResult {
        public Boolean result { get; set; }
        public Set<String> blankFields { get; set; }
        public String message { get; set; }
    }
    /****************************************************************************************************************
     * @LOB - ABHI
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

        Map<String, Schema.SObjectField> caseDetailFields = Schema.SObjectType.ABHI_Case_Detail__c.fields.getMap();
        Schema.DescribeFieldResult caseOutcomeField = caseDetailFields.get('Outcome__c').getDescribe();
        Schema.DescribeFieldResult caseResolutionField = caseDetailFields.get('Resolution__c').getDescribe();
        for(Case caseR : caseRecs){
            FieldValidationResult validation = resultsMap.get(caseR.Id);
            if(String.isBlank(caseR.ABHI_Case_Detail__r.Outcome__c)) {
                validation.blankFields.add(caseOutcomeField.getLabel());
                validation.result = true;
            }
            if(String.isBlank(caseR.ABHI_Case_Detail__r.Resolution__c)) {
                validation.blankFields.add(caseResolutionField.getLabel());
                validation.result = true;
            }
            System.debug(caseR.ABHI_Case_Detail__r.Outcome__c);
            if (caseR.ABHI_Case_Detail__r.Outcome__c == 'Unresolved') {
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
     * @LOB - ABHI
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

        Map<String, Schema.SObjectField> caseDetailFields = Schema.SObjectType.ABHI_Case_Detail__c.fields.getMap();
        Schema.DescribeFieldResult resolveCaseField = caseDetailFields.get('Resolve_case__c').getDescribe();
        Schema.DescribeFieldResult resolutionCommentsField = caseDetailFields.get('Resolution_Comments__c').getDescribe();
        Schema.DescribeFieldResult investigationCommentsField = caseDetailFields.get('Investigation_Comment__c').getDescribe();
        Schema.DescribeFieldResult acknowledgementConField = caseDetailFields.get('Acknowledgement_contacted__c').getDescribe();
        for(Case caseR : caseRecs){
            FieldValidationResult validation = resultsMap.get(caseR.Id);
           /* if(String.isBlank(caseR.ABHI_Case_Detail__r.Resolve_case__c)) {
                validation.blankFields.add(resolveCaseField.getLabel());
                validation.result = true;
            }*/
            if(String.isBlank(caseR.ABHI_Case_Detail__r.Resolution_Comments__c)) {
              //  validation.blankFields.add(resolutionCommentsField.getLabel());
                //validation.result = true;
            }
            /*if(String.isBlank(caseR.ABHI_Case_Detail__r.Investigation_Comment__c)) {
                validation.blankFields.add(investigationCommentsField.getLabel());
                validation.result = true;
            }
            if(String.isBlank(caseR.ABHI_Case_Detail__r.Acknowledgement_contacted__c)) {
                validation.blankFields.add(acknowledgementConField.getLabel());
                validation.result = true;
            }*/
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
            resultsMap.put(caseR.Id, validation);
        }
        
        return resultsMap;
    }   
}