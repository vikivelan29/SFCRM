/*********************************************************
*@Class      :  ABHFL_LODIntegration
*@Author       :  Dhinesh Kumar T
*@Created Date :  11/29/2023
*@Last Modified:  12/13/2023
*@description  :  Class for LOD STP integration. 
*********************************************************/
public with sharing  class ABHFL_LODIntegration implements ASF_IntegrationInvocable{
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - evaluate
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the ASF_IntegrationsController class, this method evaluates whether List of Documents integration should be fired or not.
    *****************************************************************************************************************/
    
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = ABHFL_Constants.ERROR;
        result.response = Custom_Messages__mdt.getInstance('LOD_EvaluateFailure').Message__c;
        
        
        Case caseRecord = [
            SELECT Id, Asset.Last_Disbursement_Date__c,Source__c,Asset.Branch__r.Branch_Queue_Id__c,Asset.LAN__c,ABHFL_Case_Detail__r.STP_Request_Type__c,OwnerId,CCC_External_Id__c,No_Auto_Communication__c
            FROM Case
            WHERE Id =: caseRec.Id 
        ]; 
        Calendar_Year__mdt cY =[SELECT Id, Current_Calendar_Year__c
								FROM Calendar_Year__mdt 
								LIMIT  1];
        //Check for mandatory API conditions
        if(String.isNotBlank(caseRecord.Asset.LAN__c) && caseRecord.ABHFL_Case_Detail__r.STP_Request_Type__c == 'Email'){
            //Check for Disbursement Date > Current Calendar Year
            if(caseRecord.Asset.Last_Disbursement_Date__c !=null && caseRecord.Asset.Last_Disbursement_Date__c >= cY.Current_Calendar_Year__c){
                  result.status = ABHFL_Constants.SUCCESS;
                  result.response = Custom_Messages__mdt.getInstance('LOD_EvaluateSuccess').Message__c;
            }
            else{
                 result.response = Custom_Messages__mdt.getInstance('LOD_DisbursedBefore').Message__c; 
            }
            
        }
        Boolean isUserinQueue = isUserInQueue(caseRecord.OwnerId,caseRecord.Asset.Branch__r.Branch_Queue_Id__c);
       
        //If Evaluate is failed and Source is not Branch, Assign to Branch Master Queue.
        if (result.status == ABHFL_Constants.ERROR && caseRecord.Asset.Branch__c != null) {
            if(!isUserinQueue && caseRecord.Source__c != ABHFL_Constants.BRANCH){
                caseRecord.OwnerId = caseRecord.Asset.Branch__r.Branch_Queue_Id__c;
                //ASF_TriggerSkipperUtility.markTriggerRun('Case');
                if(Schema.sObjectType.Case.isUpdateable()){
                	update caseRecord;    
                }
    		 	
            	//Error Message when evaluation is failed.
            	result.response = Custom_Messages__mdt.getInstance('LOD_DisbursedBeforeBranchAssignment').Message__c;
            }
		}
        
        return result;
        

    }
     /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - run
    * @param intSpec - ASF_Integration record.
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @description - Invoked from the ASF_IntegrationsController class, this method runs the List of Documents integration and creates Case Integration record.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c intSpec, Case caseRec){
         List<ASF_Case_Integration__c> existingCaseIntRecords = [SELECT Id, Status__c FROM ASF_Case_Integration__c
                                                               WHERE Case__c =:caseRec.Id 
                                                               AND Integration_Ext_Id__c =:intSpec.External_Id__c ];
        if(existingCaseIntRecords.size()>0){
        	for(ASF_Case_Integration__c caseInt : existingCaseIntRecords){
                if(caseInt.Status__c == ABHFL_Constants.PENDING){
                   caseInt.Status__c = ABHFL_Constants.CANCELED;  
                }
            }
            if(Schema.sObjectType.ASF_Case_Integration__c.isUpdateable()){
            	update existingCaseIntRecords;                
            }
        }

        Case caseRecord = [SELECT Id, Asset.LAN__c,CaseNumber,Business_Unit__c  FROM Case where Id =: caseRec.Id ];
        ASF_IntegrationsController.IntegrationWrapper response = new ASF_IntegrationsController.IntegrationWrapper();
        response.status = ABHFL_Constants.SUCCESS;
        ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
        caseInteg.Integration_Ext_Id__c = intSpec.External_Id__c;
        caseInteg.Case__c = caseRec.Id;
        caseInteg.Status__c = ABHFL_Constants.PENDING;
        caseInteg.Request__c = JSON.serialize(new LODRequestWrapper(caseRecord.CaseNumber,caseRecord.Asset.Lan__c));
        if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
        	insert caseInteg;    
        }
        
        ASF_Case_Integration__c caseInt = [Select Name from ASF_Case_Integration__c where id =: caseInteg.Id ];
         Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
        caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
        caseIntOut.Case_Integration_ID__c = caseInt.Name;
        caseIntOut.Integration_Name__c  = intSpec.Display_Name__c;
        caseIntOut.Request_Payload__c  =  JSON.serialize(new LODRequestWrapper(caseRecord.CaseNumber,caseRecord.Asset.Lan__c));
        caseIntOut.ServiceName__c = ABHFL_Constants.REPORTING_SERVICE;
        Database.SaveResult publishResult = EventBus.publish(caseIntOut);
        if(publishResult.isSuccess()){
            response.status = ABHFL_Constants.SUCCESS;
        }else{
            response.status = ABHFL_Constants.ERROR;
        }
       
        return response;
    }   
    
     /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - processResponse
    * @param caseInteg - ASF_Case_Integration record.
    * @description - Invoked from the Case Integration trigger, this method processes the response of the integration received.
    *****************************************************************************************************************/
    public void processResponse(ASF_Case_Integration__c caseInteg){
        //processing of case, move to next
        Boolean integrationFailure = true;
        Case caseRec = [
                SELECT Id,AccountId,ContactId,CCC_External_Id__c, MoveToNext__c,Attachment_Status__c,Asset.Branch__r.Branch_Queue_Id__c,OwnerId,CreatedById,ABHFL_Case_Detail__r.STP_Failure__c,No_Auto_Communication__c
            	FROM Case
            	WHERE Id =: caseInteg.Case__c
        	];
        if(caseInteg.Status__c == ABHFL_Constants.SUCCESS && caseRec!=null){
            integrationFailure = false;
        	Boolean isTransferred = ABCL_IntegrationCommonUtility.transferAttachments(caseInteg);
			if(isTransferred){
                  List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id, CCC_External_Id__c, Resolved_Case_Email_Template__c, 
                                                                        Resolved_Case_SMS_Metadata__c, Additional_SMS_Metadata__c, Additional_Email_Templates__c  FROM ASF_Case_Category_Config__c
                                                                        WHERE CCC_External_Id__c =:caseRec.CCC_External_Id__c];
                
                  Map<String, String> emailTemplateMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_Email_Templates__c);
                Map<String, String> smsMetadataMap = ABCL_IntegrationCommonUtility.fetchStpTemplates(cccRecord[0].Additional_SMS_Metadata__c);

                ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRec, emailTemplateMap.get('Resolved'), smsMetadataMap.get('Resolved'), isTransferred);
                  caseRec.MoveToNext__c = true;
                if(Schema.sObjectType.Case.isUpdateable()){
                  	update caseRec;          
                }
                  
            }else if(caseRec.OwnerId != caseRec.Asset.Branch__r.Branch_Queue_Id__c){
                            caseRec.OwnerId = caseRec.Asset.Branch__r.Branch_Queue_Id__c;
                            if(Schema.sObjectType.Case.isUpdateable()){
                            	update caseRec;    
                            }			
                            
                    		ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRec, ABHFL_Constants.LOD_NAME, ABHFL_Constants.STP_DOC_RETRIEVAL_FAILURE);
                  }
            
        }
        if(integrationFailure != caseRec.ABHFL_Case_Detail__r.STP_Failure__c){
        	caseRec.ABHFL_Case_Detail__r.STP_Failure__c = integrationFailure;
            if(caseRec.OwnerId != caseRec.Asset.Branch__r.Branch_Queue_Id__c){
                    caseRec.OwnerId = caseRec.Asset.Branch__r.Branch_Queue_Id__c;
                    if(Schema.sObjectType.Case.isUpdateable()){
                    	update caseRec;    
                    }
                    
            		ABCL_IntegrationCommonUtility.branchAssignmentNotification(caseRec, ABHFL_Constants.LOD_NAME, ABHFL_Constants.STP_DOC_RETRIEVAL_FAILURE);
        	}
        }
        ABCL_IntegrationCommonUtility.updateErrorMessage(caseInteg);
    }
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - isUserInQueue
    * @param - userId, queueId.
    * @return - boolean - true when user is in the specified queue.
    * @description - to check if a user is in a specified queue.
    *****************************************************************************************************************/
    public static Boolean isUserInQueue(Id userId, Id queueId) {
        // Query to find if the user is a member of the specified queue
        List<GroupMember> queueMemberships = [SELECT Id FROM GroupMember WHERE UserOrGroupId = :userId AND GroupId = :queueId ];

        // Check if the user is in the specified queue
        return !queueMemberships.isEmpty();
    }
    /****************************************************************************************************************
    *@description - Response Wrapper
    *****************************************************************************************************************/
    public class LODRequestWrapper{
        public string caseId;
        public string souce;
        public string requestType;
        public string lan;
        public string reportName;
        public string documentType;
        
        public LODRequestWrapper(string caseNumber,string lanNo){
            this.caseId = caseNumber;
            this.souce = ABHFL_Constants.CRM;
            this.requestType = ABHFL_Constants.EMAIL;
            this.lan = lanNo;
            this.reportName = ABHFL_Constants.LOD_REPORT;
            this.documentType = ABHFL_Constants.BINARY_DATA;
        }
    }

}
