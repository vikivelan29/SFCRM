/*********************************************************
*Class        :  ABFL_InvokeEnachRegistration
*Author       :  Aditee Churiwala 
*Created Date :  11/02/2024
*Last Modified:  11/02/2024
*Description  :  ABFL_InvokeEnachRegistration */
public with sharing class ABFL_InvokeEnachRegistration implements ASF_IntegrationInvocable {
    public Enach_data enach_data;
    /****************************************************************************************************************
    * @LOB - ABFL
    * @Function - evaluate
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @Description - This method will be used to evaluate criteria for BRE API invocations.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        System.debug('@@evaluate');
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = ABFL_Constants.SUCCESS;
        result.response = ABFL_Constants.EVALUATION_SUCCESS;
        Case caseRecord = ABFL_SOQL_Case.getCaseInfo(caseRec.Id);
        
        if(caseRecord.ABFL_Case_Detail__r.EMI_Amount__c == null) { // Check Amount
            result.status = ABFL_Constants.ERROR;
            result.response = ABFL_Constants.EVALUATION_FAILED_AMOUNT_ERROR;
        }
        else if(caseRecord.ABFL_Case_Detail__r.Frequency__c == null) { // Check Frequency__c
            result.status = ABFL_Constants.ERROR;
            result.response = ABFL_Constants.EVALUATION_FAILED_FREQUENCY_ERROR;
        } 
        else if(caseRecord.ABFL_Case_Detail__r.From_Date__c == null) { // Check To_Date__c
            result.status = ABFL_Constants.ERROR;
            result.response = ABFL_Constants.EVALUATION_FAILED_TO_DATE_ERROR;
        }
        else if(caseRecord.ABFL_Case_Detail__r.New_Bank_Account_No__c == null) { // Check New_Bank_Account_No__c
            result.status = ABFL_Constants.ERROR;
            result.response = ABFL_Constants.EVALUATION_FAILED_TO_DATE_ERROR;
        }
        else if(caseRecord.ABFL_Case_Detail__r.Bank_IFSC_Code__c == null) { // Check Bank_IFSC_Code__c
            result.status = ABFL_Constants.ERROR;
            result.response = ABFL_Constants.EVALUATION_FAILED_TO_DATE_ERROR;
        }
        
        return result;
    }

    /****************************************************************************************************************
    * @LOB - ABFL
    * @Function - run
    * @param integ - ASF_Integration record.
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @Description - Invoked from the ASF_IntegrationsController class, this method runs the STP integration and creates Case Integration record.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integRec, Case caseRec) {
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        //Cancel existing records in ASF_Case_Integration__c
        ASF_IntegrationsController.cancelPendingCaseIntegrations(caseRec.Id, integRec.External_Id__c);
        
        if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
			insert new ASF_Case_Integration__c(
                Case__c  = caseRec.Id,
                Integration_Ext_Id__c = integRec.External_Id__c,
                Status__c = ABFL_Constants.PENDING,
                Type__c = 'Enach', // Identifier needs to be passed to middleware
                Response__c = ABFL_Constants.WAITING_API_RESPONSE
            );
        }
        Case caseRecord = ABFL_SOQL_Case.getCaseInfo(caseRec.Id);
        // Fire Actual Integration---Ends
        createEnachRegistration(integRec, caseRecord);
        result.status = ABFL_Constants.SUCCESS;
        result.response = ABFL_Constants.WAITING_API_RESPONSE;
        return result;        
    }
    
    private static void createEnachRegistration(ASF_Integration__c integRec, Case caseRecord) {
        List<ASF_Case_Integration__c> caseIntg = ABFL_SOQL_Integration.getCaseIntegrationInfo(caseRecord.Id,'Enach');
        Enach_data data = new Enach_data();
        EnachRegistration payload = new EnachRegistration();
        String emailId = (caseRecord.AccountId != NULL)?(caseRecord.Account.IsPersonAccount?caseRecord.Account.PersonEmail:caseRecord.Account.Office_Email__c):NULL;
        String mobileNo = (caseRecord.AccountId != NULL)?(caseRecord.Account.IsPersonAccount?caseRecord.Account.PersonMobilePhone:caseRecord.Account.Phone):NULL;
        String name = (caseRecord.AccountId != NULL)?(caseRecord.Account.Name != null?caseRecord.Account.Name:caseRecord.Account.Full_Name__pc):NULL;
        Date toDate = caseRecord.ABFL_Case_Detail__r.To_Date__c;
        String endDate = toDate != null ? DateTime.newInstance(toDate.year(), toDate.month(), toDate.day()).format('YYYYMMdd'): null;
        Date fromDate = caseRecord.ABFL_Case_Detail__r.From_Date__c;
        String startDate = fromDate != null ? DateTime.newInstance(fromDate.year(), fromDate.month(), fromDate.day()).format('YYYYMMdd'): null;
        /*Map<String, Object> payloadWrap = new Map<String, Object>{ 
            'pl_merchant_id'=>ABCL_Encryption.getENachInt().Merchant_Id__c,
                'customer_Id'=> caseRecord.Client_Code__c,
                'customer_mobile_no'=> mobileNo,
                'customer_name'=> name,
                'customer_email_id'=> emailId,
                'customer_bank_ifsc'=> caseRecord.ABFL_Case_Detail__r.Bank_IFSC_Code__c,
                'customer_bank_acc_no'=> caseRecord.ABFL_Case_Detail__r.New_Bank_Account_No__c,
                'amount'=> caseRecord.ABFL_Case_Detail__r.EMI_Amount__c,
                'start_date'=> startDate,
                'end_date'=> endDate,
                'frequency'=> caseRecord.ABFL_Case_Detail__r.Frequency__c,
                'debit_type'=> caseRecord.ABFL_Case_Detail__r.Debit_Type__c,
                'return_url'=>'http://localhost:8090/resultpage'
                };*/
        data.pl_merchant_id = ABCL_Encryption.getENachInt().Merchant_Id__c;
        data.customer_Id = caseRecord.Client_Code__c;
        data.customer_mobile_no = mobileNo;
        data.customer_name =name;
        data.customer_email_id = emailId;
        data.customer_bank_ifsc = caseRecord.ABFL_Case_Detail__r.Bank_IFSC_Code__c;
        data.customer_bank_acc_no = caseRecord.ABFL_Case_Detail__r.New_Bank_Account_No__c;
        data.amount = String.ValueOf(caseRecord.ABFL_Case_Detail__r.EMI_Amount__c);
        data.start_date = startDate;
        data.end_date = endDate;
        data.frequency = caseRecord.ABFL_Case_Detail__r.Frequency__c;
        data.debit_type = caseRecord.ABFL_Case_Detail__r.Debit_Type__c;
        data.return_url = 'http://localhost:8090/resultpage';
        payload.enach_data = data;
        System.debug('@@@payloadWrap'+JSON.serialize(payload));
         
        Database.SaveResult publishResult = EventBus.publish(new Case_Integration_Outbound__e (
            Business_Unit__c  = caseRecord.Business_Unit__c,
            Case_Integration_ID__c = caseIntg[0]?.Name,
            Integration_Name__c  = integRec.STP_API_Identifier__c, // STP_API_Identifier__c is the actual name of API to invoke
            ServiceName__c = integRec.STP_API_Identifier__c,
            Request_Payload__c  =  ABCL_Encryption.encrypt(JSON.serialize(payload))
        ));
     }
    /****************************************************************************************************************
    * @LOB - ABFL
    * @Function - processResponse
    * @param caseInteg - ASF_Case_Integration record.
    * @return - void.
    * @Description - Invoked when status Case Intg is updated to success, it processes the response of the integration received.
    *****************************************************************************************************************/
    public void processResponse(ASF_Case_Integration__c caseInteg){
        try {
            if(caseInteg.Status__c == ABFL_Constants.SUCCESS) {
                Case caseRecord = ABFL_SOQL_Case.getCaseInfo(caseInteg.Case__c);
                ASF_Integration__c intg = ABFL_SOQL_Integration.getIntegrationInfo(caseInteg.Integration_Ext_Id__c);
                Map<Id, ASF_CaseMovementHelper.StageWrapper> resultWrap = new Map<Id, ASF_CaseMovementHelper.StageWrapper>();
                
                String decryptedResponse = ABCL_Encryption.decrypt(caseInteg.Response__c);
                 System.debug('@@@decryptedResponse'+decryptedResponse);
                ABFL_EnachRegistrationResponse jsonMap = (ABFL_EnachRegistrationResponse)JSON.deserialize(decryptedResponse, ABFL_EnachRegistrationResponse.class);
                if(jsonMap.registration_data.return_code == '0000' && jsonMap.registration_data.registration_link != '') {
                    
                    ABFL_Case_Detail__c caseDetail = new ABFL_Case_Detail__c();
                    caseDetail.Id = caseRecord.ABFL_Case_Detail__c;    
                    caseDetail.Registration_Link__c  = jsonMap.registration_data.registration_link;
                    if(Schema.sObjectType.ABFL_Case_Detail__c.isUpdateable()){
                        update caseDetail;
                    }
                    ASF_Integration__c intRec = ABFL_SOQL_Integration.getIntegrationInfo(caseInteg.Integration_Ext_Id__c);
                   
                    if (String.isNotBlank(intRec.STP_Template__c)){
                        Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord, intRec.STP_Template__c, null, false);
                        
                        Boolean isEmailSentToCustomer = true;
                        
                        if (!platformEventResult.isSuccess()){
                            isEmailSentToCustomer = false;
                        }
                    }
                }    
            }   
        }
        catch(Exception e) {
            System.debug('@@@mess'+e.getMessage()+' '+e.getLineNumber());
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABFL_InvokeBREProcess.processResponse');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
        }
        
    }
    public class Enach_data {
		public String pl_merchant_id;
		public String customer_Id;
		public String customer_mobile_no;
		public String customer_name;
		public String customer_email_id;
		public String customer_bank_ifsc;
		public String customer_bank_acc_no;
		public String amount;
		public String start_date;
		public String end_date;
		public String frequency;
		public String debit_type;
		public String return_url;
	}
    public class EnachRegistration {
        Enach_data enach_data;
    }
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){return null;}
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs){return null;}
}