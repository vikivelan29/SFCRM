/*********************************************************
*Class        :  ABHFL_LitmusApi
*Author       :  Anirudh Raturi
*Created Date :  03/11/2024
*Last Modified:  03/11/2024
*Description  :  Class for Litmus Integration
*********************************************************/

public with sharing class ABHFL_LitmusApi implements ASF_IntegrationInvocable {

    public static boolean isRecursive = true;

    public Case getCaseRec(String caseId){
        Case caseRecord = [
            SELECT AccountId, Account.Name, Account.RecordType.Name, Account.PersonMobilePhone, Account.Phone, Account.PersonEmail, Account.Office_Email__c,
                    CaseNumber, Recategorisation_Reason__c,Overall_Case_Closure_SLA__c, CCC_External_Id__c, Type_Text__c, Sub_Type_Text__c, Source__c, Business_Unit__c, Nature__c,
                    createdBy.Name, createdDate, ClosedDate, owner.name, LAN__c, FTR__c, Ageing_Number_Of_Days__c, Status
            FROM Case
            WHERE Id =:caseId
        ];
        return caseRecord;
    }

    public List<ASF_Case_Category_Config__c> getCCC(String cccExternalId){
        
        List<ASF_Case_Category_Config__c> cccRecordList = [
            SELECT Litmus_Trigger__c, Litmus_Project__c, Overall_Case_Closure_SLA__c,Business_Unit__c, CCC_External_Id__c
            FROM ASF_Case_Category_Config__c
            WHERE CCC_External_Id__c =:cccExternalId
        ];
        return cccRecordList;
    }
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - evaluate
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @Description - Invoked from the ASF_IntegrationsController class, this method evaluates whether Litmus Integration should be fired or not.
    *****************************************************************************************************************/

    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        
        String caseRecId = '';
        Boolean litmusTrigger = false;
        String bussUnit = '';
        String nature = '';
        String cccExternalId = '';
        String litmusProject = '';
        String caseStatus = '';
        String subtype = caseRec.Sub_Type_Text__c;

        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = 'Error';

        caseRecId = caseRec.Id;
        Case caseRecord = getCaseRec(caseRecId);
        caseStatus = caseRecord.Status;
        ASF_Case_Category_Config__c cccRec = getCCC(caseRecord.CCC_External_Id__c).size() > 0 ? getCCC(caseRecord.CCC_External_Id__c)[0] : new ASF_Case_Category_Config__c();
        litmusTrigger = cccRec.Litmus_Trigger__c;
        litmusProject = String.isNotBlank(cccRec.Litmus_Project__c) ? cccRec.Litmus_Project__c : '';
        bussUnit = String.isNotBlank(cccRec.Business_Unit__c) ? cccRec.Business_Unit__c : '';
        cccExternalId = String.isNotBlank(cccRec.CCC_External_Id__c) ? cccRec.CCC_External_Id__c : '';
        nature = caseRec.Nature__c;

        if(litmusTrigger == true && bussUnit == 'ABHFL' && caseStatus == 'Resolved' && litmusProject != '') {
            result.status = 'Success';
            result.response = 'Litmus Api submitted successfully';
        }

        return result;
    }

    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - run
    * @param integ - ASF_Integration record.
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @Description - Invoked from the ASF_IntegrationsController class, this method runs the Litmus Integration and creates Case Integration record.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integ, Case caseRec){
        
        ASF_IntegrationsController.IntegrationWrapper response = new ASF_IntegrationsController.IntegrationWrapper();
        if(isRecursive) {
            callLitmusApi(integ, caseRec.Id);
            response.status = 'Success';
        }
        return response;
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

    // @Description - Callout for Litmus Integration.
    public void callLitmusApi(ASF_Integration__c integrtn, String caseId) {

        Case caseRecord = getCaseRec(caseId); 
        String caseSubType = caseRecord.Sub_Type_Text__c;
        ASF_Case_Category_Config__c cccRec = getCCC(caseRecord.CCC_External_Id__c).size() > 0 ? getCCC(caseRecord.CCC_External_Id__c)[0] : new ASF_Case_Category_Config__c();

        List<ASF_Case_Integration__c> existingCaseIntRecords = [SELECT Id, Status__c FROM ASF_Case_Integration__c
                                                               WHERE Case__c =:caseRecord.Id
                                                               AND Integration_Ext_Id__c = 'ABHFL Litmus Api' and Type__c = 'Litmus' WITH SECURITY_ENFORCED];

        if(existingCaseIntRecords.size()>0){
        	for(ASF_Case_Integration__c cInt : existingCaseIntRecords){
                cInt.Status__c = 'Canceled';
            }
            update existingCaseIntRecords;            
        }

        String jsonBody = generateReqBody(caseRecord, cccRec);
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Case__c  = caseRecord.Id;
        caseInt.Integration_Ext_Id__c = 'ABHFL Litmus Api';
        caseInt.Type__c = 'Litmus';
        caseInt.Status__c = 'Pending';
        insert caseInt;

        if(String.isNotBlank(jsonBody)) {
            firePlatformEvtForCallout(caseInt, jsonBody);
        }

        isRecursive = false;
    }

    // @Description - Preparing JSON body for Litmus Api.
    public String generateReqBody(Case caseRecord, ASF_Case_Category_Config__c cccRecord) {
        
        String userPhne = '';
        String userEml = '';

        String ftrOrNFTRVal = caseRecord.FTR__c == true ? 'FTR' : 'NFTR';
        String accountRecordTypeName = caseRecord.Account.RecordType.Name;
        List<Contact> con = [SELECT Id, Email FROM Contact WHERE AccountId=:caseRecord.AccountId LIMIT 1];

        userPhne = accountRecordTypeName  == 'Individual' ?  caseRecord.Account.PersonMobilePhone : caseRecord.Account.Phone;
        //userEml  = accountRecordTypeName  == 'Individual' ?  caseRecord.Account.PersonEmail : caseRecord.Account.Office_Email__c;
        userEml  = accountRecordTypeName  == 'Individual' ?  caseRecord.Account.PersonEmail : (con.size()>0?con[0].Email:'');

        LitmusApiWrapper litmusApiWrappObj = new LitmusApiWrapper();
        litmusApiWrappObj.appId = cccRecord.Litmus_Project__c;
        litmusApiWrappObj.userPhone = userPhne;
        litmusApiWrappObj.userEmail = userEml;
        litmusApiWrappObj.tag_case_sub_type = caseRecord.Sub_Type_Text__c;
        litmusApiWrappObj.name = caseRecord.Account.Name;
        litmusApiWrappObj.tag_case_id = caseRecord.CaseNumber;
        litmusApiWrappObj.tag_case_type = caseRecord.Type_Text__c;
        litmusApiWrappObj.tag_sla_deadline = String.valueOf(caseRecord.Overall_Case_Closure_SLA__c);
        litmusApiWrappObj.tag_category = caseRecord.Nature__c;
        litmusApiWrappObj.tag_created_by = caseRecord.createdBy.Name;
        litmusApiWrappObj.tag_created_on = String.valueOf(caseRecord.createdDate);
        litmusApiWrappObj.tag_source = caseRecord.Source__c;
        litmusApiWrappObj.tag_resolved_on = String.valueOf(caseRecord.ClosedDate);
        litmusApiWrappObj.tag_owner = caseRecord.owner.name;
        litmusApiWrappObj.tag_loan_account_no = caseRecord.LAN__c;
        litmusApiWrappObj.tag_ftr_nftr = ftrOrNFTRVal;
        litmusApiWrappObj.tag_ageing = String.valueOf(caseRecord.Ageing_Number_Of_Days__c);

        String reqBody = JSON.serialize(litmusApiWrappObj);

        return reqBody;
    }

    // @Description - Firing Platform Event to make Callout for Litmus Api.
    public void firePlatformEvtForCallout(ASF_Case_Integration__c caseInteg, String jsonBody) {

        ASF_Case_Integration__c caseInt = [Select Name from ASF_Case_Integration__c where id =: caseInteg.Id];
        
        Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
        caseIntOut.Business_Unit__c  = 'ABHFL';
        caseIntOut.ServiceName__c  = 'Litmus';//ABHFL_Constants.REPORTING_SERVICE;
        caseIntOut.Case_Integration_ID__c = caseInt.Name;
        caseIntOut.Integration_Name__c  = 'Litmus';
        caseIntOut.Request_Payload__c  =  jsonBody;
        Database.SaveResult publishResult = EventBus.publish(caseIntOut);
    }

    public class LitmusApiWrapper{
		public String tag_category;
		public String tag_created_by;
		public String tag_sla_deadline;
		public String tag_created_on;
		public String tag_case_type;
		public String tag_source;
		public String tag_case_id;
		public String tag_resolved_on;
		public String name;
		public String tag_owner;
		public String tag_case_sub_type;
		public String tag_loan_account_no;
		public String userEmail;
		public String tag_ftr_nftr;
		public String userPhone;
		public String tag_ageing;
		public String appId;
    }

    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){return null;}
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs){return null;}
}
