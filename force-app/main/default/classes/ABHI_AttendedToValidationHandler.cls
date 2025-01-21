public with sharing class ABHI_AttendedToValidationHandler {
    
    public static final Map<String,String> caseExtFields = new Map<String,String>{'Type_of_Disposal__c'=>'Type of Disposal',
        'Resolution_Comments__c'=>'Resolution Comments',
        'Claim_Received_Amount__c'=>'Claim Received Amount'};
        //'AccountId'=>'Customer',
        //'AssetId'=>'Asset'};
            
            public static void validateAttendedToNonEscalated(Case caseRecord,
                                                              ASF_IntegrationsController.IntegrationWrapper result)
        {
            if (caseRecord.Stage__c <> 'Resolved' && caseRecord.ABHI_Case_Detail__r.IGMS_Complaint_Status__c == '3')
            {
                result.status = ABSLI_Constants.SUCCESS;
                result.response = ABSLI_Constants.EVALUATION_SUCCESS;
            }
            
            String errorText = '';
            boolean bErrored = false;

            Map<Id, ABHI_CTSTHelper.FieldValidationResult> wrapperResultMap = ABHI_CTSTHelper.validateResolutionfieldComplaints(new List<Case>{caseRecord});
            if(wrapperResultMap.containsKey(caseRecord.Id)){
                ABHI_CTSTHelper.FieldValidationResult wrapperResult = wrapperResultMap.get(caseRecord.Id);
                if(wrapperResult.result){
                    result.status = ABSLI_Constants.ERROR;
                    result.response = wrapperResult.message; 
                    errorText = wrapperResult.message + ', '; 
                    bErrored = true;
                }
            }

            for(String fieldName : caseExtFields.keySet()){
              /*  if (String.isBlank(caseRecord.AccountId) || String.isBlank(caseRecord.AssetId)) {
                    errorText = 'Customer and Asset';
                    bErrored = true;
                }    */   
                if(caseRecord.ABHI_Case_Detail__r.get(fieldName) == null || caseRecord.ABHI_Case_Detail__r.get(fieldName) == ''){
                    if(!(caseRecord.IGMS_Complaint_Type_Code__c == '3' || caseRecord.IGMS_Complaint_Type_Code__c == '4') && fieldName == 'Claim_Received_Amount__c'){
                        //
                    } else if(caseRecord.ABHI_Case_Detail__r.Type_of_Disposal__c == '3' && fieldName == 'Claim_Received_Amount__c'){

                    }
                    else{
                        errorText += caseExtFields.get(fieldName)+', ';
                      bErrored = true;
                    }
                    
                }
              
            }
          

            if(String.isNotBlank(errorText)){
                errorText = errorText.removeEnd(', ');
                errorText += ' fields are mandatory for Attended to IGMS button.';
            }
            fieldSpecificValidation(caseRecord);


            if(caseRecord.ABHI_Case_Detail__r.IGMS_Complaint_Status__c != '3'){
                errorText = 'To Attend to IGMS, Successful Sync To IGMS is needed';
            }

            if(bErrored){
                result.status = ABSLI_Constants.ERROR;
                result.response = errorText;
            }
            
        }
    public static void fieldSpecificValidation(Case caseRecord){
        if(caseRecord.ABHI_Case_Detail__r.Type_of_Disposal__c == 'Duplicate'){
            
        }
    }

    public static final Map<String,String> caseExtFieldsEscalated = new Map<String,String>{'Final_Resolution_Remark__c'=>'Final Resolution Remark',
    'Additional_Closure_Information__c'=>'Additional Closure Information',
     'Insurer_Resolution_Letter_date__c'=>'Insurer Resolution Letter Date'
   };

    public static void validateAttendedToEscalated(Case caseRecord,ASF_IntegrationsController.IntegrationWrapper result){
        //if (caseRecord.ABHI_Case_Detail__r.Reopened_Date__c != null && caseRecord.ABHI_Case_Detail__r.IGMS_Complaint_Status__c == '6'){
            if ( caseRecord.ABHI_Case_Detail__r.IGMS_Complaint_Status__c == '6'){
            result.status = ABSLI_Constants.SUCCESS;
            result.response = ABSLI_Constants.EVALUATION_SUCCESS;
        }
        
        Map<Id, ABHI_CTSTHelper.FieldValidationResult> wrapperResultMap = ABHI_CTSTHelper.validateResolutionfieldComplaints(new List<Case>{caseRecord});
        if(wrapperResultMap.containsKey(caseRecord.Id)){
            ABHI_CTSTHelper.FieldValidationResult wrapperResult = wrapperResultMap.get(caseRecord.Id);
            if(wrapperResult.result){
                result.status = ABSLI_Constants.ERROR;
                result.response = wrapperResult.message; 
            }
        }

        String errorText = '';
        boolean bErrored = false;
        if(caseRecord.Type_Text__c == 'Claim'){
            for(String fieldName : caseExtFieldsEscalated.keySet()){
                if(caseRecord.ABHI_Case_Detail__r.get(fieldName) == null || caseRecord.ABHI_Case_Detail__r.get(fieldName) == '')
                {
                    if(caseRecord.ABHI_Case_Detail__r.Type_of_Disposal__c == '3' && fieldName == 'Claim_Received_Amount__c'){
                        // do nothing.
                    }
                    else{
                        errorText += caseExtFieldsEscalated.get(fieldName)+', ';
                        bErrored = true;
                    }
                    
                }
                
            }
    	}
        if(String.isNotBlank(errorText)){
            errorText = errorText.removeEnd(', ');
            errorText += ' and other fields are mandatory for Attended Esc to IGMS button.';
        }
        fieldSpecificValidation(caseRecord);

        if(bErrored){
            result.status = ABSLI_Constants.ERROR;
            result.response = errorText;
        }
            
    }
}