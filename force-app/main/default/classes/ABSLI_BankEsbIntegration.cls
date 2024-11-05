/*********************************************************
*Class        :  ABSLI_BankEsbIntegration
*Author       :  Aditya Mehrotra
*Created Date :  05/27/2024
*Last Modified:  05/27/2024
*@description :  Class for Bank ESB Service Integration with SSESB
*********************************************************/
@SuppressWarnings('PMD.CognitiveComplexity')
public without sharing class ABSLI_BankEsbIntegration implements ASF_IntegrationInvocable{
	
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = ABSLI_Constants.ERROR;
        result.response = Custom_Messages__mdt.getInstance('ABSLI_BankEsbIntegration_FROMBTN').Message__c;
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> returnMap = evaluate(new List<Case>{caseRec});
        return returnMap.get(caseRec.Id);
    }
    
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        List<Case> caseRecords = new List<Case>();
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }
        for(Case caseRecord : caseRecords){
            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            result.status = ABSLI_Constants.ERROR;
            result.response = Custom_Messages__mdt.getInstance('ABSLI_BankEsbIntegration_ERR1').Message__c;
            
            if(caseRecord.ABSLI_Case_Detail__r.Status_Valid_For_STP__c == true && caseRecord.Technical_Source__c=='API'){
				if(!String.isBlank(caseRecord.ABSLI_Case_Detail__r.IFSC_Code__c) || !String.isBlank(caseRecord.ABSLI_Case_Detail__r.MICR_Code__c)){
                    result.status = ABSLI_Constants.SUCCESS;
                }else{
                    result.response = Custom_Messages__mdt.getInstance('ABSLI_BankEsbIntegration_ERR2').Message__c;
                } 
            }else if(caseRecord.Technical_Source__c =='LWC'){
                if(!String.isBlank(caseRecord.ABSLI_Case_Detail__r.IFSC_Code__c) || !String.isBlank(caseRecord.ABSLI_Case_Detail__r.MICR_Code__c)){
                    result.status = ABSLI_Constants.SUCCESS;
                }else{
                    result.response = Custom_Messages__mdt.getInstance('ABSLI_BankEsbIntegration_ERR2').Message__c;
                }
            }
            resultMap.put(caseRecord.Id, result);
        }
        return resultMap;
    }
    
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integ, Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        Map<Id, List<ASF_Integration__c>> integMap = new Map<Id,List<ASF_Integration__c>>();
        integMap.put(caseRec.Id,new List<ASF_Integration__c>{integ});
        Map<Id,ASF_IntegrationsController.IntegrationWrapper> resultMap = run(integMap,new List<Case>{caseRec});
        return resultMap.get(caseRec.Id);
    }
    
    @SuppressWarnings('PMD.AvoidDeeplyNestedIfStmts')
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        
        Case caseRecord = ASF_IntegrationsController.queriedCasesForIntegration.get(caseRecs[0].Id);
        if(integs.get(caseRecs[0].Id)[0].Processing_Class__c == ABSLI_BankEsbIntegration.class.getName()){
            String ifscCode = String.valueOf(caseRecord.ABSLI_Case_Detail__r.IFSC_Code__c);
            String micrCode = String.valueOf(caseRecord.ABSLI_Case_Detail__r.MICR_Code__c);
            
            ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
            caseInt.Case__c  = caseRecord.Id;
            caseInt.Integration_Ext_Id__c = integs.get(caseRecord.Id)[0].External_Id__c;
            caseInt.Status__c = ABSLI_Constants.PENDING;
            caseInt.Request__c  =  JSON.serialize(new BankEsbRequest(ifscCode,micrCode));
            caseInt.Response__c = ABSLI_Constants.WAITING_API_RESPONSE;
            
            ABCL_IntegrationCallout.IntegrationResponseWrapper responseWrapper = ABSLI_BankEsbIntegration.performCallout(ifscCode, micrCode);
            if(responseWrapper.statusCode == 200 && String.isNotBlank(responseWrapper.responseBody)){
                BankEsbResponse bankEsbResponse = (BankEsbResponse)JSON.deserialize(responseWrapper.responseBody,BankEsbResponse.class);
                if(bankEsbResponse.ReturnCode == '0'){
                    ABSLI_Case_Detail__c caseExt = [SELECT Id, IFSC_Code__c, MICR_Code__c, Bank_Name__c, Branch_Name__c
                                                   FROM ABSLI_Case_Detail__c WHERE Id=:caseRecord.ABSLI_Case_Detail__c WITH SYSTEM_MODE];
                    caseExt.IFSC_Code__c = String.valueOf(bankEsbResponse.lstDetails.IFSC_CODE);
                    caseExt.MICR_Code__c = String.valueOf(bankEsbResponse.lstDetails.MICR_CODE);
                    caseExt.Bank_Name__c = String.valueOf(bankEsbResponse.lstDetails.BANK_NAME);
                    caseExt.Branch_Name__c = String.valueOf(bankEsbResponse.lstDetails.BANK_BRANCH);
                    
                    if(!Test.IsRunningTest() && Schema.sObjectType.ABSLI_Case_Detail__c.isUpdateable()){
                        update caseExt;
                    }
                    
                  	caseInt.Response__c = String.valueOf(bankEsbResponse);
                    caseInt.Status__c = ABHFL_Constants.SUCCESS;
                    ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
                   	wrap.status = ABHFL_Constants.SUCCESS;
                    wrap.response = Custom_Messages__mdt.getInstance('REKYC_RUN_SUCCESS').Message__c;
                    resultMap.put(caseRecord.Id, wrap);
                }else{
                    caseInt.Response__c = ABSLI_Constants.BANK_ESB_FAILURE_RESPONSE;
                    caseInt.Status__c = ABHFL_Constants.FAILURE;
                    ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
                    wrap.status = ABHFL_Constants.ERROR;
                   	wrap.response = ABSLI_Constants.BANK_ESB_FAILURE_RESPONSE;
                    resultMap.put(caseRecord.Id, wrap);
                }
            }
            
            List<ASF_Case_Integration__c> existingCaseIntegrations = new List<ASF_Case_Integration__c>();
            existingCaseIntegrations = [SELECT Id, Status__c, Case__c, Integration_Ext_Id__c 
                                                                    FROM ASF_Case_Integration__c
                                                                    WHERE Case__c =:caseRecs[0].Id 
                                                                    AND Integration_Ext_Id__c =:integs.get(caseRecs[0].Id)[0].External_Id__c WITH SYSTEM_MODE];
            
            if(existingCaseIntegrations.size()>0){
                for(ASF_Case_Integration__c cInt : existingCaseIntegrations){
                    cInt.Status__c = ABHFL_Constants.CANCELED;
                }
                if(Schema.sObjectType.ASF_Case_Integration__c.isUpdateable()){
                    ASF_TriggerSkipperUtility.markTriggerRun('ASF_Case_Integration__c');
                    update existingCaseIntegrations;
                    ASF_TriggerSkipperUtility.resetTriggerRun('ASF_Case_Integration__c');
                }
            }
            
            if(!Test.IsRunningTest() && Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
                ASF_TriggerSkipperUtility.markTriggerRun('ASF_Case_Integration__c');
                insert caseInt;
                ASF_TriggerSkipperUtility.resetTriggerRun('ASF_Case_Integration__c');
            }
            
        }        
        return resultMap;
    }
    
    public static ABCL_IntegrationCallout.IntegrationResponseWrapper performCallout(String ifscCode, String micrCode){ 
       	return(ABCL_IntegrationCallout.executeCallout(ABSLI_Constants.BANK_ESB_INTEGRATION_METADATA,
                                                          JSON.serialize(new BankEsbRequest(ifscCode,micrCode)),null));
    }
    
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public void processResponse(ASF_Case_Integration__c caseInteg){
    }
    
    public class BankEsbRequest{
        public ObjRequest ObjRequest{get;set;}
        public BankEsbRequest(String ifscCode, String micrCode)
        {
            ObjRequest obj = new ObjRequest();
            obj.IFSC_CODE = ifscCode;
            obj.MICR_CODE = micrCode;
            obj.ClientIPAddress = '';
            obj.DeviceID = '';
            obj.OS = '';
            obj.IMEI = '';
            obj.UDP = '';
            obj.UDP1 = '';
            obj.UDP2 = '';
            obj.UDP3 = '';
            obj.UDP4 = '';
            obj.UDP5 = '';
            this.ObjRequest = obj;
        }
    }
    
    public class ObjRequest{
        public String IFSC_CODE{get;set;}
        public String MICR_CODE{get;set;}
        public String ClientIPAddress{get;set;}
        public String DeviceID{get;set;}
        public String OS{get;set;}
        public String IMEI{get;set;}
        public String UDP{get;set;}
        public String UDP1{get;set;}
        public String UDP2{get;set;}
        public String UDP3{get;set;}
        public String UDP4{get;set;}
        public String UDP5{get;set;}
    }
    
    public class BankEsbResponse{
        public String ReturnMessage{get;set;}
        public String ReturnCode{get;set;}
        public lstDetails lstDetails{get;set;}
    }
    
    public class lstDetails{
        public String IFSC_CODE{get;set;}
        public String MICR_CODE{get;set;}
        public String BANK_NAME{get;set;}
        public String BANK_BRANCH{get;set;}
    }
}