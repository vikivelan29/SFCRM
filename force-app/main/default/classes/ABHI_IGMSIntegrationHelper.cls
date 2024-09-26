public with sharing class ABHI_IGMSIntegrationHelper {
    
      public static void createRegisterComplaintRequest(List<Case> caseRecords,
                                                      Map<Id, List<ASF_Integration__c>> integs,
                                                      Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap)
    {
        cancelPendingCaseIntegrationRequests(integs, caseRecords, ABHI_RegisterIGMSComplaintIntegration.class.getName());
        
        List<ASF_Case_Integration__c> newCaseIntegrations = new List<ASF_Case_Integration__c>();
        Map<Integer, Case_Integration_Outbound__e> peMap = new Map<Integer, Case_Integration_Outbound__e>();
        Integer index = 0;
        Map<Integer, Id> indexToCaseId = new Map<Integer, Id>();
        
        for (Case caseRecord : caseRecords) {
            String policyNumberText = '';
            List<ABHI_RegisterIGMSComplaintIntegration.objReq> lstRequest = new List<ABHI_RegisterIGMSComplaintIntegration.objReq>();
            if (caseRecord.Technical_Source__c == 'API') {
                policyNumberText = caseRecord.AssetId != null
                    ? caseRecord.Asset.Policy_No__c
                    : caseRecord.LAN__c;
            } else {
                policyNumberText = caseRecord.AssetId != null ? caseRecord.Asset.Policy_No__c : '';
            }
            
            ABHI_RegisterIGMSComplaintIntegration.objReq requestJSON = new ABHI_RegisterIGMSComplaintIntegration.objReq();
            
            /* ALL REQUIRED ATTRIBUTES HERE */
            requestJSON.First_Name = caseRecord.Account.FirstName+''+caseRecord.Account.LastName;
            //requestJSON.LastName = caseRecord.Account.LastName;
            String gender = caseRecord.Account?.PersonGenderIdentity;
            // SEND O-OTHER WHEN NOT EQUALS M/F
            requestJSON.Sex = ABSLI_Constants.validGenders.contains(gender)? gender : 'O';
            
            String addr = caseRecord.Account?.Street_Address_1__c;
            requestJSON.Address1 = (addr != null && addr != '')?addr : 'Not Available';
            
            Date birthDate = caseRecord.Account?.PersonBirthdate;
            requestJSON.Date_Of_Birth = birthDate != null ? ABCL_IntegrationCommonUtility.dateFormat(birthDate, 'dd-MM-YYYY') : null;
            requestJSON.Entity_Complaint_Ref_Number = 'ABHI'+caseRecord.CaseNumber;
            requestJSON.Complaint_Details = caseRecord.Description.left(4000);
            requestJSON.Complaint_Date = ABCL_IntegrationCommonUtility.dateFormat(System.today(), 'dd-MM-YYYY');
            requestJSON.Complaint_Receipt_Date = ABCL_IntegrationCommonUtility.dateFormat(Date.ValueOf(caseRecord.CreatedDate), 'dd-MM-YYYY');
            //requestJSON.Policy_Type_Id = caseRecord.ABHI_Case_Detail__r.IGMS_type_of_policy__c;
            requestJSON.Policy_Type_Id = '5';
            requestJSON.Complaint_Type_Id = caseRecord.IGMS_Complaint_Type_Code__c;
            requestJSON.Complaint_Description_Id = caseRecord.CCC_External_Id__c;
            
            String complaintSource = caseRecord.ABHI_Case_Detail__r?.IGMS_Source_of_Complaint__c;
            requestJSON.Source_Of_Complaint = (complaintSource != null && complaintSource != '')?complaintSource:'';
            
            String receiptNo = caseRecord.ABHI_Case_Detail__r?.Receipt_Number__c;
            // IF RECEIPT NUMBER IS NOT PRESENT THEN SEND (.) AS VALUE, OTHERWISE SEND ACTUAL VALUE
            requestJSON.Receipt_Number = (receiptNo != null && receiptNo !='')?receiptNo:'.';
            requestJSON.Policy_Number = policyNumberText;
            requestJSON.Policy_Proposal_Cert_ClaimNumber = policyNumberText;
            
            String mobileNo = caseRecord.Account?.PersonMobilePhone;
            requestJSON.Mobile_Number = (mobileNo != null && mobileNo != '')?mobileNo:'';
            
            
            
            
            string requestBody = JSON.serialize(requestJSON);
            
            for (ASF_Integration__c intSpec : integs.get(caseRecord.Id)) {
                System.debug('intSpec.Processing_Class__c --> '+intSpec.Processing_Class__c);
                if (intSpec.Processing_Class__c == ABHI_RegisterIGMSComplaintIntegration.class.getName()) {
                    ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
                    caseInteg.Integration_Ext_Id__c = intSpec.External_Id__c;
                    caseInteg.Case__c = caseRecord.Id;
                    caseInteg.Status__c = ABSLI_Constants.PENDING;
                    caseInteg.Request__c = requestBody;
                    caseInteg.Response__c = ABSLI_Constants.WAITING_API_RESPONSE;
                    caseInteg.Is_Validation_Success__c = true;
                    newCaseIntegrations.add(caseInteg);
                    
                    Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e();
                    caseIntOut.Business_Unit__c = caseRecord.Business_Unit__c;
                    caseIntOut.Request_Payload__c = requestBody;
                    caseIntOut.Integration_Name__c = ABSLI_Constants.IGMS_REGCOMPLAINT_SRV_NAME;
                    caseIntOut.ServiceName__c = ABSLI_Constants.IGMS_REGCOMPLAINT_SRV_NAME;
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
    }
    public static void createAckComplaintRequest(List<Case> caseRecords,
                                                 Map<Id, List<ASF_Integration__c>> integs,
                                                 Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap)
    {
        cancelPendingCaseIntegrationRequests(integs, caseRecords, ABHI_AckIGMSComplaintIntegration.class.getName());
        List<ASF_Case_Integration__c> newCaseIntegrations = new List<ASF_Case_Integration__c>();
        Map<Integer, Case_Integration_Outbound__e> peMap = new Map<Integer, Case_Integration_Outbound__e>();
        Integer index = 0;
        Map<Integer, Id> indexToCaseId = new Map<Integer, Id>();
        
        for (Case caseRecord : caseRecords) {
            String policyNumberText = '';
            ABHI_AckIGMSComplaintIntegration.objReq requestJSON = new ABHI_AckIGMSComplaintIntegration.objReq();
            
            /* ALL REQUIRED ATTRIBUTES HERE */
            requestJSON.Entity_Complaint_Ref_Number = 'ABHI'+caseRecord.CaseNumber;
            requestJSON.IRDAI_Token_Number = caseRecord.IRDAI_Token_Number__c;
            requestJSON.IRDA_Token_Number = caseRecord.IRDAI_Token_Number__c;
            
            string requestBody = JSON.serialize(requestJSON);
            
            for (ASF_Integration__c intSpec : integs.get(caseRecord.Id)) {
                System.debug('intSpec.Processing_Class__c --> '+intSpec.Processing_Class__c);
                if (intSpec.Processing_Class__c == ABHI_AckIGMSComplaintIntegration.class.getName()) {
                    ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
                    caseInteg.Integration_Ext_Id__c = intSpec.External_Id__c;
                    caseInteg.Case__c = caseRecord.Id;
                    caseInteg.Status__c = ABSLI_Constants.PENDING;
                    caseInteg.Request__c = requestBody;
                    caseInteg.Response__c = ABSLI_Constants.WAITING_API_RESPONSE;
                    caseInteg.Is_Validation_Success__c = true;
                    newCaseIntegrations.add(caseInteg);
                    
                    Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e();
                    caseIntOut.Business_Unit__c = caseRecord.Business_Unit__c;
                    caseIntOut.Request_Payload__c = requestBody;
                    caseIntOut.Integration_Name__c = ABSLI_Constants.IGMS_UPDATECOMPLAINT_SRV_NAME;
                    caseIntOut.ServiceName__c = ABSLI_Constants.IGMS_UPDATECOMPLAINT_SRV_NAME;
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
    }
    public static void createPendingComplaintRequest(List<Case> caseRecords,
                                                     Map<Id, List<ASF_Integration__c>> integs,
                                                     Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap)
    {
        cancelPendingCaseIntegrationRequests(integs, caseRecords, ABHI_PendingIGMSComplaintIntegration.class.getName());
        List<ASF_Case_Integration__c> newCaseIntegrations = new List<ASF_Case_Integration__c>();
        Map<Integer, Case_Integration_Outbound__e> peMap = new Map<Integer, Case_Integration_Outbound__e>();
        Integer index = 0;
        Map<Integer, Id> indexToCaseId = new Map<Integer, Id>();
        
        for (Case caseRecord : caseRecords) {
            String policyNumberText = '';
            ABHI_PendingIGMSComplaintIntegration.objReq requestJSON = new ABHI_PendingIGMSComplaintIntegration.objReq();
            
            /* ALL REQUIRED ATTRIBUTES HERE */
            requestJSON.Entity_Complaint_Ref_Number = 'ABHI'+caseRecord.CaseNumber;
            requestJSON.IRDAI_Token_Number = caseRecord.IRDAI_Token_Number__c;
            requestJSON.IRDA_Token_Number = caseRecord.IRDAI_Token_Number__c;
            
            string requestBody = JSON.serialize(requestJSON);
            
            for (ASF_Integration__c intSpec : integs.get(caseRecord.Id)) {
                System.debug('intSpec.Processing_Class__c --> '+intSpec.Processing_Class__c);
                if (intSpec.Processing_Class__c == ABHI_PendingIGMSComplaintIntegration.class.getName()) {
                    ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
                    caseInteg.Integration_Ext_Id__c = intSpec.External_Id__c;
                    caseInteg.Case__c = caseRecord.Id;
                    caseInteg.Status__c = ABSLI_Constants.PENDING;
                    caseInteg.Request__c = requestBody;
                    caseInteg.Response__c = ABSLI_Constants.WAITING_API_RESPONSE;
                    caseInteg.Is_Validation_Success__c = true;
                    newCaseIntegrations.add(caseInteg);
                    
                    Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e();
                    caseIntOut.Business_Unit__c = caseRecord.Business_Unit__c;
                    caseIntOut.Request_Payload__c = requestBody;
                    caseIntOut.Integration_Name__c = ABSLI_Constants.IGMS_UPDATECOMPLAINT_SRV_NAME;
                    caseIntOut.ServiceName__c = ABSLI_Constants.IGMS_UPDATECOMPLAINT_SRV_NAME;
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
    }

    
    /**
* @description Before Initiating new Integration callout, cancel existing running request
*
* @param integs - List of Integration configs
* @param caseRecs - List of Case record from the framework
*/
    public static void cancelPendingCaseIntegrationRequests(Map<Id, List<ASF_Integration__c>> integs, 
                                                            List<Case> caseRecs,
                                                            String runningClassName) 
    {
        Set<String> intIds = new Set<String>();
        for (Case caseRec : caseRecs) {
            for (ASF_Integration__c integ : integs.get(caseRec.Id)) {
                if (integ.Processing_Class__c == runningClassName) {
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
}