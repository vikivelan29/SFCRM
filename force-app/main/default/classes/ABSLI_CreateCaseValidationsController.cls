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
                if(policy.Plan_Name__c.contains(ABSLI_Constants.SARAL_HEALTH_PLAN_NAME)){ 
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

    @AuraEnabled(cacheable = false)
    public static List<RedirectToPortalResponse> redirectToCustomerPortalValidation(String caseId){
        List<RedirectToPortalResponse> returnList = new List<RedirectToPortalResponse>();
        Case c = [SELECT Id, ABSLI_Case_Detail__c,CCC_External_Id__c FROM Case WHERE Id=:caseId];
        if(c.ABSLI_Case_Detail__c!=null){
        	ABSLI_Case_Detail__c caseExt = [SELECT Id, Reinstatement_Amount__c, COI_Covid_Quest__c, Medicals__c, COI_Signed_Date__c,Remarks__c
                                           FROM ABSLI_Case_Detail__c WHERE Id=:c.ABSLI_Case_Detail__c];
            Map<String,String> fieldNamesAndTypes = ABSLI_Constants.FIELD_AND_TYPE_FOR_CUSTOMER_PORTAL_REDIRECTION;
            List<String> blankFields = new List<String>();
            // VIRENDRA - 22 JUL 2024.
            String fCode = ABSLI_Constants.CCC_AND_FUNCTION_CODE.containsKey(c.CCC_External_Id__c)
            	? ABSLI_Constants.CCC_AND_FUNCTION_CODE.get(c.CCC_External_Id__c) : '';
            
            for(String field : fieldNamesAndTypes.keySet()){
              	Object fieldValue = caseExt.get(field);
            	String fieldType = fieldNamesAndTypes.get(field);
                if (fieldType == 'String' && String.isBlank((String)fieldValue)) {
                    blankFields.add(field);
                } else if (fieldType == 'Decimal' && (fieldValue == null || ((Decimal)fieldValue) == 0)) {
                    blankFields.add(field);
                } else if (fieldType == 'Date' && fieldValue == null) {
                    blankFields.add(field);
                }
            }
            
            for(ASF_Checklist__c checkList : [SELECT Id, Case__c, Status__c FROM ASF_Checklist__c WHERE Case__c =:caseId AND Mandatory__c=TRUE]){
                if(!ABSLI_Constants.CHECKLIST_PASS_STATUS.split(',').contains(checkList.Status__c)){
                    RedirectToPortalResponse responseWrap = new RedirectToPortalResponse('error','Checklist/s are still pending');
                    returnList.add(responseWrap);
                    break;
                }
            }
            if (!blankFields.isEmpty()) {
                RedirectToPortalResponse responseWrap = new RedirectToPortalResponse('error','The following fields are blank: ' + String.join(blankFields, ', '));
                returnList.add(responseWrap);
            }
            // VIRENDRA - 22 JUL 2024.
            if(caseExt.COI_Covid_Quest__c != null && fCode =='STPRI'){
                if(caseExt.COI_Covid_Quest__c.countMatches(ABSLI_Constants.RQ_REDIRECT_COVID_QUE) > 1 ){
                    RedirectToPortalResponse responseWrap = new RedirectToPortalResponse('error','Due to joint life redirect not done and treat as Non STP.');
                	returnList.add(responseWrap);
                }
            }
            
            if(returnList.size()<1){
				RedirectToPortalResponse responseWrap = new RedirectToPortalResponse('success','Redirecting to Customer Portal...');
                returnList.add(responseWrap);
            }
            
            
            return returnList;
        }else{
            RedirectToPortalResponse responseWrap = new RedirectToPortalResponse('error','Not eligible');
            returnList.add(responseWrap);
            return returnList;
        }
    }
    
    @AuraEnabled(cacheable = true)
    public static String generateCustomerPortalURL(String caseId){
        
        String staticUrl = Label.ABSLI_CustomerPortalUrl;
        DateTime currentDateTime = DateTime.Now();
        
        Case cs = [SELECT Id,CaseNumber,CCC_External_Id__c,AssetId,Asset.Policy_No__c,Client_Code__c,ABSLI_Case_Detail__r.COI_Covid_Quest__c
                  FROM Case 
                  WHERE Id=:caseId];
        
        String fCode = ABSLI_Constants.CCC_AND_FUNCTION_CODE.containsKey(cs.CCC_External_Id__c)
            	? ABSLI_Constants.CCC_AND_FUNCTION_CODE.get(cs.CCC_External_Id__c) : '';
        
        String coiValue = '';
        if(!String.isBlank(cs.ABSLI_Case_Detail__r.COI_Covid_Quest__c)){
        	coiValue = cs.ABSLI_Case_Detail__r.COI_Covid_Quest__c.replace('[', '').replace(']', '').replace('COVID_QUE','').replace('"','').replace(',','');    
        }
        
        String urlParameters = '{functionCode='+fCode+'&';
       	urlParameters += 'clientId='+cs.Client_Code__c+'&';
        urlParameters += 'policyNumber='+cs.AssetId!=null?cs.Asset.Policy_No__c:''+'&';
        urlParameters += 'timestamp='+currentDateTime.Day()+currentDateTime.Month()+currentDateTime.Year()+currentDateTime.Hour()+currentDateTime.Minute()+currentDateTime.Second()+'000'+'&';
        urlParameters += 'caseId='+cs.CaseNumber+'&';
        urlParameters += 'source='+ABSLI_Constants.ESB_SOURCE_ID+'&';
        urlParameters += 'COI='+coiValue+'}';
        
        System.debug('urlParameters--> '+urlParameters);
        
        Blob IvValue = Blob.valueOf(Label.ABSLI_Ivkey);
        Blob keyValue = Blob.ValueOf(Label.ABSLI_key);
        Blob urlParamValue = Blob.valueOf(urlParameters);
        Blob urlParamEncrypted = Crypto.encrypt('AES256', keyValue, IvValue, urlParamValue);
        String urlParamEncryptedString = EncodingUtil.base64Encode (urlParamEncrypted);

        String customerPortalUrl = staticUrl + urlParamEncryptedString;
        
        return customerPortalUrl;
    }
    
    //AM-PR970457-2001 - Loan payout validation before case creation. Call Gen Fund API to check loan eligibility.
    @AuraEnabled 
    public static String genFundApiValidationCallout(String caseRecord){
        try{
            PolicyGenFundRequestWrapper requestWrap = new PolicyGenFundRequestWrapper();
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped((caseRecord));
            Asset policy = [SELECT Id, Name,Policy_No__c,Type__c, Effective_Date__c FROM Asset WHERE Business_Unit__c=:ABSLI_Constants.BUSINESS_UNIT
                           AND Id=:String.valueOf(jsonMap.get('AssetId'))];
            if(policy!=null)
            {
               	requestWrap.policy_id = policy.Policy_No__c;
                Date today = Date.today();
                DateTime todayDateTime = DateTime.newInstance(today.year(),today.month(),today.day());
                requestWrap.effective_date = (todayDateTime.format('dd-MM-yyyy'));
                /*DateTime effectiveDateTime;
                if(policy.Effective_Date__c!=null){
                	effectiveDateTime = DateTime.newInstance(policy.Effective_Date__c.year(), policy.Effective_Date__c.month(),policy.Effective_Date__c.day());    
                }
               	requestWrap.effective_date = policy.Effective_Date__c!=null ? (effectiveDateTime.format('dd-MM-yyyy')) : '';*/
                requestWrap.source = ABSLI_Constants.GEN_FUND_SOURCE;
                if(policy.Type__c!='ULIP'){
                    requestWrap.PolicyType = 'NonUlip';
                }else{
                    requestWrap.PolicyType = '';
                }
                ABCL_IntegrationCallout.IntegrationResponseWrapper genFundResponse = ABCL_IntegrationCallout.executeCallout(ABSLI_Constants.POLICY_GEN_FUND_INTEGRATION_METADATA,
                                                                                                                    JSON.serialize(requestWrap),
                                                                                                                    null);
                if(String.isNotBlank(genFundResponse.responseBody) && genFundResponse.statusCode == 200){
               		GenFundResponseWrapper responseWrapper = (GenFundResponseWrapper)JSON.deserialize(genFundResponse.responseBody,GenFundResponseWrapper.class);
                    if(responseWrapper.BFID_RESPONSE.ProcessCode=='00'){
                        ABSLI_Case_Detail__c caseExt = new ABSLI_Case_Detail__c(Id=String.valueOf(jsonMap.get('ABSLI_Case_Detail__c')));
                        if(String.valueOf(jsonMap.get('CCC_External_Id__c'))=='PCPT021'){
                         	if(Decimal.valueOf(responseWrapper.BFID_RESPONSE.MAX_LOAD_AMOUNT_AVAILABLE)>5000 && !String.isBlank(responseWrapper.BFID_RESPONSE.MAX_LOAD_AMOUNT_AVAILABLE)){
                                caseExt.Max_Loan_Amount__c = Decimal.valueOf(responseWrapper.BFID_RESPONSE.MAX_LOAD_AMOUNT_AVAILABLE);
                            }else{
                                return 'Maximum loan amount should be equal to or greater than 5000.';
                            }  
                        }else if(String.valueOf(jsonMap.get('CCC_External_Id__c'))=='PCPT033'){
                         	if(Decimal.valueOf(responseWrapper.BFID_RESPONSE.MAX_LOAD_AMOUNT_AVAILABLE)>0 && !String.isBlank(responseWrapper.BFID_RESPONSE.MAX_LOAD_AMOUNT_AVAILABLE)){
                                caseExt.Max_Loan_Amount__c = Decimal.valueOf(responseWrapper.BFID_RESPONSE.MAX_LOAD_AMOUNT_AVAILABLE);
                            }else{
                                return 'Maximum loan amount should be more than 0.';
                            }
                            if(Decimal.valueOf(responseWrapper.BFID_RESPONSE.MINIMUM_LOAN_AMT)>0 && !String.isBlank(responseWrapper.BFID_RESPONSE.MINIMUM_LOAN_AMT)){
                                caseExt.Min_Loan_Amount__c = Decimal.valueOf(responseWrapper.BFID_RESPONSE.MINIMUM_LOAN_AMT);    
                            }else{
                                caseExt.Min_Loan_Amount__c = Decimal.valueOf(Label.ABSLI_Min_Loan_Amount);
                            }   
                        }else if(String.valueOf(jsonMap.get('CCC_External_Id__c'))=='PPAY008' || String.valueOf(jsonMap.get('CCC_External_Id__c'))=='PFTT011'){
                           	if(Decimal.valueOf(responseWrapper.BFID_RESPONSE.MINIMUM_WITHDRAWAL_AMT)>0 && !String.isBlank(responseWrapper.BFID_RESPONSE.MINIMUM_WITHDRAWAL_AMT)){
                                caseExt.Minimum_Withdrawal_Amount__c = Decimal.valueOf(responseWrapper.BFID_RESPONSE.MINIMUM_WITHDRAWAL_AMT);
                            }
                            if(Decimal.valueOf(responseWrapper.BFID_RESPONSE.WITHDRAWL_AMOUNT_AVAILABLE)>0 && !String.isBlank(responseWrapper.BFID_RESPONSE.WITHDRAWL_AMOUNT_AVAILABLE)){
                                caseExt.Withdrawal_Amount_Available__c = Decimal.valueOf(responseWrapper.BFID_RESPONSE.WITHDRAWL_AMOUNT_AVAILABLE);    
                            }else{
                                return 'Withdrawal amount available should be more than 0.';
                            } 
                        }else if(String.valueOf(jsonMap.get('CCC_External_Id__c'))=='PPAY001' || String.valueOf(jsonMap.get('CCC_External_Id__c'))=='PFTT010'){
                            if(Decimal.valueOf(responseWrapper.BFID_RESPONSE.CASH_SURRENDER_VALUE)>0 && !String.isBlank(responseWrapper.BFID_RESPONSE.CASH_SURRENDER_VALUE)){
                                caseExt.Cash_Surrender_Value__c = Decimal.valueOf(responseWrapper.BFID_RESPONSE.CASH_SURRENDER_VALUE);
                            }else{
                                return 'Cash Surrender Value should be more than 0.';
                            }
                        }
                        else if(String.valueOf(jsonMap.get('CCC_External_Id__c'))=='NNOP004'){
                            if(Decimal.valueOf(responseWrapper.BFID_RESPONSE.MAX_LOAD_AMOUNT_AVAILABLE)<=5000 || String.isBlank(responseWrapper.BFID_RESPONSE.MAX_LOAD_AMOUNT_AVAILABLE)){
                                return 'Maximum loan amount should be more than 5000.';
                            }
                        }
                        update caseExt;
                    	return 'Success';    
                    }else{
            			return 'Policy is not eligible.';         	   
                    }
                }else if(String.isNotBlank(genFundResponse.responseBody)){
                    system.debug('genFundResponse.responseBody:'+genFundResponse.responseBody);
                    system.debug('genFundResponse:'+genFundResponse);
                    GenFundFailureResponseBodyWrapper failureResponseWrapper = (GenFundFailureResponseBodyWrapper)JSON.deserialize(genFundResponse.responseBody,GenFundFailureResponseBodyWrapper.class);
                    if(failureResponseWrapper!=null && (failureResponseWrapper.Fault)!=null && !String.isBlank(failureResponseWrapper.Fault.FaultMessage)){
                        return 'API Error: '+failureResponseWrapper.Fault.FaultMessage;
                    }
                }
            }
        	return 'An error occurred while processing your request. Please try again later.';
        }catch (Exception e) {
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABSLI_PolicyGenFundIntegration callout');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class GenFundFailureResponseBodyWrapper{
        public FaultBody Fault{get;set;}
    }

    public class FaultBody{
        public String FaultCode{get;set;}
        public String FaultMessage{get;set;}
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
                    return 'Policy is not eligible.';
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
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped((caseRecord));
            system.debug('Aditya ccc'+String.valueOf(jsonMap.get('CCC_External_Id__c')));
            if(policy!=null && policy.Issue_Date__c!=null){
                Date issueDate = Date.newInstance(policy.Issue_Date__c.year(), policy.Issue_Date__c.month(), policy.Issue_Date__c.day());
                if(String.valueOf(jsonMap.get('CCC_External_Id__c'))=='DUP002'){
                 	Date oneYearAfterIssueDate = issueDate.addYears(1);
                    if(Date.Today() <= oneYearAfterIssueDate){
                        return 'Success';
                    }else{
                        return 'Policy is not eligible.';
                    }   
                }else if(String.valueOf(jsonMap.get('CCC_External_Id__c'))=='PNFT019'){
                    Date today = Date.today();
                    Date oneYearBeforeToday = today.addYears(-1);
                    if(issueDate <= oneYearBeforeToday){
                        return 'Success';
                    }else{
                        return 'Policy is not eligible.';
                    }
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
                /*if(policy.Effective_Date__c!=null){
                    DateTime effectiveDateTime = DateTime.newInstance(policy.Effective_Date__c.year(), policy.Effective_Date__c.month(),policy.Effective_Date__c.day());
                    request.EFFECTIVE_DATE = (effectiveDateTime.format('ddMMyyyy'));
                }*/
                Date today = Date.today();
                DateTime todayDateTime = DateTime.newInstance(today.year(),today.month(),today.day());
                request.EFFECTIVE_DATE = (todayDateTime.format('ddMMyyyy'));
                request.SOURCE = ABSLI_Constants.UIN_API_SOURCE;

                ABCL_IntegrationCallout.IntegrationResponseWrapper uinApiResponse = ABCL_IntegrationCallout.executeCallout(ABSLI_Constants.UIN_API_INTEGRATION_METADATA,
                                                                                                                        JSON.serialize(request),
                                                                                                                        null);
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
    
    @AuraEnabled
    public static String assignmentIssueTypeValidation(String caseRecord){
        try {
            Asset policy = ABSLI_CreateCaseValidationsController.getPolicyDetails(caseRecord);
            if(policy!=null){
                if(policy.Policy_Identification__c!=ABSLI_Constants.ASSIGNMENT_ISSUE_TYPE_VALIDATION){
                    return 'Success';
                }else{
                    return 'Policy is not eligible';
                }
            }
            return 'User is not eligible';
            
        } catch (Exception e) {
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABSLI_Assignment/Assignment Employer Employee Case creation validation');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String changeInInvestorProfileValidation(String caseRecord){
        try {
            Asset policy = ABSLI_CreateCaseValidationsController.getPolicyDetails(caseRecord);
            if(policy!=null){
                if(policy.Type__c=='ULIP'){
                    return 'Success';
                }else{
                    return 'Policy is not eligible.';
                }
            }
            return 'User is not eligible';
            
        } catch (Exception e) {
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABSLI_Change_In_Investor_Profile Case creation validation');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String interestWaiverForHOValidation(String caseRecord){
        try {
            Asset policy = ABSLI_CreateCaseValidationsController.getPolicyDetails(caseRecord);
            if(policy!=null){
                if(policy.Type__c!='ULIP'){
                    return 'Success';
                }else{
                    return 'Policy is not eligible.';
                }
            }
            return 'User is not eligible';
            
        } catch (Exception e) {
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABSLI_Interest_Waiver_for_HO_Users Case creation validation');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String reinstatementValidation(String caseRecord){
        try {
            Asset policy = ABSLI_CreateCaseValidationsController.getPolicyDetails(caseRecord);
            if(policy!=null){
                if(policy.Type__c=='ULIP' && Decimal.valueOf(policy.Payment_Term__c)>5){
                    return 'Success';
                }else{
                    return 'Policy is not eligible.';
                }
            }
            return 'User is not eligible';
            
        } catch (Exception e) {
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABSLI_Reinstatement Case creation validation');
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

    public class RedirectToPortalResponse{
        @AuraEnabled
        public String status{get;set;}
        @AuraEnabled
        public String message{get;set;}
        
        public RedirectToPortalResponse(String st, String ms){
            this.status = st;
            this.message = ms;
        }
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
        public String source{get;set;}
        public String PolicyType{get;set;}
    }
    
    public class GenFundResponseWrapper{
        public BfidResponse BFID_RESPONSE{get;set;}
        public GenFundResponseWrapper() {
            this.BFID_RESPONSE = new BfidResponse();
        }
    }
    
    public class BfidResponse{
        public String MINIMUM_WITHDRAWAL_AMT{get;set;}
        public String ProcessCode{get;set;}
        public String MINIMUM_LOAN_AMT{get;set;}
        public String WITHDRAWL_AMOUNT_AVAILABLE{get;set;}
        public String CASH_SURRENDER_VALUE{get;set;}
        public String MAX_LOAD_AMOUNT_AVAILABLE{get;set;}
    }

}
