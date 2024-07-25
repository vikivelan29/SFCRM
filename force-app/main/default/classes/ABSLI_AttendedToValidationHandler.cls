public with sharing class ABSLI_AttendedToValidationHandler {
    
    public static final Map<String,String> caseExtFields = new Map<String,String>{'Type_of_Disposal__c'=>'Type of Disposal',
        'Resolution_Comments__c'=>'Resolution Comments',
        'Claim_Received_Amount__c'=>'Claim Received Amount'};
            
            public static void validateAttendedToNonEscalated(Case caseRecord,
                                                              ASF_IntegrationsController.IntegrationWrapper result)
        {
            if (caseRecord.Stage__c <> 'Resolved' && caseRecord.ABSLI_Case_Detail__r.Reopened_Date__c == null && caseRecord.ABSLI_Case_Detail__r.IGMS_Complaint_Status__c == '3')
            {
                result.status = ABSLI_Constants.SUCCESS;
                result.response = ABSLI_Constants.EVALUATION_SUCCESS;
            }
            
            String errorText = '';
            boolean bErrored = false;
            for(String fieldName : caseExtFields.keySet()){
                if(caseRecord.ABSLI_Case_Detail__r.get(fieldName) == null || caseRecord.ABSLI_Case_Detail__r.get(fieldName) == '')
                {
                    if(caseRecord.ABSLI_Case_Detail__r.Type_of_Disposal__c == '3' && fieldName == 'Claim_Received_Amount__c'){
                        // do nothing.
                    }
                    else{
                        errorText += caseExtFields.get(fieldName)+', ';
                    	bErrored = true;
                    }
                    
                }
                
            }
            fieldSpecificValidation(caseRecord);
            if(bErrored){
                result.status = ABSLI_Constants.ERROR;
                result.response = errorText;
            }
            
        }
    public static void fieldSpecificValidation(Case caseRecord){
        if(caseRecord.ABSLI_Case_Detail__r.Type_of_Disposal__c == 'Duplicate'){
            
        }
    }
    
}