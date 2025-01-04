/*********************************************************
*Class        :  ABSLAMC_LitmusSurveyApi
*Author       :  Santosh V
*Created Date :  03/11/2024
*Last Modified:  03/11/2024
*Description  :  Class for Litmus Integration
*********************************************************/


public with sharing class ABSLAMC_LitmusSurveyApi implements ASF_IntegrationInvocable {
    Boolean isRecursive = true;
    String allowedSources = System.label.ABSLAMC_Litmus_Allowed_Sources;
    String allowedCallertType = System.label.ABSLAMC_Litmus_Allowed_CallerTypes;
    String dataSyncUsrFedId = System.label.ABSLAMC_DataSyncUser_FederationId;

    list<String> litmusAllowedSourcesList =  allowedSources.split(';');
    list<String> litmusAllowedCallerTypesList = allowedCallertType.split(';');

    Map<Id, Account> accountMap = new Map<Id, Account>();
    Map<Id, Case> caseMap = new Map<Id, Case>();
    Map<String, ASF_Case_Category_Config__c> cccExternalCaseCategoryMap = new Map<String, ASF_Case_Category_Config__c>();
    Map<Id, List<ASF_Case_Integration__c>> caseIntegrationMap = new Map<Id, List<ASF_Case_Integration__c>>();
    
    /****************************************************************************************************************
    * @LOB - ABSLAMC
    * @Function - isAllCasesClosed
    * @param caseId - Record id of Case
    * @param accountId - Record id of Case's Account
    * @return - Case 
    * @Description - get the account info and its related cases where there are no open cases with allowed source & caller type with the passed case Id.
        retriving the case whose status is not 
    *****************************************************************************************************************/

    public boolean isAllCasesClosedFallBack(String caseId, String accountId){
        List<Account> accountWithCases = [SELECT id, 
                                        (SELECT id, CaseNumber, Status,CCC_External_Id__c, Source__c
                                        FROM Cases 
                                        WHERE Stage__c NOT IN (:ABSLAMC_Constants.RESOLVED_STAGE, :ABSLAMC_Constants.UNRESOLVED_STAGE) AND Id != :caseId) 
                                    FROM Account 
                                    WHERE Id=:accountId
                                    WITH SECURITY_ENFORCED];
        if(!accountWithCases.isEmpty() && accountWithCases[0].cases.isEmpty()){
            return true;
        }
        return false;
    }

    public void getRelatedAccounts(Set<Id> accountIds){
        accountMap = new Map<Id, Account>();

        for(Account acc : [SELECT Id, (SELECT Id, CaseNumber, Status,CCC_External_Id__c, Source__c FROM Cases WHERE Stage__c NOT IN (:ABSLAMC_Constants.RESOLVED_STAGE, :ABSLAMC_Constants.UNRESOLVED_STAGE)) FROM Account WHERE Id IN :accountIds]){
            accountMap.put(acc.Id, acc);
        }

    }

    public boolean isAllCasesClosed(Id caseId, Id accountId){
        Integer count = 0;
        if(accountMap.containsKey(accountId)){
            Account acc = accountMap.get(accountId);
            for(Case caseRecord : acc.Cases){
                if(caseRecord.Id != caseId){
                    count++;
                }
            }
        }
        else{
            return isAllCasesClosedFallBack(caseId, accountId);
        }
        return count == 0 ? true :false;
    }

    public void getCaseMapHelper(Set<Id> caseIds){
        caseMap = new Map<Id, Case>();
        
        for(Case caseRecord : [SELECT AccountId, Account.Name, Account.RecordType.Name, Account.PersonMobilePhone, Account.Phone, Account.PersonEmail, Account.Office_Email__c, Account.isPersonAccount,
        Account.PAN__c, Account.ARN_Number__c,
        CaseNumber, ABSLAMC_Case_Detail__r.Caller_Type__c, CCC_External_Id__c, Type_Text__c, Sub_Type_Text__c, Source__c, Business_Unit__c, Nature__c,
        createdBy.Name, createdDate, ClosedDate, owner.name, LAN__c, FTR__c, Ageing_Number_Of_Days__c, Status, Stage__c, isClosed,LOB__c,Channel__c, CreatedById, OnCreateCloseSR__c
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
        Case caseRecord = [
            SELECT AccountId, Account.Name, Account.RecordType.Name, Account.PersonMobilePhone, Account.Phone, Account.PersonEmail, Account.Office_Email__c, Account.isPersonAccount,
                    Account.PAN__c, Account.ARN_Number__c,
                    CaseNumber, ABSLAMC_Case_Detail__r.Caller_Type__c, CCC_External_Id__c, Type_Text__c, Sub_Type_Text__c, Source__c, Business_Unit__c, Nature__c,
                    createdBy.Name, createdDate, ClosedDate, owner.name, LAN__c, FTR__c, Ageing_Number_Of_Days__c, Status, Stage__c, isClosed,LOB__c,Channel__c, CreatedById, OnCreateCloseSR__c
            FROM Case
            WHERE Id =:caseId
        ];
        return caseRecord;
    }

    public void getCCCMapHelper(Set<String> cccExternalIds){
        cccExternalCaseCategoryMap = new Map<String, ASF_Case_Category_Config__c>();
        for(ASF_Case_Category_Config__c temp : [SELECT Litmus_Trigger__c, Litmus_Project__c, Overall_Case_Closure_SLA__c, CCC_External_Id__c FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c IN :cccExternalIds AND Litmus_Trigger__c = true WITH SECURITY_ENFORCED]){
            cccExternalCaseCategoryMap.put(temp.CCC_External_Id__c, temp);
        }
    }

    public ASF_Case_Category_Config__c getCCC(String cccExternalId){
        if(cccExternalCaseCategoryMap.containsKey(cccExternalId)){
            return cccExternalCaseCategoryMap.get(cccExternalId);
        }
        else{
            return getCCCFallback(cccExternalId);
        }
    }

    public ASF_Case_Category_Config__c getCCCFallback(String cccExternalId){
        list<ASF_Case_Category_Config__c> cccList = [
            SELECT Litmus_Trigger__c, Litmus_Project__c, Overall_Case_Closure_SLA__c, CCC_External_Id__c
            FROM ASF_Case_Category_Config__c
            WHERE CCC_External_Id__c =:cccExternalId AND Litmus_Trigger__c = true WITH SECURITY_ENFORCED
        ];
        if(!cccList.isEmpty()){
            return cccList[0];
        }
        return null;
    }

    /****************************************************************************************************************
    * @LOB - ABSLAMC
    * @Function - evaluate
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @Description - Invoked from the ASF_IntegrationsController class, this method evaluates whether Litmus Integration should fired or not.
    *****************************************************************************************************************/

    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){  // configure the query field on the stage which are needed....
        Case caseDetails = getCaseRec(caseRec.Id);
        boolean allCasesClosed = isAllCasesClosed(caseDetails.Id, caseDetails.AccountId);
        ASF_Case_Category_Config__c cccRec = getCCC(caseDetails.CCC_External_Id__c);

        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = 'Error';
        System.debug('all cases.. '+allCasesClosed);
        System.debug('caseDetails.Stage__c '+caseDetails.Stage__c);
        System.debug('caseDetails.ABSLAMC_Case_Detail__r.Caller_Type__c '+caseDetails.ABSLAMC_Case_Detail__r.Caller_Type__c);
        System.debug('caseDetails.source__c ' +caseDetails.source__c);
        System.debug('cccRec => '+cccRec);

        if( allCasesClosed && cccRec!=null && caseDetails.Stage__c == ABSLAMC_Constants.RESOLVED_STAGE
            && litmusAllowedCallerTypesList.contains( caseDetails.ABSLAMC_Case_Detail__r.Caller_Type__c) 
            && allowedSources.contains(caseDetails.source__c) )
        {
            result.status = 'Success';
            result.response = 'Litmus Api submitted successfully';
        }
        System.debug('from evaluate -> result => '+result);
        return result;

    }

    /****************************************************************************************************************
    * @LOB - ABSLAMC
    * @Function - run
    * @param integ - ASF_Integration record.
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @Description - Invoked from the ASF_IntegrationsController class, this method runs the Litmus Integration and creates Case Integration record.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integ, Case caseRec){ // configure the query field on the stage which are needed....
        
        ASF_IntegrationsController.IntegrationWrapper response = new ASF_IntegrationsController.IntegrationWrapper();
        if(isRecursive) {
            callLitmusApi(integ, caseRec.Id);
            response.status = 'Success';
        }
        return response;
    }

    public void getCaseIntegrationMap(Set<Id> caseIds){
        caseIntegrationMap = new Map<Id, List<ASF_Case_Integration__c>>();

        for(ASF_Case_Integration__c caseInt : [SELECT Id, Status__c, Case__c FROM ASF_Case_Integration__c
                                            WHERE Case__c IN :caseIds
                                            AND Integration_Ext_Id__c = 'ABSLAMC Litmus Api' and Type__c = 'Litmus' WITH SECURITY_ENFORCED]){

            List<ASF_Case_Integration__c> caseIntegrationRecordsTemp = new List<ASF_Case_Integration__c>();
            if(caseIntegrationMap.containsKey(caseInt.Case__c)){
                caseIntegrationRecordsTemp = caseIntegrationMap.get(caseInt.Case__c);
            }
            caseIntegrationRecordsTemp.add(caseInt);
            caseIntegrationMap.put(caseInt.Case__c, caseIntegrationRecordsTemp);
        }
            
        
    }


    // @Description - Callout for Litmus Integration.
    public void callLitmusApi(ASF_Integration__c integrtn, String caseId) {

        Case caseRecord = getCaseRec(caseId); 
        ASF_Case_Category_Config__c cccRec = caseRecord!=null ?  getCCC(caseRecord.CCC_External_Id__c) : null;

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

        String jsonBody = generateReqBody(caseRecord, cccRec);
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Case__c  = caseRecord.Id;
        caseInt.Integration_Ext_Id__c = 'ABSLAMC Litmus Api';
        caseInt.Type__c = 'Litmus';
        caseInt.Status__c = 'Pending';
        insert caseInt;

        if(String.isNotBlank(jsonBody)) {
            firePlatformEvtForCallout(caseInt, jsonBody);
        }

        isRecursive = false;
    }

     /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - processResponse
    * @param caseInteg - ASF_Case_Integration record.
    * @return - void.
    * @Description - Invoked from the Case Integration trigger, this method processes the response of the integration received.
    *****************************************************************************************************************/
    public void processResponse(ASF_Case_Integration__c caseInt){
        
    }

    // @Description - Firing Platform Event to make Callout for Litmus Api.
    public void firePlatformEvtForCallout(ASF_Case_Integration__c caseInteg, String jsonBody) {

        ASF_Case_Integration__c caseInt = [Select Name from ASF_Case_Integration__c where id =: caseInteg.Id];
        
        Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
        caseIntOut.Business_Unit__c  = 'ABSLAMC';
        caseIntOut.ServiceName__c  = 'Litmus Survey';
        caseIntOut.Case_Integration_ID__c = caseInt.Name;
        caseIntOut.Integration_Name__c  = 'Litmus';
        caseIntOut.Request_Payload__c  =  jsonBody;
        Database.SaveResult publishResult = EventBus.publish(caseIntOut);
    }

   

     // @Description - Preparing JSON body for Litmus Api.
    public String generateReqBody(Case caseRecord, ASF_Case_Category_Config__c cccRecord) {
        Account caseAccount = caseRecord.Account;

        String userPhne = '';
        String userEml = '';
        String ftrOrNFTRVal = caseRecord.FTR__c == true ? 'FTR' : 'NFTR';
        String accountRecordTypeName = caseAccount.RecordType.Name;
        
        Boolean isDistributor = accountRecordTypeName.contains(ABSLAMC_Constants.ABSLAMC_DISTRIBUTOR_STRING);
        
        List<Contact> con = [SELECT Id, Email FROM Contact WHERE AccountId=:caseAccount.Id  WITH SECURITY_ENFORCED LIMIT 1];

        userPhne = caseAccount.isPersonAccount ?  caseAccount.PersonMobilePhone : caseAccount.Phone;
        //userEml  = accountRecordTypeName  == 'Individual' ?  caseAccount.PersonEmail : caseAccount.Office_Email__c;
        userEml  = caseAccount.isPersonAccount ?  caseAccount.PersonEmail : (con.size()>0?con[0].Email:'');

        ABCL_LitmusSurveyWrapper litmusApiWrappObj = new ABCL_LitmusSurveyWrapper();
        /**
         * Branch - 0xzr_touchpoint
            Email – Call Centre- 15kk_touchpoint
            Phone - Call Centre - 9nu0_touchpoint
         */

        List<ABSLAMC_Litmus_AppId_Metadata__mdt> litmusAppIdMdtList = new List<ABSLAMC_Litmus_AppId_Metadata__mdt>();

        litmusAppIdMdtList = [SELECT MasterLabel, Source__c, Channel__c, AppId__c
                              FROM ABSLAMC_Litmus_AppId_Metadata__mdt
                              WHERE Source__c =:caseRecord.Source__c
                              AND Channel__c =:caseRecord.Channel__c];

        String appid = litmusAppIdMdtList.size() > 0 ? litmusAppIdMdtList[0].AppId__c : '';
        
        litmusApiWrappObj.app_id = appid;
        litmusApiWrappObj.user_phone = userPhne;
        litmusApiWrappObj.user_email = userEml;
        litmusApiWrappObj.tag_sub_type = caseRecord.Sub_Type_Text__c;
        litmusApiWrappObj.name = caseAccount.Name;
        litmusApiWrappObj.tag_case_number = caseRecord.CaseNumber;
        litmusApiWrappObj.tag_case_type = caseRecord.Type_Text__c;
        litmusApiWrappObj.tag_sla_deadline = String.valueOf(cccRecord.Overall_Case_Closure_SLA__c);
        litmusApiWrappObj.tag_category = caseRecord.Nature__c;
        litmusApiWrappObj.tag_created_by = caseRecord.createdBy.Name;
        litmusApiWrappObj.tag_created_on = String.valueOf(caseRecord.createdDate);
        litmusApiWrappObj.tag_source = caseRecord.Channel__c;
        litmusApiWrappObj.tag_resolved_on = String.valueOf(caseRecord.ClosedDate);
        litmusApiWrappObj.tag_owner = caseRecord.owner.name;
        litmusApiWrappObj.tag_loan_account_no = caseRecord.LAN__c;
        litmusApiWrappObj.tag_ftr_nftr = ftrOrNFTRVal;
        litmusApiWrappObj.tag_ageing = String.valueOf(caseRecord.Ageing_Number_Of_Days__c);


        litmusApiWrappObj.panorarn = isDistributor ? caseAccount.ARN_Number__c : caseAccount.PAN__c;
        litmusApiWrappObj.caller_type = caseRecord.ABSLAMC_Case_Detail__r.Caller_Type__c;
        litmusApiWrappObj.lob = caseRecord.LOB__c;
        litmusApiWrappObj.type = isDistributor ? ABSLAMC_Constants.ABSLAMC_DISTRIBUTOR_STRING : ABSLAMC_Constants.ABSLAMC_CUSTOMER_STRING;

        String reqBody = JSON.serialize(litmusApiWrappObj);

        return reqBody;
    }


    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> integrationWrapperMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        List<Case> newList = new List<Case>();
        Set<Id> userIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<String> cccExternalIds = new Set<String>();
        Set<Id> caseIds = new Set<Id>();

        for(Case cs : caseRecs){
            userIds.add(cs.CreatedById);
        }
        Map<Id, User> userMap = new Map<Id,User>();
        for(User u : [SELECT Id, FederationIdentifier FROM User where Id IN: userIds]){
            userMap.put(u.Id, u);
        }
        for(Case cs : caseRecs){
            if(!(cs.OnCreateCloseSR__c == true && String.isNotBlank(userMap.get(cs.CreatedById).FederationIdentifier) && userMap.get(cs.CreatedById).FederationIdentifier == dataSyncUsrFedId)){
                newList.add(cs);
                if(cs.AccountId!= null){
                    accountIds.add(cs.AccountId);
                    
                }
                if(cs.CCC_External_Id__c!= null){
                    cccExternalIds.add(cs.CCC_External_Id__c);
                }
                if(cs.Id!= null){
                    caseIds.add(cs.Id);
                }
            }
        }

        getRelatedAccounts(accountIds);
        getCCCMapHelper(cccExternalIds);
        getCaseMapHelper(caseIds);

        for(case cs : newList){
            integrationWrapperMap.put(cs.Id,evaluate(cs));   
        }
        return integrationWrapperMap;
    }

    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs){
       Map<Id, ASF_IntegrationsController.IntegrationWrapper> integrationWrapperMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();

       Set<Id> accountIds = new Set<Id>();
       Set<String> cccExternalIds = new Set<String>();
       Set<Id> caseIds = new Set<Id>();

       for(Case cs : caseRecs){
            if(cs.AccountId!= null){
                accountIds.add(cs.AccountId);
                
            }
            if(cs.CCC_External_Id__c!= null){
                cccExternalIds.add(cs.CCC_External_Id__c);
            }
            if(cs.Id!= null){
                caseIds.add(cs.Id);
            }
        }

        getRelatedAccounts(accountIds);
        getCCCMapHelper(cccExternalIds);
        getCaseMapHelper(caseIds);

        for(case cs : caseRecs){
            for(ASF_Integration__c asfIntObj : integs.get(cs.id)){
                if(asfIntObj.Processing_Class__c == 'ABSLAMC_LitmusSurveyApi'){
                    integrationWrapperMap.put(cs.Id,run(asfIntObj,cs));
               } 
                
            }
        }
        
        return integrationWrapperMap;
        
    
    }
        
}