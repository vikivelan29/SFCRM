/*********************************************************
* @Class           ABFL_InvokeEnachRegistration
* @Author          Aditee Churiwala 
* @Created Date    11/02/2024
* @Last Modified   11/02/2024
* @description     ABFL_InvokeEnachRegistration */
public with sharing class ABFL_InvokeEnachRegistration implements ASF_IntegrationInvocable {
    public Enach_data enach_data;
    /****************************************************************************************************************
    * @LOB - ABFL
    * @Function - evaluate
    * @param caseRec
    * @return  ASF_IntegrationsController.IntegrationWrapper.
    * @description  This method will be used to evaluate criteria for BRE API invocations.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
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
            result.response = ABFL_Constants.EVALUATION_FAILED_FROM_DATE_ERROR;
        }
        else if(caseRecord.ABFL_Case_Detail__r.To_Date__c == null) { // Check To_Date__c
            result.status = ABFL_Constants.ERROR;
            result.response = ABFL_Constants.EVALUATION_FAILED_TO_DATE_ERROR;
        }
         // Check From Date is greater than Today
        else if(!(caseRecord.ABFL_Case_Detail__r.To_Date__c > System.Today() && caseRecord.ABFL_Case_Detail__r.From_Date__c > System.Today())) { // Check From Date is greater than Today
            result.status = ABFL_Constants.ERROR;
            result.response = ABFL_Constants.EVALUATION_FAILED_DATE_VALIDATION;
        }
        // Check From Date is greater than Today
        else if(caseRecord.ABFL_Case_Detail__r.To_Date__c == caseRecord.ABFL_Case_Detail__r.From_Date__c) { 
            result.status = ABFL_Constants.ERROR;
            result.response = ABFL_Constants.EVALUATION_FAILED_FROM_TO_DATE_VALIDATION;
        }    
        else if(caseRecord.ABFL_Case_Detail__r.New_Bank_Account_No__c == null) { // Check New_Bank_Account_No__c
            result.status = ABFL_Constants.ERROR;
            result.response = ABFL_Constants.EVALUATION_FAILED_BANK_ACCOUNT_ERROR;
        }
        else if(caseRecord.ABFL_Case_Detail__r.Bank_IFSC_Code__c == null) { // Check Bank_IFSC_Code__c
            result.status = ABFL_Constants.ERROR;
            result.response = ABFL_Constants.EVALUATION_FAILED_IFSC_CODE_ERROR;
        }
        
        return result;
    }

    /****************************************************************************************************************
    * @LOB - ABFL
    * @Function - run
    * @param integRec
    * @param caseRec
    * @return  ASF_IntegrationsController.IntegrationWrapper.
    * @description  Invoked from the ASF_IntegrationsController class, this method runs the STP integration and creates Case Integration record.
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
    /****************************************************************************************************************
    * @LOB - ABFL
    * @Function - createEnachRegistration
    * @param integRec
    * @param caseRecord
    * @description  Create Enach Registration
    *****************************************************************************************************************/
    private static void createEnachRegistration(ASF_Integration__c integRec, Case caseRecord) {
        List<ASF_Case_Integration__c> caseIntg = ABFL_SOQL_Integration.getCaseIntegrationInfo(caseRecord.Id,'Enach');
        Enach_data enachData = new Enach_data();
        EnachRegistration payload = new EnachRegistration();
        String emailId = '';
        String mobileNo = '';
        if(caseRecord.AccountId != NULL && caseRecord.Account.IsPersonAccount) {
            emailId = caseRecord.Account.PersonEmail;
            mobileNo = caseRecord.Account.PersonMobilePhone;
        }
        else if(caseRecord.AccountId != NULL) {
            List<Contact> con = [SELECT Id, Email, MobilePhone FROM Contact WHERE AccountId = :caseRecord.AccountId];
            emailId = con.size()>0 && con[0] != null && con[0].Email != null?con[0]?.Email:caseRecord.Account.Office_Email__c; 
            mobileNo = con.size()>0 && con[0] != null && con[0].MobilePhone != null?con[0]?.MobilePhone:caseRecord.Account.Phone;
        }
        //String emailId = (caseRecord.AccountId != NULL)?(caseRecord.Account.IsPersonAccount?caseRecord.Account.PersonEmail:caseRecord.Account.Office_Email__c):NULL;
       // String mobileNo = (caseRecord.AccountId != NULL)?(caseRecord.Account.IsPersonAccount?caseRecord.Account.PersonMobilePhone:caseRecord.Account.Phone):NULL;
        String name = (caseRecord.AccountId != NULL)?(caseRecord.Account.Name != null?caseRecord.Account.Name:caseRecord.Account.Full_Name__pc):NULL;
        Date toDate = caseRecord.ABFL_Case_Detail__r.To_Date__c;
        String endDate = toDate != null ? DateTime.newInstance(toDate.year(), toDate.month(), toDate.day()).format('YYYYMMdd'): null;
        Date fromDate = caseRecord.ABFL_Case_Detail__r.From_Date__c;
        String startDate = fromDate != null ? DateTime.newInstance(fromDate.year(), fromDate.month(), fromDate.day()).format('YYYYMMdd'): null;
        
        enachData.pl_merchant_id = ABCL_Encryption.getENachInt().Merchant_Id__c;
        enachData.customer_Id = caseRecord.Client_Code__c;
        enachData.customer_mobile_no = mobileNo;
        enachData.customer_name = name;
        enachData.customer_email_id = emailId;
        enachData.customer_bank_ifsc = caseRecord.ABFL_Case_Detail__r.Bank_IFSC_Code__c;
        enachData.customer_bank_acc_no = caseRecord.ABFL_Case_Detail__r.New_Bank_Account_No__c;
        enachData.amount = String.ValueOf(caseRecord.ABFL_Case_Detail__r.EMI_Amount__c);
        enachData.start_date = startDate;
        enachData.end_date = endDate;
        enachData.frequency = caseRecord.ABFL_Case_Detail__r.Frequency__c;
        enachData.debit_type = caseRecord.ABFL_Case_Detail__r.Debit_Type__c;
        enachData .lan = caseRecord.LAN__c;
        enachData.return_url = 'http://localhost:8090/resultpage';
        payload.enach_data = enachData;
         
        System.debug('@@@mobileN'+mobileNo);
                System.debug('@@@emailId'+emailId);
        EventBus.publish(new Case_Integration_Outbound__e (
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
    * @param caseInteg
    * @description  Invoked when status Case Intg is updated to success, it processes the response of the integration received.
    *****************************************************************************************************************/
    public void processResponse(ASF_Case_Integration__c caseInteg){
        try {
            String decryptedResponse = ABCL_Encryption.decrypt(caseInteg.Response__c);
            //Updating to show decrypted response on UI
            //As Trigger is in After update context same record can't be directly updated
            if(Schema.sObjectType.ASF_Case_Integration__c.isUpdateable()) {
                    upsert new ASF_Case_Integration__c(Id = caseInteg.Id , Response__c = decryptedResponse);
            }
            if(caseInteg.Status__c == ABFL_Constants.SUCCESS) {
                Case caseRecord = ABFL_SOQL_Case.getCaseInfo(caseInteg.Case__c);
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
            ABCL_Logger.enableExceptionLogging();
            ABCL_Logger.push('ABFL_InvokeEnachRegistration.processResponse');
            ABCL_Logger.message(e.getMessage());
            ABCL_Logger.emit();
        }
        
    }
    /*********************************************************
    * @Class           ABFL_InvokeEnachRegistration
    * @Author          Aditee Churiwala 
    * @Created Date    11/02/2024
    * @Last Modified   11/02/2024
    * @description     ABFL_InvokeEnachRegistration */
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
        public String lan;
		public String debit_type;
		public String return_url;
	}
    /*********************************************************
    * @Class           ABFL_InvokeEnachRegistration
    * @Author          Aditee Churiwala 
    * @Created Date    11/02/2024
    * @Last Modified   11/02/2024
    * @description     ABFL_InvokeEnachRegistration */
    public class EnachRegistration {
        Enach_data enach_data;
    }
     /****************************************************************************************************************
    * @LOB - ABFL
    * @Function - evaluate
    * @param caseRecs
    * @return  Map<Id, ASF_IntegrationsController.IntegrationWrapper>
    * @description  This method will be used to evaluate criteria for BRE API invocations.
    *****************************************************************************************************************/
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){return null;}
     /****************************************************************************************************************
    * @LOB - ABFL
    * @Function - run
    * @param integs
    * @param caseRecs
    * @return  Map<Id, ASF_IntegrationsController.IntegrationWrapper>
    * @description  This method will be used to evaluate criteria for BRE API invocations.
    *****************************************************************************************************************/
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs){return null;}
}