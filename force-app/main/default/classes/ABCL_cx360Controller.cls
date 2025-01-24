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
    public static List<caseStatusWrapper> createCases(String customerId,String lanId,List<String> docs){
        List<caseStatusWrapper> statusWrapper = New List<caseStatusWrapper>();
        try{
            Asset asset=[Select Id,Loan_Start_Date__c,Loan_Disbursement_Status__c, Disbursed_Amount__c, Status, Name, LAN__c,LOB__c,Loan_Type__c,DA_Transaction__c,Sanction_Amount__c,VAN__c from Asset Where AccountId=:customerId AND Id=:lanId];
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
            if(docs.contains('IC')){
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
    public static List<Map<String, String>> getFieldSetFieldsAndValues(String objectName, String fieldSetName, Id recordId) {
        List<Map<String, String>> fieldList = new List<Map<String, String>>();
        
        try {
            // Get the object describe
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
            if (objectType != null) {
                // Get the field set
                Schema.FieldSet fieldSet = objectType.getDescribe().fieldSets.getMap().get(fieldSetName);
                if (fieldSet != null) {
                    // Create a list of field API names
                    List<String> fieldApiNames = new List<String>();
                    for (Schema.FieldSetMember field : fieldSet.getFields()) {
                        fieldApiNames.add(field.getFieldPath());
                    }
                    
                    // Query the record data
                    String queryString = 'SELECT ' + String.join(fieldApiNames, ',') + ',City__c'+
                        ' FROM ' + objectName + ' WHERE Id = :recordId';
                    SObject record = Database.query(queryString);
                    
                    // Iterate through fields in the order defined in the Field Set
                    for (Schema.FieldSetMember field : fieldSet.getFields()) {
                        Schema.DescribeFieldResult fieldDescribe = Schema.getGlobalDescribe()
                            .get(objectName)
                            .getDescribe()
                            .fields
                            .getMap()
                            .get(field.getFieldPath())
                            .getDescribe();
                        
                        Map<String, String> fieldInfo = new Map<String, String>();
                        fieldInfo.put('label', fieldDescribe.getLabel());
                        fieldInfo.put('value', String.valueOf(record.get(field.getFieldPath())));
                        //Updates to the labels
                        object fieldLabel = fieldDescribe.getLabel();
                        if(String.valueOf(field.getFieldPath())=='PersonGenderIdentity'){
                        	fieldInfo.put('label', 'Gender');    
                        }
                        if(String.valueOf(field.getFieldPath())=='Phone'){
                        	fieldInfo.put('label', 'Phone Number');    
                        }
                        if(String.valueOf(field.getFieldPath())=='PAN__c'){
                        	fieldInfo.put('label', 'PAN Number');    
                        }
                        if(String.valueOf(field.getFieldPath())=='PersonBirthdate'){
                        	fieldInfo.put('label', 'DOB/DOC');    
                        }
                        if(String.valueOf(field.getFieldPath())=='State__c'){
                        	fieldInfo.put('label', 'State, City');
                            List<String> addressStrings = New List<String>();
                            addressStrings.add(String.valueOf(record.get('State__c')));
                            addressStrings.add(String.valueOf(record.get('City__c')));
                            system.debug('addressStrings'+addressStrings);
                            if(addressStrings.size()>1){
                                fieldInfo.put('value', String.join(addressStrings, ', '));
                            }else if(addressStrings.size()==1){
                                fieldInfo.put('value', String.valueOf(addressStrings[0]));
                            }
                            system.debug('Map>>'+fieldInfo);
                        }
                        // Handle datetime to date
                        Object fieldValue = record.get(field.getFieldPath());
                        if (fieldValue instanceof Datetime) {
                            fieldInfo.put('value', ((Datetime)fieldValue).date().format());
                        } else if (fieldDescribe.getType() == Schema.DisplayType.DATE) {
                            fieldInfo.put('value', String.valueOf(fieldValue));
                        }
                        fieldList.add(fieldInfo);
                    }
                } else {
                    throw new AuraHandledException('Field Set not found: ' + fieldSetName);
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Field Set fields and values: ' + e.getMessage());
        }
        
        return fieldList;
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
    
    /**
    @AuraEnabled(cacheable=true)
    public static List<accountDetailsWrapper> getAccountDetails(String customerId,String businessUnit){
        system.debug('Account Id:>>'+customerId+', BU:>> '+businessUnit);
        try {
            List<accountDetailsWrapper> accDetails = New List<accountDetailsWrapper>();
            Map<String,Schema.SObjectField> mfields = Schema.Account.SObjectType.getDescribe().fields.getMap();
            system.debug('1');
            List<ABCL_CX_360_Account_Details_Field_Map__mdt> fieldMap = [SELECT Id,Business_Unit__c,Field_List__c ,Field_Section__c FROM ABCL_CX_360_Account_Details_Field_Map__mdt WHERE Business_Unit__c =: businessUnit WITH SYSTEM_MODE];
            system.debug('fieldMap>>'+fieldMap);
            String AccountInfoFields;
            String AccountAddressFields;
            String AccountEmploymentFields;
            for(ABCL_CX_360_Account_Details_Field_Map__mdt fm:fieldMap){
                if(fm.Field_Section__c=='Account Information'){
                    AccountInfoFields=(fm.Field_List__c);
                }
                if(fm.Field_Section__c=='Address Details'){
                    AccountAddressFields=(fm.Field_List__c);
                }
                if(fm.Field_Section__c=='Employment Details'){
                    AccountEmploymentFields=(fm.Field_List__c);
                }
            }
            system.debug('AccountInfoFields>>'+AccountInfoFields);
            system.debug('AccountAddressFields>>'+AccountAddressFields);
            system.debug('AccountEmploymentFields>>'+AccountEmploymentFields);
            String fields;
            if(String.isNotBlank(AccountInfoFields)){
                fields=AccountInfoFields;
            }
            if(String.isNotBlank(AccountAddressFields)){
                fields=fields+','+AccountAddressFields;
            }
            if(String.isNotBlank(AccountEmploymentFields)){
                fields=fields+','+AccountEmploymentFields;
            }
            system.debug('fields to Query>>'+fields);
            system.debug('Fields:'+fields);
            String query = 'SELECT Id,' + fields + ' FROM Account WHERE Id = :customerId';
            Account account = Database.query(query);
            system.debug('account>>>'+account);
            List<String> fieldList = fields.split(',');
            for (String field : fieldList) {
                system.debug('In final FOR');
                accountDetailsWrapper fieldwrapper = new accountDetailsWrapper();
                fieldwrapper.fieldAPIName=field;
                fieldwrapper.fieldLabel=String.Valueof(mfields.get(field).getDescribe().getLabel());
                fieldwrapper.fieldValue=String.valueOf(account.get(field));
                if(AccountInfoFields.contains(field)){
                    fieldwrapper.fieldSection='Account Information';
                }
                if(AccountAddressFields.contains(field)){
                    fieldwrapper.fieldSection='Address Details';
                }
                if(AccountEmploymentFields.contains(field)){
                    fieldwrapper.fieldSection='Employment Details';
                }
                system.debug('fieldwrapper>>'+fieldwrapper);
                accDetails.add(fieldwrapper);
            }
            system.debug('final accDetails>>'+accDetails);
            return accDetails;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    **/
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
    
    public class accountDetailsWrapper{
        @AuraEnabled
        public String fieldAPIName;
        @AuraEnabled
        public String fieldLabel;
        @AuraEnabled
        public String fieldValue;
        @AuraEnabled
        public String fieldSection;
    }
}
