public with sharing class ABHI_EndorsementStpApi implements ASF_IntegrationInvocable{

    /**
    * @description Invoked from the ASF_IntegrationsController class, this method evaluates whether integration should be fired or not
    *
    * @param caseRec - Case record from the framework
    * @return ASF_IntegrationsController.IntegrationWrapper
    */
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec) {
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result = evaluate(new List<Case>{ caseRec }).get(caseRec.Id);
        return result;
    }

    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs) {
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        List<Case> caseRecords = new List<Case>();
        for (Case caseRec : caseRecs) {
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }
        for (Case caseRecord : caseRecords) {
            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            result.status = ABHI_Constants.ERROR;
            String errorMessage = 'Please update the mandatory fields first';
            boolean bErrorOccured = false;
            List<ABHI_Endorsement_API__mdt> customMetaList = [SELECT ID, Mandatory_Fields__c FROM ABHI_Endorsement_API__mdt WHERE MasterLabel = :caseRecord.Sub_Type_Text__c LIMIT 1]; 
            system.debug('customMeta---->'+customMetaList); 
            if(!customMetaList.isEmpty() && caseRecord.Technical_Source__c == 'LWC') {
                String strMandatFields = customMetaList[0].Mandatory_Fields__c ;
                List<String> mandatoryFields = strMandatFields.split(',');
                for (String field : mandatoryFields) {
                field = field.trim(); 
                if (field.containsIgnoreCase('__r')) {
                        Integer index = field.lastIndexOf('__r');
                        String baseField = field.substring(index + 4).trim(); 
                        System.debug('baseField---->' + baseField); 
                        ABHI_Case_Detail__c caseDetail = caseRecord.ABHI_Case_Detail__r;
                        if (caseDetail == null || caseDetail.get(baseField) == null) {
                            bErrorOccured = true;
                        }
                    } 
                    else {
                        if (caseRecord.get(field) == null) {
                            bErrorOccured = true;
                        }
                    }
                }
            }         
            if(bErrorOccured){
                errorMessage = errorMessage.removeEnd(', ');
                result.response = errorMessage;
                resultMap.put(caseRecord.Id, result);
            } 
            else{
                result.status = ABHI_Constants.SUCCESS;
                result.response = 'Evaluation Success';
            }
            resultMap.put(caseRecord.Id, result);
        }
        system.debug('resultMap---->'+resultMap);
        return resultMap;
    }

    /**
    * @description Invoked from the ASF_IntegrationsController class, this method runs the integration and creates Case Integration record
    *
    * @param caseInteg - ASF_Integration record
    * @param caseRec - Case record from the framework
    * @return ASF_IntegrationsController.IntegrationWrapper
    */
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c caseInteg, Case caseRec) {
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result = run(
            new Map<Id, List<ASF_Integration__c>>{ caseRec.Id => new List<ASF_Integration__c>{ caseInteg } },
            new List<Case>{ caseRec }
        )
            .get(caseRec.Id);
        return result;
    }

    /**
    * @description Invoked from the ASF_IntegrationsController class, this method runs the integration and creates Case Integration record
    *
    * @param caseIntegs - List of ASF_Integration record
    * @param caseRecs - List of Case record from the framework
    * @return Map<Id, ASF_IntegrationsController.IntegrationWrapper>
    */
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(
        Map<Id, List<ASF_Integration__c>> integs,
        List<Case> caseRecs
    ) {
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        
        //Before Initiating new Integration callout, cancel existing running request
        cancelPendingCaseIntegrationRequests(integs, caseRecs);
        
        List<Case> caseRecords = new List<Case>();
        for (Case caseRec : caseRecs) {
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }
        
        List<ASF_Case_Integration__c> newCaseIntegrations = new List<ASF_Case_Integration__c>();
        Map<Integer, Case_Integration_Outbound__e> peMap = new Map<Integer, Case_Integration_Outbound__e>();
        Integer index = 0;
        Map<Integer, Id> indexToCaseId = new Map<Integer, Id>();
        //string requestBody = JSON.serialize(requestJSON);
         // Query the custom metadata for the specified case subtype
        List<ABHI_Endorsement_API__mdt > payloadMeta = [SELECT ID, Payload__c  FROM ABHI_Endorsement_API__mdt WHERE MasterLabel = :caseRecords[0].Sub_Type_Text__c LIMIT 1];
        String payloadTemplate = payloadMeta[0].Payload__c;
        System.debug('payloadTemplate--> '+payloadTemplate);
        //String payload = '{"CrossSaleReferenceNumber":"", "IsCombi":"Asset.IsCombi__c", "Endorsement":[{"Service_Request_Number":"000022332", "Policy_Number":"12121212121", "MemObj":[{"Member":[{"MemberNo":"", "MemberCode":"", "Member_FirstName":"", "Member_LastName":"", "Member_ContactNumber":"", "Member_AlternateNumber":"", "Member_EmailId":"", "Member_AlternateEmailId":"", "Member_AdharNumber":"", "Member_PAN":"", "Member_Height":"", "Member_Weight":"", "Member_AnnualIncome":"", "Member_Occupation":"", "Member_Education":"", "Member_PED":""}]}], "Home_Address1":"", "Home_Address2":"", "Home_Address3":"", "Home_Pincode":"", "Home_Mobile1":"", "Home_Mobile2":"", "Home_Mobile3":"", "Home_LandLine1":"", "Home_LandLine2":"", "Home_FaxNo":"", "Home_Area":"", "SameASHome":"", "Mailling_Address1":"", "Mailling_Address2":"", "Mailling_Address3":"", "Mailling_Pincode":"", "Mailling_Mobile1":"", "Mailling_Mobile2":"", "Mailling_Mobile3":"", "Mailling_LandLine1":"", "Mailling_LandLine2":"", "Mailling_FaxNo":"", "Mailling_Area":"", "Email1":"", "Email2":"", "Email3":"", "Alternateemail":"", "AADHAR_Number":"","PAN": "1212121", "Nominee_Relationship":"", "Nominee_Name":"", "Nominee_Contact_Number":"", "Height":"", "Weight":"", "Country_Code":"", "Internation_Contact_No":"", "Internation_Address":"", "Flag":"17"}]}';
        for (Case caseRecord : caseRecords) {
           	String payload = buildPayload(payloadTemplate, caseRecord);
            System.debug('requestBody--> '+payload);
            System.debug('requestBodyss--> '+integs);
            System.debug('caseRecord.Id--> '+caseRecord.Id);
            for (ASF_Integration__c intSpec : integs.get(caseRecord.Id)) {
                System.debug('intSpec.Processing_Class__c --> '+intSpec.Processing_Class__c);
                if (intSpec.Processing_Class__c == ABHI_EndorsementStpApi.class.getName()) {
                    ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
                    caseInteg.Integration_Ext_Id__c = intSpec.External_Id__c;
                    caseInteg.Case__c = caseRecord.Id;
                    caseInteg.Status__c = ABSLI_Constants.PENDING;
                    caseInteg.Request__c = payload;
                    caseInteg.Response__c = ABSLI_Constants.WAITING_API_RESPONSE;
                    caseInteg.Is_Validation_Success__c = true;
                    newCaseIntegrations.add(caseInteg);
                    
                    Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e();
                    caseIntOut.Business_Unit__c = caseRecord.Business_Unit__c;
                    caseIntOut.Request_Payload__c = payload;
                    caseIntOut.Integration_Name__c = 'Endorsement';
                    caseIntOut.ServiceName__c = 'Endorsement';
                    peMap.put(index, caseIntOut);
                    indexToCaseId.put(index, caseRecord.Id);
                    index++;
                }
                
            }
        }
        
        System.debug(peMap);
        
        index = 0;
        if(newCaseIntegrations.size()>0){
            List<Database.SaveResult> results = Database.insert(newCaseIntegrations, false, AccessLevel.SYSTEM_MODE);
            Map<Id, ASF_Case_Integration__c> caseIntegrations = new Map<Id, ASF_Case_Integration__c>(
                ABHI_IntegrationQueryHelper.getCaseIntegrations(newCaseIntegrations)
            );
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    Case_Integration_Outbound__e caseIntOut = peMap.get(index);
                    System.debug('caseIntegrations --> '+caseIntegrations.get(sr.getId()).Name + ' caseIntOut --> '+caseIntOut);
                    caseIntOut.Case_Integration_ID__c = caseIntegrations.get(sr.getId()).Name;
                    peMap.put(index, caseIntOut);
                } else {
                    ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
                    wrap.status = ABSLI_Constants.ERROR;
                    resultMap.put(indexToCaseId.get(index), wrap);
                    peMap.remove(index);
                    indexToCaseId.remove(index);
                }
                index++;
            }
            
            List<Database.SaveResult> publishResults = EventBus.publish(peMap.values());
            index = 0;
            for (Database.SaveResult publishResult : publishResults) {
                if (publishResult.isSuccess()) {
                    ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
                    wrap.status = ABSLI_Constants.SUCCESS;
                    wrap.response = Custom_Messages__mdt.getInstance(ABSLI_Constants.ABSLI_IGMSSYNC_SUCCESS_MESSAGE)
                        .Message__c;
                    resultMap.put(indexToCaseId.values()[index], wrap);
                } else {
                    ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
                    wrap.status = ABSLI_Constants.ERROR;
                    wrap.response = Custom_Messages__mdt.getInstance(ABSLI_Constants.ABSLI_IGMSSYNC_FAILURE_MESSAGE)
                        .Message__c;
                    resultMap.put(indexToCaseId.values()[index], wrap);
                }
                index++;
            } 
        }
        
        
        return resultMap;
    }

    /**
    * @description Before Initiating new Integration callout, cancel existing running request
    *
    * @param integs - List of Integration configs
    * @param caseRecs - List of Case record from the framework
    */
    public void cancelPendingCaseIntegrationRequests(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs) {
        Set<String> intIds = new Set<String>();
        for (Case caseRec : caseRecs) {
            for (ASF_Integration__c integ : integs.get(caseRec.Id)) {
                if (integ.Processing_Class__c == ABHI_EndorsementStpApi.class.getName()) {
                    intIds.add(integ.External_Id__c);
                }
            }
        }
        
        List<ASF_Case_Integration__c> existingCaseIntegrations = new List<ASF_Case_Integration__c>();
        for (ASF_Case_Integration__c caseInt : ABHI_IntegrationQueryHelper.getCaseIntegrations1(caseRecs, intIds)) {
            if (integs.containsKey(caseInt.Case__c)) {
                for (ASF_Integration__c integ : integs.get(caseInt.Case__c)) {
                    if (
                        integ.External_Id__c == caseInt.Integration_Ext_Id__c &&
                        caseInt.Status__c == ABSLI_Constants.PENDING
                    ) {
                        caseInt.Status__c = ABSLI_Constants.CANCELED;
                        existingCaseIntegrations.add(caseInt);
                    }
                }
            }
        }
        
        ASF_TriggerSkipperUtility.markTriggerRun('ASF_Case_Integration__c');
        Database.update(existingCaseIntegrations, AccessLevel.SYSTEM_MODE);
        ASF_TriggerSkipperUtility.resetTriggerRun('ASF_Case_Integration__c');
    }

    /**
    * @description Invoked from the Case Integration trigger, this method processes the response of the integration received
    * If ProcessCode = 0, Successful Transaction. Then Resolve Case
    *
    * @param caseInteg - ASF_Integration record
    * @return
    */
    public void processResponse(ASF_Case_Integration__c caseInteg) {
        try {
            if (caseInteg.Status__c == ABHI_Constants.SUCCESS) {
                Case caseRecord = ABHI_IntegrationQueryHelper.getCaseInfo(caseInteg.Case__c); 
                EndorsementResponse jsonMap = (EndorsementResponse) JSON.deserialize(caseInteg.Response__c,EndorsementResponse.class);
                List<sObject> dmlRecords = new List<sObject>();
                String inWardnumber = jsonMap.Response.InwardNumber;
                if(caseRecord.ABHI_Case_Detail__c != null){
                    ABHI_Case_Detail__c caseExt = new ABHI_Case_Detail__c(Id = caseRecord.ABHI_Case_Detail__c);
                    if(!string.isEmpty(inWardnumber)){
                    	caseExt.Inward_Number__c  = inWardnumber;
                    }
                    dmlRecords.add(caseExt);
                    caseRecord.Stage__c = 'Resolved';
                    dmlRecords.add(caseRecord);
                    Database.SaveResult[] results = Database.update(dmlRecords, true);
                }
            }
             else if (caseInteg.Status__c == ABHI_Constants.FAILURE) {
             	Case caseRecord = ABHI_IntegrationQueryHelper.getCaseInfo(caseInteg.Case__c);                
                List<sObject> dmlRecords = new List<sObject>();
					caseRecord.MoveToNext__c  = true;
                    dmlRecords.add(caseRecord);
                    Database.SaveResult[] results = Database.update(dmlRecords, true);     
            }
        }
        catch (Exception e) {
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABHI_EndorsementStpApi.processResponse');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
        }
    }

	public static String buildPayload(String jsonStructure, Case caseRecord) {        
		String regex = '\\{(.*?)\\}';
        Pattern pattern = Pattern.compile(regex);
        Matcher matcher = pattern.matcher(jsonStructure);
    	String finalJson = jsonStructure;
		while (matcher.find()) {
            String placeholder = matcher.group(1); // Extracting field name inside { }
            String fieldValue = getFieldValue(caseRecord, placeholder); // Getting the field value from caseRecord
            String replacement = fieldValue != null ? fieldValue : '';
            finalJson = finalJson.replace('{' + placeholder + '}', replacement);
       }
    	return finalJson.replaceAll('\r', '').replaceAll('\n', '');  // Returning the modified JSON string
	}
    public static String getFieldValue(Object obj, String fieldName) {
    if (fieldName == null || string.isEmpty(fieldName)) {
        return null;
    }
    String[] fieldParts = fieldName.split('\\.');
    Object currentValue = obj;
    if (fieldName.contains('.')) {
        system.debug('AssetIDSS '+fieldName);
        Integer relLevel = 0;  
        for (Integer i = 0; i < fieldParts.size(); i++) {
            String part = fieldParts[i];            
            if (part.endsWith('__r')) {
                relLevel++;
                if (relLevel >= 3) {
                    break;  // Stoping if it reaches 3 relationship levels
                }
            }
        }
        if (relLevel == 1) {
            system.debug(relLevel);
            if (currentValue instanceof SObject) {
                currentValue = ((SObject) currentValue).getSObject(fieldParts[0])?.get(fieldParts[1]);
            }
        } else if (relLevel == 2) {
            if (currentValue instanceof SObject) {
                currentValue = ((SObject) currentValue).getSObject(fieldParts[0])?.getSObject(fieldParts[1])?.get(fieldParts[2]);
            }
        } else if (relLevel == 3) {
            if (currentValue instanceof SObject) {
                currentValue = ((SObject) currentValue).getSObject(fieldParts[0])?.getSObject(fieldParts[1])?.getSObject(fieldParts[2])?.get(fieldParts[3]);
            }
        } else {
              system.debug('else--> '+fieldParts[0]);
            if (currentValue instanceof SObject) {
                currentValue = ((SObject) currentValue).get(fieldParts[0]);
            }
        }
    } else {
        if (currentValue instanceof SObject) {
            currentValue = ((SObject) currentValue).get(fieldParts[0]);
        }
    }
    return currentValue != null ? String.valueOf(currentValue).replaceAll('\r', '').replaceAll('\n', '') : null;
	}
    @SuppressWarnings('PMD.VariableNamingConventions,PMD.FieldNamingConventions')
    public class EndorsementResponse {
    	public Response response { get; set; }
    }
    public class Response {
        public String ErrorNumber { get; set; }
        public String ErrorMessage { get; set; }
        public String Endorsement_Number { get; set; }
        public String DCN_Number { get; set; }
        public String Status { get; set; }
        public String Policy_Number { get; set; }
        public String InwardNumber { get; set; }
    }
}