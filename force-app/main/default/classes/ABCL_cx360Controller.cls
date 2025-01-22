/*********************************************************
*Class        :  ABCL_cx360Controller
*Author       :  Nikhil Patewar(EY)
*Description  :  Backend Controller for Customer 360 data and actions
*********************************************************/
public with sharing class ABCL_cx360Controller {
    
    @AuraEnabled(cacheable=true)
    public static Account getCustomerInfo(String customerId){
        try {
            //return [Select Id,Name,AccountNumber, PersonEmail, Phone, PAN__c, PAN_Number__c, PreferredLanguage__pc, ShippingState, BillingState, Handle_With_Care_HWC__c, Customer_Since__c, WhatsApp_Opt_in_status__c, ABC_Consent__c from Account Where Id=:customerId];
            return [Select Id,Name,AccountNumber, PersonEmail, Phone, PAN__c, ShippingState, BillingState from Account Where Id=:customerId];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Asset> getProductsOwned(String customerId){
        try {
            return [Select Id,Loan_Disbursement_Status__c, Disbursed_Amount__c, Status, Name, LAN__c,LOB__c,Loan_Type__c,DA_Transaction__c,Sanction_Amount__c,VAN__c from Asset Where AccountId=:customerId];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ABCL_CX360_Quick_Actions__mdt> getQuickActions(String customerId){
        try {
            Account acc=[Select Id,Business_Unit__c from Account Where Id=:customerId];
            return [Select Id,Business_Unit__c,Icon_Name__c,MasterLabel,Sequence__c FROM ABCL_CX360_Quick_Actions__mdt WHERE Business_Unit__c =:acc.Business_Unit__c Order By Sequence__c ASC];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Boolean createCases(String customerId,String lanId,Boolean createSOACase,Boolean createRSCase,Boolean createICCase,Boolean createPICCase, Boolean createNDCCase, Boolean createWKCase, Boolean createLODCase){
        try{
            List<caseStatusWrapper> statusWrapper = New List<caseStatusWrapper>();
            Boolean casesCreated=false;
            Account acc=[Select Id,Business_Unit__c from Account Where Id=:customerId];
            Asset asset=[Select Id,Loan_Disbursement_Status__c, Disbursed_Amount__c, Status, Name, LAN__c,LOB__c,Loan_Type__c,DA_Transaction__c,Sanction_Amount__c,VAN__c from Asset Where AccountId=:customerId AND Id=:lanId];
            if(createSOACase==true){
                caseStatusWrapper soaCase= new caseStatusWrapper();
                soaCase.documentName='SOA';
                soaCase.status=ABHFL_Constants.SUCCESS;
                system.debug('Inside SOA case creation');
                ASF_Case_Category_Config__c caseCatConfig = [Select Id, Type__c,Sub_Type__c,CCC_External_Id__c,Business_Unit__c,Nature__c from ASF_Case_Category_Config__c Where CCC_External_Id__c=:ABHFL_Constants.SOA_CCC_EXTERNALID];
                //Insert case
                Case caseCreated= insertCase(ABHFL_Constants.SOA_CCC_EXTERNALID,caseCatConfig,customerId,lanId);
                
                //Insert ABHFL_Case_Details__c
                createCaseDetail(caseCreated,asset,ABHFL_Constants.SOA_CCC_EXTERNALID);
                
                //call SOAIntegration
                //Get Integration details
                ASF_Integration__c integ=getAllIntegrationDetails(ABHFL_Constants.SOA_CCC_EXTERNALID,'Open','ABHFL_SOAIntegration');
                system.debug('ASF Integ record>>'+integ);
                //Call Evaluate and run method of the processing class
                ASF_IntegrationsController.IntegrationWrapper resultWrapper=ASF_IntegrationsController.runIntegration(integ,caseCreated);
                system.debug('result wrapper>>'+resultWrapper);
                if(resultWrapper.status == ABHFL_Constants.SUCCESS){
                    casesCreated=true;
                }
            }
            if(createRSCase==true){
                system.debug('Inside RS case creation');
                ASF_Case_Category_Config__c caseCatConfig = [Select Id, Type__c,Sub_Type__c,CCC_External_Id__c,Business_Unit__c,Nature__c from ASF_Case_Category_Config__c Where CCC_External_Id__c=:ABHFL_Constants.Amort_CCC_EXTERNALID];
                //Insert case
                Case caseCreated= insertCase(ABHFL_Constants.Amort_CCC_EXTERNALID,caseCatConfig,customerId,lanId);
                
                //Insert ABHFL_Case_Details__c
                createCaseDetail(caseCreated,asset,ABHFL_Constants.Amort_CCC_EXTERNALID);
                
                //call RCIntegration
                //Get Integration details
                ASF_Integration__c integ=getAllIntegrationDetails(ABHFL_Constants.Amort_CCC_EXTERNALID,'Open','ABHFL_AmortizationIntegration');
                system.debug('ASF Integ record>>'+integ);
                //Call Evaluate and run method of the processing class
                ASF_IntegrationsController.IntegrationWrapper resultWrapper=ASF_IntegrationsController.runIntegration(integ,caseCreated);
                system.debug('result wrapper>>'+resultWrapper);
                if(resultWrapper.status == ABHFL_Constants.SUCCESS){
                    casesCreated=true;
                }
            }
            if(createICCase==true){
                system.debug('Inside IC case creation');
                ASF_Case_Category_Config__c caseCatConfig = [Select Id, Type__c,Sub_Type__c,CCC_External_Id__c,Business_Unit__c,Nature__c from ASF_Case_Category_Config__c Where CCC_External_Id__c=:ABHFL_Constants.IC_CCC_EXTERNALID];
                
                //Insert case
                Case caseCreated= insertCase(ABHFL_Constants.IC_CCC_EXTERNALID,caseCatConfig,customerId,lanId);
                
                //Insert ABHFL_Case_Details__c
                createCaseDetail(caseCreated,asset,ABHFL_Constants.IC_CCC_EXTERNALID);
                
                //call IcIntegration
                //Get Integration details
                ASF_Integration__c integ=getAllIntegrationDetails(ABHFL_Constants.IC_CCC_EXTERNALID,'Open','ABHFL_ICAndPIC_Integration');
                system.debug('ASF Integ record>>'+integ);
                
                //Call Evaluate and run method of the processing class
                ASF_IntegrationsController.IntegrationWrapper resultWrapper=ASF_IntegrationsController.runIntegration(integ,caseCreated);
                system.debug('result wrapper>>'+resultWrapper);
                if(resultWrapper.status == ABHFL_Constants.SUCCESS){
                    casesCreated=true;
                }
            }
            if(createPICCase==true){
                ASF_Case_Category_Config__c caseCatConfig = [Select Id, Type__c,Sub_Type__c,CCC_External_Id__c,Business_Unit__c,Nature__c from ASF_Case_Category_Config__c Where CCC_External_Id__c=:ABHFL_Constants.PIC_CCC_EXTERNALID];
                
                //Insert case
                Case caseCreated= insertCase(ABHFL_Constants.PIC_CCC_EXTERNALID,caseCatConfig,customerId,lanId);
                
                //Insert ABHFL_Case_Details__c
                createCaseDetail(caseCreated,asset,ABHFL_Constants.PIC_CCC_EXTERNALID);
                //call PICIntegration
            }
            if(createNDCCase==true){
                system.debug('Inside NDC case creation');
                ASF_Case_Category_Config__c caseCatConfig = [Select Id, Type__c,Sub_Type__c,CCC_External_Id__c,Business_Unit__c,Nature__c from ASF_Case_Category_Config__c Where CCC_External_Id__c=:ABHFL_Constants.NDC_CCC_EXTERNALID];
                
                //Insert case
                Case caseCreated= insertCase(ABHFL_Constants.NDC_CCC_EXTERNALID,caseCatConfig,customerId,lanId);
                
                //Insert ABHFL_Case_Details__c
                createCaseDetail(caseCreated,asset,ABHFL_Constants.NDC_CCC_EXTERNALID);
                
                //call NDCIntegration
                //Get Integration details
                ASF_Integration__c integ=getAllIntegrationDetails(ABHFL_Constants.NDC_CCC_EXTERNALID,'Open','ABHFL_NDCSTPHandler');
                system.debug('ASF Integ record>>'+integ);
                
                //Call Evaluate and run method of the processing class
                ASF_IntegrationsController.IntegrationWrapper resultWrapper=ASF_IntegrationsController.runIntegration(integ,caseCreated);
                system.debug('result wrapper>>'+resultWrapper);
                if(resultWrapper.status == ABHFL_Constants.SUCCESS){
                    casesCreated=true;
                }
                
            }
            if(createWKCase==true){
                system.debug('Inside WK case creation');
                ASF_Case_Category_Config__c caseCatConfig = [Select Id, Type__c,Sub_Type__c,CCC_External_Id__c,Business_Unit__c,Nature__c from ASF_Case_Category_Config__c Where CCC_External_Id__c=:ABHFL_Constants.WK_CCC_EXTERNALID];
                
                //Insert case
                Case caseCreated= insertCase(ABHFL_Constants.WK_CCC_EXTERNALID,caseCatConfig,customerId,lanId);
                
                //Insert ABHFL_Case_Details__c
                createCaseDetail(caseCreated,asset,ABHFL_Constants.WK_CCC_EXTERNALID);
                
                //call WKIntegration
                //Get Integration details
                ASF_Integration__c integ=getAllIntegrationDetails(ABHFL_Constants.WK_CCC_EXTERNALID,'Open','ABHFL_WelcomeKitIntegration');
                system.debug('ASF Integ record>>'+integ);
                
                //Call Evaluate and run method of the processing class
                ASF_IntegrationsController.IntegrationWrapper resultWrapper=ASF_IntegrationsController.runIntegration(integ,caseCreated);
                system.debug('result wrapper>>'+resultWrapper);
                if(resultWrapper.status == ABHFL_Constants.SUCCESS){
                    casesCreated=true;
                }
                
            }
            if(createLODCase==true){
                system.debug('Inside SOA case creation');
                ASF_Case_Category_Config__c caseCatConfig = [Select Id, Type__c,Sub_Type__c,CCC_External_Id__c,Business_Unit__c,Nature__c from ASF_Case_Category_Config__c Where CCC_External_Id__c=:ABHFL_Constants.LOD_CCC_EXTERNALID];
                //Insert case
                Case caseCreated= insertCase(ABHFL_Constants.LOD_CCC_EXTERNALID,caseCatConfig,customerId,lanId);
                
            }
            return casesCreated;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
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
    
    @AuraEnabled(cacheable=true)
    public static List<String> getFieldSetFields(String objectName, String fieldSetName) {
        List<String> fieldSetFields = new List<String>();
        
        try {
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
            if (objectType != null) {
                Schema.FieldSet fieldSet = objectType.getDescribe().fieldSets.getMap().get(fieldSetName);
                if (fieldSet != null) {
                    for (Schema.FieldSetMember field : fieldSet.getFields()) {
                        fieldSetFields.add(field.getFieldPath());
                    }
                } else {
                    throw new AuraHandledException('Field set not found: ' + fieldSetName);
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching field set fields: ' + e.getMessage());
        }
        
        return fieldSetFields;
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getAccountFields(Id recordId, List<String> fieldApiNames) {
        Map<String, Object> fieldValues = new Map<String, Object>();
        try {
            String fields = String.join(fieldApiNames, ', ');
            String query = 'SELECT ' + fields + ' FROM Account WHERE Id = :recordId';
            Account account = Database.query(query);
            
            for (String field : fieldApiNames) {
                fieldValues.put(field, account.get(field));
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Account fields: ' + e.getMessage());
        }
        return fieldValues;
    }
    
    @AuraEnabled
    public static Case insertCase(String cccExternalId,ASF_Case_Category_Config__c caseCatConfig,String customerId,String lanId){
        try{
            Case caseRecord = new Case();
            caseRecord.Subject=caseCatConfig.Sub_Type__c +' - Required';
            caseRecord.Description=caseCatConfig.Sub_Type__c +' - Required';
            caseRecord.CCC_External_Id__c=ABHFL_Constants.SOA_CCC_EXTERNALID;
            caseRecord.Nature__c=caseCatConfig.Nature__c;
            caseRecord.AccountId=customerId;
            caseRecord.AssetId = lanId;
            caseRecord.Source__c= 'Inbound call';
            caseRecord.Business_Unit__c=ABHFL_Constants.BUSINESS_UNIT_ABHFL;
            //caseRecord.RecordTypeId=
            if(Schema.sObjectType.Case.isCreateable()){
                Insert caseRecord;   
            }
            system.debug('careated case>>'+caseRecord.Id);
            return [Select Id,CaseNumber from Case where Id=:caseRecord.Id];
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        
    }
    
    @AuraEnabled
    public static void createCaseDetail(Case c,Asset asset,String cccExternalId){
        try{
            ABHFL_Case_Detail__c caseDetails = new ABHFL_Case_Detail__c();
            caseDetails.From_Date__c=asset.Loan_Start_Date__c;
            caseDetails.To_Date__c=System.Today();
            caseDetails.STP_Request_Type__c = ABHFL_Constants.EMAIL;
            caseDetails.Case__r.Id=c.Id;
            if(cccExternalId==ABHFL_Constants.IC_CCC_EXTERNALID){
                caseDetails.Financial_Year__c=getCurrentFinancialYear(ABHFL_Constants.IC_CCC_EXTERNALID);
            }else if(cccExternalId==ABHFL_Constants.PIC_CCC_EXTERNALID){
                caseDetails.Financial_Year__c=getCurrentFinancialYear(ABHFL_Constants.PIC_CCC_EXTERNALID);
            }
            if(Schema.sObjectType.ABHFL_Case_Detail__c.isCreateable()){
                Insert caseDetails;
            }
            system.debug('careated ABHFL casedeatils>>'+[select Id,From_Date__c,To_Date__c from ABHFL_Case_Detail__c where id=:caseDetails.Id]);
            
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
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
        public String documentName;
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
