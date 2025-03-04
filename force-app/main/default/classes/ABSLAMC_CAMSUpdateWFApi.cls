/*********************************************************
*Class        :  ABSLAMC_CAMSUpdateWFApi
*Author       :  Asmita Mathur
*Created Date :  03/11/2024
*Last Modified:  03/11/2024
*Description  :  Class for CAMS Update Workflow Integration
*********************************************************/

public with sharing class ABSLAMC_CAMSUpdateWFApi implements ASF_IntegrationInvocable{


    Map<Id, Case> caseMap = new Map<Id, Case>();
    Map<Id, ABSLAMC_Case_Detail__c> caseDetailMap = new Map<Id, ABSLAMC_Case_Detail__c>();
    Map<Id, List<ASF_Case_Integration__c>> caseIntegrationMap = new Map<Id, List<ASF_Case_Integration__c>>();



/***************************************************************************************************************    
    * @LOB - ABSLAMC
    * @Function - getCaseRec
    * @param caseId - Record id of Case
    * @return - Case 
    * @Description - get case record with the case Id with all the fields which need to be populated in the request
*****************************************************************************************************************/

    public void getCaseMapHelper(Set<Id> caseIds){
        caseMap = new Map<Id, Case>();
        
        for(Case caseRecord : [ SELECT CaseNumber, CCC_External_Id__c, Source__c, Business_Unit__c, Nature__c, LAN__c,Stage__c,
        Pending_Clarification__c, LOB__c
        FROM Case
        WHERE Id IN :caseIds]){
            caseMap.put(caseRecord.Id, caseRecord);
        }
    }

    public Case getCaseRec(String caseId){
        if(caseMap.containsKey(caseId)){
            return caseMap.get(caseId);
        }
        else{
            return getCaseRecFallback(caseId);
        }
    }

    public Case getCaseRecFallback(String caseId){
        
        Case caseRecord = [SELECT CaseNumber, CCC_External_Id__c, Source__c, Business_Unit__c, Nature__c, LAN__c,Stage__c,
                           Pending_Clarification__c, LOB__c
                           FROM Case
                           WHERE Id =:caseId
        ];
        return caseRecord;
    }



/***************************************************************************************************************    
    * @LOB - ABSLAMC - END
    * @Function - getCaseRec
    * @param caseId - Record id of Case
    * @return - Case 
    * @Description - get case record with the case Id with all the fields which need to be populated in the request
*****************************************************************************************************************/



/****************************************************************************************************************  
    * @LOB - ABSLAMC
    * @Function - getCaseDetail
    * @param caseId - Record id of Case
    * @return - ABSLAMC_Case_Detail__c 
    * @Description - get the ABSLAMC_Case_Detail__c record with the case Id passed as param
*****************************************************************************************************************/
    

    public void getCaseDetailMapHelper(Set<Id> caseIds){
        caseDetailMap = new Map<Id, ABSLAMC_Case_Detail__c>();
        
        for(ABSLAMC_Case_Detail__c caseDetail : [ SELECT Id, Name, CAMS_Ticket_Reference_Number__c,CAMS_Ticket_Status__c,
        Note_For_CAMS__c,Critical_Request__c, Additional_Remarks_for_CAMS__c,
        Reply_Type_for_CAMS__c, (SELECT Id FROM Cases__r) 
        FROM ABSLAMC_Case_Detail__c 
        WHERE Id IN (SELECT ABSLAMC_Case_Detail__c FROM CASE WHERE Id IN :caseIds)]){
            caseDetailMap.put(caseDetail.Cases__r[0].Id, caseDetail);
        }
    }

    public ABSLAMC_Case_Detail__c getCaseDetail(String caseId){
        if(caseDetailMap.containsKey(caseId)){
            return caseDetailMap.get(caseId);
        }
        else{
            return getCaseDetailFallback(caseId);
        }
    }
    public ABSLAMC_Case_Detail__c getCaseDetailFallback(String caseId){
        
        ABSLAMC_Case_Detail__c caseDetail =  [SELECT Id, Name, CAMS_Ticket_Reference_Number__c,CAMS_Ticket_Status__c,
                                              Note_For_CAMS__c,Critical_Request__c, Additional_Remarks_for_CAMS__c,
                                              Reply_Type_for_CAMS__c
                                              FROM ABSLAMC_Case_Detail__c 
                                              WHERE Id IN (SELECT ABSLAMC_Case_Detail__c FROM CASE WHERE Id = :caseId)];
                                              
       return caseDetail;
    }


/****************************************************************************************************************  
    * @LOB - ABSLAMC - END
    * @Function - getCaseDetail
    * @param caseId - Record id of Case
    * @return - ABSLAMC_Case_Detail__c 
    * @Description - get the ABSLAMC_Case_Detail__c record with the case Id passed as param
*****************************************************************************************************************/
    

/****************************************************************************************************************
    * @LOB - ABSLAMC
    * @Function - processResponse
    * @param caseInteg - ASF_Case_Integration record.
    * @return - void
    * @Description - Invoked from the Case Integration trigger, this method processes the response of the integration received.
*****************************************************************************************************************/  
    public void processResponse(ASF_Case_Integration__c caseInt){
        
    }
/****************************************************************************************************************
    * @LOB - ABSLAMC
    * @Function - evaluate
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @Description - Invoked from the ASF_IntegrationsController class, 
    *                This method evaluates whether CAMS Integration should be fired or not.
*****************************************************************************************************************/
	public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){

        ABSLAMC_Case_Detail__c caseDetailRec = getCaseDetail(caseRec.Id);
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        if(caseRec.Business_Unit__c == ABSLAMC_Constants.ABSLAMCBU && String.isNotBlank(caseDetailRec.CAMS_Ticket_Reference_Number__c) && 
          ((caseRec.Stage__c == ABSLAMC_Constants.CAMSPENDINGSTATUS && caseRec.Pending_Clarification__c == true)
           || caseRec.Stage__c == ABSLAMC_Constants.RESOLVED_STAGE ) && caseDetailRec.CAMS_Ticket_Status__c == ABSLAMC_Constants.CAMSOPENSTATUS)
        {
          result.status = 'Success';
          result.response = 'CAMS Api - UpdateWorkflow submitted successfully';            
        }
        return result;
	}
   /****************************************************************************************************************
    * @LOB - ABSLAMC
    * @Function - run
    * @param integ - ASF_Integration record.
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @Description - Invoked from the ASF_IntegrationsController class, 
                     This method runs the CAMS Integration and creates Case Integration record.
    *****************************************************************************************************************/
	public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integ, Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper response = new ASF_IntegrationsController.IntegrationWrapper();
        callCAMSUpdateWFApi(integ, caseRec.Id);
        response.status = 'Success';
        return response;
    }

    public void getCaseIntegrationMap(Set<Id> caseIds){
        caseIntegrationMap = new Map<Id, List<ASF_Case_Integration__c>>();

        for(ASF_Case_Integration__c caseInt : [SELECT Id, Status__c, Case__c 
                        FROM ASF_Case_Integration__c
                        WHERE Case__c IN :caseIds
                        AND Integration_Ext_Id__c = 'ABSLAMC CAMS-UpdateWF API' 
                        AND Type__c = 'CAMS' WITH SECURITY_ENFORCED]){

            List<ASF_Case_Integration__c> caseIntegrationRecordsTemp = new List<ASF_Case_Integration__c>();
            if(caseIntegrationMap.containsKey(caseInt.Case__c)){
                caseIntegrationRecordsTemp = caseIntegrationMap.get(caseInt.Case__c);
            }
            caseIntegrationRecordsTemp.add(caseInt);
            caseIntegrationMap.put(caseInt.Case__c, caseIntegrationRecordsTemp);
        }
            
        
    }

/****************************************************************************************************************
    * @LOB - ABSLAMC
    * @Function - callCAMSCreateWFApi
    * @param integ - ASF_Integration record
    * @param caseRec - Case record Id 
    * @return - void
    * @Description - This method makes Callout for CAMS-UpdateWorkflow Api.
*****************************************************************************************************************/    
    public void callCAMSUpdateWFApi(ASF_Integration__c integrtn, String caseId) {
        Case caseRecord = getCaseRec(caseId);
        ABSLAMC_Case_Detail__c caseDetailRecord = getCaseDetail(caseId);

        List<ASF_Case_Integration__c> existingCaseIntRecords = new List<ASF_Case_Integration__c>();

        if(caseIntegrationMap.containsKey(caseId)){
            existingCaseIntRecords = caseIntegrationMap.get(caseId);
        }

        if(existingCaseIntRecords.size()>0){
        	for(ASF_Case_Integration__c cInt : existingCaseIntRecords){
                cInt.Status__c = 'Canceled';
            }
            update existingCaseIntRecords;            
        }
        String jsonBody = generateReqBody(caseRecord, caseDetailRecord);
        
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Case__c  = caseRecord.Id;
        caseInt.Integration_Ext_Id__c = ABSLAMC_Constants.CAMSUPDATEWFAPI;
        caseInt.Type__c = ABSLAMC_Constants.CAMS;
        caseInt.Status__c = 'Pending';
        insert caseInt;
        if(String.isNotBlank(jsonBody)) {
            firePlatformEvtForCallout(caseInt, jsonBody);
        }

    }
/****************************************************************************************************************
    * @LOB - ABSLAMC
    * @Function - generateReqBody
    * @param caseRec - Case record
    * @param caseDetail - ABSLAMC_Case_Detail__c
    * @return - Request Body
    * @Description - This method generates request JSON body for CAMS-UpdateWorkflow Api.
*****************************************************************************************************************/  
    public String generateReqBody(Case caseRecord, ABSLAMC_Case_Detail__c caseDetail) {
        
        CAMSUpdateWfReqWrapper CAMSUpdateWfReqWrapperObj = new CAMSUpdateWfReqWrapper();
        CAMSUpdateWfReqWrapperObj.msgCompStatus = caseRecord.Stage__c != 'Resolved' ? '' : 'Y';
        CAMSUpdateWfReqWrapperObj.messageID = caseDetail.CAMS_Ticket_Reference_Number__c;
        CAMSUpdateWfReqWrapperObj.msgCurrStatus = caseDetail.Additional_Remarks_for_CAMS__c;
         if(caseDetail.Reply_Type_for_CAMS__c != 'S'){
        CAMSUpdateWfReqWrapperObj.interimReply = caseDetail.Reply_Type_for_CAMS__c;
        }
        //CAMSUpdateWfReqWrapperObj.interimReply = caseDetail.Reply_Type_for_CAMS__c;
        CAMSUpdateWfReqWrapperObj.talismaID = caseRecord.CaseNumber;
        CAMSUpdateWfReqWrapperObj.lob = caseRecord.LOB__c;
        
        String reqBody = JSON.serialize(CAMSUpdateWfReqWrapperObj);
      
        return reqBody;
    }

/****************************************************************************************************************
    * @LOB - ABSLAMC
    * @Function - firePlatformEvtForCallout
    * @param caseInteg - ASF_Case_Integration__c record
    * @param jsonBody - JSON of Request
    * @return - void
    * @Description - This method fires Platform Event to make Callout for CAMS-CreateWorkflow Api.
*****************************************************************************************************************/        
    public void firePlatformEvtForCallout(ASF_Case_Integration__c caseInteg, String jsonBody) {

        ASF_Case_Integration__c caseInt = [Select Name from ASF_Case_Integration__c where id =: caseInteg.Id];
        Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
        caseIntOut.Business_Unit__c  = ABSLAMC_Constants.ABSLAMCBU;
        caseIntOut.ServiceName__c  = null;
        caseIntOut.Case_Integration_ID__c = caseInt.Name;
        caseIntOut.Integration_Name__c  = ABSLAMC_Constants.UPDATEWFINT;
        caseIntOut.Request_Payload__c  =  jsonBody;
        Database.SaveResult publishResult = EventBus.publish(caseIntOut); 

    }
    
     public class CAMSUpdateWfReqWrapper{
		public string messageID;
        public string msgCurrStatus;
        public string interimReply;
        public string msgCompStatus;
        public string talismaID; 
        public string lob;       
    }

    
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> mapOfAsfInt = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();

        Set<Id> caseIds = new Set<Id>();

        for(Case tempCaseRecord : caseRecs){
            caseIds.add(tempCaseRecord.Id);
        }
        getCaseDetailMapHelper(caseIds);
        getCaseMapHelper(caseIds);
        for(case cs : caseRecs){
         mapOfAsfInt.put(cs.Id,evaluate(cs));   
        }
        return mapOfAsfInt;
    }
    
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs){
         Map<Id, ASF_IntegrationsController.IntegrationWrapper> mapOfAsfInt = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        
        Set<Id> caseIds = new Set<Id>();

        for(Case tempCaseRecord : caseRecs){
            caseIds.add(tempCaseRecord.Id);
        }
        getCaseDetailMapHelper(caseIds);
        getCaseMapHelper(caseIds);
        getCaseIntegrationMap(caseIds);

        for(case cs : caseRecs){
            for(ASF_Integration__c asfInt : integs.get(cs.id)){
               if(asfInt.Processing_Class__c == 'ABSLAMC_CAMSUpdateWFApi'){
                     mapOfAsfInt.put(cs.Id,run(asfInt,cs)); 
               } 
            }
        }
        
        return mapOfAsfInt;
    }


}