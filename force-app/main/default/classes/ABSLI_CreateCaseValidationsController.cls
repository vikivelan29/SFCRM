public without sharing class ABSLI_CreateCaseValidationsController {

    //AM-PR970457-2002 - nominee change pre case creation validation from UI
    @AuraEnabled
    public static String nomineeChangeCaseCreationValidation(String caseRecord){
        try {

            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped((caseRecord));
            Asset policy = [SELECT Id, Name, Policy_Identification__c 
                            FROM Asset 
                            WHERE Business_Unit__c=:ABSLI_Constants.BUSINESS_UNIT
                            AND Id=:String.valueOf(jsonMap.get('AssetId'))];
            if(policy!=null){
                if((!ABSLI_Constants.NOMINEE_UPDATE_POLICY_IDENTIFICATION_VALIDATION.contains(policy.Policy_Identification__c))){
                    return 'Success';
                }else{
                    return 'Policy is not eligible for nominee update.';
                }
            }
            return 'User is not eligible';
            
        } catch (Exception e) {
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABSLI_NomineeChange Case creation validation');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
            throw new AuraHandledException(e.getMessage());
        }
    }

}