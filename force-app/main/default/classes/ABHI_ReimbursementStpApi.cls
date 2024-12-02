/*********************************************************
*Class        :  ABHI_ReimbursementStpApi
*Author       :  Amrit Preet Singh
*Created Date :  06/11/2024
*Last Modified:  06/11/2024
*@description  :  This class is used as the STP controller for Reimbursement Claim Intimation & Cashless Claim Intimation CTST
*********************************************************/
@SuppressWarnings('PMD.CyclomaticComplexity,PMD.CognitiveComplexity,PMD.ExcessivePublicCount,PMD.FieldNamingConventions')
public with sharing class ABHI_ReimbursementStpApi implements ASF_IntegrationInvocable{

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

     /**
    * @description Invoked from the ASF_IntegrationsController class, this method evaluates whether integration should be fired or not
    *
    * @param caseRecs - List of Case records from the evaluate method
    * @return Map<Id, ASF_IntegrationsController.IntegrationWrapper>
    */
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
            System.debug('description>>>'+caseRecord.Description);
            // if(caseRecord.ABHI_Case_Detail__r.Patient_Name__c == null || caseRecord.ABHI_Case_Detail__r.Patient_Name__c == '') {
            if(String.isBlank(caseRecord.Description)){
                bErrorOccured = true;
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
    * @param integs - List of ASF_Integration record
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
        for (Case caseRecord : caseRecords) {
           	String payload = buildPayload(caseRecord);
            System.debug('requestBody--> '+payload);
            System.debug('requestBodyss--> '+integs);
            System.debug('caseRecord.Id--> '+caseRecord.Id);
            for (ASF_Integration__c intSpec : integs.get(caseRecord.Id)) {
                System.debug('intSpec.Processing_Class__c --> '+intSpec.Processing_Class__c);
                if (intSpec.Processing_Class__c == ABHI_ReimbursementStpApi.class.getName()) {
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
                    caseIntOut.Integration_Name__c = 'ClaimIntimation';
                    caseIntOut.ServiceName__c = 'ClaimIntimation';
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
                if (integ.Processing_Class__c == ABHI_ReimbursementStpApi.class.getName()) {
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
    */
    public void processResponse(ASF_Case_Integration__c caseInteg) {
        try {
            if (caseInteg.Status__c == ABHI_Constants.SUCCESS) {
                System.debug('In Success 223');
                Case caseRecord = ABHI_IntegrationQueryHelper.getCaseInfo(caseInteg.Case__c); 
                ReimbursementResponse jsonMap = (ReimbursementResponse) JSON.deserialize(caseInteg.Response__c,ReimbursementResponse.class);
                List<sObject> dmlRecords = new List<sObject>();
                String inWardnumber = jsonMap.Claim_Number;
                System.debug('InwardNumber>>>' + inWardnumber);
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
            ABCL_Logger.push('ABHI_ReimbursementStpApi.processResponse');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
        }
    }

    /****************************************************************************************************************
    * @Function - buildPayload
    * @return String
    * @param caseRecord - caseRecord for which the payload needs to be built
    * @description This method will return the pauyload request need sto be passed to the API
    *****************************************************************************************************************/
	public static String buildPayload(Case caseRecord) {   
        ReimbursementRequest requestWrapper = new ReimbursementRequest();
        PreAuthObjWrapper patInst = new PreAuthObjWrapper();
        patInst.Policy_Number = caseRecord.Asset.Policy_No__c;
        patInst.FamilyId = caseRecord.Account.Client_Code__c;
        patInst.Cover_code = caseRecord.ABHI_Case_Detail__r.Cover_Name__r.Cover_Code__c;
        patInst.Cover_Name = caseRecord.ABHI_Case_Detail__r.Cover_Name__r.Cover_Name__c;
        patInst.Hospital_Name = caseRecord.ABHI_Case_Detail__r.Hospital__r.Provider_Name__c;
        patInst.Hospital_Code = caseRecord.ABHI_Case_Detail__r.Hospital__r.Provider_Code__c;
        patInst.Date_of_Admission = caseRecord.ABHI_Case_Detail__r.Date_of_Admission__c.format('MM/dd/yyyy');
        patInst.Time_of_Admission = caseRecord.ABHI_Case_Detail__r.Date_of_Admission__c.format('hh:mm');
        patInst.Date_of_Discharge = caseRecord.ABHI_Case_Detail__r.Date_of_Discharge__c.format('MM/dd/yyyy');
        patInst.Time_of_Discharge = caseRecord.ABHI_Case_Detail__r.Date_of_Discharge__c.format('hh:mm');
        Datetime now = Datetime.now();
        patInst.Document_Received_Date = now.format('MM/dd/yyyy');
        patInst.Document_Received_Time = now.format('hh:mm');
        patInst.Patient_Name = caseRecord.ABHI_Case_Detail__r.Patient_Name__r.Member_Name__c;
        patInst.Claim_Amount = String.valueOf(caseRecord.ABHI_Case_Detail__r.Claim_Amount__c);
        patInst.Intimation_Type = caseRecord.Type_Text__c;
        patInst.Claim_Intimation_Through = 'CRM';
        patInst.Claim_Intimation_Source = 'CRM';
        patInst.Source_System_Code = 'CRM';
        patInst.Other_Ind = caseRecord.ABHI_Case_Detail__r.Hospital__r.Provider_Name__c == 'Others' ? 'Yes' : 'No';
        patInst.Hospital_Nm = caseRecord.ABHI_Case_Detail__r.Hospital_Name__c!=null?caseRecord.ABHI_Case_Detail__r.Hospital_Name__c:caseRecord.ABHI_Case_Detail__r.Hospital__r.Provider_Name__c;
        PreexistingObjWrapper peoInst = new PreexistingObjWrapper();
        peoInst.Preexisting_Deases = '';
        peoInst.Status = '';
        peoInst.Sincewhen = '';
        peoInst.Remarks = '';
        requestWrapper.PreAuthObj = new List<PreAuthObjWrapper>();
        requestWrapper.PreAuthObj.add(patInst);
        requestWrapper.PreexistingObj = new List<PreexistingObjWrapper>();
        requestWrapper.PreexistingObj.add(peoInst);
        PCSObjWrapper pcsInst = new PCSObjWrapper();
        pcsInst.PCS_Code = '';
        requestWrapper.PCSObj = new List<PCSObjWrapper>();
        requestWrapper.PCSObj.add(pcsInst);
        ICDObjWrapper icdInst = new ICDObjWrapper();
        icdInst.ICD_Code = '';
        requestWrapper.ICDObj = new List<ICDObjWrapper>();
        requestWrapper.ICDObj.add(icdInst);
        DocObjWrapper docInst = new DocObjWrapper();
        docInst.UploadStatus = '';
        docInst.Filename = '';
        requestWrapper.DocObj = new List<DocObjWrapper>();
        requestWrapper.DocObj.add(docInst);
        return JSON.serialize(requestWrapper);
	}

    /*********************************************************
    *Class        :  ReimbursementResponse
    *Author       :  Amrit Preet Singh
    *Created Date :  06/11/2024
    *Last Modified:  06/11/2024
    *@description  : This is the wrapper class to hold the response from API
    *********************************************************/
    public class ReimbursementResponse {
        public String Code;	//101
        public String Message;	//Entered Policy Number : GHI-HB-22-2095784-V2 doesn't exists. Please check the Health Card and submit the Request again.
        public String Claim_Number;	//
        public String Pre_Auth_Id;
    }

    /*********************************************************
    *Class        :  ReimbursementResponse
    *Author       :  Amrit Preet Singh
    *Created Date :  06/11/2024
    *Last Modified:  06/11/2024
    *@description  : This is the wrapper class to hold the request for API
    *********************************************************/
    public class ReimbursementRequest{
        public List<PreAuthObjWrapper> PreAuthObj;
        public List<PreexistingObjWrapper> PreexistingObj;
        public List<PCSObjWrapper> PCSObj;
        public List<ICDObjWrapper> ICDObj;
        public List<DocObjWrapper> DocObj;
        
    }

    /*********************************************************
    *Class        :  PreAuthObjWrapper
    *Author       :  Amrit Preet Singh
    *Created Date :  06/11/2024
    *Last Modified:  06/11/2024
    *@description  : This is the wrapper class to hold inner request data for API
    *********************************************************/
    @SuppressWarnings('PMD.TooManyFields')
    public class PreAuthObjWrapper {
        public String Policy_Number;	//21-24-0000882-00
        public String FamilyId;	//PT87553252
        public String Claim_Intimation_Through;	//Online
        public String Claim_Intimation_Source;	//CUSTOMERPORTAL
        public String Intimation_Type;	//Reimbursement
        public String Cover_code;	//42214101
        public String Cover_Name;	//In-patientHospitalization
        public String Hospital_Name;	//HS00009753
        public String Hospital_Code;	//HS00009753
        public String Diagnosis;	//ok
        public String Date_of_Admission;	//8/1/2024
        public String Time_of_Admission;	//17:20
        public String Date_of_Discharge;	//8/3/2024
        public String Time_of_Discharge;	//06:00
        public String Claim_Amount;	//5000
        public String Source_System_Code;	//CUSTOMERPORTAL
        public String Document_Received_Date;	//08/19/2024
        public String Document_Received_Time;	//05:28
        public String Patient_Name;	//PrajaktaPatil
        public String Co_morbidities;	//
        public String Service_flag;	//
        public String Name_Of_Treating_Doctor;	//
        public String Doctor_Contact_No;	//
        public String Duration_Of_Present_Ailment;	//
        public String Proposed_line_of_treatment;	//
        public String Investigation_MedicalManagementDetails;	//
        public String Name_Of_Surgery;	//
        public String IRDA_Code_Of_surgery;	//
        public String How_did_injury_occur;	//
        public String Case_Of_accident;	//
        public String IsItRTA;	//
        public String Date_Of_Inhury;	//
        public String ReportedtoPolice;	//
        public String FirNo;	//
        public String Injury_Disease_Alcohalconsumption;	//
        public String IsMaternity;	//
        public String G;	//
        public String P;	//
        public String L;	//
        public String A;	//
        public String Date_Of_Delivery;	//
        public String Emergency_Planned_Event;	//
        public String Room_Type;	//
        public String DeaseasWithPresentingComplaints;	//
        public String ReleventClinicalFinding;	//
        public String DateOfFirstConsultation;	//
        public String ProvisionalDiagnosis;	//
        public String Doctor_Registration_No;	//
        public String IsPreexisting;	//
        public String IsNaturalCalamityCase;	//
        public String Test_ConductedToEstablishThis;	//
        public String AlcohalordrugAbuse;	//
        public String AnyHivorStdRelatedAilments;	//
        public String AnyOtherAilments;	//
        public String Other_Ind;	//
        public String Hospital_Nm;	//
        public String Hospital_Address;	//
        public String Hospital_Country;	//
        public String Hospital_State;	//
        public String Hospital_District;	//
        public String Hospital_City;	//
        public String Hospital_PinCode;	//
        public String Hospital_Mail;	//
        public String Hospital_StdCode;	//
        public String Hospital_PhoneNo;	//
        public String Hospital_MobileNo;	//
        public String Hospital_FaxNo;	//
        public String Hospital_WebSite;	//
        public String Hospital_LandMark;	//
    }
    /*********************************************************
    *Class        :  ReimbursementResponse
    *Author       :  Amrit Preet Singh
    *Created Date :  06/11/2024
    *Last Modified:  06/11/2024
    *@description  : This is the wrapper class to hold the response from API
    *********************************************************/
    public class PreexistingObjWrapper {
        public String Preexisting_Deases;	//
        public String Status;	//
        public String Sincewhen;	//
        public String Remarks;	//
    }
    /*********************************************************
    *Class        :  PCSObjWrapper
    *Author       :  Amrit Preet Singh
    *Created Date :  06/11/2024
    *Last Modified:  06/11/2024
    *@description  : This is the wrapper class to hold inner request data for API
    *********************************************************/
    public class PCSObjWrapper {
        public String PCS_Code;	//
    }

    /*********************************************************
    *Class        :  ICDObjWrapper
    *Author       :  Amrit Preet Singh
    *Created Date :  06/11/2024
    *Last Modified:  06/11/2024
    *@description  : This is the wrapper class to hold inner request data for API
    *********************************************************/
    public class ICDObjWrapper {
        public String ICD_Code;	//
    }

    /*********************************************************
    *Class        :  DocObjWrapper
    *Author       :  Amrit Preet Singh
    *Created Date :  06/11/2024
    *Last Modified:  06/11/2024
    *@description  : This is the wrapper class to hold inner request data for API
    *********************************************************/
    public class DocObjWrapper {
        public String UploadStatus;	//No
        public String Filename;	//
    }
}