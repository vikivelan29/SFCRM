/*********************************************************
*@Class        :  ABHFL_REKYCIntegration
*@Author       :  Anjali Sharma
*@Created Date :  
*@Last Modified:  
*@description  :  Class for Re Kyc integration. 
*********************************************************/

public with sharing class ABHFL_REKYCIntegration implements ASF_IntegrationInvocable {

    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - evaluate
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the ASF_IntegrationsController class, this method evaluates whether REKYC integration should be fired or not.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();

        Integer withinMonth = Integer.valueOf(System.label.Re_Kyc_Month);
        result.status = ABHFL_Constants.ERROR;
        
        Case caseRecord = [
            SELECT Id, Account.IsPersonAccount, Account.KYC_Done_Date__c, Account.Client_Code__c, Business_Unit__c, CCC_External_Id__c, Customer_name_formula__c
            FROM Case
            WHERE Id =: caseRec.Id WITH SECURITY_ENFORCED
        ];
        //Check for Mandatory Conditions...
        if(String.isNotBlank(caseRecord.Customer_name_formula__c) && String.isNotBlank(caseRecord.Account.Client_Code__c) 
                     &&  caseRecord.Business_Unit__c != null  && String.isNotBlank(caseRecord.CCC_External_Id__c) && caseRecord.Account.KYC_Done_Date__c!=null){
            Date dueDate = caseRecord.Account.KYC_Done_Date__c;
            Date withinMonthDate = dueDate.addMonths(withinMonth);
            if(Date.today() < withinMonthDate){
                result.status = ABHFL_Constants.SUCCESS;
                result.response = Custom_Messages__mdt.getInstance('REKYC_EVALUATION_SUCCESS_RESPONSE').Message__c;
            }else{
                result.response = Custom_Messages__mdt.getInstance('REKYC_DUE_PERIODE_ENDED').Message__c;
            }
        }else{
            result.response = Custom_Messages__mdt.getInstance('REKYC_EVALUATE_FAILED_FIELD_BLANK_ERROR').Message__c;
        }
        return result;
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
                                                               AND Integration_Ext_Id__c =:integ.External_Id__c WITH SECURITY_ENFORCED];
        if(existingCaseIntRecords.size()>0 && Schema.sObjectType.ASF_Case_Integration__c.isUpdateable()){
        	for(ASF_Case_Integration__c cInt : existingCaseIntRecords){
                cInt.Status__c = ABHFL_Constants.CANCELED;
            }
            update existingCaseIntRecords;            
        }
        
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Case__c  = caseRec.Id;
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Status__c = ABHFL_Constants.PENDING;
        caseInt.Response__c = ABHFL_Constants.WAITING_API_RESPONSE;
        if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
            insert caseInt; 
        }

        Case caseRecord = [
            SELECT Id , Account.Client_Code__c, Business_Unit__c, CCC_External_Id__c, Customer_name_formula__c, Asset.LAN__c, Nature__c, Account.KYC_Done_Date__c, Account.PersonEmail,
             Account.PersonMobilePhone, Account.PAN__c, Account.PersonBirthdate, Account.Street_Address_1__c, Account.Street_Address_2__c, Account.Street_Address_3__c, Account.City__c, Account.State__c
            FROM Case
            WHERE Id =: caseRec.Id WITH SECURITY_ENFORCED
        ];

        String kycDoneDate = String.valueOf(caseRecord.Account.KYC_Done_Date__c);
        String birthDate = String.valueOf(caseRecord.Account.PersonBirthdate);

        Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
        caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
        caseIntOut.Case_Integration_ID__c = caseInt.Id;
        caseIntOut.Integration_Name__c  = integ.Display_Name__c;
        caseIntOut.Request_Payload__c  =  JSON.serialize(new REKYCRequestWrapper(caseRecord.Business_Unit__c, caseRecord.CCC_External_Id__c, caseRecord.Account.Client_Code__c, caseRecord.Customer_name_formula__c, caseRecord.Asset.LAN__c,
                                            caseRecord.Nature__c, kycDoneDate, caseRecord.Account.PersonEmail, caseRecord.Account.PersonMobilePhone, caseRecord.Account.PAN__c, birthDate,
                                             caseRecord.Account.Street_Address_1__c, caseRecord.Account.Street_Address_2__c, caseRecord.Account.Street_Address_3__c, caseRecord.Account.City__c, caseRecord.Account.State__c
                                            ));
        Database.SaveResult publishResult = EventBus.publish(caseIntOut);
        if(publishResult.isSuccess()){
            result.status = ABHFL_Constants.SUCCESS;
            result.response = Custom_Messages__mdt.getInstance('REKYC_RUN_SUCCESS').Message__c;
        }else{
            result.status = ABHFL_Constants.ERROR;
        }
        return result;
    }



    /****************************************************************************************************************
    * @description - 
    * @Function - processResponse
    * @param caseInteg - ASF_Case_Integration record.
    *****************************************************************************************************************/
    public void processResponse(ASF_Case_Integration__c caseInteg){
       
    }


    /****************************************************************************************************************
    *@description - Wrapper class to get set all the request parameters
    *****************************************************************************************************************/

    public class REKYCRequestWrapper{
        public string lob;
        public String ccc;
        public String customerNo;
        public String name;
        public String lanNo;
        public String riskCategory;
        public String reKYCDate;
        public String email;
        public String mobile1;
        public String pan;
        public String dob;
        public String currentAddressLine1;
        public String currentAddressLine2;
        public String currentAddressLine3;
        public String currentCity;
        public String currentState;
       // public String customerCategory;
        
        REKYCRequestWrapper(string lob, String ccc, String customerNo, String name, String lanNo, String riskCategory, String reKYCDate, String email, String mobile1, String pan, String dob,String currentAddressLine1 ,String currentAddressLine2 ,String currentAddressLine3, String currentCity, String currentState){
            this.lob = lob;
            this.ccc = ccc;
            this.customerNo = customerNo;
            this.name = name;
            this.lanNo = lanNo;
            this.riskCategory = riskCategory;
            this.reKYCDate = reKYCDate;
            this.email = email;
            this.mobile1 = mobile1;
            this.pan = pan;
            this.dob = dob;
            this.currentAddressLine1 = currentAddressLine1;
            this.currentAddressLine2 = currentAddressLine2;
            this.currentAddressLine3 = currentAddressLine3; 
            this.currentCity = currentCity;
            this.currentState = currentState;
           // this.customerCategory = customerCategory;
        }
    }
}