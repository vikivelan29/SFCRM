/**
 * @description       : ABSLI CTST Helper
 * @author            : dhinesh.t@salesforce.com
 * @group             : 
 * @last modified on  : 06-03-2024
 * @last modified by  : dhinesh.t@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   06-05-2024   dhinesh.t@salesforce.com   Initial Version
**/
public with sharing class ABSLI_CTSTHelper {
	 /****************************************************************************************************************
     * @LOB - ABSLI
     * @Function 
     * @param   
     * @param 
     * @return 
     * @description - 
     *****************************************************************************************************************/
   /*public static Boolean areIGMSPopulated(List<Case> cases) {
        // List of field API names of ABSLI to be checked
        List<String> fieldApiNames = new List<String>{
            'Is_IRDAI_Status_Closed__c',
            'Complaint_Details__c',
            'Type_of_Disposal__c'
        };

        Set<Id> parentIds = new Set<Id>();
        
        for (Case c : cases) {
            if (c.ABSLI_Case_Detail__c != null) {
                parentIds.add(c.ABSLI_Case_Detail__c);
            }
        }
        
       
        String queryString = 'SELECT ' + String.join(fieldApiNames, ', ') + ' FROM ABSLI_Case_Detail__c WHERE Id IN :parentIds';
        List<ABSLI_Case_Detail__c> parentRecords = Database.query(queryString);
        
        for (ABSLI_Case_Detail__c parentRecord : parentRecords) {
            for (String fieldName : fieldApiNames) {
                Object fieldValue = parentRecord.get(fieldName);
                if (fieldValue == null) {
                    return true; // Return true if any field is not populated
                }
            }
        }
        
        return false; // Return false if all fields are populated
    }*/
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