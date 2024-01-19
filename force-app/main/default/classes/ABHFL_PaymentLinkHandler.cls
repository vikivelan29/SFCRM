/*********************************************************
*Class        :  ABHFL_PaymentLinkHandler
*Author       :  Siddarth Jaitly
*Created Date :  20/12/2023
*Last Modified:  20/12/2023
*Description  :  Class for Payment Link STP
*********************************************************/
public with sharing class ABHFL_PaymentLinkHandler implements ASF_IntegrationInvocable {
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - evaluate
    * @param caseRec - Case record from the framework. 
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @Description - Invoked from the ASF_IntegrationsController class, this method evaluates whether Payment Link should be generated or not.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        Case caseRecord = [SELECT Id,Account.Office_Email__c,Account.PersonEmail,Account.RecordType.Name,ABHFL_Case_Detail__r.Payable_Charges__c 
                           FROM Case WHERE Id =: caseRec.Id WITH SECURITY_ENFORCED];
        
        //Check for mandatory API conditions
        result.status = ABHFL_Constants.SUCCESS;
        result.response = Custom_Messages__mdt.getInstance('PaymentLink_EvaluationSuccessful').Message__c; 
        if(caseRecord.Account.RecordType.Name == ABHFL_Constants.ACCOUNT_RECORDTYPE_INDIVIDUAL && String.isBlank(caseRecord.Account.PersonEmail)){
            result.status = ABHFL_Constants.ERROR;
            result.response = Custom_Messages__mdt.getInstance('PaymentLink_IndividualEmailMissing').Message__c;             
        }
        
        if(caseRecord.Account.RecordType.Name == ABHFL_Constants.ACCOUNT_RECORDTYPE_NON_INDIVIDUAL && String.isBlank(caseRecord.Account.Office_Email__c)){
            result.status = ABHFL_Constants.ERROR;
            result.response = Custom_Messages__mdt.getInstance('PaymentLink_BusinessEmailMissing').Message__c;             
        }
        
        if(caseRecord.ABHFL_Case_Detail__r.Payable_Charges__c == null){
            result.status = ABHFL_Constants.ERROR;
            result.response = Custom_Messages__mdt.getInstance('PaymentLink_PayableChargeMissing').Message__c;              
        }
        
        return result;
    }
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - run
    * @param integ - ASF_Integration record.
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @Description - Invoked from the ASF_IntegrationsController class, this method runs the PaymentLink integration and creates Case Integration record.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c intSpec, Case caseRec){
        List<ASF_Case_Integration__c> existingCaseIntRecords = [SELECT Id, Status__c FROM ASF_Case_Integration__c
                                                               WHERE Case__c =:caseRec.Id 
                                                               AND Integration_Ext_Id__c =:intSpec.External_Id__c WITH SECURITY_ENFORCED];
        if(existingCaseIntRecords.size()>0){
        	for(ASF_Case_Integration__c caseInt : existingCaseIntRecords){
                caseInt.Status__c = ABHFL_Constants.CANCELED;
            }
            if(Schema.sObjectType.ASF_Case_Integration__c.isUpdateable()){
                update existingCaseIntRecords;
            }
        }

        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = ABHFL_Constants.ERROR;
        ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
        caseInteg.Integration_Ext_Id__c = intSpec.External_Id__c;
        caseInteg.Case__c = caseRec.Id;
        caseInteg.Status__c = ABHFL_Constants.PENDING;
        if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
            insert caseInteg;
        }
        
        Case caseRecord = [SELECT Id,ABHFL_Case_Detail__r.ROI_Switch_Fee__c,CCC_External_Id__c,CaseNumber,Customer_name_formula__c,Asset.LAN__c,Account.Office_Email__c ,Account.PersonEmail,Account.Phone,
                           Account.RecordType.Name,ABHFL_Case_Detail__r.Payable_Charges__c,Case.ContactId, No_Auto_Communication__c FROM Case where Id =: caseRec.Id WITH SECURITY_ENFORCED];

        String cccExternalId = caseRecord.CCC_External_Id__c;
        List<Doc_Charge__mdt> docChargeMdtLst = [SELECT id, Charges__c, Charge_Code__c 
                                                FROM Doc_Charge__mdt
                                                WHERE CCC_External_Id__c =:cccExternalId];
        
        String chargeReason = docChargeMdtLst[0].Charges__c;
        String amount = String.valueOf(caseRecord.ABHFL_Case_Detail__r.ROI_Switch_Fee__c);
        String chargeCode = docChargeMdtLst[0].Charge_Code__c;
        String integrationResponse = ABHFL_Constants.FAILURE;

        PaytmRequestWrapper paytmRequestWrapper = new PaytmRequestWrapper(caseRecord);
        paytmRequestWrapper.amount = amount;
        string paytmRequestBody = JSON.serialize(paytmRequestWrapper);
        PaytmResponseWrapper paytmResponseWrapper = new PaytmResponseWrapper() ;
        ABCL_IntegrationCallout.IntegrationResponseWrapper paytmResponse = ABCL_IntegrationCallout.executeCallout(ABHFL_Constants.PAYTMLINK_INTEGRATION_METADATA,paytmRequestBody,null);
        if(paytmResponse.statusCode == 200 && String.isNotBlank(paytmResponse.responseBody)){
            system.debug('paytmResponse.responseBody'+paytmResponse.responseBody);
            paytmResponseWrapper = (PaytmResponseWrapper)JSON.deserialize(paytmResponse.responseBody,PaytmResponseWrapper.class);
            system.debug('paytmResponse Parsed'+paytmResponseWrapper);
            if(paytmResponseWrapper.operationStatus == '1'){
                PaymentRequestWrapper paymentRequestWrapper = new PaymentRequestWrapper(caseRecord,paytmResponseWrapper);
                paymentRequestWrapper.reasonOfPayment = chargeReason;
                paymentRequestWrapper.chargeCode = chargeCode;
                string paymentRequestBody = JSON.serialize(paymentRequestWrapper);
                ABCL_IntegrationCallout.IntegrationResponseWrapper paymentResponse = ABCL_IntegrationCallout.executeCallout(ABHFL_Constants.PAYMENTLINK_INTEGRATION_METADATA,paymentRequestBody,null);
                if(paymentResponse.statusCode == 200 && String.isNotBlank(paymentResponse.responseBody)){
                        system.debug('paymentResponse.responseBody'+paymentResponse.responseBody);
                        PaymentResponseWrapper paymentResponseWrapper = (PaymentResponseWrapper)JSON.deserialize(paymentResponse.responseBody,PaymentResponseWrapper.class);
                        system.debug('paymentResponseWrapper Parsed'+paymentResponseWrapper);
                        if(paymentResponseWrapper.returnCode == '1'){
                            result.Status = ABHFL_Constants.SUCCESS;
                            result.Response = paymentResponseWrapper.shortUrl; 
                            integrationResponse = ABHFL_Constants.SUCCESS;
                        }
                } 
            }
        } 

        if(result.Status == ABHFL_Constants.SUCCESS){
            ABHFL_Case_Detail__c caseDetail = new ABHFL_Case_Detail__c();
            caseDetail.Id = caseRecord.ABHFL_Case_Detail__c;    
            caseDetail.Paytm_Link__c = paytmResponseWrapper.shortUrl;
            caseDetail.Payment_Link__c = result.Response;
            caseDetail.Payment_Link_Trigger_Time__c = System.now();
            if(Schema.sObjectType.ABHFL_Case_Detail__c.isUpdateable()){
                update caseDetail;
            }
            caseInteg.Status__c = integrationResponse;
            if(Schema.sObjectType.ASF_Case_Integration__c.isUpdateable()){
                update caseInteg;
            }
            List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id,Resolved_Case_Email_Template__c FROM ASF_Case_Category_Config__c 
                                                                   WHERE CCC_External_Id__c =:cccExternalId WITH SECURITY_ENFORCED];
            Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord, 
                                                                                                                    cccRecord[0].Resolved_Case_Email_Template__c, 
                                                                                                                    null, 
                                                                                                                    false); 
        }
        
        return result;
    }
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - processResponse
    * @param caseInteg - ASF_Case_Integration record.
    * @return - void.
    * @Description - Invoked from the Case Integration trigger, this method processes the response of the integration received.
    *****************************************************************************************************************/
    public void processResponse(ASF_Case_Integration__c caseInt){} 

    public class PaytmRequestWrapper{
        public string custname;
        public string salesId;
        public string emailId;
        public string mobileNumber;
        public string type;
        public string amount;

        public PaytmRequestWrapper(Case caseRecord){
            this.custname = caseRecord.Customer_name_formula__c;
            this.salesId = caseRecord.Asset.LAN__c;
            this.emailId = caseRecord.Account.RecordType.Name == ABHFL_Constants.ACCOUNT_RECORDTYPE_NON_INDIVIDUAL?caseRecord.Account.Office_Email__c:caseRecord.Account.PersonEmail;
            this.mobileNumber = caseRecord.Account.Phone;
            this.type = ABHFL_Constants.PAYTM_REQUEST_TYPE;
            this.amount = String.valueof(caseRecord.ABHFL_Case_Detail__r.Payable_Charges__c);
        }

        public PaytmRequestWrapper(){}
    }
    
    public class PaytmResponseWrapper{
        public string operationStatus;
        public string operationMessage;
        public string orderId;
        public string mobileNumber;
        public string id;
        public string shortUrl;
    }
    
    public class PaymentRequestWrapper{
        public string customerName;
        public string lAN;
        public string crmCaseId;
        public string chargeCode;
        public string reasonOfPayment;
        public string paymentLink;
        public string paymentExpiryDate;

        public PaymentRequestWrapper(Case caseRecord, PaytmResponseWrapper paytmResponseWrapper ){
            this.CustomerName = caseRecord.Customer_name_formula__c;
            this.LAN = caseRecord.Asset.LAN__c;
            this.CRMCaseId = caseRecord.CaseNumber;
            this.ChargeCode = '';
            this.ReasonOfPayment = ABHFL_Constants.REASON_FOR_PAYMENT;
            this.PaymentLink = paytmResponseWrapper.shortUrl;
            this.PaymentExpiryDate = '';
        }

        public PaymentRequestWrapper(){}
    }
    
    public class PaymentResponseWrapper{
        public string returnCode;
        public string returnMessage;
        public string shortUrl;
    }
}