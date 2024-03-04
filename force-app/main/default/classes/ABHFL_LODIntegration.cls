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
        String cY = System.Label.ABHFL_LOD_Calendar_Year;
        //Check for mandatory API conditions
        if(String.isNotBlank(caseRecord.Asset.LAN__c) && caseRecord.ABHFL_Case_Detail__r.STP_Request_Type__c == 'Email'){
            //Check for Disbursement Date > Current Calendar Year
            if(caseRecord.Asset.Last_Disbursement_Date__c !=null && caseRecord.Asset.Last_Disbursement_Date__c >= Date.valueOf(cY)){
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

    public Map<Id, ASF_IntegrationsController.IntegrationWrapper> evaluate(List<Case> caseRecs){
        Map<Id, ASF_IntegrationsController.IntegrationWrapper> resultMap = new Map<Id, ASF_IntegrationsController.IntegrationWrapper>();
        
        // Case caseRecord = [
        //     SELECT Id, Asset.Last_Disbursement_Date__c,Source__c,Asset.Branch__r.Branch_Queue_Id__c,Asset.LAN__c,ABHFL_Case_Detail__r.STP_Request_Type__c,OwnerId,CCC_External_Id__c,No_Auto_Communication__c
        //     FROM Case
        //     WHERE Id =: caseRec.Id 
        // ];
        List<Case> caseRecords = new List<Case>();
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }

        Set<Id> ownerIds = new Set<Id>();
        Set<Id> groupIds = new Set<Id>();
        for(Case caseRec : caseRecords){
            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            result.status = ABHFL_Constants.ERROR;
            result.response = Custom_Messages__mdt.getInstance('LOD_EvaluateFailure').Message__c;
            resultMap.put(caseRec.Id, result);
            ownerIds.add(caseRec.OwnerId);
            groupIds.add(caseRec.Asset.Branch__r.Branch_Queue_Id__c);
        }
        Map<Id, Set<Id>> groupIdToMemberIds = isUserInQueue(ownerIds, groupIds);
        String cY = System.Label.ABHFL_LOD_Calendar_Year;
        for(Case caseRecord : caseRecords){
            ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
            //Check for mandatory API conditions
            if(String.isNotBlank(caseRecord.Asset.LAN__c) && caseRecord.ABHFL_Case_Detail__r.STP_Request_Type__c == 'Email'){
                //Check for Disbursement Date > Current Calendar Year
                if(caseRecord.Asset.Last_Disbursement_Date__c !=null && caseRecord.Asset.Last_Disbursement_Date__c >= Date.valueOf(cY)){
                    result.status = ABHFL_Constants.SUCCESS;
                    result.response = Custom_Messages__mdt.getInstance('LOD_EvaluateSuccess').Message__c;
                }
                else{
                    result.response = Custom_Messages__mdt.getInstance('LOD_DisbursedBefore').Message__c; 
                }
                
            }
            Boolean isUserinQueue = groupIdToMemberIds.containsKey(caseRecord.Asset.Branch__r.Branch_Queue_Id__c)?groupIdToMemberIds.get(caseRecord.Asset.Branch__r.Branch_Queue_Id__c).contains(caseRecord.OwnerId):false;
       
            //If Evaluate is failed and Source is not Branch, Assign to Branch Master Queue.
            if (result.status == ABHFL_Constants.ERROR && caseRecord.Asset.Branch__c != null) {
                if(!isUserinQueue && caseRecord.Source__c != ABHFL_Constants.BRANCH){
                    Case updatedCase = new Case(Id=caseRecord.Id);
                    updatedCase.OwnerId = caseRecord.Asset.Branch__r.Branch_Queue_Id__c;
                    result.updatedCase = updatedCase;
                    //Error Message when evaluation is failed.
                    result.response = Custom_Messages__mdt.getInstance('LOD_DisbursedBeforeBranchAssignment').Message__c;
                }
            }
            resultMap.put(caseRecord.Id, result);
        }
        
        return resultMap;
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


        //Case caseRecord = [SELECT Id, Asset.LAN__c,CaseNumber,Business_Unit__c  FROM Case where Id =: caseRec.Id ];
        List<Case> caseRecords = new List<Case>();
        for(Case caseRec : caseRecs){
            caseRecords.add(ASF_IntegrationsController.queriedCasesForIntegration.get(caseRec.Id));
        }

        List<ASF_Case_Integration__c> newCaseIntegrations = new List<ASF_Case_Integration__c>();
        Map<Integer, Case_Integration_Outbound__e> peMap = new Map<Integer, Case_Integration_Outbound__e>();
        Integer index = 0;
        Map<Integer, Id> indexToCaseId = new Map<Integer, Id>();
        for(Case caseRecord : caseRecords){
            ASF_IntegrationsController.IntegrationWrapper response = new ASF_IntegrationsController.IntegrationWrapper();
            response.status = ABHFL_Constants.SUCCESS;
            for(ASF_Integration__c intSpec : integs.get(caseRecord.Id))
            {
                ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
                caseInteg.Integration_Ext_Id__c = intSpec.External_Id__c;
                caseInteg.Case__c = caseRecord.Id;
                caseInteg.Status__c = ABHFL_Constants.PENDING;
                caseInteg.Request__c = JSON.serialize(new LODRequestWrapper(caseRecord.CaseNumber,caseRecord.Asset.Lan__c));
                newCaseIntegrations.add(caseInteg);

                Case_Integration_Outbound__e caseIntOut = new Case_Integration_Outbound__e ();
                caseIntOut.Business_Unit__c  = caseRecord.Business_Unit__c;
                //caseIntOut.Case_Integration_ID__c = caseInt.Name;
                caseIntOut.Integration_Name__c  = intSpec.Display_Name__c;
                caseIntOut.Request_Payload__c  =  JSON.serialize(new LODRequestWrapper(caseRecord.CaseNumber,caseRecord.Asset.Lan__c));
                caseIntOut.ServiceName__c = ABHFL_Constants.REPORTING_SERVICE;
                peMap.put(index, caseIntOut);
                indexToCaseId.put(index, caseRecord.Id);
                index++;
            }
            resultMap.put(caseRecord.Id, response);
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
    public static Map<Id, Set<Id>> isUserInQueue(Set<Id> ownerIds, Set<Id> groupIds) {
        Map<Id, Set<Id>> groupIdToMemberIds = new Map<Id, Set<Id>>();
        // Query to find if the user is a member of the specified queue
        for(GroupMember gm : [SELECT Id, groupId, UserOrGroupId FROM GroupMember WHERE UserOrGroupId IN :ownerIds AND GroupId IN :groupIds ]){
            if(!groupIdToMemberIds.containsKey(gm.groupId)){
                groupIdToMemberIds.put(gm.groupId, new Set<Id>());
            }
            groupIdToMemberIds.get(gm.groupId).add(gm.UserOrGroupId);
        }
        
        return groupIdToMemberIds;
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