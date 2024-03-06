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
        if(caseRecord.Account.IsPersonAccount){
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
        } else{
            result.response = Custom_Messages__mdt.getInstance('REKYC_FAILED_NOT_PERSON_ACCOUNT').Message__c;
        }
        return result;
    }
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        
        Integer withinMonth = Integer.valueOf(System.label.Re_Kyc_Month);
        
        // Case caseRecord = [
        //     SELECT Id, Account.IsPersonAccount, Account.KYC_Done_Date__c, Account.Client_Code__c, Business_Unit__c, CCC_External_Id__c, Customer_name_formula__c
        //     FROM Case
        //     WHERE Id =: caseRec.Id WITH SECURITY_ENFORCED
        // ];
        List<Case> caseRecords = new List<Case>();
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }

        for(Case caseRecord : caseRecords){
            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            result.status = ABHFL_Constants.ERROR;
            //Check for Mandatory Conditions...
            if(caseRecord.Account.IsPersonAccount){
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
            } else{
                result.response = Custom_Messages__mdt.getInstance('REKYC_FAILED_NOT_PERSON_ACCOUNT').Message__c;
            }
            resultMap.put(caseRecord.Id, result);
        }
        return resultMap;
    }

     /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - run
    * @param integ - ASF_Integration record.
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the ASF_IntegrationsController class, this method runs the REKYC integration and creates Case Integration record.
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
        
        Case caseRecord = [
            SELECT Id , Account.Client_Code__c, Business_Unit__c, CCC_External_Id__c, Customer_name_formula__c, Asset.LAN__c, Asset.Last_Disbursement_Date__c, Nature__c, Account.KYC_Done_Date__c, Account.PersonEmail,
             Account.PersonMobilePhone, Account.PAN__c, Account.PersonBirthdate, Account.Street_Address_1__c, Account.Street_Address_2__c, Account.Street_Address_3__c, Account.City__c, Account.State__c
            FROM Case
            WHERE Id =: caseRec.Id WITH SECURITY_ENFORCED
        ];

        String kycDoneDate = String.valueOf(caseRecord.Account.KYC_Done_Date__c);
        String birthDate = String.valueOf(caseRecord.Account.PersonBirthdate);
        String lastDisbursementDate = String.valueOf(caseRecord.Asset.Last_Disbursement_Date__c);

        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Case__c  = caseRec.Id;
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Status__c = ABHFL_Constants.PENDING;
        caseInt.Request__c  =  JSON.serialize(new REKYCRequestWrapper(caseRecord.Business_Unit__c, caseRecord.CCC_External_Id__c, caseRecord.Account.Client_Code__c, caseRecord.Customer_name_formula__c, caseRecord.Asset.LAN__c,
                                            caseRecord.Nature__c, kycDoneDate, caseRecord.Account.PersonEmail, caseRecord.Account.PersonMobilePhone, caseRecord.Account.PAN__c, birthDate,
                                             caseRecord.Account.Street_Address_1__c, caseRecord.Account.Street_Address_2__c, caseRecord.Account.Street_Address_3__c, caseRecord.Account.City__c, caseRecord.Account.State__c, 
                                             lastDisbursementDate
                                            ));
        caseInt.Response__c = ABHFL_Constants.WAITING_API_RESPONSE;
        if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
            insert caseInt; 
        }

        ASF_Case_Integration__c caseInt1 = [Select id, name from ASF_Case_Integration__c where id =: caseInt.Id ];
        Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
        caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
        caseIntOut.Case_Integration_ID__c = caseInt1.Name;
        caseIntOut.ServiceName__c = ABHFL_Constants.REKYC_SERVICE_NAME;
        caseIntOut.Integration_Name__c  = ABHFL_Constants.REKYC_SERVICE_NAME;
        caseIntOut.Request_Payload__c  =  JSON.serialize(new REKYCRequestWrapper(caseRecord.Business_Unit__c, caseRecord.CCC_External_Id__c, caseRecord.Account.Client_Code__c, caseRecord.Customer_name_formula__c, caseRecord.Asset.LAN__c,
                                            caseRecord.Nature__c, kycDoneDate, caseRecord.Account.PersonEmail, caseRecord.Account.PersonMobilePhone, caseRecord.Account.PAN__c, birthDate,
                                             caseRecord.Account.Street_Address_1__c, caseRecord.Account.Street_Address_2__c, caseRecord.Account.Street_Address_3__c, caseRecord.Account.City__c, caseRecord.Account.State__c,
                                             lastDisbursementDate
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
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();

        Set<String> intIds = new Set<String>();
        for(Case caseRec : caseRecs){
            for(ASF_Integration__c integ : integs.get(caseRec.Id)){
                intIds.add(integ.External_Id__c);
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
        
        // Case caseRecord = [
        //     SELECT Id , Account.Client_Code__c, Business_Unit__c, CCC_External_Id__c, Customer_name_formula__c, Asset.LAN__c, Asset.Last_Disbursement_Date__c, Nature__c, Account.KYC_Done_Date__c, Account.PersonEmail,
        //      Account.PersonMobilePhone, Account.PAN__c, Account.PersonBirthdate, Account.Street_Address_1__c, Account.Street_Address_2__c, Account.Street_Address_3__c, Account.City__c, Account.State__c
        //     FROM Case
        //     WHERE Id =: caseRec.Id WITH SECURITY_ENFORCED
        // ];
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
                String kycDoneDate = String.valueOf(caseRecord.Account.KYC_Done_Date__c);
                String birthDate = String.valueOf(caseRecord.Account.PersonBirthdate);
                String lastDisbursementDate = String.valueOf(caseRecord.Asset.Last_Disbursement_Date__c);

                ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
                caseInt.Case__c  = caseRecord.Id;
                caseInt.Integration_Ext_Id__c = integ.External_Id__c;
                caseInt.Status__c = ABHFL_Constants.PENDING;
                caseInt.Request__c  =  JSON.serialize(new REKYCRequestWrapper(caseRecord.Business_Unit__c, caseRecord.CCC_External_Id__c, caseRecord.Account.Client_Code__c, caseRecord.Customer_name_formula__c, caseRecord.Asset.LAN__c,
                                                    caseRecord.Nature__c, kycDoneDate, caseRecord.Account.PersonEmail, caseRecord.Account.PersonMobilePhone, caseRecord.Account.PAN__c, birthDate,
                                                    caseRecord.Account.Street_Address_1__c, caseRecord.Account.Street_Address_2__c, caseRecord.Account.Street_Address_3__c, caseRecord.Account.City__c, caseRecord.Account.State__c, 
                                                    lastDisbursementDate
                                                    ));
                caseInt.Response__c = ABHFL_Constants.WAITING_API_RESPONSE;
                newCaseIntegrations.add(caseInt);

                Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
                caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
                //caseIntOut.Case_Integration_ID__c = caseInt1.Name;
                caseIntOut.ServiceName__c = ABHFL_Constants.REKYC_SERVICE_NAME;
                caseIntOut.Integration_Name__c  = ABHFL_Constants.REKYC_SERVICE_NAME;
                caseIntOut.Request_Payload__c  =  JSON.serialize(new REKYCRequestWrapper(caseRecord.Business_Unit__c, caseRecord.CCC_External_Id__c, caseRecord.Account.Client_Code__c, caseRecord.Customer_name_formula__c, caseRecord.Asset.LAN__c,
                                                    caseRecord.Nature__c, kycDoneDate, caseRecord.Account.PersonEmail, caseRecord.Account.PersonMobilePhone, caseRecord.Account.PAN__c, birthDate,
                                                    caseRecord.Account.Street_Address_1__c, caseRecord.Account.Street_Address_2__c, caseRecord.Account.Street_Address_3__c, caseRecord.Account.City__c, caseRecord.Account.State__c,
                                                    lastDisbursementDate
                                                    ));
                peMap.put(index, caseIntOut);
                indexToCaseId.put(index, caseRecord.Id);
                index++;
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
                wrap.response = Custom_Messages__mdt.getInstance('REKYC_RUN_SUCCESS').Message__c;
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
        public string LOB;
        public String CCC;
        public String CUSTOMERNO;
        public String NAME;
        public String LANNO;
        public String Riskcategory;
        public String ReKYCDate;
        public String EMAIL;
        public String Mobile1;
        public String PAN;
        public String DOB;
        public String CurrentAddressLine1;
        public String CurrentAddressLine2;
        public String CurrentAddressLine3;
        public String CurrentCity;
        public String CurrentState;
        //public String CustomerCategory;
        public String SYS;
        // public String Mobile2;
        // public String Mobile3;
        // public String Mobile4;
        // public String PermanentAddressLine1;
        // public String PermanentAddressLine2;
        // public String PermanentAddressLine3;
        // public String PermanentCity;
        // public String PermanentState;
        // public String CLOSERDATE;
        public String DisbursementDate;


        
        REKYCRequestWrapper(string lob, String ccc, String customerNo, String name, String lanNo, String riskCategory, String reKYCDate, String email, String mobile1, String pan, String dob,String currentAddressLine1 ,String currentAddressLine2 ,String currentAddressLine3, String currentCity, String currentState, String disbursementDate){
            this.LOB = lob;
            this.CCC = ccc;
            this.CUSTOMERNO = customerNo;
            this.NAME = name;
            this.LANNO = lanNo;
            this.Riskcategory = riskCategory;
            this.ReKYCDate = reKYCDate;
            this.EMAIL = email;
            this.Mobile1 = mobile1;
            this.PAN = pan;
            this.DOB = dob;
            this.CurrentAddressLine1 = currentAddressLine1;
            this.CurrentAddressLine2 = currentAddressLine2;
            this.CurrentAddressLine3 = currentAddressLine3; 
            this.CurrentCity = currentCity;
            this.CurrentState = currentState;
            this.DisbursementDate = disbursementDate;
            this.SYS = ABHFL_Constants.REKYC_SYS_NAME;
        }
    }
}