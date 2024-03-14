/*********************************************************
*Class        :  ABHFL_AmmortizationMultiLanIntegration
*Author       :  Aditya Mehrotra
*Created Date :  01/12/2023
*Last Modified:  01/23/2023
*@description :  Class for Ammortization API call for all LANs
*********************************************************/
public with sharing class ABHFL_AmmortizationMultiLanIntegration implements ASF_IntegrationInvocable {

    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - evaluate
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the ASF_IntegrationsController class, this method evaluates whether Ammortization API call for all LANs should be fired or not.
    *****************************************************************************************************************/
   public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec)
    {
       	ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = ABHFL_Constants.ERROR;
        result.response = Custom_Messages__mdt.getInstance('MultiAMORT_EvaluateFailure').Message__c;

        Case caseRecord = [
            SELECT Id, CCC_External_Id__c,MoveToNext__c, Asset.LAN__c, Asset.Last_Disbursement_Date__c, Channel__c, Source__c,
                ABHFL_Case_Detail__r.STP_Request_Type__c, AccountId, ContactId, Attachment_Status__c, No_Auto_Communication__c,
                ABHFL_Case_Detail__c, ABHFL_Case_Detail__r.Masked_Partial_LANs__c, ABHFL_Case_Detail__r.Masked_Full_LANs__c
            FROM Case
            WHERE Id =: caseRec.Id
        ];

        List<ABHFL_Asset_Detail__c> relatedAssetsFCROI = [SELECT Id, Asset__r.LAN__c, Asset__r.Loan_Disbursement_Status__c
                                                   FROM ABHFL_Asset_Detail__c
                                                   WHERE Case__c=:caseRecord.Id
                                                   //AND Type__c='FCROI'
                                                   AND AmmortApiStatus__c = false];
        
        if(relatedAssetsFCROI.size()>0){
            result = processAssets(caseRecord, relatedAssetsFCROI);
        }
  		return result;
    }
    
    private ASF_IntegrationsController.IntegrationWrapper processAssets(Case caseRecord, List<ABHFL_Asset_Detail__c> relatedAssets){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        Boolean sendRejectionForPartialLoans = false;
        Boolean allPartialLoans = true;
        List<String> maskedPartialLans=new List<String>();
        List<String> maskedFullLans=new List<String>();
        List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id, CCC_External_Id__c, Rejected_Case_Email_Template__c, 
                                                           Rejected_Case_SMS_Metadata__c FROM ASF_Case_Category_Config__c
                                                           WHERE CCC_External_Id__c = :caseRecord.CCC_External_Id__c WITH SECURITY_ENFORCED];
        for(ABHFL_Asset_Detail__c assetDetail : relatedAssets){
            //Check for mandatory API conditions & Check for Loan Disbursement Status
                    	if(String.isNotBlank(assetDetail.Asset__r.LAN__c) && 
              assetDetail.Asset__r.Loan_Disbursement_Status__c != null &&
              assetDetail.Asset__r.Loan_Disbursement_Status__c != 'Partially')
            {
              	maskedFullLans.add('xxxxxx'+assetDetail.Asset__r.LAN__c.substring(5));
                allPartialLoans = false;
                result.status = ABHFL_Constants.SUCCESS;
        		result.response = Custom_Messages__mdt.getInstance('MultiAMORT_EvaluateSuccess').Message__c;
            }
            else if(String.isNotBlank(assetDetail.Asset__r.LAN__c) && 
              assetDetail.Asset__r.Loan_Disbursement_Status__c != null)
            {
				maskedPartialLans.add('xxxxxx'+assetDetail.Asset__r.LAN__c.substring(5)+',');
               	sendRejectionForPartialLoans = true;
            }
      	}

        ABHFL_Case_Detail__c caseDetail = [SELECT Id, Masked_Partial_LANs__c, Masked_Full_LANs__c
                                           FROM ABHFL_Case_Detail__c WHERE Id =:caseRecord.ABHFL_Case_Detail__c];
        caseDetail.Masked_Partial_LANs__c = String.join(maskedPartialLans,',');
        caseDetail.Masked_Full_LANs__c = String.join(maskedFullLans,',');
        if(Schema.sObjectType.ABHFL_Case_Detail__c.isUpdateable()){
          	update caseDetail;
        }
        
        if(allPartialLoans && Schema.sObjectType.Case.isUpdateable()){
          	result.status = ABHFL_Constants.ERROR;
           	result.response = Custom_Messages__mdt.getInstance('MultiAMORT_Evaluate_Disbursed_Partially').Message__c;
            Group csQueue = [SELECT Id FROM Group WHERE Type =:ABHFL_Constants.QUEUE AND DeveloperName ='ABHFL_Email_Financial_Team'  Limit 1];
	        caseRecord.OwnerId = csQueue.Id;
            caseRecord.MoveToNext__c = true;
            
            update caseRecord;
            
       	}
            
        if(sendRejectionForPartialLoans && !cccRecord.isEmpty()){
         	ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(
               caseRecord,//configure this for sending mail for only Partially disbursed Loans
               ABHFL_Constants.MULTIPLELAN_AMORT_PARTIAL_EMAIL,
               ABHFL_Constants.MULTIPLELAN_AMORT_PARTIAL_SMS,
                        //cccRecord[0].Rejected_Case_Email_Template__c,
                        //cccRecord[0].Rejected_Case_SMS_Metadata__c,
               false
            );
       	}
        return result;
    }
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - run
    * @param integ - ASF_Integration record.
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the ASF_IntegrationsController class, this method runs the Ammortization API call for all LANs and create Case Integration records.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c intSpec, Case caseRec)
    {
        List<ASF_Case_Integration__c> existingCaseIntRecords = [SELECT Id, Status__c FROM ASF_Case_Integration__c
                                                               WHERE Case__c =:caseRec.Id 
                                                               AND Integration_Ext_Id__c =:intSpec.External_Id__c WITH SECURITY_ENFORCED];
        if(existingCaseIntRecords.size()>0){
          	  cancelExistingCaseIntRecords(existingCaseIntRecords);
        }
        
        Case caseRecord = [SELECT Id, Asset.LAN__c,CaseNumber,Business_Unit__c  FROM Case where Id =: caseRec.Id WITH SECURITY_ENFORCED];
        
        List<ABHFL_Asset_Detail__c> allRelatedAssetsFCROI = [SELECT Id, Asset__r.LAN__c, Asset__r.Loan_Disbursement_Status__c,
                                                   AmmortApiStatus__c
                                                   FROM ABHFL_Asset_Detail__c
                                                   WHERE Case__c=:caseRecord.Id
                                                   //AND Type__c='FCROI'
                                                   AND AmmortApiStatus__c = false];
        
        List<ABHFL_Asset_Detail__c> fullyDisAssetsFCROI = new List<ABHFL_Asset_Detail__c>();
        List<ABHFL_Asset_Detail__c> partiallyDisAssetsFCROI = new List<ABHFL_Asset_Detail__c>();
        List<ASF_Case_Integration__c> caseIntList = new List<ASF_Case_Integration__c>();
          
        for(ABHFL_Asset_Detail__c ad: allRelatedAssetsFCROI){
            if(ad.Asset__r.Loan_Disbursement_Status__c!=null && ad.Asset__r.Loan_Disbursement_Status__c!='Partially')
            {
                fullyDisAssetsFCROI.add(ad);
                
                ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
                caseInteg.Integration_Ext_Id__c = intSpec.External_Id__c;
                caseInteg.Case__c = caseRecord.Id;
                caseInteg.Request__c = JSON.serialize(new AmmortRequestWrapper(ad.Asset__r.Lan__c,caseRecord)); 
                caseInteg.Status__c = ABHFL_Constants.PENDING;
                caseInteg.Business_External_Id__c = ad.Asset__r.Lan__c;
                caseIntList.add(caseInteg);                
            }
            else if(ad.Asset__r.Loan_Disbursement_Status__c!=null)
            {
                partiallyDisAssetsFCROI.add(ad);
            }
        }
        
        ASF_IntegrationsController.IntegrationWrapper response = new ASF_IntegrationsController.IntegrationWrapper();
        
        if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
        	insert caseIntList;    
        }
        List<ASF_Case_Integration__c> cIntList = [SELECT Id, Name, Request__c FROM ASF_Case_Integration__c WHERE Id IN :caseIntList];
        response = publishEvents(caseRecord, intSpec, cIntList);
        return response;
    }
    
    private void cancelExistingCaseIntRecords(List<ASF_Case_Integration__c> existingCaseIntRecords){
        for(ASF_Case_Integration__c caseInt : existingCaseIntRecords){
            if(caseInt.Status__c == ABHFL_Constants.PENDING || caseInt.Status__c == ABHFL_Constants.FAILURE){
                caseInt.Status__c = ABHFL_Constants.CANCELED;  
            }
        }
            
        if(Schema.sObjectType.ASF_Case_Integration__c.isUpdateable()){
            update existingCaseIntRecords; 
        }  
    }
    
    private ASF_IntegrationsController.IntegrationWrapper publishEvents(Case caseRecord, ASF_Integration__c intSpec, List<ASF_Case_Integration__c> cIntList){
        ASF_IntegrationsController.IntegrationWrapper response = new ASF_IntegrationsController.IntegrationWrapper();
        List<Case_Integration_Outbound__e> eventList = new List<Case_Integration_Outbound__e>();
        for(ASF_Case_Integration__c cInt: cIntList){
            Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e();
            caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
            caseIntOut.Case_Integration_ID__c = cInt.Name;
            caseIntOut.Integration_Name__c  = intSpec.Display_Name__c;
            caseIntOut.ServiceName__c = 'ReportingService';
            caseIntOut.Request_Payload__c = cInt.Request__c;
            eventList.add(caseIntOut);
        }
		List<Database.SaveResult> eventResults = EventBus.publish(eventList);
        
        for (Database.SaveResult sr : eventResults) {
            if (sr.isSuccess()) {
                response.status = ABHFL_Constants.SUCCESS;
            } else {
                response.status = ABHFL_Constants.ERROR;
                break;
            }       
        }
        return response;
    }
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - processResponse
    * @param caseInteg - ASF_Case_Integration record.
    * @description - Invoked from the Case Integration trigger, this method processes the response of the integration received.
    *****************************************************************************************************************/
    public void processResponse(ASF_Case_Integration__c caseInteg)
    {
        Case caseRec = [SELECT Id, CCC_External_Id__c,MoveToNext__c, Asset.LAN__c, Asset.Last_Disbursement_Date__c, 
                        	Channel__c, Source__c, AccountId, ContactId, 
                        	Attachment_Status__c, No_Auto_Communication__c
                        FROM Case
                        WHERE Id =: caseInteg.Case__c WITH SECURITY_ENFORCED];
        Map<String, Integer> statusCountMap = new Map<String, Integer>();
        AggregateResult[] groupedResults = [SELECT COUNT(Id) recordCount, Status__c FROM ASF_Case_Integration__c
                                                WHERE Case__c=:caseRec.Id GROUP BY Status__c];
        for (AggregateResult ar : groupedResults) {
         	statusCountMap.put(String.valueOf(ar.get('Status__c')), Integer.valueOf(ar.get('recordCount'))==null?0:Integer.valueOf(ar.get('recordCount')));
        }
        
        if(caseInteg.Status__c == ABHFL_Constants.SUCCESS){
            
            Boolean isTransferred = ABCL_IntegrationCommonUtility.transferAttachments(caseInteg);
            if(isTransferred){
                /*List<ABHFL_Asset_Detail__c> assetDetailTest = [SELECT Id,Case__c, Asset__r.Lan__c, AmmortApiStatus__c 
                                                     FROM ABHFL_Asset_Detail__c];*/
                List<ABHFL_Asset_Detail__c> assetDetail = [SELECT Id, Asset__r.Lan__c, AmmortApiStatus__c 
                                                     FROM ABHFL_Asset_Detail__c 
                                                     WHERE Asset__r.Lan__c =:caseInteg.Business_External_Id__c
                                                     AND Case__c =:caseRec.Id LIMIT 1];
                assetDetail[0].AmmortApiStatus__c = isTransferred;
                update assetDetail[0];
            }
            if((statusCountMap.get('Pending')==0 || statusCountMap.get('Pending')==null) && 
               	(statusCountMap.get('Failure')==0 || statusCountMap.get('Failure')==null)){
                
                processSuccessResponse(caseRec);
                    
            }
            
        }
        if(statusCountMap.get('Failure')>0 && statusCountMap.get('Pending')==0){
			//assign to non financial team  
           	Group csQueue = [SELECT Id FROM Group WHERE Type =: ABHFL_Constants.QUEUE AND DeveloperName =: ABHFL_Constants.ABHFL_CUSTOMER_SERVICE_TEAM WITH SECURITY_ENFORCED Limit 1];
            caseRec.OwnerId = csQueue.Id;
            update caseRec;
        }
        
    }
    
    private void processSuccessResponse(Case caseRec){
        List<ASF_Case_Integration__c> caseIntegRecords = [SELECT Id, Status__c, Business_External_Id__c 
                                                          FROM ASF_Case_Integration__c
                                                          WHERE Case__c =:caseRec.Id 
                                                          AND Status__c = 'Success'];
                
        List<String> lanList = new List<String>();
        Boolean allTransferred = false;
        for(ASF_Case_Integration__c cInt : caseIntegRecords){
          	lanList.add(cInt.Business_External_Id__c);
        }
                
        List<ABHFL_Asset_Detail__c> assetDetails = [SELECT Id, AmmortApiStatus__c FROM ABHFL_Asset_Detail__c 
                                                    WHERE Asset__r.LAN__c IN :lanList
                                                    AND Case__c =:caseRec.Id];
        for(ABHFL_Asset_Detail__c aDet : assetDetails){
          	if(aDet.AmmortApiStatus__c == false){
               	allTransferred = false;
                break;
            }else{
                allTransferred =true;
            }
      	}
                
        //Have to accommodate isTransferred logic here
        //configure this for sending mail for only Fully disbursed Loans
        ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRec, 
                                      ABHFL_Constants.MULTIPLELAN_AMORT_FULL_EMAIL, 
                                      ABHFL_Constants.MULTIPLELAN_AMORT_FULL_SMS,
                                      allTransferred);
       	caseRec.MoveToNext__c = true;
        if(!Test.IsRunningTest()){
          	update caseRec;    
        }
    }
    
    /*********************************************************
    *@description :  Wrapper Class for Ammortization API call for all LANs
    *********************************************************/
    public class AmmortRequestWrapper{
        public string lan;
        public string caseId;
        public string souce;
        public string requestType;
        public string reportName;
        public string documentType;
        
        public AmmortRequestWrapper(string lanNo,Case caseRec){
            this.lan = lanNo;
            this.souce = ABHFL_Constants.CRM;
            this.requestType = ABHFL_Constants.EMAIL;
            this.lan = lanNo;
            this.reportName = 'RepaymentSchedule';
            this.documentType = ABHFL_Constants.BINARY_DATA;
            this.caseId = caseRec.caseNumber;
        }
    }
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){return null;}
    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> run(Map<Id, List<ASF_Integration__c>> integs, List<Case> caseRecs){return null;}
}