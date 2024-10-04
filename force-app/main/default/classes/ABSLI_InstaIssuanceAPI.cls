/*********************************************************
*@Class        :  ABSLI_InstaIssuanceAPI
*@Author       :  Laxman R
*@Created Date :  07/02/2024
*@Last Modified:  07/04/2024
*@description  :  Class for Insta Issuance API integration.
*********************************************************/
public without sharing class ABSLI_InstaIssuanceAPI implements ASF_IntegrationInvocable{
    /****************************************************************************************************************
* @LOB - ABSLI
* @Function - evaluate
* @param caseRec - Case record from the framework.
* @return - ASF_IntegrationsController.IntegrationWrapper.
* @description - Invoked from the ASF_IntegrationsController class, this method evaluates whether Amortization integration should be fired or not.
*****************************************************************************************************************/

    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){

        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result = evaluate(new List<Case>{caseRec}).get(caseRec.Id);

        return result;
    }

    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        System.debug(caseRecs);
        List<Case> caseRecords = new List<Case>();
        for(Case caseRec : caseRecs){
            System.debug(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }

        System.debug('@@caseRecords --> '+caseRecords);

        for(Case caseRecord : caseRecords){
            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            result.status = ABSLI_Constants.ERROR;
            result.response = result.response = Custom_Messages__mdt.getInstance('ABSLI_INSTAISSURANCE_FAILURE_MESSAGE').Message__c;

            if(caseRecord != null){
                result.status = ABSLI_Constants.SUCCESS;
            }
            resultMap.put(caseRecord.Id, result);
            System.debug('@@@resultMap VP---> '+resultMap);
        }

        return resultMap;
    }

    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integ, Case caseRec){

        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result = run(new Map<Id, List<ASF_Integration__c>>{caseRec.Id => new List<ASF_Integration__c>{integ}}, new List<Case>{caseRec}).get(caseRec.Id);

        return result;
    }
    /****************************************************************************************************************
* @LOB - ABSLI
* @Function - run
* @param intSpec - Integration record from the framework.
* @param caseRec - Case record from the framework.
* @return - ASF_IntegrationsController.IntegrationWrapper.
* @description - Invoked from the ASF_IntegrationsController class, this method runs the Amortization integration and creates Case Integration record.
*****************************************************************************************************************/

    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
       
        Set<String> intIds = new Set<String>();
        for(Case caseRec : caseRecs){
            for(ASF_Integration__c integ : integs.get(caseRec.Id)){
                if(integ.Processing_Class__c == ABSLI_InstaIssuanceAPI.class.getName()){
                    intIds.add(integ.External_Id__c);
                }
            }
        }
		
        List<ASF_Case_Integration__c> existingCaseIntegrations = new List<ASF_Case_Integration__c>();
        for(ASF_Case_Integration__c caseInt : [SELECT Id, Status__c, Case__c, Integration_Ext_Id__c FROM ASF_Case_Integration__c
                                               WHERE Case__c IN :caseRecs
                                               AND Integration_Ext_Id__c IN :intIds])
        {
            if(integs.containsKey(caseInt.Case__c)){
                for(ASF_Integration__c integ : integs.get(caseInt.Case__c))
                {
                    if(integ.External_Id__c == caseInt.Integration_Ext_Id__c && caseInt.Status__c == ABHFL_Constants.PENDING){
                        caseInt.Status__c = ABSLI_Constants.CANCELED;
                        existingCaseIntegrations.add(caseInt);
                    }
                }
            }
        }

        ASF_TriggerSkipperUtility.markTriggerRun('ASF_Case_Integration__c');
        update existingCaseIntegrations;
        ASF_TriggerSkipperUtility.resetTriggerRun('ASF_Case_Integration__c');
		
        String caseconfigPPCChangeType;
        String caseconfigPPCSubType;
		Set<String> externalIds = new Set<String>();
        List<Case> caseRecords = new List<Case>();
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
            externalIds.add(caseRec.CCC_External_Id__c);
        }
        for(ASF_Case_Category_Config__c casecateconfigobj : [SELECT Id, Is_FTR_Journey__c, Nature__c, Product__c, Source__c, 
                                    							Type__c, Sub_Type__c, Business_Unit__c, CCC_External_Id__c,
                                                             	PPC_Change_Type__c,PPC_Case_Sub_TYPE__c
                                   								FROM ASF_Case_Category_Config__c 
                                                                WHERE CCC_External_Id__c IN :externalIds WITH SYSTEM_MODE])
        {
           caseconfigPPCChangeType =  casecateconfigobj.PPC_Change_Type__c;
            System.debug('changeType::'+casecateconfigobj.PPC_Change_Type__c);
           caseconfigPPCSubType =  casecateconfigobj.PPC_Case_Sub_TYPE__c;
        }

        List<ASF_Case_Integration__c> newCaseIntegrations = new List<ASF_Case_Integration__c>();
        Map<Integer, Case_Integration_Outbound__e> peMap = new Map<Integer, Case_Integration_Outbound__e>();
        Integer index = 0;
        Map<Integer, Id> indexToCaseId = new Map<Integer, Id>();
        for(Case caseRecord : caseRecords){
            for(ASF_Integration__c integ : integs.get(caseRecord.Id))
            {
                if(integ.Processing_Class__c == ABSLI_InstaIssuanceAPI.class.getName()){
                    String case_no = String.valueOf(caseRecord.CaseNumber);
                    String source = caseRecord.Source__c;//System.label.ABSLI_ESB_SOURCE_VAL ;
                    String applicationnumber = '';
                    String caseRemarks = '';
                    String caseOwner = '';
                    if(String.isNotblank(caseRecord.AssetId)/*caseRecord.AssetId != null && caseRecord.AssetId != ''*/){
                         applicationnumber = String.valueOf(caseRecord.Asset.Application_Number__c);
                    }
                    String policynumber;
                    if(String.isNotblank(caseRecord.AssetId)/*caseRecord.AssetId != null && caseRecord.AssetId != ''*/){
                         policynumber = String.valueOf(caseRecord.Asset.Policy_No__c);
                    }
                    else if(caseRecord.LAN__c != null && caseRecord.LAN__c != '' && caseRecord.LAN__c != 'NA'){
                         policynumber = String.valueOf(caseRecord.LAN__c);
                    }
                    
                    if(caseRecord.ABSLI_Case_Detail__r.RCA_Comments__c != null){
                        caseRemarks = caseRecord.ABSLI_Case_Detail__r.RCA_Comments__c;
                    }
                    caseOwner = caseRecord.Owner.Name;
                    
                    ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
                    caseInt.Case__c  = caseRecord.Id;
                    caseInt.Integration_Ext_Id__c = integ.External_Id__c;
                    caseInt.Status__c = ABSLI_Constants.PENDING;
                    //caseInt.Request__c  =  JSON.serialize(new InstaIssuanceRequestWrapper(source,case_no,
                                                                                  //applicationnumber, policynumber,
                                                                                  //caseconfigPPCChangeType,caseconfigPPCSubType,caseRemarks,caseOwner));
                    caseInt.Request__c  =  JSON.serialize(new InstaIssuanceRequestWrapper(source,case_no,
                                                                                  applicationnumber, policynumber,
                                                                                  caseconfigPPCChangeType,caseconfigPPCSubType,caseRemarks,caseOwner));

                    caseInt.Response__c = ABSLI_Constants.WAITING_API_RESPONSE;
                    newCaseIntegrations.add(caseInt);

                    Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
                    caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
                    //caseIntOut.Case_Integration_ID__c = caseInt1.Name;
                    caseIntOut.ServiceName__c = ABSLI_Constants.InstaIssuranceAPI;
                    caseIntOut.Integration_Name__c  = ABSLI_Constants.InstaIssuranceAPI;
                    //caseIntOut.Request_Payload__c  =  JSON.serialize(new InstaIssuanceRequestWrapper(source,case_no,
                    //                                                              applicationnumber, policynumber,
                    //                                                              caseconfigPPCChangeType,caseconfigPPCSubType,caseRemarks,caseOwner));
                    caseIntOut.Request_Payload__c  =  JSON.serialize(new InstaIssuanceRequestWrapper(source,case_no,
                                                                                  applicationnumber, policynumber,
                                                                                  caseconfigPPCChangeType,caseconfigPPCSubType,caseRemarks,caseOwner));
                    peMap.put(index, caseIntOut);
                    indexToCaseId.put(index, caseRecord.Id);
                    index++;
                }
            }
        }

        index = 0;

        if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
            List<Database.SaveResult> results = Database.insert(newCaseIntegrations, false);
            Map<Id, ASF_Case_Integration__c> caseIntegrations = new Map<Id, ASF_Case_Integration__c>([SELECT Name, Case__c FROM ASF_Case_Integration__c WHERE Id IN :newCaseIntegrations ]);
            for(Database.SaveResult sr : results){
                if(sr.isSuccess()){
                    Case_Integration_Outbound__e caseIntOut = peMap.get(index);
                    caseIntOut.Case_Integration_ID__c = caseIntegrations.get(sr.getId()).Name;
                    peMap.put(index, caseIntOut);
                }else{
                    ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
                    wrap.status = ABHFL_Constants.ERROR;
                    resultMap.put(indexToCaseId.get(index), wrap);
                    peMap.remove(index);
                    indexToCaseId.remove(index);
                }
                index++;
            }
        }

        List<Database.SaveResult> publishResults = EventBus.publish(peMap.values());
        index = 0;
        for(Database.SaveResult publishResult : publishResults){
            if(publishResult.isSuccess()){
                ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
                wrap.status = ABHFL_Constants.SUCCESS;
                wrap.response = Custom_Messages__mdt.getInstance('REKYC_RUN_SUCCESS').Message__c;
                resultMap.put(indexToCaseId.values()[index], wrap);
            }else{
                ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
                wrap.status = ABHFL_Constants.ERROR;
                resultMap.put(indexToCaseId.values()[index], wrap);
            }
            index++;
        }

        return resultMap;
    }
    /****************************************************************************************************************
* @LOB - ABSLI
* @Function - processResponse
* @param caseInteg - ASF_Case_Integration record.
* @description - Invoked from the Case Integration trigger, this method processes the response of the integration received.
*****************************************************************************************************************/
 public void processResponse(ASF_Case_Integration__c caseInteg){
        try {
            if (caseInteg.Status__c == ABSLI_Constants.SUCCESS) {
                Case caseRecord = ABSLI_IntegrationQueryHelper.getCaseInfo(caseInteg.Case__c);

                InstaIssuanceResponseWrapper jsonMap = (InstaIssuanceResponseWrapper) JSON.deserialize(
                    caseInteg.Response__c,
                    InstaIssuanceResponseWrapper.class
                );

            }
        } catch (Exception e) {
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABSLI_EmailUpdateIntegration.processResponse');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
        }
    }

   public class InstaIssuanceRequestWrapper {
        public InstaIssuanceRequest instaIssuanceReq;
        
        public InstaIssuanceRequestWrapper(String Source, String Casenumber, String Applicationnumber, String PolicyNo,
                                           String ChangeType, String SubType, String caseRemarks,String caseOwner) {
                                               InstaIssuanceRequest req = new InstaIssuanceRequest();
                                               req.Source = Source;
                                               req.CRM_Case_Id = Casenumber;
                                               req.Application_No = Applicationnumber;
                                               if(PolicyNo != null && PolicyNo != ''){
                                                 req.Policy_No = PolicyNo;  
                                               }
                                               req.PPC_Change_Type = ChangeType;
                                               req.PPC_Case_Sub_TYPE = SubType;
                                               req.Remarks = caseRemarks;
                                               req.Case_Owner = caseOwner;
                                               
                                               this.instaIssuanceReq = req;
                                           }
    }
    
    public class InstaIssuanceRequest {
        public String Source;            // Emails
        public String CRM_Case_Id;       // CAS-30406222-D9K4C4
        public String Application_No='';    // BAP0062543
        public String Policy_No = '';         // 009465256
        public String PPC_Change_Type;   // Change_In_Owner
        public String PPC_Case_Sub_TYPE; // PPC_CLIENT_LEVEL
        public String Case_Owner;        // IN462273
        public String Remarks;           // Hi Team, As per client consent please process for Address update for Applicate Number - 009465256/BAP0062543
        public String URL1 = '';              //
        public String URL2 ='';              //
        public String URL3 = '';              //
        public String URL4 = '';              //
        public Cls_Case_Addl_Info[] Case_Addl_Info = new List<Cls_Case_Addl_Info>();
    }
    
    public class Cls_Case_Addl_Info {
        // Define the properties of Cls_Case_Addl_Info here
    }
    
    public class InstaIssuanceResponseWrapper{
        public InstaIssuanceResponseSuccess ressuccess;
        public InstaIssuanceResponseError reserror;
    }
    public class InstaIssuanceResponseSuccess {
        public String code;	//200
        public String CASE_ID;	//53
        public String descstr;	//Case Successfully processed.
    }
    public class InstaIssuanceResponseError {
        public String code;	//202
        public String descstr;	//Invalid Input values, one of the mandatory vlues are blank-[Source,CRM_Case_Id,Application_No,Policy_No,PPC_Change_Type,PPC_Case_Sub_TYPE].
    }
    

}