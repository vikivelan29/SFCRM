/*********************************************************
*@Class        :  ABHFL_SOAIntegration
*@Author       :  Anjali Sharma
*@Created Date :  12/12/2023
*@Last Modified:  
*@description  :  Class for SOA Integration
*********************************************************/
public with sharing class ABHFL_SOAIntegration implements ASF_IntegrationInvocable { 


    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - evaluate
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the ASF_IntegrationsController class, this method evaluates whether Statment Of Account integration should be fired or not.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = ABHFL_Constants.ERROR;
        //Error Message when evaluation is failed.
        result.response = Custom_Messages__mdt.getInstance('SOA_EVALUATION_FAILED_DATE_ERROR').Message__c;

        Case caseRecord = [
            SELECT Id,Stage__c, Asset.LAN__c, ABHFL_Case_Detail__r.From_Date__c, ABHFL_Case_Detail__r.To_Date__c, ABHFL_Case_Detail__r.STP_Request_Type__c
            FROM Case
            WHERE Id =: caseRec.Id 
        ];

         //Checking for mandatory API conditions
        if(String.isNotBlank(caseRecord.Asset.LAN__c) && caseRecord.ABHFL_Case_Detail__r.From_Date__c != null && caseRecord.ABHFL_Case_Detail__r.To_Date__c != null && caseRecord.ABHFL_Case_Detail__r.STP_Request_Type__c == 'Email'){
            result.status = ABHFL_Constants.SUCCESS;
            result.response = Custom_Messages__mdt.getInstance('SOA_EVALUATION_SUCCESS_RESPONSE').Message__c;
         }

        if(caseRecord.ABHFL_Case_Detail__r.STP_Request_Type__c == ABHFL_Constants.STP_REQUEST_TYPE_DOWNLOAD){
            caseRecord.Stage__c = ABHFL_Constants.RESOLVED;
            if(Schema.sObjectType.Case.isUpdateable()){
                update caseRecord;
            }
            return new ASF_IntegrationsController.IntegrationWrapper();
        }

         return  result;
    }
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        
        // Case caseRecord = [
        //     SELECT Id, Asset.LAN__c, ABHFL_Case_Detail__r.From_Date__c, ABHFL_Case_Detail__r.To_Date__c, ABHFL_Case_Detail__r.STP_Request_Type__c
        //     FROM Case
        //     WHERE Id =: caseRec.Id 
        // ];
        List<Case> caseRecords = new List<Case>();
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }
		//List<Case> downloadStpCases = new List<Case>();
        for(Case caseRecord : caseRecords){
            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            result.status = ABHFL_Constants.ERROR;
            //Error Message when evaluation is failed.
            result.response = Custom_Messages__mdt.getInstance('SOA_EVALUATION_FAILED_DATE_ERROR').Message__c;

            //Checking for mandatory API conditions
            if(String.isNotBlank(caseRecord.Asset.LAN__c) && caseRecord.ABHFL_Case_Detail__r.From_Date__c != null && caseRecord.ABHFL_Case_Detail__r.To_Date__c != null && caseRecord.ABHFL_Case_Detail__r.STP_Request_Type__c == 'Email'){
                result.status = ABHFL_Constants.SUCCESS;
                result.response = Custom_Messages__mdt.getInstance('SOA_EVALUATION_SUCCESS_RESPONSE').Message__c;
            }
            if(caseRecord.ABHFL_Case_Detail__r.STP_Request_Type__c == ABHFL_Constants.STP_REQUEST_TYPE_DOWNLOAD){
                /*caseRecord.Stage__c = ABHFL_Constants.RESOLVED;
                if(Schema.sObjectType.Case.isUpdateable()){
                   // downloadStpCases.add(caseRecord);
                    //update caseRecord;
                
                //result.status = ABHFL_Constants.Success;
                }
               // result = new ASF_IntegrationsController.IntegrationWrapper();
                //return new ASF_IntegrationsController.IntegrationWrapper();*/
               Case updatedCase = new Case(Id=caseRecord.Id);
                updatedCase.Stage__c = ABHFL_Constants.RESOLVED;    
                result.updatedCase = updatedCase;
            }
            resultMap.put(caseRecord.Id, result);
        }
        /*if(downloadStpCases.size()>0){
            update downloadStpCases;
        }*/
        return resultMap;
    }

    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - run
    * @param integ - ASF_Integration record.
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the ASF_IntegrationsController class, this method runs the Statment Of Account integration and creates Case Integration record.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integ, Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
		List<ASF_Case_Integration__c> existingCaseIntRecords = [SELECT Id, Status__c FROM ASF_Case_Integration__c
                                                               WHERE Case__c =:caseRec.Id 
                                                               AND Integration_Ext_Id__c =:integ.External_Id__c ];
        if(existingCaseIntRecords.size()>0){
        	for(ASF_Case_Integration__c cInt : existingCaseIntRecords){
                cInt.Status__c = ABHFL_Constants.CANCELED;
            }
            if(Schema.sObjectType.ASF_Case_Integration__c.isUpdateable()){
                update existingCaseIntRecords;     
            }       
        }

        Case caseRecord = [SELECT Id, caseNumber, Business_Unit__c, Asset.LAN__c, ABHFL_Case_Detail__r.To_Date__c, ABHFL_Case_Detail__r.From_Date__c  FROM Case where Id =: caseRec.Id ];
        

        String toDate = DateTime.newInstance((caseRecord.ABHFL_Case_Detail__r.To_Date__c).year(),(caseRecord.ABHFL_Case_Detail__r.To_Date__c).month(),(caseRecord.ABHFL_Case_Detail__r.To_Date__c).day()).format('dd-MM-YYYY');
        String fromDate = DateTime.newInstance((caseRecord.ABHFL_Case_Detail__r.From_Date__c).year(),(caseRecord.ABHFL_Case_Detail__r.From_Date__c).month(),(caseRecord.ABHFL_Case_Detail__r.From_Date__c).day()).format('dd-MM-YYYY');

        
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Case__c  = caseRec.Id;
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Status__c = ABHFL_Constants.PENDING;
        caseInt.Request__c  =  JSON.serialize(new SOARequestWrapper(caseRecord.Asset.Lan__c, toDate, fromDate, caseRecord.caseNumber));
        caseInt.Response__c = ABHFL_Constants.WAITING_API_RESPONSE;
        if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
            insert caseInt;
        }

        ASF_Case_Integration__c caseInt1 = [Select id, name from ASF_Case_Integration__c where id =: caseInt.Id ];
       
        Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
        caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
        caseIntOut.Case_Integration_ID__c = caseInt1.Name;
        caseIntOut.Integration_Name__c  = ABHFL_Constants.SOA_INTEGRATION_NAME;
        caseIntOut.ServiceName__c = ABHFL_Constants.REPORTING_SERVICE;
        caseIntOut.Request_Payload__c  =  JSON.serialize(new SOARequestWrapper(caseRecord.Asset.Lan__c, toDate, fromDate, caseRecord.caseNumber));
        Database.SaveResult publishResult = EventBus.publish(caseIntOut);
        if(publishResult.isSuccess()){
            result.status = ABHFL_Constants.SUCCESS;
            result.response = Custom_Messages__mdt.getInstance('SOA_RUN_SUCCESS').Message__c;
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
                if(integ.Processing_Class__c == 'ABHFL_SOAIntegration'){
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


        //Case caseRecord = [SELECT Id, caseNumber, Business_Unit__c, Asset.LAN__c, ABHFL_Case_Detail__r.To_Date__c, ABHFL_Case_Detail__r.From_Date__c  FROM Case where Id =: caseRec.Id ];
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
                if(integ.Processing_Class__c == 'ABHFL_SOAIntegration'){
                    String toDate = DateTime.newInstance((caseRecord.ABHFL_Case_Detail__r.To_Date__c).year(),(caseRecord.ABHFL_Case_Detail__r.To_Date__c).month(),(caseRecord.ABHFL_Case_Detail__r.To_Date__c).day()).format('dd-MM-YYYY');
                    String fromDate = DateTime.newInstance((caseRecord.ABHFL_Case_Detail__r.From_Date__c).year(),(caseRecord.ABHFL_Case_Detail__r.From_Date__c).month(),(caseRecord.ABHFL_Case_Detail__r.From_Date__c).day()).format('dd-MM-YYYY');

            
                    ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
                    caseInt.Case__c  = caseRecord.Id;
                    caseInt.Integration_Ext_Id__c = integ.External_Id__c;
                    caseInt.Status__c = ABHFL_Constants.PENDING;
                    caseInt.Request__c  =  JSON.serialize(new SOARequestWrapper(caseRecord.Asset.Lan__c, toDate, fromDate, caseRecord.caseNumber));
                    caseInt.Response__c = ABHFL_Constants.WAITING_API_RESPONSE;
                    newCaseIntegrations.add(caseInt);

                    Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
                    caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
                    //caseIntOut.Case_Integration_ID__c = caseInt1.Name;
                    caseIntOut.Integration_Name__c  = ABHFL_Constants.SOA_INTEGRATION_NAME;
                    caseIntOut.ServiceName__c = ABHFL_Constants.REPORTING_SERVICE;
                    caseIntOut.Request_Payload__c = JSON.serialize(new SOARequestWrapper(caseRecord.Asset.Lan__c, toDate, fromDate, caseRecord.caseNumber));

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
                wrap.status = Custom_Messages__mdt.getInstance('SOA_RUN_SUCCESS').Message__c;
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
        Boolean isTransferred = False;

        if(caseInteg.Status__c == ABHFL_Constants.SUCCESS){
            isTransferred = ABCL_IntegrationCommonUtility.transferAttachments(caseInteg);
        }

        Case caseRec =[SELECT Id, No_Auto_Communication__c, CreatedById, Source__c, OwnerId, status,  AccountId,ContactId,CCC_External_Id__c, MoveToNext__c,Attachment_Status__c, ABHFL_Case_Detail__r.STP_Failure__c   
                           FROM Case WHERE Id=:caseInteg.Case__c ];

        if(caseInteg.Status__c == ABHFL_Constants.SUCCESS && caseRec != null && isTransferred ){  
            handleSuccessfullTransfer(caseRec);
        }else if(caseInteg.Status__c != ABHFL_Constants.CANCELED && caseInteg.Status__c != ABHFL_Constants.PENDING) {
            handleUnsuccessfullTransfer(caseRec);
        }
        if(isTransferred == caseRec.ABHFL_Case_Detail__r.STP_Failure__c){
            ABHFL_Case_Detail__c caseDetails = new ABHFL_Case_Detail__c();
            caseDetails.STP_Failure__c = !isTransferred;
            caseDetails.Id = caseRec.ABHFL_Case_Detail__c;

            if(Schema.sObjectType.ABHFL_Case_Detail__c.isUpdateable()){
                update caseDetails;   
            }            
        }

        ABCL_IntegrationCommonUtility.updateErrorMessage(caseInteg);
    }



    private void handleSuccessfullTransfer(Case caserec){
        List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id, CCC_External_Id__c, Resolved_Case_Email_Template__c, Additional_SMS_Metadata__c, Additional_Email_Templates__c, 
        Resolved_Case_SMS_Metadata__c FROM ASF_Case_Category_Config__c
        WHERE CCC_External_Id__c =:caseRec.CCC_External_Id__c ];

        Map<String, String> emailTemplateMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_Email_Templates__c);
        Map<String, String> smsMetadataMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_SMS_Metadata__c);


        ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRec, emailTemplateMap.get('Resolved'), smsMetadataMap.get('Resolved'), true);

        caseRec.MoveToNext__c = true;
        caseRec.Attachment_Status__c = ABHFL_Constants.COMPLETED;
        caseRec.Stage__c = ABHFL_Constants.RESOLVED;
        if(Schema.sObjectType.Case.isUpdateable()){
            update caseRec;  
        }
    }


    private void handleUnsuccessfullTransfer(Case caseRec){
        if(caseRec.Source__c ==  ABHFL_Constants.BRANCH){
            if(caseRec.OwnerId != caseRec.CreatedById && Schema.sObjectType.Case.isUpdateable()){
                caseRec.OwnerId = caseRec.CreatedById;
                update caseRec;
                ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRec,'SOA',null);
            }
        } else {
            Group csQueue = [SELECT Id FROM Group WHERE Type =:ABHFL_Constants.QUEUE AND DeveloperName =:ABHFL_Constants.ABHFL_CUSTOMER_SERVICE_TEAM  Limit 1];
            caseRec.OwnerId = csQueue.Id;
            if(Schema.sObjectType.Case.isUpdateable()){
                update caseRec;
            }                
        }  
    }


/****************************************************************************************************************
    *@description - Wrapper class to get all the request parameters
*****************************************************************************************************************/

    public class SOARequestWrapper{

        public string lan;
        public String toDate;
        public String fromDate;
        public String caseId;
        public String souce = ABHFL_Constants.SOA_SOURCE;
        public String requestType = ABHFL_Constants.SOA_REQUEST_TYPE;
        public String reportName = ABHFL_Constants.SOA_REPORT_NAME;
        public String documentType = ABHFL_Constants.SOA_DOCUMENT_TYPE;
        
        SOARequestWrapper(string lanNo, String toDate, String fromDate, String caseId){
            this.lan = lanNo;
            this.toDate = toDate;
            this.fromDate = fromDate;
            this.caseId = caseId;
        }
    }
}
