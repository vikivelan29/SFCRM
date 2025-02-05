/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-06-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class ABSLI_AttendedToValidationHandler {
    
    public static final Map<String,String> caseExtFields = new Map<String,String>{'Type_of_Disposal__c'=>'Type of Disposal',
        'Resolution_Comments__c'=>'Resolution Comments',
        'Claim_Received_Amount__c'=>'Claim Received Amount',
        'Is_Complainant_Informed__c'=>'Is Complainant Informed'};
            
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

            Map<Id, ABSLI_CTSTHelper.FieldValidationResult> wrapperResultMap = ABSLI_CTSTHelper.validateResolutionfieldComplaints(new List<Case>{caseRecord});
            if(wrapperResultMap.containsKey(caseRecord.Id)){
                ABSLI_CTSTHelper.FieldValidationResult wrapperResult = wrapperResultMap.get(caseRecord.Id);
                if(wrapperResult.result){
                    result.status = ABSLI_Constants.ERROR;
                    result.response = wrapperResult.message; 
                    errorText = wrapperResult.message + ', '; 
                    bErrored = true;
                }
            }

            for(String fieldName : caseExtFields.keySet()){
                if(caseRecord.ABSLI_Case_Detail__r.get(fieldName) == null || caseRecord.ABSLI_Case_Detail__r.get(fieldName) == '')
                {
                    if(!(caseRecord.IGMS_Complaint_Type_Code__c == '3' || caseRecord.IGMS_Complaint_Type_Code__c == '4') && fieldName == 'Claim_Received_Amount__c'){
                        //
                    } else if(caseRecord.ABSLI_Case_Detail__r.Type_of_Disposal__c == '3' && fieldName == 'Claim_Received_Amount__c'){

                    }
                    else{
                        errorText += caseExtFields.get(fieldName)+', ';
                    	bErrored = true;
                    }
                    
                }
                
            }

            if(String.isNotBlank(errorText)){
                errorText = errorText.removeEnd(', ');
                errorText += ' fields are mandatory in the Attended to section.';
            }
            fieldSpecificValidation(caseRecord);


            if(caseRecord.ABSLI_Case_Detail__r.IGMS_Complaint_Status__c != '3'){
                errorText = 'To Attend to IGMS, Successful Sync To IGMS is needed';
            }


            if(String.isBlank(caseRecord.Issue_Type__c)){
                List<ASF_Case_Category_Config__c> caseConfigRecord = [Select id,Allowed_Issue_Types__c from ASF_Case_Category_Config__c where CCC_External_Id__c =: caseRecord.CCC_External_Id__c Limit 1];
                if(caseConfigRecord.size() > 0 && String.isNotBlank(caseConfigRecord[0].Allowed_Issue_Types__c)){
                    errorText = 'Issue Type is Mandatory for this Case Type. Kindly use the "Update Issue Type" Button';
                    bErrored = true;
                }
            }

            if(bErrored){
                result.status = ABSLI_Constants.ERROR;
                result.response = errorText;
            }
            
        }
    public static void fieldSpecificValidation(Case caseRecord){
        if(caseRecord.ABSLI_Case_Detail__r.Type_of_Disposal__c == 'Duplicate'){
            
        }
    }

    public static final Map<String,String> caseExtFieldsEscalated = new Map<String,String>{'Final_Resolution_Remark__c'=>'Final Resolution Remark',
    'Re_Open_Comments__c'=>'Re-Open Comments',
    'Date_of_Honoring_Service__c'=>'Date of Honoring Service',
    'TAT_Crossed_Remark__c'=>'TAT Crossed Remark'};

    public static void validateAttendedToEscalated(Case caseRecord,ASF_IntegrationsController.IntegrationWrapper result){
        if (caseRecord.ABSLI_Case_Detail__r.Reopened_Date__c != null && caseRecord.ABSLI_Case_Detail__r.IGMS_Complaint_Status__c == '6'){
            result.status = ABSLI_Constants.SUCCESS;
            result.response = ABSLI_Constants.EVALUATION_SUCCESS;
        }
        
        Map<Id, ABSLI_CTSTHelper.FieldValidationResult> wrapperResultMap = ABSLI_CTSTHelper.validateResolutionfieldComplaints(new List<Case>{caseRecord});
        if(wrapperResultMap.containsKey(caseRecord.Id)){
            ABSLI_CTSTHelper.FieldValidationResult wrapperResult = wrapperResultMap.get(caseRecord.Id);
            if(wrapperResult.result){
                result.status = ABSLI_Constants.ERROR;
                result.response = wrapperResult.message; 
            }
        }

        String errorText = '';
        boolean bErrored = false;
        for(String fieldName : caseExtFieldsEscalated.keySet()){
            if(caseRecord.ABSLI_Case_Detail__r.get(fieldName) == null || caseRecord.ABSLI_Case_Detail__r.get(fieldName) == '')
            {
                if(caseRecord.ABSLI_Case_Detail__r.Type_of_Disposal__c == '3' && fieldName == 'Claim_Received_Amount__c'){
                    // do nothing.
                }
                else{
                    errorText += caseExtFieldsEscalated.get(fieldName)+', ';
                    bErrored = true;
                }
                
            }
            
        }

        if(String.isNotBlank(errorText)){
            errorText = errorText.removeEnd(', ');
            errorText += ' fields are mandatory in the Attended to Escalated section.';
        }
        fieldSpecificValidation(caseRecord);

        if(bErrored){
            result.status = ABSLI_Constants.ERROR;
            result.response = errorText;
        }
            
    }
    
}