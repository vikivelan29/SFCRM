/**
* @File Name : ABHI_OmniDocViewController.cls
* @Description : Class to handle Omnidocs integration
* @Author : Salesforce
* @Last Modified By : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On : 11-13-2024
* @Modification Log : updated templateDetails method to handle opp email
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 20, 2024 | Aditya Jawadekar  | Initial Version
* 1.1.| Oct 28, 2024    | Raj Raghuwanshi   | updated templateDetails method to handle opp email
**/

@SuppressWarnings('PMD.CyclomaticComplexity,PMD.StdCyclomaticComplexity,PMD.CognitiveComplexity,PMD.ExcessivePublicCount,PMD.IfStmtsMustUseBraces,PMD.IfElseStmtsMustUseBraces,PMD.AvoidDeeplyNestedIfStmts,PMD.ExcessiveParameterList,PMD.NcssMethodCount,PMD.ClassNamingConventions,PMD.FieldNamingConventions,PMD.VariableNamingConventions')
public without sharing class ABHI_OmniDocViewController{

    public static OmniDocListRequest objPayload{get;set;}
    public static ABCL_IntegrationCallout.IntegrationResponseWrapper objPayloadResponse{get;set;}
    public static OmniDocDownloadRequest objDocDownloadPayload{get;set;}
    public static Case_Integration_Outbound__e objCIOEvent{get;set;}
    public static ASF_Case_Integration__c objASFCaseInt{get;set;}
    public static List<Asf_Dynamic_Datatable_Child__mdt> lstAllDatatableColumns{get;set;}
    public static list<Object> lstColumnsReturned{get;set;}

    static{
        objPayload = new OmniDocListRequest();
        objDocDownloadPayload = new OmniDocDownloadRequest();
        objPayloadResponse = new ABCL_IntegrationCallout.IntegrationResponseWrapper();
        objCIOEvent = new Case_Integration_Outbound__e();
        objASFCaseInt = new ASF_Case_Integration__c();
        lstAllDatatableColumns = new List<Asf_Dynamic_Datatable_Child__mdt>();
        lstColumnsReturned = new list<Object>();
    }
	
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - getColumnsForDataTable
    * @param - strParentConfigName 
    * @return -  list<Object>
    * @description - This method will be used to get datatable columns from metadata for a specific parent config name
    *****************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static list<Object> getColumnsForDataTable(String strParentConfigName){

        try{

            lstAllDatatableColumns = [SELECT MasterLabel,Order__c, DeveloperName ,Asf_Dynamic_Datatable_Parent__c , 
                                        Api_Name__c, Data_Type__c, Asf_Dynamic_Datatable_Parent__r.Page_Size__c, 
                                        Asf_Dynamic_Datatable_Parent__r.DeveloperName, Type_Attributes__c 
                                        FROM Asf_Dynamic_Datatable_Child__mdt
                                        WHERE Asf_Dynamic_Datatable_Parent__r.DeveloperName = :strParentConfigName WITH SYSTEM_MODE
                                        ORDER BY Order__c ASC];
            
            if(!lstAllDatatableColumns.isEmpty()){
                for(Asf_Dynamic_Datatable_Child__mdt objDynaChild : lstAllDatatableColumns){
                    Map<String, Object> mapColumnEntry = new Map<String, Object>();
                    if(!String.isBlank(objDynaChild.MasterLabel))
                        mapColumnEntry.put(ABHI_Constants.DT_LABEL,objDynaChild.MasterLabel);
                    if(!String.isBlank(objDynaChild.Api_Name__c))
                        mapColumnEntry.put(ABHI_Constants.DT_FIELDNAME,objDynaChild.Api_Name__c);
                    if(!String.isBlank(objDynaChild.Data_Type__c))
                        mapColumnEntry.put(ABHI_Constants.DT_TYPE,objDynaChild.Data_Type__c);
                    if(!String.isBlank(objDynaChild.Type_Attributes__c))
                        mapColumnEntry.put(ABHI_Constants.DT_TYPEATTRIBUTES,(Object)JSON.deserializeuntyped(objDynaChild.Type_Attributes__c));
                    lstColumnsReturned.add((Object)mapColumnEntry);
                }
                return lstColumnsReturned;
            }else{
                throw callException(null,false,ABHI_Constants.ERROR_DT_NORECORDS);
            }

        }catch(Exception objException){
            throw callException(objException,true,'');
        }
    }
	
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - callOmiDocSearchRequest
    * @param - strAssetId, strPolicyNo
    * @return - Object
    * @description - This method performs omnidoc integration to get the list of documents
    *****************************************************************************************************************/
    @AuraEnabled
    Public static Object callOmiDocSearchRequest(String strAssetId, String strPolicyNo){

        try{
            objPayload.LogicalID = ABHI_Constants.LOGICAL_ID;
            objPayload.TaskID = ABHI_Constants.TASK_ID;
            objPayload.ReferenceID = strAssetId;
            objPayload.CreationDateTime = System.now().format();
            objPayload.TODID = strAssetId;
            objPayload.CategoryID = ABHI_Constants.CATEGORY_ID;
            if(Id.valueOf(strAssetId).getSObjectType().getDescribe().getName() == 'Case') objPayload.DocSearchParamId = ABHI_Constants.CASE_PARAM_ID;
            else objPayload.DocSearchParamId = ABHI_Constants.PARAM_ID;
            objPayload.SourceSystemName = ABHI_Constants.LOGICAL_ID;
            objPayload.SearchOperator = ABHI_Constants.SEARCH_OPERATOR;
            objPayload.Value = strPolicyNo;

            objPayloadResponse = objPayload != null ? ABCL_IntegrationCallout.executeCallout(ABHI_Constants.OMNIDOC_INTEGRATION_NAME, JSON.serialize(objPayload), null) : null;
            if(objPayloadResponse != null && objPayloadResponse.statusCode == ABHI_Constants.STATUS_OK){
                Object objResponse = (Object)JSON.deserializeuntyped(objPayloadResponse.responseBody);
                return objResponse;
            }else{
                throw callException(null,false,objPayloadResponse.responseBody);
            }

        }catch(Exception objException){
            throw callException(objException,true,'');
        }
    }
	
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - publishCaseIntegrationOutbound
    * @param - strAssetId, mapRow, strASFRecordId
    * @return - boolean
    * @description - This method publishes platform event for AWS to send us the document on the created ASF record
    *****************************************************************************************************************/
    @AuraEnabled
    Public static boolean publishCaseIntegrationOutbound(String strAssetId, Map<String, Object> mapRow, String strASFRecordId){

        List<ASF_Case_Integration__c> lstAsfCaseIntegration = new List<ASF_Case_Integration__c>();
        try{
            if(!String.isBlank(strAssetId) && mapRow != null){

                lstAsfCaseIntegration = [SELECT Id, Name, Business_External_Id__c, Status__c, Request__c, createdDate
                                        FROM ASF_Case_Integration__c 
                                        WHERE Id = :strASFRecordId WITH SYSTEM_MODE
                                        ORDER BY createdDate DESC
                                        LIMIT 1];
                
                if(!lstAsfCaseIntegration.isEmpty()){
                    objCIOEvent.Business_Unit__c = ABHI_Constants.ABHI;
                    objCIOEvent.Case_Integration_ID__c = lstAsfCaseIntegration?.iterator()?.next()?.Name;
                    objCIOEvent.Integration_Name__c = ABHI_Constants.OMNI_INT_TYPE;
                    objCIOEvent.Request_Payload__c = lstAsfCaseIntegration?.iterator()?.next()?.Request__c;
                    objCIOEvent.ServiceName__c = ABHI_Constants.OMNI_INT_TYPE;

                    Database.SaveResult objSaveResultPEInsert = EventBus.publish(objCIOEvent);
                    if(objSaveResultPEInsert.isSuccess()){
                        return true;
                    }else{
                        String strException = ABHI_Constants.ERROR_CIO_PUBLISH;
                        for(Database.Error objError : objSaveResultPEInsert.getErrors()) {
                            strException = strException + objError.getMessage() + ' ';
                        }
                        throw callException(null,false,strException);
                    }
                }else{
                    throw callException(null,false,ABHI_Constants.ERROR_CIO_ZEROINTREC);
                }
            }else{
                throw callException(null,false,ABHI_Constants.ERROR_NULLPARAM);
            }
        }catch(Exception objException){
            throw callException(objException,true,'');
        }
        
    }
	
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - createASFIntegrationRecord
    * @param - strAssetId, mapRow
    * @return - Object
    * @description - This method creates ASF record where the documents are to be transferred
    *****************************************************************************************************************/
    @AuraEnabled
    Public static Object createASFIntegrationRecord(String strAssetId, Map<String, Object> mapRow){

        try{

            if(!String.isBlank(strAssetId) && mapRow != null){

                objDocDownloadPayload.LogicalID = ABHI_Constants.LOGICAL_ID;
                objDocDownloadPayload.OmniDocIndex = (String) mapRow.get(ABHI_Constants.OMNIPAYLOAD_OMNIDOCINDEX);
                objDocDownloadPayload.VID = (String) mapRow.get(ABHI_Constants.OMNIPAYLOAD_VID);
                objDocDownloadPayload.CreationDateTime = (String) mapRow.get(ABHI_Constants.OMNIPAYLOAD_UPLOADEDDATE);
                objDocDownloadPayload.FileName = (String) mapRow.get(ABHI_Constants.OMNIPAYLOAD_FILENAME);
                objDocDownloadPayload.OmniDocImageIndex = (String) mapRow.get(ABHI_Constants.OMNIPAYLOAD_OMNIDOCIMAGEINDEX);

                objASFCaseInt.Business_External_Id__c = generateExternalId((String) mapRow.get(ABHI_Constants.OMNIPAYLOAD_VID), (String) mapRow.get(ABHI_Constants.OMNIPAYLOAD_OMNIDOCINDEX), (String) mapRow.get(ABHI_Constants.OMNIPAYLOAD_OMNIDOCIMAGEINDEX), strAssetId);
                objASFCaseInt.Type__c = ABHI_Constants.OMNI_INT_TYPE;
                objASFCaseInt.Request__c = JSON.serialize(objDocDownloadPayload);
                objASFCaseInt.Retry__c = false;

                Database.SaveResult objSaveResultASFInsert = Database.insert(objASFCaseInt, true, AccessLevel.SYSTEM_MODE);
                if(objSaveResultASFInsert.isSuccess()){
                    return (Object) objASFCaseInt;
                }else{
                    String strException = ABHI_Constants.ERROR_ASFINSERT;
                    for(Database.Error objError : objSaveResultASFInsert.getErrors()) {
                        strException = strException + objError.getMessage() + ' ';
                    }
                    throw callException(null,false,strException);
                }

            }else{
                throw callException(null,false,ABHI_Constants.ERROR_NULLPARAM);
            }
        }catch(Exception objException){
            throw callException(objException,true,'');
        }
    }
	
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - templateDetails
    * @param - mapRow, strASFRecordId, strAssetId, strPlanName, strAccountId, strAccountEmail
    * @return - boolean
    * @description - This method sends email to customer with document
    *****************************************************************************************************************/
	@AuraEnabled(cacheable=false)
	Public static boolean templateDetails(Map<String, Object> mapRow, String strASFRecordId, String strAssetId, String strPlanName, String strAccountId, String strAccountEmail){

        List<ASF_Case_Integration__c> lstAsfCaseIntegration = new List<ASF_Case_Integration__c>();
        List<String> lstString = new List<String>(); 

        try{
            EmailTemplate objEmailTemplate = new EmailTemplate();
            String strTemplateName; 
            String strFromAddress; 
            String sObjName = Id.valueOf(strAssetId).getSObjectType().getDescribe().getName();

            OrgWideEmailAddress objOrgWideEmailAddress = new OrgWideEmailAddress();

            if(sObjName == 'Opportunity'){
                strTemplateName = RNWL_Constants.OMNIDOC_TEMPLATE_DEVELOPER_NAME;
                strFromAddress = RNWL_Constants.FROM_ADDRESS_DISPLAY_NAME;
            } 
            else{
                strTemplateName = ABHI_Constants.EMAIL_TEMPLATE_DEVELOPER_NAME;
                strFromAddress = ABHI_Constants.FROM_ADDRESS_DISPLAY_NAME;
            }

           if(!String.isBlank(strASFRecordId) && !String.isBlank(strAssetId) && !String.isBlank(strPlanName) && !String.isBlank(strAccountId) && mapRow != null ){
				
                if(Id.valueOf(strAssetId).getSObjectType().getDescribe().getName() == 'Opportunity'){
                    strTemplateName = RNWL_Constants.OMNIDOC_TEMPLATE_DEVELOPER_NAME;
                    strFromAddress = RNWL_Constants.FROM_ADDRESS_DISPLAY_NAME; 
                }else if(Id.valueOf(strAssetId).getSObjectType().getDescribe().getName() == 'Case'){
                    strTemplateName = ABHI_Constants.EMAIL_TEMPLATE_DEVELOPER_NAME_CASE;
                    strFromAddress = ABHI_Constants.FROM_ADDRESS_DISPLAY_NAME;
                }else{
                    strTemplateName = ABHI_Constants.EMAIL_TEMPLATE_DEVELOPER_NAME;
                    strFromAddress = ABHI_Constants.FROM_ADDRESS_DISPLAY_NAME;
                }
                
                objOrgWideEmailAddress = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = : strFromAddress WITH SYSTEM_MODE LIMIT 1];
                objEmailTemplate = [SELECT Id FROM EmailTemplate WHERE DeveloperName =: strTemplateName WITH SYSTEM_MODE LIMIT 1];
                lstAsfCaseIntegration = [SELECT Id, Business_External_Id__c, Status__c, Request__c, createdDate,
                                            (SELECT Id, ContentDocument.CreatedDate, ContentDocument.LatestPublishedVersion.FileType, ContentDocument.LatestPublishedVersion.VersionData, ContentDocument.LatestPublishedVersion.PathOnClient, ContentDocument.LatestPublishedVersionId FROM ContentDocumentLinks)
                                            FROM ASF_Case_Integration__c
                                            WHERE Id = :strASFRecordId WITH SYSTEM_MODE
                                            ORDER BY createdDate DESC
                                            LIMIT 1];

                if(!lstAsfCaseIntegration.isEmpty()){
                    for(ContentDocumentLink objCDL: lstAsfCaseIntegration?.iterator()?.next()?.ContentDocumentLinks){
                        lstString.add(objCDL.ContentDocument.LatestPublishedVersionId);
                    }
                }else{
                    throw callException(null,false,ABHI_Constants.ERROR_CIO_ZEROINTREC);
                }

                if(!lstString.isEmpty() && lstAsfCaseIntegration?.iterator()?.next()?.Status__c == ABHI_Constants.OMNIRES_SUCCESS){

                    if(calculateDateDifference(DateTime.now(), lstAsfCaseIntegration?.iterator()?.next()?.createdDate).minutes < 1){
                        Contact objCon = [SELECT Id, Name FROM Contact WHERE AccountId =: strAccountId WITH SYSTEM_MODE];

                        Messaging.SingleEmailMessage objEmail = Messaging.renderStoredEmailTemplate(objEmailTemplate.Id, objCon.Id, strAssetId);
                        objEmail.setTemplateId(objEmailTemplate.Id);
                        objEmail.setOrgWideEmailAddressId(objOrgWideEmailAddress.Id);
                        if(Id.valueOf(strAssetId).getSObjectType().getDescribe().getName() == 'Case'){
                            objEmail.setSubject(objEmail.getSubject().replace(strAssetId.substring(0,15), strPlanName + ' ' + String.valueOf(mapRow.get(ABHI_Constants.OMNIPAYLOAD_FILENAME))));
                            objEmail.setHtmlBody(objEmail.getHTMLBody().replace(strAssetId.substring(0,15), strPlanName + ' '+ String.valueOf(mapRow.get(ABHI_Constants.OMNIPAYLOAD_FILENAME))));
                        }else{
                            objEmail.setSubject(objEmail.getSubject().replace(strPlanName, strPlanName + ' ' + String.valueOf(mapRow.get(ABHI_Constants.OMNIPAYLOAD_FILENAME))));
                            objEmail.setHtmlBody(objEmail.getHTMLBody().replace(strPlanName, strPlanName + ' '+ String.valueOf(mapRow.get(ABHI_Constants.OMNIPAYLOAD_FILENAME))));
                        }
                        objEmail.setEntityAttachments(lstString);
                        objEmail.setWhatId(strAssetId);
                        objEmail.setTargetObjectId(objCon.Id);
                        objEmail.setSaveAsActivity(true);
                        Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {objEmail}, true);
                        return sendResults.iterator().next().isSuccess();
                    }else{
			            throw callException(null,false,ABHI_Constants.ERROR_OMNISUCCESSLONG);
                    }
                }else if(lstAsfCaseIntegration?.iterator()?.next()?.Status__c == ABHI_Constants.OMNIRES_FAILURE){
                    throw callException(null,false,ABHI_Constants.ERROR_OMNIRESFAIL);
                }else if(lstAsfCaseIntegration?.iterator()?.next()?.Status__c == ABHI_Constants.OMNIRES_PENDING){
                    if(calculateDateDifference(DateTime.now(), lstAsfCaseIntegration?.iterator()?.next()?.createdDate).minutes < 1)
                        return false;
                    else
                        throw callException(null,false,ABHI_Constants.ERROR_OMNIRESPENDINGLONG);
                }
            }else{
                throw callException(null,false,ABHI_Constants.ERROR_NULLPARAM);
            }
        }catch(Exception objException){
            throw callException(objException,true,'');
        }
        return false;
	}
	
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - calculateDateDifference
    * @param - dateTimeNew, dateTimeOld
    * @return - dateDifferenceWrap
    * @description - This method calculates date difference
    *****************************************************************************************************************/
    private static dateDifferenceWrap calculateDateDifference(DateTime dateTimeNew, DateTime dateTimeOld){
        Long dt1Long = dateTimeNew.getTime();
        Long dt2Long = dateTimeOld.getTime();
        Long milliseconds = math.abs(dt2Long - dt1Long);
        dateDifferenceWrap objDtWrap = new dateDifferenceWrap();
        objDtWrap.seconds = milliseconds / 1000;
        objDtWrap.minutes = (milliseconds / 1000)/60;
        objDtWrap.hours = ((milliseconds / 1000)/60)/60;
        objDtWrap.days = (((milliseconds / 1000)/60)/60)/24;
        return objDtWrap;
    }
	
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - callException
    * @param - objException, boolIsException, strErrorMessage
    * @return - AuraHandledException
    * @description - This method handles exception
    *****************************************************************************************************************/
    private static AuraHandledException callException(Exception objException, Boolean boolIsException, String strErrorMessage) {
        if(boolIsException && objException != null){
            AuraHandledException objAHException = new AuraHandledException('Exception ' + objException.getMessage() + ' at ' + objException.getLineNumber());
            objAHException.setMessage('Exception ' + objException.getMessage() + ' at ' + objException.getLineNumber());
            return objAHException;
        }else{
            AuraHandledException objAHException = new AuraHandledException('Exception: ' + strErrorMessage);
            objAHException.setMessage('Exception: ' + strErrorMessage);
            return objAHException;
        }
    }
	
    /****************************************************************************************************************
    * @LOB - ABHI
    * @Function - generateExternalId
    * @param - strVID, strOmniDocIndex, strOmniDocImageIndex, strAssetId
    * @return - String
    * @description - This method handles exception
    *****************************************************************************************************************/
    public static String generateExternalId(String strVID, String strOmniDocIndex, String strOmniDocImageIndex,String strAssetId){
        return strVID + strOmniDocIndex + strOmniDocImageIndex + strAssetId + UserInfo.getUserId();
    }
	
    /*********************************************************
    * @Class        :  dateDifferenceWrap 
    * @Author       :  Aditya Jawadekar
    * @description  :  Date difference wrapper
    *********************************************************/
    public class dateDifferenceWrap{
        @AuraEnabled
        public long seconds;
        @AuraEnabled
        public long minutes;
        @AuraEnabled
        public long hours;
        @AuraEnabled
        public long days;
    }
	
    /*********************************************************
    * @Class        :  OmniDocListRequest 
    * @Author       :  Aditya Jawadekar
    * @description  :  Wrapper class of Omnidoc List request
    *********************************************************/
    public class OmniDocListRequest{
        @AuraEnabled
        public String LogicalID;
        @AuraEnabled
        public String TaskID;
        @AuraEnabled
        public String ReferenceID;
        @AuraEnabled
        public String CreationDateTime;
        @AuraEnabled
        public String TODID;
        @AuraEnabled
        public String CategoryID;
        @AuraEnabled
        public String DocSearchParamId;
        @AuraEnabled
        public String SourceSystemName;
        @AuraEnabled
        public String SearchOperator;
        @AuraEnabled
        public String Value;
    }
	
    /*********************************************************
    * @Class        :  OmniDocDownloadRequest 
    * @Author       :  Aditya Jawadekar
    * @description  :  Wrapper class of Omnidoc download request
    *********************************************************/
    public class OmniDocDownloadRequest{
        @AuraEnabled
        public String LogicalID;
        @AuraEnabled
        public String OmniDocIndex;
        @AuraEnabled
        public String VID;
        @AuraEnabled
        public String CreationDateTime;
        @AuraEnabled
        public String FileName;
        @AuraEnabled
        public String OmniDocImageIndex;
    }
}