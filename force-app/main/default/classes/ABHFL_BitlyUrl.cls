/*********************************************************
*@Class        :  BitlyUrl
*@Author       :  Anjali Sharma
*@Created Date :  12/12/2023
*@Last Modified:  
*@description  :  Class for Bitly Url
*********************************************************/

public with sharing class ABHFL_BitlyUrl implements ASF_IntegrationInvocable {

    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - evaluate
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the ASF_IntegrationsController class, this method evaluates whether Statment Of Account integration should be fired or not.
    *****************************************************************************************************************/

    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRe){
        Case caseRec = [SELECT Id, CCC_External_Id__c, Source__c FROM Case WHERE Id = :caseRe.Id];
        ASF_Case_Category_Config__c accc = [SELECT Id, CCC_External_Id__c, Documentation_Type__c, Nature__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c  = :caseRec.CCC_External_Id__c ];
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = ABHFL_Constants.ERROR;
        
        if(accc.Nature__c == 'Complaint' || (accc.Nature__c == 'Query' && caseRec.Source__c == 'Email') || (accc.Nature__c == 'Request' && (caseRec.Source__c == 'Email' || (caseRec.Source__c != 'Email' && accc.Documentation_Type__c != 'Scanned')))){
            result.status = ABHFL_Constants.SUCCESS;
        }

        return  result;
    }
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        
        //Case caseRec = [SELECT Id, CCC_External_Id__c, Source__c FROM Case WHERE Id = :caseRe.Id];
        List<Case> caseRecords = new List<Case>();
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }
        Set<String> cccIds = new Set<String>();
        Map<String, ASF_Case_Category_Config__c> configIdToConfigMap = new Map<String,ASF_Case_Category_Config__c>();
        for(Case caseRec : caseRecords){
            cccIds.add(caseRec.CCC_External_Id__c);
        }
        
        for(ASF_Case_Category_Config__c cccRecord : [SELECT Id, CCC_External_Id__c, Documentation_Type__c, Nature__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c IN :cccIds ])
        {
            configIdToConfigMap.put(cccRecord.CCC_External_Id__c, cccRecord);
        }
        
        for(Case caseRec : caseRecords){
            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            result.status = ABHFL_Constants.ERROR;
            ASF_Case_Category_Config__c accc = configIdToConfigMap.get(caseRec.CCC_External_Id__c);
            if(accc.Nature__c == 'Complaint' || (accc.Nature__c == 'Query' && caseRec.Source__c == 'Email') || (accc.Nature__c == 'Request' && (caseRec.Source__c == 'Email' || (caseRec.Source__c != 'Email' && accc.Documentation_Type__c != 'Scanned')))){
                result.status = ABHFL_Constants.SUCCESS;
            }
            resultMap.put(caseRec.Id, result);
        }
        return resultMap;
    }

    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - run
    * @param integ - ASF_Integration record.
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the ASF_IntegrationsController class, this method runs the Bitly URL integration and creates Case Integration record.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integ, Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();

        List<ASF_Case_Integration__c> existingCaseIntRecords = [SELECT Id, Status__c FROM ASF_Case_Integration__c
        WHERE Case__c =:caseRec.Id 
        AND Integration_Ext_Id__c =:integ.External_Id__c ];
        if(existingCaseIntRecords.size()>0 && Schema.sObjectType.ASF_Case_Integration__c.isUpdateable()){
            for(ASF_Case_Integration__c cInt : existingCaseIntRecords){
                cInt.Status__c = ABHFL_Constants.CANCELED;
            }
            update existingCaseIntRecords;            
        }


        caseRec = [SELECT Id, CaseNumber, Business_Unit__c FROM Case WHERE Id = :caseRec.Id ];
		String longUrl = System.label.ABHFL_Base_URL_For_Bitly + caseRec.CaseNumber;
        Integer expiryDay = Integer.valueOf(System.label.ExpiryDay_For_Bitly_URL);
        String lob = caseRec.Business_Unit__c;

        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Case__c  = caseRec.Id;
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Status__c = ABHFL_Constants.PENDING;

        caseInt.Request__c  =  JSON.serialize(new BitlyRequestWrapper(longUrl, lob, expiryDay));
        caseInt.Response__c = ABHFL_Constants.WAITING_API_RESPONSE;
        if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
            insert caseInt; 
        }

        ASF_Case_Integration__c caseInt1 = [Select id, name from ASF_Case_Integration__c where id =: caseInt.Id ];

               
        Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
        caseIntOut.Business_Unit__c  = caseRec.Business_Unit__c;
        caseIntOut.Case_Integration_ID__c = caseInt1.Name;
        caseIntOut.ServiceName__c = ABHFL_Constants.BITLY_SERVICE_NAME;
        caseIntOut.Integration_Name__c  = ABHFL_Constants.BITLTY_INTEGRATION_NAME;
        caseIntOut.Request_Payload__c  =   JSON.serialize(new BitlyRequestWrapper(longUrl, lob, expiryDay));
        Database.SaveResult publishResult = EventBus.publish(caseIntOut);
        if(publishResult.isSuccess()){
            result.status = ABHFL_Constants.SUCCESS;
        }else{
            result.status = ABHFL_Constants.ERROR;
        }
        return result;
    }
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();

        Set<String> intIds = new Set<String>();
        for(Case caseRec : caseRecs){
            for(ASF_Integration__c integ : integs.get(caseRec.Id)){
                if(integ.Processing_Class__c == 'ABHFL_BitlyUrl'){
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
                        caseInt.Status__c = ABHFL_Constants.CANCELED;
                        existingCaseIntegrations.add(caseInt);
                    }
                }
            }
        }

        ASF_TriggerSkipperUtility.markTriggerRun('ASF_Case_Integration__c');
        update existingCaseIntegrations;
        ASF_TriggerSkipperUtility.resetTriggerRun('ASF_Case_Integration__c');

        //caseRec = [SELECT Id, CaseNumber, Business_Unit__c FROM Case WHERE Id = :caseRec.Id WITH SECURITY_ENFORCED];
        List<Case> caseRecords = new List<Case>();
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }

        List<ASF_Case_Integration__c> newCaseIntegrations = new List<ASF_Case_Integration__c>();
        Map<Integer, Case_Integration_Outbound__e> peMap = new Map<Integer, Case_Integration_Outbound__e>();
        Integer index = 0;
        Map<Integer, Id> indexToCaseId = new Map<Integer, Id>();
        for(Case caseRecord : caseRecords){
            String longUrl = System.label.ABHFL_Base_URL_For_Bitly + caseRecord.CaseNumber;
            Integer expiryDay = Integer.valueOf(System.label.ExpiryDay_For_Bitly_URL);
            String lob = caseRecord.Business_Unit__c;
            for(ASF_Integration__c intSpec : integs.get(caseRecord.Id))
            {
                if(intSpec.Processing_Class__c == 'ABHFL_BitlyUrl'){
                    ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
                    caseInt.Case__c  = caseRecord.Id;
                    caseInt.Integration_Ext_Id__c = intSpec.External_Id__c;
                    caseInt.Status__c = ABHFL_Constants.PENDING;

                    caseInt.Request__c  =  JSON.serialize(new BitlyRequestWrapper(longUrl, lob, expiryDay));
                    caseInt.Response__c = ABHFL_Constants.WAITING_API_RESPONSE;
                    newCaseIntegrations.add(caseInt);

                    Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
                    caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
                    //caseIntOut.Case_Integration_ID__c = caseInt1.Name;
                    caseIntOut.ServiceName__c = ABHFL_Constants.BITLY_SERVICE_NAME;
                    caseIntOut.Integration_Name__c  = ABHFL_Constants.BITLTY_INTEGRATION_NAME;
                    caseIntOut.Request_Payload__c  =   JSON.serialize(new BitlyRequestWrapper(longUrl, lob, expiryDay));
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
    * @LOB - ABHFL
    * @Function - processResponse
    * @param caseInteg - ASF_Case_Integration record.
    * @description - Invoked from the Case Integration trigger, this method processes the response of the integration received.
    *****************************************************************************************************************/
    public void processResponse(ASF_Case_Integration__c caseInteg){
        Boolean integrationFailure = true;
        Case caseRec =[SELECT Id, AccountId, No_Auto_Communication__c, ContactId, Business_Unit__c, ABHFL_Case_Detail__c, ABHFL_Case_Detail__r.STP_Failure__c, CCC_External_Id__c  FROM Case WHERE Id=:caseInteg.Case__c ];
        List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id, New_Case_Email_Template__c, New_Case_SMS_Metadata__c, Nature__c, Send_open_stage_communications__c, 
                            (select id, Status_Mapping__c, SLA_Override_Enabled__c from Case_Stage_Configs__r where Status_Mapping__c = 'In Progress')  FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c =:caseRec.CCC_External_Id__c ];
        Boolean sendCommunication = shouldSendCommunication(cccRecord[0]);

        if(caseInteg.Status__c == ABHFL_Constants.SUCCESS){
            handleSuccessResponse(sendCommunication, caseRec, cccRecord[0], caseInteg);
        }else if(sendCommunication && caseInteg.Status__c != ABHFL_Constants.PENDING){
            handleErrorResponse(sendCommunication, caseRec, cccRecord[0]); 
        }

        if(integrationFailure != caseRec.ABHFL_Case_Detail__r.STP_Failure__c){
            ABHFL_Case_Detail__c caseDetails = new ABHFL_Case_Detail__c();
            caseDetails.STP_Failure__c = integrationFailure;
            caseDetails.Id = caseRec.ABHFL_Case_Detail__c;
            if(Schema.sObjectType.ABHFL_Case_Detail__c.isUpdateable() && caseDetails.Id != null){
                update caseDetails;   
            }            
        }
    }


    private static Boolean shouldSendCommunication(ASF_Case_Category_Config__c cccRecord) {


        if(cccRecord.Send_open_stage_communications__c == true){
            return false;
        }else if(cccRecord.Nature__c == 'Complaint' && !(cccRecord.Case_Stage_Configs__r).isEmpty() && (cccRecord.Case_Stage_Configs__r)[0].SLA_Override_Enabled__c == true){
            return false;
        }
        return true;
    }


    private static void handleSuccessResponse(Boolean sendCommunication,  Case caseRec, ASF_Case_Category_Config__c cccRecord, ASF_Case_Integration__c caseInteg){
        System.debug('insiede handle success --  ');
        List<String> emailTemplates = (cccRecord.New_Case_Email_Template__c).split(',');
        List<String> smsMetadata = (cccRecord.New_Case_SMS_Metadata__c).split(',');
        
        ResponseWrapper result = (ResponseWrapper) System.JSON.deserialize(caseInteg.Response__c, ResponseWrapper.class);                        

        ABHFL_Case_Detail__c caseDetails = new ABHFL_Case_Detail__c();
        caseDetails.STP_Failure__c = false;
        caseDetails.Id = caseRec.ABHFL_Case_Detail__c;
        caseRec.Short_URL__c = result.urlReturned;

        if(Schema.sObjectType.ABHFL_Case_Detail__c.isUpdateable() && caseDetails.Id != null){
            update caseDetails;   
        }

        if(Schema.sObjectType.Case.isUpdateable()){
            update caseRec;
        }

        if(sendCommunication){
            ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRec, emailTemplates[0], smsMetadata[0], false);
        }
    }

    
    private static void handleErrorResponse(Boolean sendCommunication,  Case caseRec, ASF_Case_Category_Config__c cccRecord){
        List<String> emailTemplates = (cccRecord.New_Case_Email_Template__c).split(',');
        List<String> smsMetadata = (cccRecord.New_Case_SMS_Metadata__c).split(',');

        ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRec, emailTemplates[1], smsMetadata[1], false); 
    }


    /****************************************************************************************************************
    *@description - Wrapper class to get all the request parameters
    *****************************************************************************************************************/

    public class BitlyRequestWrapper {
        public String LongURL;
        public String LOB;
        public Integer ExpiryDay;
        // public String UserId;
        // public String Password;


        BitlyRequestWrapper(string longURL, String lob, Integer expiryDay){
            this.LongURL = longURL;
            this.LOB = System.Label.ABHFL_Bitly_LOB; // Custom Label has added for WO0000000091712 by Yogesh
            this.ExpiryDay = expiryDay;
        }
    }

    
    

    public class ResponseWrapper{
        String returnCode;
        String returnMessage;
        String urlReturned;
    }
}