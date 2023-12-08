/*********************************************************
*Class        :  ABHFL_LODIntegration
*Author       :  Dhinesh Kumar T
*Created Date :  11/29/2023
*Last Modified:  12/5/2023
*Description  :  Class for LOD STP integration. 
*********************************************************/
public without sharing  class ABHFL_LODIntegration implements ASF_IntegrationInvocable{
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - evaluate
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @Description - Invoked from the ASF_IntegrationsController class, this method evaluates whether List of Documents integration should be fired or not.
    *****************************************************************************************************************/
    
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = 'Error';
        result.response = 'Evaluation Failed, cannot retrieve List of Documents';
        System.debug(caseRec);
        Asset asset =[SELECT Id, Last_Disbursement_Date__c,Branch__r.Branch_Queue_Id__c,LAN__c from Asset WHERE Id =: caseRec.AssetId] ;
        
        ABHFL_Case_Detail__c caseDetail = [SELECT Id,STP_Request_Type__c from ABHFL_Case_Detail__c WHERE Id =: caseRec.ABHFL_Case_Detail__c];
        System.debug(caseDetail);
        /*Case caseRecord = [
            SELECT Id, Asset.Last_Disbursement_Date__c,Source__c,Asset.Branch__r.Branch_Queue_Id__c,Asset.LAN__c,ABHFL_Case_Detail__r.STP_Request_Type__c,OwnerId
            FROM Case
            WHERE Id =: caseRec.Id
        ];*/ 
        Calendar_Year__mdt CY =[SELECT Id, Current_Calendar_Year__c
								FROM Calendar_Year__mdt
								LIMIT  1];
        //Checking for mandatory API conditions
        if(String.isNotBlank(asset.LAN__c) && caseDetail.STP_Request_Type__c == 'Email'){
        
            if(asset.Last_Disbursement_Date__c !=null){
                    //Check for Disbursement Date > Current Calendar Year
        			if(asset.Last_Disbursement_Date__c >= CY.Current_Calendar_Year__c){
                       result.status = 'Success';
                       result.response = 'Evaluation Success, Submit to get the List of Documents.';
                    }else{
                       result.response = 'Disbursed before current year, cannot fetch List of Documents.'; 
                    }
            }
        }
        Boolean isUserinQueue = isUserInQueue(caseRec.OwnerId,asset.Branch__r.Branch_Queue_Id__c);
       
        System.debug(result);
        
        //If Evaluate is failed and Source is not Branch, Assign to Branch Master Queue.
        if (result.status == 'Error'&& asset.Branch__c != null) {
            if(caseRec.Source__c != 'Branch'){
                caseRec.OwnerId = asset.Branch__r.Branch_Queue_Id__c;
                //ASF_TriggerSkipperUtility.markTriggerRun('Case');
    		 	update caseRec;
            	//Error Message when evaluation is failed.
            	result.response ='Disbursed before current year, cannot fetch List of Documents. Assigning the case to Branch';
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
    * @Description - Invoked from the ASF_IntegrationsController class, this method runs the List of Documents integration and creates Case Integration record.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integ, Case caseRec){
        

        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        ASF_Case_Integration__c caseInteg = new ASF_Case_Integration__c();
        caseInteg.Integration_Ext_Id__c = integ.External_Id__c;
        caseInteg.Case__c = caseRec.Id;
        caseInteg.Status__c='Pending';
        insert caseInteg;
       
        return result;
    }
    
     /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - processResponse
    * @param caseInteg - ASF_Case_Integration record.
    * @return - void.
    * @Description - Invoked from the Case Integration trigger, this method processes the response of the integration received.
    *****************************************************************************************************************/
    public void processResponse(ASF_Case_Integration__c caseInteg){
        //processing of case, move to next
        if(caseInteg.Status__c=='Success'){
		Case caseRecord = [
            SELECT Id, Asset.Last_Disbursement_Date__c,Source__c,Branch_Master__r.Queue_Id__c
            FROM Case
            WHERE Id =: caseInteg.Case__c
        ];
        caseRecord.MoveToNext__c = TRUE;
        update caseRecord;
    }
    }
    
    public static Boolean isUserInQueue(Id userId, Id queueId) {
        // Query to find if the user is a member of the specified queue
        List<GroupMember> queueMemberships = [SELECT Id FROM GroupMember WHERE UserOrGroupId = :userId AND GroupId = :queueId];

        // Check if the user is in the specified queue
        return !queueMemberships.isEmpty();
    }

}