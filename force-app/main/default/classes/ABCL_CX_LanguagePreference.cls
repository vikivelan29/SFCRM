public class ABCL_CX_LanguagePreference {
    
    @AuraEnabled(cacheable=true)
    public static List<Asset> fetchAssetsForAccount(String customerId){
        try {
            return [Select Id,Loan_Disbursement_Status__c, Disbursed_Amount__c, Status, Name, LAN__c,LOB__c,Loan_Type__c,DA_Transaction__c,Sanction_Amount__c,VAN__c from Asset Where AccountId=:customerId Order By CreatedDate];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
     @AuraEnabled(cacheable=true)
    public static Account getCustomerInfo(String customerId){
        try {
            //return [Select Id,Name,AccountNumber, PersonEmail, Phone, PAN__c, PAN_Number__c, PreferredLanguage__pc, ShippingState, BillingState, Handle_With_Care_HWC__c, Customer_Since__c, WhatsApp_Opt_in_status__c, ABC_Consent__c from Account Where Id=:customerId];
            return [Select Id,Name,AccountNumber, PersonEmail, Phone, PAN__c, ShippingState, BillingState from Account Where Id=:customerId];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<caseStatusWrapper> createCases(String customerId){
        List<caseStatusWrapper> statusWrapper = New List<caseStatusWrapper>();
        try{
            system.debug('Inside Case creation'+customerId);
            Asset asset=[Select Id,Loan_Start_Date__c,Loan_Disbursement_Status__c, Disbursed_Amount__c, Status, Name, LAN__c,LOB__c,Loan_Type__c,DA_Transaction__c,Sanction_Amount__c,VAN__c from Asset Where AccountId=:customerId LIMIT 1];
      
                /*caseStatusWrapper response= new caseStatusWrapper();
                response.status=ABHFL_Constants.ERROR;*/
                
                //Insert ABHFL_Case_Details__c
                caseStatusWrapper response= new caseStatusWrapper();
                caseStatusWrapper caseDetailsCreatedWrapper=createCaseDetail(asset,ABHFL_Constants.LANG_CC_EXTERNALID);
                response.newCaseDetail=caseDetailsCreatedWrapper.newCaseDetail;
                response.status=caseDetailsCreatedWrapper.status;
                response.message=caseDetailsCreatedWrapper.message;
                
                //Insert case
                caseStatusWrapper caseCreatedWrapper;
                if(response.status==ABHFL_Constants.SUCCESS){
                    caseCreatedWrapper= insertCase(response.newCaseDetail.Id,ABHFL_Constants.LANG_CC_EXTERNALID,customerId,asset.id);
                    response.newCase=caseCreatedWrapper.newCase;
                    response.status=caseCreatedWrapper.status;
                    response.message=caseCreatedWrapper.message;
                    system.debug('SOA response>>'+response);
                    statusWrapper.add(response);
                }
                
                //Get Integration details
               /* if(response.status==ABHFL_Constants.SUCCESS && response.newCase!=null){
                    ASF_Integration__c integ=getAllIntegrationDetails(ABHFL_Constants.SOA_CCC_EXTERNALID,'Open','ABHFL_SOAIntegration');
                    ASF_IntegrationsController.IntegrationWrapper resultWrapper=ASF_IntegrationsController.runIntegration(integ,caseCreatedWrapper.newCase);
                    system.debug('result wrapper>>'+resultWrapper);
                }*/
        }
        catch(Exception e){
            caseStatusWrapper response= New caseStatusWrapper();
            response.status=ABHFL_Constants.ERROR;
            response.message='Case/s could not be created, due to error -'+e.getMessage();
            statusWrapper.add(response);
        }    
   
        system.debug('Final response for LWC>>>'+statusWrapper);
        return statusWrapper;
    }
    
    
    @AuraEnabled
    public static ASF_Integration__c getAllIntegrationDetails(string c3ExtId, string stageName, String ProcessingClass){
        ASF_Integration__c returnList;
        if(c3ExtId != null && stageName != null){
            returnList = [
                SELECT Id, Processing_Class__c, STP_Processing_Class__c,UI_Component__c,
                External_Id__c, Type__c, Display_Name__c,STP_API_Identifier__c, Query_Fields__c
                FROM ASF_Integration__c
                WHERE C3ExternalId__c =: c3ExtId
                AND Case_Stage_Config__r.StageName__c =: stageName
                AND STP_Processing_Class__c=:ProcessingClass LIMIT 1
            ];
        }
        return returnList;
    }
    
          @AuraEnabled
    public static caseStatusWrapper insertCase(String caseDetailId,String cccExternalId,String customerId,String assetId){
        caseStatusWrapper responseWrapper= New caseStatusWrapper();
        try{
            system.debug('Inside case creation method');
            ASF_Case_Category_Config__c caseCatConfig = [Select Id, Type__c,Sub_Type__c,CCC_External_Id__c,Business_Unit__c,Nature__c from ASF_Case_Category_Config__c Where CCC_External_Id__c=:cccExternalId];
            Case caseRecord = new Case();
            caseRecord.Subject=caseCatConfig.Sub_Type__c +' - Required';
            caseRecord.Description=caseCatConfig.Sub_Type__c +' - Required';
            caseRecord.CCC_External_Id__c=cccExternalId;
            caseRecord.Nature__c=caseCatConfig.Nature__c;
            caseRecord.Type_Text__c=caseCatConfig.Type__c;
            caseRecord.Sub_Type_Text__c=caseCatConfig.Sub_Type__c;
            caseRecord.AccountId=customerId;
            caseRecord.AssetId = assetId;
            //caseRecord.Source__c= 'Inbound call';
            caseRecord.Business_Unit__c=ABHFL_Constants.BUSINESS_UNIT_ABHFL;
            caseRecord.Stage__c='In-progress';
            caseRecord.Case_Stage_Change_Date__c = system.now();
            caseRecord.RecordTypeId=ASF_Constants.RT_FRAMEWORK;
            caseRecord.ABHFL_Case_Detail__c=caseDetailId;
            if(Schema.sObjectType.Case.isCreateable()){
                Insert caseRecord;   
            }
            Case newCase=[Select Id,CaseNumber from Case where Id=:caseRecord.Id Limit 1];
            system.debug('careated case>>'+caseRecord.Id);
            responseWrapper.newCase = newCase;
            responseWrapper.status=ABHFL_Constants.SUCCESS;
            
        }catch(DmlException e){
            system.debug('Issue is:'+e.getMessage());
            responseWrapper.status=ABHFL_Constants.ERROR;
            responseWrapper.message=e.getMessage();
            
        }
        return responseWrapper;
    }
    
    
   @AuraEnabled
    public static caseStatusWrapper createCaseDetail(Asset asset,String cccExternalId){
        caseStatusWrapper response= New caseStatusWrapper();
        system.debug('Inside ABHFL case creation');
        try{
            ABHFL_Case_Detail__c caseDetails = new ABHFL_Case_Detail__c();
            caseDetails.From_Date__c=asset.Loan_Start_Date__c;
            caseDetails.To_Date__c=System.Today();
            caseDetails.Financial_Year__c=getCurrentFinancialYear(cccExternalId);
            if(cccExternalId==ABHFL_Constants.LANG_CC_EXTERNALID){
                caseDetails.Financial_Year__c=getCurrentFinancialYear(cccExternalId);
              }

            //caseDetails.STP_Request_Type__c = ABHFL_Constants.EMAIL;
            if(Schema.sObjectType.ABHFL_Case_Detail__c.isCreateable()){
                Insert caseDetails;
            }
            system.debug('careated ABHFL casedeatils>>'+[select Id,From_Date__c,To_Date__c,Financial_Year__c from ABHFL_Case_Detail__c where id=:caseDetails.Id]);
            response.newCaseDetail = [select Id,From_Date__c,To_Date__c,Financial_Year__c from ABHFL_Case_Detail__c where id=:caseDetails.Id];
            response.status=ABHFL_Constants.SUCCESS;
        }catch(DmlException e){
            system.debug('Issue is:'+e.getMessage());
            response.status=ABHFL_Constants.ERROR;
            response.message=e.getMessage();
        }
        return response;
    }
        
     public static String getCurrentFinancialYear(String cccExternalId) {
        String financialYear;
        Date today = Date.today();
        Integer fiscalYearStartMonth = 3; // Default fiscal start month (March)
        Integer fiscalYear = (today.month() >= fiscalYearStartMonth) ? today.year() + 1 : today.year();
        if(cccExternalId==ABHFL_Constants.IC_CCC_EXTERNALID){
            financialYear =  String.valueOf((fiscalYear - 2)+'-'+String.valueOf(fiscalYear - 1).right(2));
        }else{
            financialYear =  String.valueOf((fiscalYear - 1)+'-'+String.valueOf(fiscalYear).right(2));
        }
        system.debug('FY>>'+financialYear);
        return financialYear;
    }    
        
   public class caseStatusWrapper{
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String message;
        @AuraEnabled
        public Case newCase;
        @AuraEnabled
        public ABHFL_Case_Detail__c newCaseDetail;
    }
    
    
}