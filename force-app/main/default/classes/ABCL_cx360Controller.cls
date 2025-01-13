/*********************************************************
*Class        :  ABCL_cx360Controller
*Author       :  Nikhil Patewar
*Description  :  Backend Controller for Customer 360 data and actions
*********************************************************/
public class ABCL_cx360Controller {
    
    @AuraEnabled(cacheable=true)
    public static Account getCustomerInfo(String customerId){
        try {
            //return [Select Id,Name,AccountNumber, PersonEmail, Phone, PAN__c, PAN_Number__c, PreferredLanguage__pc, ShippingState, BillingState, Handle_With_Care_HWC__c, Customer_Since__c, WhatsApp_Opt_in_status__c, ABC_Consent__c from Account Where Id=:customerId];
            return [Select Id,Name,AccountNumber, PersonEmail, Phone, PAN__c, ShippingState, BillingState from Account Where Id=:customerId];
		} catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
	@AuraEnabled(cacheable=true)
    public static List<Asset> getProductsOwned(String customerId){
        try {
            return [Select Id,Loan_Disbursement_Status__c, Disbursed_Amount__c, Status, Name, LAN__c,LOB__c,Loan_Type__c,DA_Transaction__c,Sanction_Amount__c,VAN__c from Asset Where AccountId=:customerId];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ABCL_CX360_Quick_Actions__mdt> getQuickActions(String customerId){
        try {
            Account acc=[Select Id,Business_Unit__c from Account Where Id=:customerId];
            return [Select Id,Business_Unit__c,Icon_Name__c,MasterLabel,Sequence__c FROM ABCL_CX360_Quick_Actions__mdt WHERE Business_Unit__c =:acc.Business_Unit__c Order By Sequence__c ASC];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Boolean createCases(String customerId,String lanId,Boolean createSOACase,Boolean createRSCase,Boolean createICCase,Boolean createPICCase, Boolean createNDCCase, Boolean createWKCase, Boolean createLODCase){
        try{
            Boolean casesCreated=false;
            Account acc=[Select Id,Business_Unit__c from Account Where Id=:customerId];
            Asset asset=[Select Id,Loan_Disbursement_Status__c, Disbursed_Amount__c, Status, Name, LAN__c,LOB__c,Loan_Type__c,DA_Transaction__c,Sanction_Amount__c,VAN__c from Asset Where AccountId=:customerId AND Id=:lanId];
            if(createSOACase==true){
                ASF_Case_Category_Config__c caseCatConfig = [Select Id, Type__c,Sub_Type__c,CCC_External_Id__c,Business_Unit__c,Nature__c from ASF_Case_Category_Config__c Where CCC_External_Id__c=:ABHFL_Constants.SOA_CCC_EXTERNALID];
                //Insert case
                Case caseRecord = new Case();
                caseRecord.CCC_External_Id__c=caseCatConfig.CCC_External_Id__c;
                caseRecord.Nature__c=caseCatConfig.Nature__c;
                caseRecord.AccountId=customerId;
                caseRecord.AssetId = lanId;
                caseRecord.Source__c= 'API';
                if(Schema.sObjectType.Case.isCreateable()){
                    Insert caseRecord;   
                }
        		
                case caseCreated=[SELECT Id,CaseNumber FROM Case WHERE Id=:caseRecord.Id];
                
                //Insert ABHFL_Case_Details__c
                ABHFL_Case_Detail__c caseDetails = new ABHFL_Case_Detail__c();
                caseDetails.From_Date__c=
                caseDetails.To_Date__c=System.Today();
                caseDetails.STP_Request_Type__c = 'Email';
                caseDetails.Case__r.Id=caseCreated.Id;
                if(Schema.sObjectType.ABHFL_Case_Detail__c.isCreateable()){
                    Insert caseDetails;
                }
                
                //call SOAIntegration
                //Get Integration details
                ASF_Integration__c integ=getAllIntegrationDetails(ABHFL_Constants.SOA_CCC_EXTERNALID,'Open','ABHFL_SOAIntegration');
                //Call Evaluate and run method of the processing class
                ASF_IntegrationsController.IntegrationWrapper resultWrapper=ASF_IntegrationsController.runIntegration(integ,caseCreated);
                if(resultWrapper.status == ABHFL_Constants.SUCCESS){
                    casesCreated=true;
                }
            }
            if(createRSCase==true){
                ASF_Case_Category_Config__c caseCatConfig = [Select Id, Type__c,Sub_Type__c,CCC_External_Id__c,Business_Unit__c,Nature__c from ASF_Case_Category_Config__c Where CCC_External_Id__c=:ABHFL_Constants.Amort_CCC_EXTERNALID];
                //call RCIntegration
            }
            if(createICCase==true){
                ASF_Case_Category_Config__c caseCatConfig = [Select Id, Type__c,Sub_Type__c,CCC_External_Id__c,Business_Unit__c,Nature__c from ASF_Case_Category_Config__c Where CCC_External_Id__c=:ABHFL_Constants.IC_PIC_CCC_EXTERNALID];
                //call IcIntegration
            }
            if(createPICCase==true){
                ASF_Case_Category_Config__c caseCatConfig = [Select Id, Type__c,Sub_Type__c,CCC_External_Id__c,Business_Unit__c,Nature__c from ASF_Case_Category_Config__c Where CCC_External_Id__c=:ABHFL_Constants.IC_PIC_CCC_EXTERNALID];
                
                //call PICIntegration
            }
            if(createNDCCase==true){
                ASF_Case_Category_Config__c caseCatConfig = [Select Id, Type__c,Sub_Type__c,CCC_External_Id__c,Business_Unit__c,Nature__c from ASF_Case_Category_Config__c Where CCC_External_Id__c=:ABHFL_Constants.NDC_CCC_EXTERNALID];
                
                //call NDCIntegration
            }
            if(createWKCase==true){
                ASF_Case_Category_Config__c caseCatConfig = [Select Id, Type__c,Sub_Type__c,CCC_External_Id__c,Business_Unit__c,Nature__c from ASF_Case_Category_Config__c Where CCC_External_Id__c=:ABHFL_Constants.WK_CCC_EXTERNALID];
                
                //call WKIntegration
            }
            if(createLODCase==true){
                ASF_Case_Category_Config__c caseCatConfig = [Select Id, Type__c,Sub_Type__c,CCC_External_Id__c,Business_Unit__c,Nature__c from ASF_Case_Category_Config__c Where CCC_External_Id__c=:ABHFL_Constants.LOD_CCC_EXTERNALID];
                
                //call LODIntegration
            }
            return casesCreated;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static ASF_Integration__c getAllIntegrationDetails(string c3ExtId, string stageName, String ProcessingClass){
        ASF_Integration__c returnList;
        if(c3ExtId != null && stageName != null){
            returnList = [
                SELECT Id, Processing_Class__c, STP_Processing_Class__c,UI_Component__c,
                    External_Id__c, Type__c, Display_Name__c,STP_API_Identifier__c, Query_Fields__c
                FROM ASF_Integration__c
                WHERE C3ExternalId__c =: c3ExtId
                AND Case_Stage_Config__r.StageName__c =: stageName
                AND STP_Processing_Class__c=:ProcessingClass LIMIT 1
            ];
        }
        return returnList;
    }
}