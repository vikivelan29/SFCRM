public with sharing class ABSLI_FetchBankDetailsController {
    @AuraEnabled(cacheable=true)
    public static ABSLI_Case_Detail__c getCaseDetails(Id caseId) {
        try {
            Case queryCase = [SELECT Id,ABSLI_Case_Detail__c,ABSLI_Case_Detail__r.MICR_Code__c FROM Case WHERE Id = :caseId];
            System.debug(queryCase.ABSLI_Case_Detail__r.MICR_Code__c);
            return [
                SELECT Id, IFSC_Code__c, MICR_Code__c, Bank_Name__c, Branch_Name__c 
                FROM ABSLI_Case_Detail__c 
                WHERE Id = :queryCase.ABSLI_Case_Detail__c
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve case details: ' + e.getMessage());
        }
    }
    @AuraEnabled
    public static void updateBankDetailOnExtn(String caseExtId,String ifscCd,String micrCd,
                                              String bankName,String bankBranchNm, String caseId)
    {
        Case caseRec = new Case(Id=caseId);
        
        ABSLI_Case_Detail__c caseExtRecord = new ABSLI_Case_Detail__c(Id=caseExtId);
        caseExtRecord.IFSC_Code__c = ifscCd;
        caseExtRecord.MICR_Code__c = micrCd;
        caseExtRecord.Bank_Name__c = bankName;
        caseExtRecord.Branch_Name__c = bankBranchNm;
        
        List<SObject> recordsToUpdate = new List<SObject>();
            if(caseExtRecord != null){
                recordsToUpdate.add(caseExtRecord);
            }
            recordsToUpdate.add(caseRec);
            
        
        try{
            update recordsToUpdate;
        }
        catch(DMLException dmlEx){
            String errMsg = '';
            for (Integer i = 0; i < dmlEx.getNumDml(); i++) {
                // Process exception here
                errMsg =+ dmlEx.getDmlMessage(i);
            }
            
            throw new AuraException(errMsg);
        }
        
    }
    @AuraEnabled(Cacheable=false)
    public static bankDetailResponseWrapper fetchBankDetail(String caseId){
        bankDetailResponseWrapper respWrapper = new bankDetailResponseWrapper();
        if(caseId == null || caseId == ''){
            respWrapper.ReturnCode = '-1';
            respWrapper.ReturnMessage = 'Case Id is blank.';
            return respWrapper;
        }
        
        Case caseRecord = [SELECT ID,ABSLI_Case_Detail__c,ABSLI_Case_Detail__r.IFSC_Code__c,ABSLI_Case_Detail__r.MICR_Code__c 
                           FROM Case WHERE Id =: caseId];
        
        if((caseRecord.ABSLI_Case_Detail__r.IFSC_Code__c == null && caseRecord.ABSLI_Case_Detail__r.MICR_Code__c == null ) || 
           (caseRecord.ABSLI_Case_Detail__r.IFSC_Code__c == '' && caseRecord.ABSLI_Case_Detail__r.MICR_Code__c == ''))
        {
            respWrapper.ReturnCode = '-1';
            respWrapper.ReturnMessage = 'Either IFSC Code or MICR Code required to fetch Bank Branch Details.';
            return respWrapper;
        }
        bankDetailRequest bitlyRequestWrapper = new bankDetailRequest();
        detail detailCls = new detail();
        detailCls.IFSC_CODE = caseRecord.ABSLI_Case_Detail__r.IFSC_Code__c;
        bitlyRequestWrapper.ObjRequest = detailCls;
        
        string bankDetailRequestBody = JSON.serialize(detailCls);
        
        ABCL_IntegrationCallout.IntegrationResponseWrapper bankDetailResponse = ABCL_IntegrationCallout.executeCallout(ABSLI_Constants.FETCH_BANK_DETAIL_METADATA,bankDetailRequestBody,null);
        System.debug('response - '+bankDetailResponse.responseBody);
        if(bankDetailResponse.statusCode == 200 && String.isNotBlank(bankDetailResponse.responseBody)){
            respWrapper = (bankDetailResponseWrapper) JSON.deserialize(bankDetailResponse.responseBody, bankDetailResponseWrapper.class);
            respWrapper.absliCaseExtId = caseRecord.ABSLI_Case_Detail__c;
        }
        
        return respWrapper;
    }
    
    @AuraEnabled(Cacheable = false)
    public static bankDetailResponseWrapper fetchBankDetailFromField(String CaseId,String IFSC_Code){
        bankDetailResponseWrapper respWrapper = new bankDetailResponseWrapper();
        //bankDetailRequest bitlyRequestWrapper = new bankDetailRequest();
        detail detailCls = new detail();
        detailCls.IFSC_CODE = IFSC_Code;
        //bitlyRequestWrapper.ObjRequest = detailCls;
        string bankDetailRequestBody = JSON.serialize(detailCls);
        system.debug('hre'+bankDetailRequestBody);
        
        ABCL_IntegrationCallout.IntegrationResponseWrapper bankDetailResponse = ABCL_IntegrationCallout.executeCallout(ABSLI_Constants.FETCH_BANK_DETAIL_METADATA,bankDetailRequestBody,null);
        if(bankDetailResponse.statusCode == 200 && String.isNotBlank(bankDetailResponse.responseBody)){
            respWrapper = (bankDetailResponseWrapper) JSON.deserialize(bankDetailResponse.responseBody, bankDetailResponseWrapper.class);
            system.debug('here'+respWrapper);
        }
        
        return respWrapper;
    }
    public class bankDetailRequest{
        public detail ObjRequest{get;set;}
    }
    public class detail{
        public string IFSC_CODE{get;set;}
        public string MICR_CODE{get;set;}
    }
    public class bankDetailResponseWrapper{
        @AuraEnabled
        public string absliCaseExtId{get;set;}
        @AuraEnabled
        public string ReturnCode{get;set;}
        @AuraEnabled
        public string ReturnMessage{get;set;}
        @AuraEnabled
        public bankDetail lstDetails{get;set;}
    }
    public class bankDetail{
        @AuraEnabled
        public string IFSC_CODE{get;set;}
        @AuraEnabled
        public string MICR_CODE{get;set;}
        @AuraEnabled
        public string BANK_NAME{get;set;}
        @AuraEnabled
        public string BANK_BRANCH{get;set;}
    }
    
}