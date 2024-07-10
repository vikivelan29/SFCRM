/*********************************************************
*Class        :  ABSLI_CreateCaseValidationsController
*Author       :  Aditya Mehrotra
*Created Date :  06/05/2024
*Last Modified:  06/05/2024
*@description :  Class for all ABSLI pre case creation validations from UI
*********************************************************/
public without sharing class ABSLI_CreateCaseValidationsController {
    
    @AuraEnabled
    public static String penalInterestPayoutSaralHealthValidation(String caseRecord){
        try {
            Asset policy = ABSLI_CreateCaseValidationsController.getPolicyDetails(caseRecord);
            if(policy!=null){
                if(policy.Plan_Name__c==ABSLI_Constants.SARAL_HEALTH_PLAN_NAME){
                    return 'Success';
                }else{
                    return 'Policy is not eligible for Penal Interest Payout - Saral Health Reimbursement.';
                }
            }
            return 'User is not eligible';
            
        } catch (Exception e) {
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABSLI_Penal Interest Payout - Saral Health Reimbursement Case creation validation');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    //AM-PR970457-2001 - Loan payout validation before case creation. Call Gen Fund API to check loan eligibility.
    @AuraEnabled 
    public static String genFundApiValidationCallout(String caseRecord){
        try{
            PolicyGenFundRequestWrapper requestWrap = new PolicyGenFundRequestWrapper();
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped((caseRecord));
            Asset policy = [SELECT Id, Name, Effective_Date__c FROM Asset WHERE Business_Unit__c=:ABSLI_Constants.BUSINESS_UNIT
                           AND Id=:String.valueOf(jsonMap.get('AssetId'))];
            if(policy!=null)
            {
               	requestWrap.policy_id = policy.Name;
                DateTime effectiveDateTime;
                if(policy.Effective_Date__c!=null){
                	effectiveDateTime = DateTime.newInstance(policy.Effective_Date__c.year(), policy.Effective_Date__c.month(),policy.Effective_Date__c.day());    
                }
               	requestWrap.effective_date = policy.Effective_Date__c!=null ? (effectiveDateTime.format('dd-MM-yyyy')) : '';
                ABCL_IntegrationCallout.IntegrationResponseWrapper genFundResponse = ABCL_IntegrationCallout.executeCallout(ABSLI_Constants.POLICY_GEN_FUND_INTEGRATION_METADATA,
                                                                                                                    JSON.serialize(requestWrap),
                                                                                                                    null);
                if(String.isNotBlank(genFundResponse.responseBody) && genFundResponse.statusCode == 200){
               		GenFundResponseWrapper responseWrapper = (GenFundResponseWrapper)JSON.deserialize(genFundResponse.responseBody,GenFundResponseWrapper.class);
                    if(responseWrapper.ProcessCode=='00'){
                        ABSLI_Case_Detail__c caseExt = new ABSLI_Case_Detail__c(Id=String.valueOf(jsonMap.get('ABSLI_Case_Detail__c')));
                        if(Decimal.valueOf(responseWrapper.MAX_LOAD_AMOUNT_AVAILABLE)>0 || !String.isBlank(responseWrapper.MAX_LOAD_AMOUNT_AVAILABLE)){
                            caseExt.Max_Loan_Amount__c = Decimal.valueOf(responseWrapper.MAX_LOAD_AMOUNT_AVAILABLE);
                        }else{
                            return 'Maximum loan amount not specified.';
                        }
                        if(Decimal.valueOf(responseWrapper.MINIMUM_LOAN_AMT)>0 || !String.isBlank(responseWrapper.MINIMUM_LOAN_AMT)){
                        	caseExt.Min_Loan_Amount__c = Decimal.valueOf(responseWrapper.MINIMUM_LOAN_AMT);    
                        }else{
                            caseExt.Min_Loan_Amount__c = Decimal.valueOf(Label.ABSLI_Min_Loan_Amount);
                        }
                        update caseExt;
                    	return 'Success';    
                    }else{
            			return 'Policy is not eligible for loan payout.';         	   
                    }
                }
            }
        	return 'User is not eligible';
        }catch (Exception e) {
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABSLI_PolicyGenFundIntegration callout');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
            throw new AuraHandledException(e.getMessage());
        }
    }

    //AM-PR970457-2002 - nominee change pre case creation validation from UI
    @AuraEnabled
    public static String nomineeChangeCaseCreationValidation(String caseRecord){
        try {
			Asset policy = ABSLI_CreateCaseValidationsController.getPolicyDetails(caseRecord);
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

    //AM-PR970457-2026 - pre case creation validation from UI
    @AuraEnabled
    public static String duplicatePolicyPrintingValidation(String caseRecord){
        try {
            Asset policy = ABSLI_CreateCaseValidationsController.getPolicyDetails(caseRecord);
            if(policy!=null && policy.Issue_Date__c!=null){
                Date issueDate = Date.newInstance(policy.Issue_Date__c.year(), policy.Issue_Date__c.month(), policy.Issue_Date__c.day());
                Date oneYearAgo = Date.today().addYears(-1);
                if(issueDate >= oneYearAgo){
                    return 'Success';
                }else{
                    return 'Policy is not eligible for Duplicate Policy printing.';
                }
            }
            return 'User is not eligible';
        } catch (Exception e) {
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABSLI Duplicate Policy printing validation');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
            throw new AuraHandledException(e.getMessage());
        }
    }

    //AM-PR970457-2026 - pre case creation validation from UI,calling UIN API to check policy eligibility
    @AuraEnabled
    public static String performUINapiCallout(String caseRecord){
        try{
            Asset policy = ABSLI_CreateCaseValidationsController.getPolicyDetails(caseRecord);
            if(policy!=null){
                UINapiRequestWrapper request = new UINapiRequestWrapper();
                request.POLICY_ID = policy.Policy_No__c;
                if(policy.Effective_Date__c!=null){
                    DateTime effectiveDateTime = DateTime.newInstance(policy.Effective_Date__c.year(), policy.Effective_Date__c.month(),policy.Effective_Date__c.day());
                    request.EFFECTIVE_DATE = (effectiveDateTime.format('ddMMyyyy'));
                }
                request.SOURCE = ABSLI_Constants.UIN_API_SOURCE;

                ABCL_IntegrationCallout.IntegrationResponseWrapper uinApiResponse = ABCL_IntegrationCallout.executeCallout(ABSLI_Constants.UIN_API_INTEGRATION_METADATA,
                                                                                                                        JSON.serialize(request),
                                                                                                                        null);
                system.debug('Aditya uinApiResponse:'+uinApiResponse);
                system.debug('Aditya uinApiResponse:'+uinApiResponse.responseBody);
                system.debug('Aditya uinApiResponse:'+uinApiResponse.statusCode);
                if(String.isNotBlank(uinApiResponse.responseBody) && uinApiResponse.statusCode == 200){
                    UINapiResponseWrapper responseWrapper = (UINapiResponseWrapper)JSON.deserialize(uinApiResponse.responseBody,UINapiResponseWrapper.class);
                    if(responseWrapper.Response.Status_Code=='0'){
                        return 'Success';
                    }else{
                        return 'Policy is not eligible.';
                    }
                }else{
                    return 'User is not eligible.';
                }
            }else{
                return 'User is not eligible.';
            }
        }catch(Exception e) {
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABSLI UIN API callout');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static Asset getPolicyDetails(String caseRecord){
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped((caseRecord));
        String assetId = '';
        if(jsonMap.get('AssetId')==null){
            Case cs = [SELECT Id, AssetId FROM Case WHERE Id=:String.valueOf(jsonMap.get('Id'))];
            assetId = cs.AssetId;
        }else{
            assetId = String.valueOf(jsonMap.get('AssetId'));
        }
        Asset policy = [SELECT Id, Name, Policy_No__c, Effective_Date__c, Issue_Date__c, Type__c, Payment_Term__c, 
                            Policy_Identification__c, Plan_Name__c
                        FROM Asset 
                        WHERE Business_Unit__c=:ABSLI_Constants.BUSINESS_UNIT
                        AND Id=:assetId];

        return policy;
    }

    public class UINapiRequestWrapper{
        public String POLICY_ID{get;set;}
        public String EFFECTIVE_DATE{get;set;}
        public String SOURCE{get;set;}
    }

    public class UINapiResponseWrapper{
        public innerObject Response{get;set;}
    }

    public class innerObject{
        public String Status_Code{get;set;}
        public String Message{get;set;}
    }
     
    public class PolicyGenFundRequestWrapper{
        public String policy_id{get;set;}
        public String effective_date{get;set;}
    }
    
    public class GenFundResponseWrapper{
        public String MORE_MESSAGES_IND { get; set; }
        public String MINIMUM_WITHDRAWAL_AMT { get; set; }
        public String ProcessCode { get; set; }
        public String POLICY_BILLED_TO_DATE { get; set; }
        public String MINIMUM_LOAN_AMT { get; set; }
        public String CSV_PAYABLE_HOLD_AMOUNT { get; set; }
        public String POLICY_BILL_MODE { get; set; }
        public String FUND_DETAILS { get; set; }
        public String WITHDRAWL_AMOUNT_AVAILABLE { get; set; }
        public String navdate { get; set; }
        public String MESSAGES_T { get; set; }
        public String LOAN_AMOUNT_AVAILED { get; set; }
        public String MESSAGES { get; set; }
        public String MESSAGES_T_3 { get; set; }
        public String MESSAGES_T_2 { get; set; }
        public String ProcessMessage { get; set; }
        public String MESSAGES_T_1 { get; set; }
        public String CASH_SURRENDER_VALUE { get; set; }
        public String MAX_LOAD_AMOUNT_AVAILABLE { get; set; }
        public String POLICY_SA { get; set; }
    }

}