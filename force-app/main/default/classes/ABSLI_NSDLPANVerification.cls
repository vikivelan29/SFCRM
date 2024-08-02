public with sharing class ABSLI_NSDLPANVerification {

    @AuraEnabled(cacheable=true)
    public static PANVerificationWrapper getPanVerificationDetails(string caseId){
        try {
            PANVerificationWrapper panWrapper = new PANVerificationWrapper();

            Case caseRecord = [Select id,AccountId,ABSLI_Case_Detail__r.Status_Valid_For_STP__c,Account.Name,
                               Account.IsPersonAccount,Account.PAN__c,Account.PersonBirthdate,ABSLI_Case_Detail__r.PAN_Number__c	
                               from Case where id =: caseId limit 1];
            
            if(caseRecord.Account.IsPersonAccount){
                panWrapper.name = caseRecord.Account.Name;
                String panFromCaseExt = caseRecord.ABSLI_Case_Detail__r.PAN_Number__c;
                panWrapper.pan = panFromCaseExt != null  && panFromCaseExt != '' ? panFromCaseExt : '';
                panWrapper.dob = caseRecord.Account.PersonBirthdate;
                panWrapper.panValidationStatus = caseRecord.ABSLI_Case_Detail__r.Status_Valid_For_STP__c;
                panWrapper.caseExtId = caseRecord.ABSLI_Case_Detail__c;
            }else{
                List<Contact> contactRecord = [Select id,Name,Birthdate,Account.PAN__c from Contact where Primary__c = true and AccountId = :caseRecord.AccountId limit 1];
                if(contactRecord.size() > 0){
                    panWrapper.name = contactRecord[0].Name;
                    //panWrapper.pan = caseRecord.Account.PAN__c;
                    panWrapper.dob = contactRecord[0].Birthdate; 
                    panWrapper.panValidationStatus = caseRecord.ABSLI_Case_Detail__r.Status_Valid_For_STP__c;   
                    panWrapper.caseExtId = caseRecord.ABSLI_Case_Detail__c;
                }
            }

            return panWrapper;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void updateSTPFlagOnCaseDetail(String caseExtId, boolean flagVal){
        ABSLI_Case_Detail__c caseExtRec = new ABSLI_Case_Detail__c(Id = caseExtId);
        caseExtRec.Status_Valid_For_STP__c = flagVal;
        update caseExtRec;
    }
    
    @AuraEnabled
    public static PANVerificationResponseWrapper verifyPANDetails(String panInputWrapperStr, String caseId){
        try {
            PANVerificationResponseWrapper panResponseWrapper = new PANVerificationResponseWrapper();
            panResponseWrapper.isSuccess = false;
            PANRequestWrapper panRequest = new PANRequestWrapper();
            PANInputWrapper panInputWrapper = (PANInputWrapper)JSON.deserialize(panInputWrapperStr,PANInputWrapper.class);
            panRequest.SOURCE = System.label.ABSLI_ESB_SOURCE_VAL;
            Date dob = Date.valueof(panInputWrapper.dob);
            DateTime dobDateTime = DateTime.newInstance(dob.year(), dob.month(),dob.day());
            panInputWrapper.dob =  dobDateTime.Format('dd/MM/yyyy');
            panInputWrapper.fathername = '';
            panRequest.inputData = new List<PANInputWrapper>{panInputWrapper};
            ABCL_IntegrationCallout.IntegrationResponseWrapper nsdlResponse = ABCL_IntegrationCallout.executeCallout(ABSLI_Constants.PAN_VERIFICATION_INTEGRATION_METADATA,
                                                                                                                    JSON.serialize(panRequest),
                                                                                                                    null);
            if(String.isNotBlank(nsdlResponse.responseBody)){
                PANResponseWrapper responseWrapper = (PANResponseWrapper)JSON.deserialize(nsdlResponse.responseBody,PANResponseWrapper.class);
                if(nsdlResponse.statusCode == 200){
                    panResponseWrapper.isSuccess = true;
                    panResponseWrapper.responseStr = nsdlResponse.responseBody;
                }else {
                    if(responseWrapper.Fault != null && responseWrapper.Fault.FaultMessage != null){
                        panResponseWrapper.errorMessage = responseWrapper.Fault.FaultMessage.resposne_Message;
                    }
                    else{
                       panResponseWrapper.errorMessage = 'Opps! Something went wrong at API Layer'; 
                    }
                }
            }
            string status = '';
            if(panResponseWrapper.isSuccess){
                status = ABHFL_Constants.SUCCESS;
            }else{
                status = ABHFL_Constants.FAILURE;
            }

            ABCL_IntegrationCommonUtility.caseIntegrationLogger(caseId,
                JSON.serialize(panRequest),
                nsdlResponse.responseBody,
                /*intExtId*/'',
                status);

            return panResponseWrapper;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static PANVerificationResponseWrapper verifyPAN(String panInputWrapperStr, String caseId, String intExtId){
        try {

            /*List<ASF_Case_Integration__c> caseInt =  [SELECT Id, Status__c, Case__c, Integration_Ext_Id__c 
                                                      FROM ASF_Case_Integration__c WHERE Case__c =:caseId 
                                                      AND Integration_Ext_Id__c  =:intExtId];
                                                
            if(caseInt.size()>0){
                for(ASF_Case_Integration__c caseInteg : caseInt){
                    caseInteg.Status__c = ABSLI_Constants.CANCELED;
                }
                if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
                    update caseInt;
                }
            }               */                    

            PANVerificationResponseWrapper panResponseWrapper = new PANVerificationResponseWrapper();
            panResponseWrapper.isSuccess = false;
            PANRequestWrapper panRequest = new PANRequestWrapper();
            PANInputWrapper panInputWrapper = (PANInputWrapper)JSON.deserialize(panInputWrapperStr,PANInputWrapper.class);
            panRequest.SOURCE = System.label.ABSLI_ESB_SOURCE_VAL;
            Date dob = Date.valueof(panInputWrapper.dob);
            DateTime dobDateTime = DateTime.newInstance(dob.year(), dob.month(),dob.day());
            panInputWrapper.dob =  dobDateTime.Format('dd/MM/yyyy');
            panInputWrapper.fathername = '';
            panRequest.inputData = new List<PANInputWrapper>{panInputWrapper};
            ABCL_IntegrationCallout.IntegrationResponseWrapper nsdlResponse = ABCL_IntegrationCallout.executeCallout(ABSLI_Constants.PAN_VERIFICATION_INTEGRATION_METADATA,
                                                                                                                    JSON.serialize(panRequest),
                                                                                                                    null);
            if(String.isNotBlank(nsdlResponse.responseBody)){
                PANResponseWrapper responseWrapper = (PANResponseWrapper)JSON.deserialize(nsdlResponse.responseBody,PANResponseWrapper.class);
                if(nsdlResponse.statusCode == 200){
                    Case caseRecord = [Select ABSLI_Case_Detail__c from Case where id =: caseId limit 1];
                    ABSLI_Case_Detail__c caseDetail = new ABSLI_Case_Detail__c();
                    caseDetail.Id = caseRecord.ABSLI_Case_Detail__c;
                    caseDetail.Status_Valid_For_STP__c = true;
                    if(Schema.sObjectType.ABSLI_Case_Detail__c.isUpdateable()){
                        update caseDetail;
                    }
                    panResponseWrapper.isSuccess = true;
                    panResponseWrapper.responseStr = nsdlResponse.responseBody;
                }else {
                    if(responseWrapper.Fault != null && responseWrapper.Fault.FaultMessage != null){
                        panResponseWrapper.errorMessage = responseWrapper.Fault.FaultMessage.resposne_Message;
                    }
                }
            }
            string status = '';
            if(panResponseWrapper.isSuccess){
                status = ABHFL_Constants.SUCCESS;
            }else{
                status = ABHFL_Constants.FAILURE;
            }

            ABCL_IntegrationCommonUtility.caseIntegrationLogger(caseId,
                                                                JSON.serialize(panRequest),
                                                                nsdlResponse.responseBody,
                                                                intExtId,
                                                                status);
            return panResponseWrapper;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static PANVerificationResponseWrapper updatePAN(string caseId){
        try {
            PANVerificationResponseWrapper responseWrapper = new PANVerificationResponseWrapper();
            responseWrapper.isSuccess = true;
            Case caseRecord = [Select ABSLI_Case_Detail__c,CCC_External_Id__c from Case where id =: caseId limit 1];
            ABSLI_PanUpdateIntegration panUpdateInt = new ABSLI_PanUpdateIntegration();
            ABSLI_Case_Detail__c caseDetail = new ABSLI_Case_Detail__c();
            caseDetail.Id = caseRecord.ABSLI_Case_Detail__c;
            caseDetail.Status_Valid_For_STP__c = true;
            if(Schema.sObjectType.ABSLI_Case_Detail__c.isUpdateable()){
                update caseDetail;
            }
            //ASF_IntegrationsController.IntegrationWrapper evaluationResponseWrapper = panUpdateInt.evaluate(caseRecord);
            //if(evaluationResponseWrapper.status == ABSLI_Constants.SUCCESS){
            /*    List<ASF_Integration__c> integrationSpec = [SELECT Id, OwnerId, IsDeleted, Name, CreatedDate, CreatedById, 
                                                      LastModifiedDate, LastModifiedById, SystemModstamp, Auto_Run_on_Load__c, 
                                                      Case_Stage_Config__c, Display_Name__c, Display_Order__c, External_Id__c, 
                                                      Mandatory_At_Stage_Movement__c, Processing_Class__c, STP_Processing_Class__c, 
                                                      Type__c, UI_Component__c, Visibility_Class__c, When_to_Appear__c, C3ExternalId__c, 
                                                      Query_Fields__c, STP_API_Identifier__c, STP_Config_External_Id__c, STP_Template__c, 
                                                      Priority__c, Run_Integration_From_LWC__c 
                                                      FROM ASF_Integration__c 
                                                      where Processing_Class__c = 'ABSLI_PanUpdateIntegration'
                                                      AND Case_Stage_Config__r.Case_Category_Config__r.CCC_External_Id__c =: caseRecord.CCC_External_Id__c limit 1];
            if(integrationSpec.size() > 0){
                ASF_IntegrationsController.IntegrationWrapper intResponse = ASF_IntegrationsController.runIntegration(integrationSpec[0],caseRecord);                                                     
                if(intResponse.status == ABSLI_Constants.SUCCESS){
                    responseWrapper.isSuccess = true;
                }else{
                    responseWrapper.errorMessage = intResponse.response;
                }               
            }*/

                /*ASF_IntegrationsController.IntegrationWrapper runResponseWrapper = panUpdateInt.run(integrationSpec,caseRecord);
                if(runResponseWrapper.status == ABSLI_Constants.SUCCESS){
                    responseWrapper.isSuccess = true;
                } else {
                    responseWrapper.errorMessage = runResponseWrapper.response;
                }
            }else{
                responseWrapper.errorMessage = evaluationResponseWrapper.response;
            }*/
            return responseWrapper;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    public class PANVerificationWrapper{
        @AuraEnabled
        public string name;
        @AuraEnabled
        public string pan;
        @AuraEnabled
        public Date dob;
        @AuraEnabled
        public Boolean panValidationStatus;
        @AuraEnabled
        public string caseExtId;
    }

    public class PANRequestWrapper{
        public String SOURCE;
        public PANInputWrapper[] inputData;
    }

    public class PANInputWrapper{
        public string name;
        public string pan;
        public string dob;
        public string fathername;
    }

    public class PANResponseWrapper{
        public String response_Code;
        public PANOutputWrapper[] outputData;
        public FaultWrapper Fault;
        public String resposne_Message;
    }

    public class PANOutputWrapper {
        public String pan;
        public String pan_status;
        public String name;
        public String fathername;
        public String dob;
        public String seeding_status;
    }

    public class PANErrorResponseWrapper{
        public FaultWrapper Fault;
    }

    class FaultWrapper {
        public String FaultCode;
        public FaultMessageWrapper FaultMessage;
    }

    public class FaultMessageWrapper {
        public String response_Code;
        public String resposne_Message;
    }

    public class PANVerificationResponseWrapper{
        @AuraEnabled
        public String errorMessage;
        @AuraEnabled
        public Boolean isSuccess;
        @AuraEnabled
        public String responseStr;
    }
}