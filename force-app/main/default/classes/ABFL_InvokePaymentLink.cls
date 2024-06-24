/*********************************************************
*@Class        :  ABFL_InvokePaymentLink
*@Author       :  Aditee Churiwala 
*@Created Date :  28/03/2024
*@Last Modified:  28/03/2024
*@description  :  ABFL_InvokePaymentLink */
public with sharing class ABFL_InvokePaymentLink implements ASF_IntegrationInvocable {
    /****************************************************************************************************************
    * @LOB - ABFL
    * @Function - evaluate
    * @param caseRec
    * @return ASF_IntegrationsController.IntegrationWrapper.
    * @description This method will be used to evaluate criteria for BRE API invocations.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = ABFL_Constants.SUCCESS;
        result.response = ABFL_Constants.EVALUATION_SUCCESS;
        Case caseRecord = ABFL_SOQL_Case.getCaseInfo(caseRec.Id);
        
        if(caseRecord.ABFL_Case_Detail__r.Amount__c == null) { // Check Amount
            result.status = ABFL_Constants.ERROR;
            result.response = ABFL_Constants.EVALUATION_FAILED_AMOUNT_ERROR;
        }
        return result;
    }

    /****************************************************************************************************************
    * @LOB - ABFL
    * @Function - run
    * @param integRec
    * @param caseRec
    * @return ASF_IntegrationsController.IntegrationWrapper.
    * @description Invoked from the ASF_IntegrationsController class, this method runs the STP integration and creates Case Integration record.
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
                Type__c = 'Payment', // Identifier needs to be passed to middleware
                Response__c = ABFL_Constants.WAITING_API_RESPONSE
            );
        }
        Case caseRecord = ABFL_SOQL_Case.getCaseInfo(caseRec.Id);
        // Fire Actual Integration---Ends
        createPaymentLink(integRec, caseRecord);
        result.status = ABFL_Constants.SUCCESS;
        result.response = ABFL_Constants.WAITING_API_RESPONSE;
        return result;        
    }
     /****************************************************************************************************************
    * @LOB - ABFL
    * @Function - createPaymentLink
    * @param integRec
    * @param caseRecord
    * @description  Create Payment Link
    *****************************************************************************************************************/
    private static void createPaymentLink(ASF_Integration__c integRec, Case caseRecord) {
        List<ASF_Case_Integration__c> caseIntg = ABFL_SOQL_Integration.getCaseIntegrationInfo(caseRecord.Id,'Payment');
        PaymentData paymentData = new PaymentData();
        PaymentLink payload = new PaymentLink();
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
        ABFL_Payment_Link__mdt paymentLink = ABFL_Payment_Link__mdt.getInstance('ABFL_Payload');
       // String emailId = (caseRecord.AccountId != NULL)?(caseRecord.Account.IsPersonAccount?caseRecord.Account.PersonEmail:caseRecord.Account.Office_Email__c):NULL;
       // String mobileNo = (caseRecord.AccountId != NULL)?(caseRecord.Account.IsPersonAccount?caseRecord.Account.PersonMobilePhone:caseRecord.Account.Phone):NULL;
        String name = (caseRecord.AccountId != NULL)?(caseRecord.Account.Name != null?caseRecord.Account.Name:caseRecord.Account.Full_Name__pc):NULL;
        String mercOrderDate = DateTime.now().formatGMT('yyyyMMddHHmmss');
        Date dueDate = paymentLink.ABFL_Due_Date__c;
        
        //paymentData.pl_order_id = caseRecord.caseNumber+mercOrderDate;
        paymentData.merc_order_date = mercOrderDate;
        paymentData.merc_id = ABCL_Encryption.getENachInt().Merchant_Id__c;
        paymentData.amount =String.ValueOf(caseRecord.ABFL_Case_Detail__r.Amount__c);
        paymentData.return_url = 'https://yym2qh8gwi.execute-api.ap-south-1.amazonaws.com/resultpage';
        paymentData.product_type = '';
        paymentData.product_id = '';
        paymentData.customer_id = caseRecord.Client_Code__c;
        paymentData.invoice_no = caseRecord.caseNumber+mercOrderDate;
        paymentData.customer_name = name;
        paymentData.customer_email = emailId;
        paymentData.customer_phone = mobileNo;
        paymentData.udf1 = '';
        paymentData.udf2 = '';
        paymentData.order_desc = caseRecord.Description;
        paymentData.account_no = caseRecord.ABFL_Case_Detail__r.New_Bank_Account_No__c;
        paymentData.account_ifsc = caseRecord.ABFL_Case_Detail__r.Bank_IFSC_Code__c;
        paymentData.allowed_split_payment = '0';
        paymentData.expiry_period = String.valueOf(paymentLink.ABFL_Expiry_Period__c.intValue());
        paymentData.due_date = DateTime.newInstance(dueDate.year(),dueDate.month(),dueDate.day()).format('dd/MM/yyyy');
		paymentData.send_invoice_notification = paymentLink.ABFL_Send_Notification__c ;
        
        payload.payment_data = paymentData;
         
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
            // String decryptedResponse = caseInteg.Response__c;
            //Always decrpting whether it's success or failure
            String decryptedResponse = ABCL_Encryption.decrypt(caseInteg.Response__c);
            //Updating to show decrypted response on UI
            //As Trigger is in After update context same record can't be directly updated
            if(Schema.sObjectType.ASF_Case_Integration__c.isUpdateable()) {
                    upsert new ASF_Case_Integration__c(Id = caseInteg.Id , Response__c = decryptedResponse);
            }
            if(caseInteg.Status__c == ABFL_Constants.SUCCESS) {
                Case caseRecord = ABFL_SOQL_Case.getCaseInfo(caseInteg.Case__c);
                ABFL_PaymentLinkResponse response = (ABFL_PaymentLinkResponse)JSON.deserialize(decryptedResponse, ABFL_PaymentLinkResponse.class);
                if((response.order_data.status_code == '0300'  || response.order_data.status_code == '0002')&& response.order_data.links.payment_link_web != '') {
                    
                    ABFL_Case_Detail__c caseDetail = new ABFL_Case_Detail__c();
                    caseDetail.Id = caseRecord.ABFL_Case_Detail__c;    
                    caseDetail.Registration_Link__c  = response.order_data.links.payment_link_web;
                    if(Schema.sObjectType.ABFL_Case_Detail__c.isUpdateable()){
                        update caseDetail;
                    }
                    ASF_Integration__c intRec = ABFL_SOQL_Integration.getIntegrationInfo(caseInteg.Integration_Ext_Id__c);
                    if (String.isNotBlank(intRec.STP_Template__c)){
                        //Payment link request
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
            ABCL_Logger.push('ABFL_InvokeBREProcess.processResponse');
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
    public class PaymentData {
        public String pl_order_id;
        public String merc_order_date;
        public String merc_id;
        public String amount;
        public String return_url;
        public String product_type;
        public String product_id;
        public String customer_id;
        public String customer_name;
        public String customer_email;
        public String customer_phone;
        public String udf1;
        public String udf2;
        public String invoice_no;
        public String order_desc;
        public String account_no;
        public String account_ifsc;
        //public String payment_mode;
        public String allowed_split_payment;
        public String expiry_period;
        public String due_date;
        public String send_invoice_notification;
    }
    /*********************************************************
    * @Class           ABFL_InvokeEnachRegistration
    * @Author          Aditee Churiwala 
    * @Created Date    11/02/2024
    * @Last Modified   11/02/2024
    * @description     ABFL_InvokeEnachRegistration */
    public class PaymentLink {
        PaymentData payment_data;
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