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
        Case caseRecord = [SELECT Id,AccountId, Account.Phone,Account.PersonMobilePhone,Asset.Loan_ID__c,Account.Office_Email__c,Account.PersonEmail,Account.RecordType.Name,
                            ABHFL_Case_Detail__r.Payable_Charges__c, ABHFL_Case_Detail__r.Send_Payment_Link__c, CCC_External_Id__c
                           FROM Case WHERE Id =: caseRec.Id];
		List<Contact> con = [SELECT Id, Email FROM Contact WHERE AccountId=:caseRecord.AccountId LIMIT 1];
        List<Doc_Charge__mdt> docChargMdtLst = [SELECT id, CCC_External_Id__c FROM Doc_Charge__mdt WHERE Payment_Required__c = true];

        //Check for mandatory API conditions
        result.status = ABHFL_Constants.SUCCESS;
        result.response = Custom_Messages__mdt.getInstance('PaymentLink_EvaluationSuccessful').Message__c; 

        //Dhinesh - to check for approvals 
        List<ASF_Case_Approv__c> approvals = [SELECT Id,Approval_Status__c FROM ASF_Case_Approv__c WHERE SR__c =: caseRecord.Id];
        List<String> approvalSubTypes = new List<String>{'hfl069', 'RLOAPRONHFC','REFCL001'};
        Boolean approvalPending = true;
        if(approvalSubTypes.contains(caseRecord.CCC_External_Id__c) && approvals.isEmpty()){
            result.status = ABHFL_Constants.ERROR;
            result.response = 'Case is not Approved, Please create an Approval';
        }
        for(ASF_Case_Approv__c approval : approvals) {
                if (approval.Approval_Status__c == 'Approved') {
                    approvalPending = false;
                    break; // No need to continue checking once one is found
            }
        }
        if(approvalSubTypes.contains(caseRecord.CCC_External_Id__c) && approvalPending && !approvals.isEmpty()){
            result.status = ABHFL_Constants.ERROR;
            result.response = 'Case is not Approved, cannot generate payment link';
        }
        //--Dhinesh ends
        
        if(caseRecord.Account.RecordType.Name == ABHFL_Constants.ACCOUNT_RECORDTYPE_INDIVIDUAL && String.isBlank(caseRecord.Account.PersonEmail)){
            result.status = ABHFL_Constants.ERROR;
            result.response = Custom_Messages__mdt.getInstance('PaymentLink_IndividualEmailMissing').Message__c;             
        }
        
        if(caseRecord.Account.RecordType.Name == ABHFL_Constants.ACCOUNT_RECORDTYPE_NON_INDIVIDUAL /*&& String.isBlank(caseRecord.Account.Office_Email__c) String.isBlank(con[0].Email)*/){
            if(con.size()>0){
                if(String.isBlank(con[0].Email)){
                    result.status = ABHFL_Constants.ERROR;
            		result.response = Custom_Messages__mdt.getInstance('PaymentLink_BusinessEmailMissing').Message__c;
                }
            }else{
                result.status = ABHFL_Constants.ERROR;
            	result.response = Custom_Messages__mdt.getInstance('PaymentLink_BusinessEmailMissing').Message__c;
            }                 
        }
        
        if(caseRecord.ABHFL_Case_Detail__r.Payable_Charges__c == null){
            result.status = ABHFL_Constants.ERROR;
            result.response = Custom_Messages__mdt.getInstance('PaymentLink_PayableChargeMissing').Message__c;              
        }

        if(String.isBlank(caseRecord.Asset.Loan_ID__c)) {
            result.status = ABHFL_Constants.ERROR;
            result.response = Custom_Messages__mdt.getInstance('Payment_Link_Loan_Id_is_Blank').Message__c;
        }
        
        if(caseRecord.Account.RecordType.Name == ABHFL_Constants.ACCOUNT_RECORDTYPE_NON_INDIVIDUAL && String.isBlank(caseRecord.Account.Phone)) {
            result.status = ABHFL_Constants.ERROR;
            result.response = Custom_Messages__mdt.getInstance('Phone_cannot_be_blank').Message__c;
        }
        
        if(caseRecord.Account.RecordType.Name == ABHFL_Constants.ACCOUNT_RECORDTYPE_INDIVIDUAL && String.isBlank(caseRecord.Account.PersonMobilePhone)) {
            result.status = ABHFL_Constants.ERROR;
            result.response = Custom_Messages__mdt.getInstance('Mobile_cannot_be_blank').Message__c;
        }

        for(Doc_Charge__mdt dcChrgeRec : docChargMdtLst) {
            String docCCCExternalId = dcChrgeRec.CCC_External_Id__c;
            String caseRecCCCExtId = caseRecord.CCC_External_Id__c;
            String paymentRequired = caseRecord.ABHFL_Case_Detail__r.Send_Payment_Link__c;
            if(docCCCExternalId == caseRecCCCExtId && paymentRequired == 'No') {
                result.status = ABHFL_Constants.ERROR;
                result.response = Custom_Messages__mdt.getInstance('Payment_Required_Message').Message__c;
                break;
            }
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


        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = ABHFL_Constants.ERROR;

        /*
        Ticket: PR970457-1883
        Modified By: Ishan Khichadia 
        Description: Added ABHFL_Case_Detail__r.EMI_Tenure__c in the query as it will be used in Paytym Wrapper as requested by the IT Team
        */
        Case caseRecord = [SELECT Id,AccountId, Account.PersonMobilePhone,CCC_External_Id__c,CaseNumber,Customer_name_formula__c,Asset.Loan_ID__c,Asset.LAN__c,Account.Office_Email__c ,Account.PersonEmail,Account.Phone,
                           Account.RecordType.Name,ABHFL_Case_Detail__r.Payable_Charges__c,ABHFL_Case_Detail__r.EMI_Tenure__c,Case.ContactId, No_Auto_Communication__c FROM Case where Id =: caseRec.Id];

        String cccExternalId = caseRecord.CCC_External_Id__c;
        List<Doc_Charge__mdt> docChargeMdtLst = [SELECT id, Charges__c, Charge_Code__c,Call_Payment_Link__c,Payment_Code__c	,Email_Template__c,SMS_Template__c,GST__c 
                                                FROM Doc_Charge__mdt WHERE CCC_External_Id__c =:cccExternalId];
        Boolean callPaymentLink = false;        
        string smsTemplate = '';    
        String emailTemplate = '';   
        String paymentCode = '';
        Decimal GST;
        if(docChargeMdtLst.size() > 0){
            emailTemplate = docChargeMdtLst[0].Email_Template__c;
            smsTemplate = docChargeMdtLst[0].SMS_Template__c;
            callPaymentLink = docChargeMdtLst[0].Call_Payment_Link__c;
            paymentCode = docChargeMdtLst[0].Payment_Code__c;
            GST= docChargeMdtLst[0].GST__c;
        }         
        String integrationResponse = ABHFL_Constants.FAILURE;

        PaytmRequestWrapper paytmRequestWrapper = new PaytmRequestWrapper(caseRecord,GST);
        paytmRequestWrapper.paymentCode = paymentCode;
        paytmRequestWrapper.ParentcaseID = caseRecord.Id;
        string paytmRequestBody = JSON.serialize(paytmRequestWrapper);
        system.debug('paytmRequestBody'+paytmRequestBody);
        PaytmResponseWrapper paytmResponseWrapper = new PaytmResponseWrapper() ;
        ABCL_IntegrationCallout.IntegrationResponseWrapper paytmResponse = ABCL_IntegrationCallout.executeCallout(ABHFL_Constants.PAYTMLINK_INTEGRATION_METADATA,paytmRequestBody,null);
        system.debug('paytmResponse.responseBody'+paytmResponse.responseBody);
        if(paytmResponse.statusCode == 200 && String.isNotBlank(paytmResponse.responseBody)){
            system.debug('paytmResponse.responseBody'+paytmResponse.responseBody);
            paytmResponseWrapper = (PaytmResponseWrapper)JSON.deserialize(paytmResponse.responseBody,PaytmResponseWrapper.class);
            system.debug('paytmResponse Parsed'+paytmResponseWrapper);
            if(paytmResponseWrapper.operationStatus == '1' && callPaymentLink){
                result = paymentLinkGeneration(caseRecord,paytmResponseWrapper,docChargeMdtLst,intSpec);
            } else if(paytmResponseWrapper.operationStatus == '1' && !callPaymentLink){
                result.Status = ABHFL_Constants.SUCCESS;
                result.Response = paytmResponseWrapper.shortUrl;
            }
        } 
        
        ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
        caseInteg.Integration_Ext_Id__c = intSpec.External_Id__c;
        caseInteg.Case__c = caseRec.Id;
        if(result.Status == ABHFL_Constants.SUCCESS){
            caseInteg.Status__c = ABHFL_Constants.SUCCESS;
        }else{
            caseInteg.Status__c = ABHFL_Constants.FAILURE;
        }
        caseInteg.Request__c = paytmRequestBody;
        caseInteg.Response__c = paytmResponse.responseBody;
        if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
            insert caseInteg;
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

            Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord, 
                                                                                                                    emailTemplate, 
                                                                                                                    smsTemplate, 
                                                                                                                    false); 
        }
        
        return result;
    }
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - paymentLinkGeneration
    * @param paytmResponseWrapper - Paytm Response Wrapper.
    * @param caseRec - Case record from the framework.
    * @param chargeReason - Stored Charge Reason for CTST Record.
    * @param chargeCode - Stored Charge Reason for CTST Record.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @Description - Invoked from the ASF_IntegrationsController class, this method runs the PaymentLink integration.
    *****************************************************************************************************************/
    public static ASF_IntegrationsController.IntegrationWrapper paymentLinkGeneration(Case caseRecord,PaytmResponseWrapper paytmResponseWrapper,List<Doc_Charge__mdt> docChargeMdtLst,ASF_Integration__c intSpec){
        String responseStr = '';  
        String chargeReason = '';
        String chargeCode = '';
        if(docChargeMdtLst.size() > 0){
            chargeReason = docChargeMdtLst[0].Charges__c;
            chargeCode = docChargeMdtLst[0].Charge_Code__c;
        }
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        PaymentRequestWrapper paymentRequestWrapper = new PaymentRequestWrapper(caseRecord,paytmResponseWrapper);
        paymentRequestWrapper.reasonOfPayment = chargeReason;
        paymentRequestWrapper.chargeCode = chargeCode;
        string paymentRequestBody = JSON.serialize(paymentRequestWrapper);
        system.debug('paymentRequestBody'+paymentRequestBody);
        ABCL_IntegrationCallout.IntegrationResponseWrapper paymentResponse = ABCL_IntegrationCallout.executeCallout(ABHFL_Constants.PAYMENTLINK_INTEGRATION_METADATA,paymentRequestBody,null);
        system.debug('paymentResponse.responseBody'+paymentResponse.responseBody);
        if(paymentResponse.statusCode == 200 && String.isNotBlank(paymentResponse.responseBody)){
                system.debug('paymentResponse.responseBody'+paymentResponse.responseBody);
                PaymentResponseWrapper paymentResponseWrapper = (PaymentResponseWrapper)JSON.deserialize(paymentResponse.responseBody,PaymentResponseWrapper.class);
                responseStr = JSON.serialize(paymentResponseWrapper);
                system.debug('paymentResponseWrapper Parsed'+paymentResponseWrapper);
                if(paymentResponseWrapper.returnCode == '1'){
                    result.Status = ABHFL_Constants.SUCCESS;
                    result.Response = paymentResponseWrapper.shortUrl;
                }
        }
        ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
        caseInteg.Case__c = caseRecord.Id;
        if(result.Status == ABHFL_Constants.SUCCESS){
            caseInteg.Status__c = ABHFL_Constants.SUCCESS;
        }else{
            caseInteg.Status__c = ABHFL_Constants.FAILURE;
        }
        caseInteg.Request__c = paymentRequestBody;
        caseInteg.Response__c = paymentResponse.responseBody;
        caseInteg.Integration_Ext_Id__c = intSpec.External_Id__c;
        if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
            insert caseInteg;
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
    /*
        Ticket: PR970457-1883
        Modified By: Ishan Khichadia 
        Description: Added 2 new variables called as impactType and salesId and populated it with caseRecord.ABHFL_Case_Detail__r.EMI_Tenure__c and caseRecord.Asset.Loan_Id__c respectively. Also the LAN is now populated with caseRecord.Asset.LAN__c and not with caseRecord.Asset.Loan_Id__c
        */
    public class PaytmRequestWrapper{
        public string custname;
        public string LAN;
        public string emailId;
        public string mobileNumber;
        public string type;
        public string Amount;
        public string Paymentcode;
        public string ParentcaseID;
        public Integer impactType;
        public string salesId;

        public PaytmRequestWrapper(Case caseRecord,Decimal GST){
            List<Contact> con = [SELECT Id, Email FROM Contact WHERE AccountId=:caseRecord.AccountId LIMIT 1];
            this.custname = caseRecord.Customer_name_formula__c;
            this.LAN = caseRecord.Asset.LAN__c;
            this.salesId = caseRecord.Asset.Loan_ID__c;
            this.emailId = caseRecord.Account.RecordType.Name == ABHFL_Constants.ACCOUNT_RECORDTYPE_NON_INDIVIDUAL?/*caseRecord.Account.Office_Email__c*/(con.size()>0?con[0].Email:''):caseRecord.Account.PersonEmail;
            this.mobileNumber = caseRecord.Account.RecordType.Name == ABHFL_Constants.ACCOUNT_RECORDTYPE_NON_INDIVIDUAL?caseRecord.Account.Phone:caseRecord.Account.PersonMobilePhone;
            this.type = ABHFL_Constants.PAYTM_REQUEST_TYPE;
            Decimal amountWithGST = caseRecord.ABHFL_Case_Detail__r.Payable_Charges__c * (1 + (GST / 100));
            Decimal formattedAmount = amountWithGST.setScale(2, System.RoundingMode.HALF_UP);
            this.Amount = String.valueof(formattedAmount);
            String emiTenure = caseRecord.ABHFL_Case_Detail__r.EMI_Tenure__c;
            System.debug('emiTenure: ' + emiTenure);
            if(emiTenure == 'EMI'){
                this.impactType = 1;    
            } else if(emiTenure == 'Tenure'){
                this.impactType = 2;
            } else{
                this.impactType = 0;
            }
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
        public string CustomerName;
        public string LAN;
        public string CRMCaseId;
        public string ChargeCode;
        public string ReasonOfPayment;
        public string PaymentLink;
        public string PaymentExpiryDate;


        public PaymentRequestWrapper(Case caseRecord, PaytmResponseWrapper paytmResponseWrapper ){
            this.CustomerName = caseRecord.Customer_name_formula__c;
            this.LAN = caseRecord.Asset.LAN__c;
            this.CRMCaseId = caseRecord.CaseNumber;
            this.ChargeCode = '';
            this.ReasonOfPayment = ABHFL_Constants.REASON_FOR_PAYMENT;
            this.PaymentLink = paytmResponseWrapper.shortUrl;
            this.PaymentExpiryDate = String.valueOf(system.now().addDays(5));
        }

        public PaymentRequestWrapper(){}
    }
    
    public class PaymentResponseWrapper{
        public string returnCode;
        public string returnMessage;
        public string shortUrl;
    }

    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){return null;}
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs){return null;}
}
