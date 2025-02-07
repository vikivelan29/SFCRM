/*********************************************************
*Class        :  ABCL_cx360Controller
*Author       :  Nikhil Patewar
*Description  :  Backend Controller for Customer 360 data and actions
*********************************************************/
public with sharing class ABCL_cx360Controller {
    
    @AuraEnabled(cacheable=true)
    public static Account getCustomerInfo(String customerId){
        try {
            //return [Select Id,Name,AccountNumber, PersonEmail, Phone, PAN__c, PAN_Number__c, PreferredLanguage__pc, ShippingState, BillingState, Handle_With_Care_HWC__c, Customer_Since__c, WhatsApp_Opt_in_status__c, ABC_Consent__c from Account Where Id=:customerId];
            return [Select Id,Name,AccountNumber, PersonEmail,Business_Unit__c, Phone, PAN__c, ShippingState, BillingState from Account Where Id=:customerId];
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
    public static List<caseStatusWrapper> createCases(String customerId,String lanId,List<String> docs){
        List<caseStatusWrapper> statusWrapper = New List<caseStatusWrapper>();
        try{
            Asset asset=[Select Id,Loan_Start_Date__c,Loan_Disbursement_Status__c, Disbursed_Amount__c, Status, Name, LAN__c,LOB__c,Loan_Type__c,DA_Transaction__c,Sanction_Amount__c,VAN__c from Asset Where Id=:lanId];
            if(docs.contains('SOA')){
                system.debug('Inside SOA case creation');
                caseStatusWrapper response= new caseStatusWrapper();
                response.documentName='SOA';
                response.status=ABHFL_Constants.ERROR;
                
                //Insert ABHFL_Case_Details__c
                caseStatusWrapper caseDetailsCreatedWrapper=createCaseDetail(asset,ABHFL_Constants.SOA_CCC_EXTERNALID);
                response.newCaseDetail=caseDetailsCreatedWrapper.newCaseDetail;
                response.status=caseDetailsCreatedWrapper.status;
                response.message=caseDetailsCreatedWrapper.message;
                
                //Insert case
                caseStatusWrapper caseCreatedWrapper;
                if(response.status==ABHFL_Constants.SUCCESS){
                    caseCreatedWrapper= insertCase(response.newCaseDetail.Id,ABHFL_Constants.SOA_CCC_EXTERNALID,customerId,lanId);
                    response.newCase=caseCreatedWrapper.newCase;
                    response.status=caseCreatedWrapper.status;
                    response.message=caseCreatedWrapper.message;
                    system.debug('SOA response>>'+response);
                    statusWrapper.add(response);
                }
                
                //Get Integration details
                if(response.status==ABHFL_Constants.SUCCESS && response.newCase!=null){
                    ASF_Integration__c integ=getAllIntegrationDetails(ABHFL_Constants.SOA_CCC_EXTERNALID,'Open','ABHFL_SOAIntegration');
                    ASF_IntegrationsController.IntegrationWrapper resultWrapper=ASF_IntegrationsController.runIntegration(integ,caseCreatedWrapper.newCase);
                    system.debug('result wrapper>>'+resultWrapper);
                }/** DELETE ABHFL record created if there is an issue while creating an case
else if( response.newCaseDetail !=null && (response.newCase=='')){
Delete response.newCaseDetail.Id;
}**/
            }
            if(docs.contains('RS')){
                system.debug('Inside RS case creation');
                caseStatusWrapper response= new caseStatusWrapper();
                response.documentName='Repayment Schedule';
                response.status=ABHFL_Constants.ERROR;
                
                //Insert ABHFL_Case_Details__c
                caseStatusWrapper caseDetailsCreatedWrapper=createCaseDetail(asset,ABHFL_Constants.Amort_CCC_EXTERNALID);
                response.newCaseDetail=caseDetailsCreatedWrapper.newCaseDetail;
                response.status=caseDetailsCreatedWrapper.status;
                response.message=caseDetailsCreatedWrapper.message;
                
                //Insert case
                caseStatusWrapper caseCreatedWrapper;
                if(response.status==ABHFL_Constants.SUCCESS){
                    caseCreatedWrapper= insertCase(response.newCaseDetail.Id,ABHFL_Constants.Amort_CCC_EXTERNALID,customerId,lanId);
                    response.newCase=caseCreatedWrapper.newCase;
                    response.status=caseCreatedWrapper.status;
                    response.message=caseCreatedWrapper.message;
                    statusWrapper.add(response);
                }
                
                //call RCIntegration
                if(response.status==ABHFL_Constants.SUCCESS && response.newCase!=null){
                    ASF_Integration__c integ=getAllIntegrationDetails(ABHFL_Constants.Amort_CCC_EXTERNALID,'Open','ABHFL_AmortizationIntegration');
                    ASF_IntegrationsController.IntegrationWrapper resultWrapper=ASF_IntegrationsController.runIntegration(integ,caseCreatedWrapper.newCase);
                    system.debug('result wrapper>>'+resultWrapper);
                }
                
            }
            if(docs.contains('IntC')){
                system.debug('Inside IC case creation');
                caseStatusWrapper response= new caseStatusWrapper();
                response.documentName='IC';
                response.status=ABHFL_Constants.ERROR;
                
                //Insert ABHFL_Case_Details__c
                caseStatusWrapper caseDetailsCreatedWrapper=createCaseDetail(asset,ABHFL_Constants.IC_CCC_EXTERNALID);
                response.newCaseDetail=caseDetailsCreatedWrapper.newCaseDetail;
                response.status=caseDetailsCreatedWrapper.status;
                response.message=caseDetailsCreatedWrapper.message;
                
                //Insert case
                caseStatusWrapper caseCreatedWrapper;
                if(response.status==ABHFL_Constants.SUCCESS){
                    caseCreatedWrapper = insertCase(response.newCaseDetail.Id,ABHFL_Constants.IC_CCC_EXTERNALID,customerId,lanId);
                    response.newCase=caseCreatedWrapper.newCase;
                    response.status=caseCreatedWrapper.status;
                    response.message=caseCreatedWrapper.message;
                    system.debug('IC response >>'+response);
                    statusWrapper.add(response);
                }
                
                //Get Integration details
                if(response.status==ABHFL_Constants.SUCCESS && response.newCase!=null){
                    ASF_Integration__c integ=getAllIntegrationDetails(ABHFL_Constants.IC_CCC_EXTERNALID,'Open','ABHFL_ICAndPIC_Integration');
                    ASF_IntegrationsController.IntegrationWrapper resultWrapper=ASF_IntegrationsController.runIntegration(integ,caseCreatedWrapper.newCase);
                    system.debug('result wrapper>>'+resultWrapper);
                }
            }
            if(docs.contains('PIC')){
                caseStatusWrapper response= new caseStatusWrapper();
                response.documentName='IC';
                response.status=ABHFL_Constants.ERROR;
                
                //Insert ABHFL_Case_Details__c
                caseStatusWrapper caseDetailsCreatedWrapper=createCaseDetail(asset,ABHFL_Constants.PIC_CCC_EXTERNALID);
                response.newCaseDetail=caseDetailsCreatedWrapper.newCaseDetail;
                response.status=caseDetailsCreatedWrapper.status;
                response.message=caseDetailsCreatedWrapper.message;
                
                //Insert case
                caseStatusWrapper caseCreatedWrapper;
                if(response.status==ABHFL_Constants.SUCCESS){
                    caseCreatedWrapper= insertCase(response.newCaseDetail.Id,ABHFL_Constants.PIC_CCC_EXTERNALID,customerId,lanId);
                    response.newCase=caseCreatedWrapper.newCase;
                    response.status=caseCreatedWrapper.status;
                    response.message=caseCreatedWrapper.message;
                    system.debug('PIC response>>'+response);
                    statusWrapper.add(response);
                }
                
                //call PICIntegration
                if(response.status==ABHFL_Constants.SUCCESS && response.newCase!=null){
                    ASF_Integration__c integ=getAllIntegrationDetails(ABHFL_Constants.PIC_CCC_EXTERNALID,'Open','ABHFL_ICAndPIC_Integration');
                    ASF_IntegrationsController.IntegrationWrapper resultWrapper=ASF_IntegrationsController.runIntegration(integ,caseCreatedWrapper.newCase);
                    system.debug('result wrapper>>'+resultWrapper);
                }
            }
            if(docs.contains('NDC')){
                system.debug('Inside NDC case creation');
                caseStatusWrapper response= new caseStatusWrapper();
                response.documentName='NDC';
                response.status=ABHFL_Constants.ERROR;
                
                //Insert ABHFL_Case_Details__c
                caseStatusWrapper caseDetailsCreatedWrapper=createCaseDetail(asset,ABHFL_Constants.NDC_CCC_EXTERNALID);
                response.newCaseDetail=caseDetailsCreatedWrapper.newCaseDetail;
                response.status=caseDetailsCreatedWrapper.status;
                response.message=caseDetailsCreatedWrapper.message;
                
                //Insert case
                caseStatusWrapper caseCreatedWrapper;
                if(response.status==ABHFL_Constants.SUCCESS){
                    caseCreatedWrapper= insertCase(response.newCaseDetail.Id,ABHFL_Constants.NDC_CCC_EXTERNALID,customerId,lanId);
                    response.newCase=caseCreatedWrapper.newCase;
                    response.status=caseCreatedWrapper.status;
                    response.message=caseCreatedWrapper.message;
                    system.debug('NDC response>>'+response);
                    statusWrapper.add(response);
                }
                //call NDCIntegration
                if(response.status==ABHFL_Constants.SUCCESS && response.newCase!=null){
                    ASF_Integration__c integ=getAllIntegrationDetails(ABHFL_Constants.NDC_CCC_EXTERNALID,'Open','ABHFL_NDCSTPHandler');
                    ASF_IntegrationsController.IntegrationWrapper resultWrapper=ASF_IntegrationsController.runIntegration(integ,caseCreatedWrapper.newCase);
                    system.debug('result wrapper>>'+resultWrapper);
                }
            }
            if(docs.contains('WK')){
                system.debug('Inside WK case creation');
                caseStatusWrapper response= new caseStatusWrapper();
                response.documentName='Welcome Kit';
                response.status=ABHFL_Constants.ERROR;
                
                //Insert ABHFL_Case_Details__c
                caseStatusWrapper caseDetailsCreatedWrapper=createCaseDetail(asset,ABHFL_Constants.WK_CCC_EXTERNALID);
                response.newCaseDetail=caseDetailsCreatedWrapper.newCaseDetail;
                response.status=caseDetailsCreatedWrapper.status;
                response.message=caseDetailsCreatedWrapper.message;
                
                //Insert case
                caseStatusWrapper caseCreatedWrapper;
                if(response.status==ABHFL_Constants.SUCCESS){
                    caseCreatedWrapper=insertCase(response.newCaseDetail.Id,ABHFL_Constants.WK_CCC_EXTERNALID,customerId,lanId);
                    response.newCase=caseCreatedWrapper.newCase;
                    response.status=caseCreatedWrapper.status;
                    response.message=caseCreatedWrapper.message;
                    system.debug('WK response>>'+response);
                    statusWrapper.add(response);
                }
                //call WKIntegration
                if(response.status==ABHFL_Constants.SUCCESS && response.newCase!=null){
                    ASF_Integration__c integ=getAllIntegrationDetails(ABHFL_Constants.WK_CCC_EXTERNALID,'Open','ABHFL_WelcomeKitIntegration');
                    ASF_IntegrationsController.IntegrationWrapper resultWrapper=ASF_IntegrationsController.runIntegration(integ,caseCreatedWrapper.newCase);
                    system.debug('result wrapper>>'+resultWrapper);
                }
            }
            if(docs.contains('LOD')){
                system.debug('Inside LOD case creation');
                caseStatusWrapper response= new caseStatusWrapper();
                response.documentName='List of Documents';
                response.status=ABHFL_Constants.ERROR;
                
                //Insert ABHFL_Case_Details__c
                caseStatusWrapper caseDetailsCreatedWrapper=createCaseDetail(asset,ABHFL_Constants.LOD_CCC_EXTERNALID);
                response.newCaseDetail=caseDetailsCreatedWrapper.newCaseDetail;
                response.status=caseDetailsCreatedWrapper.status;
                response.message=caseDetailsCreatedWrapper.message;
                
                //Insert case
                caseStatusWrapper caseCreatedWrapper;
                if(response.status==ABHFL_Constants.SUCCESS){
                    caseCreatedWrapper= insertCase(response.newCaseDetail.Id,ABHFL_Constants.LOD_CCC_EXTERNALID,customerId,lanId);
                    response.newCase=caseCreatedWrapper.newCase;
                    response.status=caseCreatedWrapper.status;
                    response.message=caseCreatedWrapper.message;
                    system.debug('LOD Response>>'+response);
                    statusWrapper.add(response); 
                }
            }
            
        }catch(Exception e){
            caseStatusWrapper response= New caseStatusWrapper();
            response.status=ABHFL_Constants.ERROR;
            response.message='Case/s could not be created, due to error -'+e.getMessage();
            statusWrapper.add(response);
        }
        system.debug('Final response for LWC>>>'+statusWrapper);
        return statusWrapper;
    }
    
    @AuraEnabled
    public static List<caseStatusWrapper> createCasesForLang(String customerId, String newSelectedLang){
        List<caseStatusWrapper> statusWrapper = New List<caseStatusWrapper>();
        try{
            system.debug('Inside Case creation'+customerId);
            Asset asset=[Select Id,Loan_Start_Date__c,Loan_Disbursement_Status__c, Disbursed_Amount__c, Status, Name, LAN__c,LOB__c,Loan_Type__c,DA_Transaction__c,Sanction_Amount__c,VAN__c from Asset Where AccountId=:customerId LIMIT 1];
            
            //Insert ABHFL_Case_Details__c
            caseStatusWrapper response= new caseStatusWrapper();
            caseStatusWrapper caseDetailsCreatedWrapper=createCaseDetail(asset,ABHFL_Constants.LANG_CC_EXTERNALID);
            response.newCaseDetail=caseDetailsCreatedWrapper.newCaseDetail;
            response.status=caseDetailsCreatedWrapper.status;
            response.message=caseDetailsCreatedWrapper.message;
            
            //Insert case
            caseStatusWrapper caseCreatedWrapper;
            if(response.status==ABHFL_Constants.SUCCESS){
                caseCreatedWrapper= insertCaseforLang(response.newCaseDetail.Id,ABHFL_Constants.LANG_CC_EXTERNALID,customerId,asset.id,newSelectedLang);
                response.newCase=caseCreatedWrapper.newCase;
                response.status=caseCreatedWrapper.status;
                response.message=caseCreatedWrapper.message;
                system.debug('SOA response>>'+response);
                statusWrapper.add(response);
            }
            
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
    public static caseStatusWrapper insertCaseforLang(String caseDetailId,String cccExternalId,String customerId,String assetId, String newSelectedLang){
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
            caseRecord.Preferred_Language__c=newSelectedLang;
            //caseRecord.Source__c= 'Inbound call';
            caseRecord.Business_Unit__c=ABHFL_Constants.BUSINESS_UNIT_ABHFL;
            caseRecord.Stage__c='In Progress';
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
    public static List<Map<String, String>> getAccountInfoFields(Id recordId, String businessUnit,String tileName){
        // List to hold the result of label-value pairs
        List<Map<String, String>> labelValuePairs = new List<Map<String, String>>();
        List<String> fieldWithLabel = new List<String>();
        // Fetch the metadata record for the given Business Unit
        ABCL_Cx_360_Field_Mapping__mdt fieldMap = [SELECT id, Account_Info_Fields__c,customer_happiness_fields__c FROM ABCL_Cx_360_Field_Mapping__mdt WHERE Business_Unit__c = :businessUnit LIMIT 1];
        
        // Split the Account_Info_Fields__c field value to get individual fields and labels
        if(tileName == 'Customer Happiness'){
            fieldWithLabel = fieldMap.customer_happiness_fields__c.split(',');
        }
        else{
            fieldWithLabel = fieldMap.Account_Info_Fields__c.split(',');
        }
        
        
        // Generate the query to fetch values for the specified fields
        List<String> fldAPINames = new List<String>();
        for (String fld : fieldWithLabel) {
            fldAPINames.add(fld.split(':')[1]);
        }
        
        // Build the query string dynamically to include all field API names and additional City field
        String queryString = 'SELECT ' + String.join(fldAPINames, ',') + ', City__c FROM Account WHERE Id = :recordId';
        
        // Query the record
        sObject record = Database.query(queryString);
        
        // Loop through the fieldWithLabel list and extract label-value pairs
        for (String fld : fieldWithLabel) {
            // Split each field into API name and label
            String[] fieldParts = fld.split(':');
            String apiName = fieldParts[1];
            String label = fieldParts[0];
            
            // Get the value from the queried record using the API name
            Object fieldValue = record.get(apiName);
            if (label == 'DOB/DOC' && fieldValue != null){
                fieldValue = ((Date)fieldValue).format();
            }
            if(label == 'Customer Since' && fieldValue != null){
                fieldValue = ((Datetime)fieldValue).date().format();
            }
            if(label == 'State'){
                label = 'State,City';
                if(record.get('City__c') != null && String.valueOf(record.get('City__c')) != ''){
                    fieldValue +=  ', ' + record.get('City__c');
                }else{
                    fieldValue = fieldValue;
                }
                
            }
            else{   
                if(fieldValue != null && !(fieldValue instanceof Date)){
                    fieldValue = (String)fieldValue;
                }else if(fieldValue != null && fieldValue instanceof Date){
                    fieldValue = ((Date)fieldValue).format();
                }
            }
            // Create a map for each field's label-value pair and add it to the list
            Map<String, String> labelValueMap = new Map<String, String>();
            labelValueMap.put('label', label);
            labelValueMap.put('value', (String)fieldValue);
            // Add the map to the list
            labelValuePairs.add(labelValueMap);
        }
        
        // Return the list of label-value pairs
        return labelValuePairs;
    }
    
    @AuraEnabled(cacheable=true)
    public static Boolean getHNIorHWCField(Id recordId, String businessUnit, String scenario){
        Boolean showHNI = false;
        ABCL_Cx_360_Field_Mapping__mdt field = [SELECT id, HNI_Field__c,HWC_Field__c FROM ABCL_Cx_360_Field_Mapping__mdt WHERE Business_Unit__c = :businessUnit LIMIT 1];
        String hniField = '';
        List<String> fieldAndValues = new List<String>();
        if(scenario == 'HNI'){
            hniField = field.HNI_Field__c.split(':')[0];
            fieldAndValues = field.HNI_Field__c.split(':');
        }
        else{
            hniField = field.HWC_Field__c.split(':')[0];
            fieldAndValues = field.HWC_Field__c.split(':');
        }
        List<String> hniExpectedValues = getSubList(fieldAndValues, 0, fieldAndValues.size());
        String queryString = 'SELECT ' + hniField + ' FROM Account WHERE Id = :recordId';
        Account record = (Account) Database.query(queryString);
        Object fieldValue = record.get(hniField);
        String fieldValueAsString = String.valueOf(fieldValue);
        if(hniExpectedValues.contains(fieldValueAsString)){
            showHNI = true;
        }
        return showHNI;
    }
    
    @AuraEnabled
    public static caseStatusWrapper insertCase(String caseDetailId,String cccExternalId,String customerId,String lanId){
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
            caseRecord.AssetId = lanId;
            //caseRecord.Source__c= 'Inbound call';
            caseRecord.Business_Unit__c=ABHFL_Constants.BUSINESS_UNIT_ABHFL;
            caseRecord.Stage__c='Open';
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
            caseDetails.STP_Request_Type__c = ABHFL_Constants.EMAIL;
            if(cccExternalId==ABHFL_Constants.IC_CCC_EXTERNALID){
                caseDetails.Financial_Year__c=getCurrentFinancialYear(cccExternalId);
            }else if(cccExternalId==ABHFL_Constants.PIC_CCC_EXTERNALID){
                caseDetails.Financial_Year__c=getCurrentFinancialYear(cccExternalId);
            }
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
    
    @AuraEnabled(cacheable=true)
    public static List<ASF_Communication_Log__c> getInteractionInfo(String customerId){
        List<ASF_Communication_Log__c> commLog= new List<ASF_Communication_Log__c>();
        try {
            commLog = [Select id,account__c,Name,SMS_Msg_Body__c,Status__c,CreatedDate from ASF_Communication_Log__c where account__c=:customerId ORDER BY CreatedDate DESC LIMIT 3];
            System.debug('@@@'+commLog);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return commLog;
    }
    
    public static List<String> getSubList(List<String> originalList, Integer fromIndex, Integer toIndex) {
        // Validate indices
        if (originalList == null || fromIndex < 0 || toIndex > originalList.size() || fromIndex > toIndex) {
            throw new IllegalArgumentException('Invalid index parameters.');
        }
        
        List<String> subList = new List<String>();
        for (Integer i = fromIndex; i < toIndex; i++) {
            subList.add(originalList[i]);
        }
        return subList;
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
    
    @AuraEnabled(cacheable=true)

    public static Map<String, Object> getAccountFields(String recordId) {

        Map<String, Object> fieldValues = new Map<String, Object>();

        Account a=getCustomerInfo(recordId);

        String BU=a.Business_Unit__c;

        List<String> ABHFL_Fields=New List<String>{'Customer_Since__c','Handle_With_Care_HWC__c','Business_Unit__c'};

            List<String> ABML_Fields=New List<String>{'ABML_Activation_Date__c','ABML_Status__c','Sensitive_Customer__c','Business_Unit__c'};

                try {

                    String fields = String.join(ABHFL_Fields, ', ');

                    String query = 'SELECT ' + fields + ' FROM Account WHERE Id = :recordId';

                    Account account = Database.query(query);

                    

                    for (String field : ABHFL_Fields) {

                        fieldValues.put(field, account.get(field));

                    }

                } catch (Exception e) {

                    throw new AuraHandledException('Error fetching Account fields: ' + e.getMessage());

                }

        return fieldValues;

    }
}