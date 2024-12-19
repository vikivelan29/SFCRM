/*********************************************************
*Class        :  ABFL_submitFeedbackToUNFYD
*Author       :  nikhil.patewar@in.ey.com
*Created Date :  28/11/2024
*Last Modified:  28/11/2024
*@description  :  Feedback will be sent to UNFYD via platform event
*********************************************************/
public with sharing class ABFL_submitFeedbackToUNFYD {
    public static void sendUNFYDFeedback(String caseId){
        Map<String, String> fieldsMap = New Map<String, String>();
        List<ASF_Case_Integration__c> caseIntegrationList= New List<ASF_Case_Integration__c>();
        Case caseRecord=[Select Id,CaseNumber,Type_Text__c,Sub_Type_Text__c,Nature__c,eBOT_Email_Draft__c FROM Case where Id=:caseId LIMIT 1];
        ABFL_Case_Detail__c caseDetails=[Select Id,Ebot_Feedback__c,Case__c From ABFL_Case_Detail__c where Case__r.Id =:caseRecord.Id LIMIT 1];
        if(caseRecord!= null && caseDetails!=null){
            
            //Insert ASF_Case_Integration__c
            ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();    
            caseInt.Case__c = caseRecord.Id;
            caseInt.Status__c = 'Pending';
            caseInt.Type__c = 'FEEDBACK';
            caseIntegrationList.add(caseInt);
            
            if(caseIntegrationList.size()>0 && Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
                insert caseIntegrationList;
            }
            
            fieldsMap.put('Case_Number__c',caseRecord.CaseNumber);
            if(caseDetails.Ebot_Feedback__c.contains('Incorrect Categorization')){
                fieldsMap.put('Nature__c',caseRecord.Nature__c);
            	fieldsMap.put('Type__c',caseRecord.Type_Text__c);
            	fieldsMap.put('Subtype__c',caseRecord.Sub_Type_Text__c);
            }else{
                fieldsMap.put('Nature__c','');
                fieldsMap.put('Type__c','');
            	fieldsMap.put('Subtype__c','');
            }
            fieldsMap.put('Ebot_Feedback__c',getFormattedMultiSelectValues(caseDetails.Ebot_Feedback__c));
            //fieldsMap.put('Description__c','Yes');
            if(String.isNotBlank(caseRecord.eBOT_Email_Draft__c)){
                fieldsMap.put('Email_Response_Modified__c','Yes');
                fieldsMap.put('Modified_Email_Response__c',caseRecord.eBOT_Email_Draft__c);
            }else{
                fieldsMap.put('Email_Response_Modified__c','No');
                fieldsMap.put('Modified_Email_Response__c','');
            }
            
            //Publish the platform event
            Database.SaveResult eventResult = ABHFL_CasePlatformEventHandler.publishPlatformEvent('CRM_to_UNFYD_Feedback_Event__e', fieldsMap);
        }
    }
    
    public static String getFormattedMultiSelectValues(String multiSelectField) {
        if (String.isBlank(multiSelectField)) {
            return ''; // Return empty string if no value is selected
        }
        
        // Split the multi-select values into a list
        List<String> values = multiSelectField.split(';');
        
        // Add double quotes to each value
        List<String> formattedValues = new List<String>();
        for (String value : values) {
            formattedValues.add('"' + value + '"');
        }
        
        // Join the values with commas and return
        return String.join(formattedValues, ', ');
    }
    
}