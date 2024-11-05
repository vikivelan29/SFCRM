/*********************************************************
*@Class        :  ABSLI_MobileUpdateIntegration
*@Author       :  Virendra Patil
*@Created Date :  05/22/2024
*@Last Modified:  06/03/2024
*@description  :  Class for Mobile Update integration.
*********************************************************/
public without sharing class ABSLI_MobileUpdateIntegration implements ASF_IntegrationInvocable{
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
            result.response = result.response = Custom_Messages__mdt.getInstance('ABSLI_MobileUpdateIntegration_ERR1').Message__c;

            if(caseRecord.ABSLI_Case_Detail__r.Status_Valid_For_STP__c == true){
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
                if(integ.Processing_Class__c == ABSLI_MobileUpdateIntegration.class.getName()){
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


        List<Case> caseRecords = new List<Case>();
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }

        List<ASF_Case_Integration__c> newCaseIntegrations = new List<ASF_Case_Integration__c>();
        Map<Integer, Case_Integration_Outbound__e> peMap = new Map<Integer, Case_Integration_Outbound__e>();
        Integer index = 0;
        Map<Integer, Id> indexToCaseId = new Map<Integer, Id>();
        for(Case caseRecord : caseRecords){
            for(ASF_Integration__c integ : integs.get(caseRecord.Id))
            {
                if(integ.Processing_Class__c == ABSLI_MobileUpdateIntegration.class.getName()){
                    String transaction_no = String.valueOf(caseRecord.CaseNumber);
                    String source = System.label.ABSLI_ESB_SOURCE_VAL ;
                    String strClientId = String.valueOf(caseRecord.Account.Client_Code__c);
                    if(strClientId == null || strClientId == ''){
                        strClientId = String.ValueOf(caseRecord.Client_Code_Text__c);
                    }
                    String strBusiness = '';
                    String strCellularPhone = String.valueOf(caseRecord.ABSLI_Case_Detail__r.Mobile_Number__c );

                    ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
                    caseInt.Case__c  = caseRecord.Id;
                    caseInt.Integration_Ext_Id__c = integ.External_Id__c;
                    caseInt.Status__c = ABSLI_Constants.PENDING;
                    caseInt.Request__c  =  JSON.serialize(new MobileUpdateRequest(transaction_no,source,
                                                                                  strClientId, strCellularPhone,
                                                                                  'Thane'));
                    caseInt.Response__c = ABSLI_Constants.WAITING_API_RESPONSE;
                    newCaseIntegrations.add(caseInt);

                    Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
                    caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
                    //caseIntOut.Case_Integration_ID__c = caseInt1.Name;
                    caseIntOut.ServiceName__c = ABSLI_Constants.MobileUpdateSrvName;
                    caseIntOut.Integration_Name__c  = ABSLI_Constants.MobileUpdateSrvName;
                    caseIntOut.Request_Payload__c  =  JSON.serialize(new MobileUpdateRequest(transaction_no,source,
                                                                                             strClientId, strCellularPhone,
                                                                                             'Thane'));
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
        // 1. CHECK IF THE PROCESSCODE IS 00. IF 00, THAT MEANS SUCCESSFUL.
        // 2. UPDATE THE CASE TO RESOLVE STAGE.
        // 3. IF FTR COMMUNICATION
        try {
            if (caseInteg.Status__c == ABSLI_Constants.SUCCESS) {
                Case caseRecord = ABSLI_IntegrationQueryHelper.getCaseInfo(caseInteg.Case__c);

                MobileUpdateResponse jsonMap = (MobileUpdateResponse) JSON.deserialize(
                    caseInteg.Response__c,
                    MobileUpdateResponse.class
                );
                if(jsonMap.ProcessCode == '00'){
                    // TODO : Response Attribute Reference to determine

                    Boolean isTransferred = ABCL_IntegrationCommonUtility.transferAttachments(caseInteg);
                    if (isTransferred || Test.isRunningTest()) {
                        List<ASF_Case_Category_Config__c> cccRecord = [
                            SELECT
                            Id,
                            CCC_External_Id__c,
                            Resolved_Case_Email_Template__c,
                            Additional_Email_Templates__c,
                            Additional_SMS_Metadata__c,
                            Send_FTR_communications__c,
                            Resolved_Case_SMS_Metadata__c
                            FROM ASF_Case_Category_Config__c
                            WHERE CCC_External_Id__c = :caseRecord.CCC_External_Id__c
                            WITH SECURITY_ENFORCED
                        ];
                        if(cccRecord[0].Send_FTR_communications__c == true){
                            Map<String, String> emailTemplateMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(
                                cccRecord[0].Additional_Email_Templates__c
                            );
                            Map<String, String> smsMetadataMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(
                                cccRecord[0].Additional_SMS_Metadata__c
                            );

                            Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(
                                caseRecord,
                                emailTemplateMap.get('Resolved'),
                                smsMetadataMap.get('Resolved'),
                                true
                            );

                        }
                    }
                    caseRecord.MoveToNext__c = true;
                    Database.update(caseRecord, AccessLevel.SYSTEM_MODE);
                }

            }
        } catch (Exception e) {
            System.debug('@@@mess' + e.getMessage() + ' ' + e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABSLI_EmailUpdateIntegration.processResponse');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
        }
    }

    public class MobileUpdateRequest{
        public string TRANS_NO{get;set;}
        public service service{get;set;}

        public MobileUpdateRequest(String caseNum,String src,
                                   String commonClientCd, String mobileNum,
                                   String res)
        {
            this.TRANS_NO = caseNum;
            service cls = new service();
            cls.source = src;
            cls.strClientId = commonClientCd;
            cls.strCellularPhone = mobileNum;
            cls.strResidence = res;

            this.service = cls;
        }

    }
    public class service{
        public string source{get;set;}
        public string strClientId{get;set;}
        public string strBusiness{get;set;}
        public string strCellularPhone{get;set;}
        public string strEmail{get;set;}
        public string strPager{get;set;}
        public string strResidence{get;set;}
    }
    public class MobileUpdateResponse{
        public string TRANS_NO{get;set;}
        public string ProcessMessage{get;set;}
        public string ProcessCode{get;set;}
    }

}