/*********************************************************
*Class        :  ABSLAMC_UpdatesForSprinklr
*Author       :  Asmita Mathur
*Created Date :  03/10/2024
*Description  :  Class for Sprinkler Updates Integration
*********************************************************/
public with sharing class ABSLAMC_UpdatesForSprinklr implements ASF_IntegrationInvocable {
    
    public static Map<Id, String> caseLatestNotesMap = new Map<Id, String>();
/***************************************************************************************************************    
    * @LOB - ABSLAMC
    * @Function - getCaseRec
    * @param caseId - Record id of Case
    * @return - Case 
    * @Description - get case record with the case Id with all the fields which need to be populated in the request
*****************************************************************************************************************/
    
    public Case getCaseRec(String caseId){
        
        Case caseRecord = [SELECT CaseNumber, CCC_External_Id__c, Description, Source__c, Business_Unit__c, Nature__c, LAN__c,Stage__c,
                           Pending_Clarification__c, Sprinklr_Case_Reference_Number__c, Notes_from_Sprinklr__c, Latest_Notes__c,Type_Text__c,Sub_Type_Text__c,Overall_Case_Closure_SLA__c
                           FROM Case
                           WHERE Id =:caseId
        ];
        return caseRecord;
    }
        
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
    *                This method evaluates whether Sprinklr Integration should be fired or not.
*****************************************************************************************************************/
    
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
      system.debug('asmita evaluate methd class ');
      ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
      if(caseRec.Business_Unit__c == ABSLAMC_Constants.ABSLAMCBU && caseRec.Source__c == 'Social Media' && String.isNotBlank(caseRec.Sprinklr_Case_Reference_Number__c))
        {
          result.status = 'Success';
          result.response = 'Sprinklr API submitted successfully';            
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
                     This method runs the Sprinklr Integration and creates Case Integration record.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integ, Case caseRec){
        system.debug('asmita run methd class ');        
        ASF_IntegrationsController.IntegrationWrapper response = new ASF_IntegrationsController.IntegrationWrapper();
        callSprinklerApi(integ, caseRec.Id);
        
        response.status = 'Success';
        return response;

    }
/****************************************************************************************************************
    * @LOB - ABSLAMC
    * @Function - callSprinklerApi
    * @param integ - ASF_Integration record
    * @param caseRec - Case record Id 
    * @return - void
    * @Description - This method makes Callout for Sprinklr-UpdateCase Api.
*****************************************************************************************************************/
    
     public void callSprinklerApi(ASF_Integration__c integrtn, String caseId) {
        Case caseRecord = getCaseRec(caseId);
        String originalLatestNotes = String.isNotBlank(caseLatestNotesMap.get(caseId)) ? caseLatestNotesMap.get(caseId) : ''; 
        List<ASF_Case_Integration__c> existingCaseIntRecords = [SELECT Id, Status__c 
                                                                FROM ASF_Case_Integration__c
                                                                WHERE  Case__c =:caseRecord.Id
                                                                AND Integration_Ext_Id__c = 'Sprinklr-UpdateCase API' 
                                                                AND Type__c = 'SPRINKLR' WITH SECURITY_ENFORCED];

        if(existingCaseIntRecords.size()>0){
        	for(ASF_Case_Integration__c cInt : existingCaseIntRecords){
                cInt.Status__c = 'Canceled';
            }
            update existingCaseIntRecords;            
        }
        String jsonBody = generateReqBody(caseRecord, originalLatestNotes);
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Case__c  = caseRecord.Id;
        caseInt.Integration_Ext_Id__c = ABSLAMC_Constants.SPRINKLRAPI;
        caseInt.Type__c = ABSLAMC_Constants.SPRINKLR;
        caseInt.Status__c = 'Pending';
        insert caseInt;
        if(String.isNotBlank(jsonBody)) {
            firePlatformEvtForCallout(caseInt, jsonBody);
        }
    }
/****************************************************************************************************************
    * @LOB - ABSLAMC
    * @Function - generateReqBody
    * @param integ - ASF_Integration record
    * @param caseRec - Case record
    * @return - Request Body
    * @Description - This method generates request JSON body for Sprinklr-UpdateCase Api.
*****************************************************************************************************************/     
     public String generateReqBody(Case caseRecord, String caseCommentRecord) {
        Datetime SlaDt = caseRecord.Overall_Case_Closure_SLA__c;
        String formattedSLADate = SlaDt != null  ? SlaDt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') : '';
        SprinklrReqWrapper SprinklrReqWrapperObj = new SprinklrReqWrapper();      
        SprinklrReqWrapperObj.sprinklrCaseRefNo = caseRecord.Sprinklr_Case_Reference_Number__c;
        SprinklrReqWrapperObj.SFDCCaseNo = caseRecord.CaseNumber;
        SprinklrReqWrapperObj.description = caseRecord.Description; 
        SprinklrReqWrapperObj.latestNotes =  caseCommentRecord;
        SprinklrReqWrapperObj.category = caseRecord.Nature__c;
        SprinklrReqWrapperObj.type = caseRecord.Type_Text__c;
        SprinklrReqWrapperObj.subtype = caseRecord.Sub_Type_Text__c;
        SprinklrReqWrapperObj.stage = caseRecord.Stage__c;
        SprinklrReqWrapperObj.overallCaseSLA = formattedSLADate;
       
        String reqBody = JSON.serialize(SprinklrReqWrapperObj);
      
        return reqBody;
    }

/****************************************************************************************************************
    * @LOB - ABSLAMC
    * @Function - firePlatformEvtForCallout
    * @param caseInteg - ASF_Case_Integration__c record
    * @param jsonBody - JSON of Request
    * @return - void
    * @Description - This method fires Platform Event to make Callout for Sprinklr-UpdateCase Api.
*****************************************************************************************************************/ 
    
    public void firePlatformEvtForCallout(ASF_Case_Integration__c caseInteg, String jsonBody) {
        ASF_Case_Integration__c caseInt = [SELECT Name FROM ASF_Case_Integration__c WHERE Id =:caseInteg.Id];
        Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
        caseIntOut.Business_Unit__c  = ABSLAMC_Constants.ABSLAMCBU;
        caseIntOut.ServiceName__c  = null;
        caseIntOut.Case_Integration_ID__c = caseInt.Name;
        caseIntOut.Integration_Name__c  = ABSLAMC_Constants.SPRINKLRINT;
        caseIntOut.Request_Payload__c  =  jsonBody;
        Database.SaveResult publishResult = EventBus.publish(caseIntOut);
    }
    
     public class SprinklrReqWrapper{
       public string sprinklrCaseRefNo;
       public string SFDCCaseNo;
       public string description;
       public string latestNotes;
       public string category;
       public string type;
       public string subtype;
       public string stage;
       public string overallCaseSLA ;
    }

        
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){
       Map<Id, ASF_IntegrationsController.IntegrationWrapper> mapOfAsfInt = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
       for(case cs : caseRecs){
         mapOfAsfInt.put(cs.Id,evaluate(cs));   
        }
       return mapOfAsfInt;        
    
    }
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs){
       Map<Id, ASF_IntegrationsController.IntegrationWrapper> mapOfAsfInt = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        for(case cs : caseRecs){
            for(ASF_Integration__c asfInt : integs.get(cs.id)){
                if(asfInt.Processing_Class__c == 'ABSLAMC_UpdatesForSprinklr'){
                     mapOfAsfInt.put(cs.Id,run(asfInt,cs)); 
                }
            }
        }
      return mapOfAsfInt;      
    
    }
}