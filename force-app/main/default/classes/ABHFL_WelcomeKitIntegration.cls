/*********************************************************
*Class        :  ABHFL_WelcomeKitIntegration
*Author       :  Aditya Mehrotra
*Created Date :  12/04/2023
*Last Modified:  12/05/2023
*Description  :  Class for Welcome Kit Integration
*********************************************************/
public class ABHFL_WelcomeKitIntegration implements ASF_IntegrationInvocable {
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - evaluate
    * @param caseRec - Case record from the framework.
    * @return - ASF_IntegrationsController.IntegrationWrapper.
    * @Description - Invoked from the ASF_IntegrationsController class, this method evaluates whether Welcome Kit integration should be fired or not.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper evaluate(Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper result = new ASF_IntegrationsController.IntegrationWrapper();
        result.status = 'Error';
        result.response = 'Evaluation Failed, cannot retrieve Welcome Kit.';
        system.debug('Case record:'+caseRec);
        /*Case caseRecord = [
            SELECT Id, CCC_External_Id__c, Asset.LAN__c, Asset.Last_Disbursement_Date__c, Channel__c, Source__c,
            	Branch_Master__r.Queue_Id__c, ABHFL_Case_Detail__r.STP_Request_Type__c
            FROM Case
            WHERE Id =: caseRec.Id
        ];*/
        
        Asset asset = [SELECT Id, Lan__c, Last_Disbursement_Date__c FROM Asset WHERE Id =:caseRec.AssetId];
		ABHFL_Case_Detail__c caseDetail = [SELECT Id, STP_Request_Type__c FROM ABHFL_Case_Detail__c WHERE Id=:caseRec.ABHFL_Case_Detail__c];        
        
        //Checking for mandatory API conditions
        if(String.isNotBlank(asset.LAN__c) && caseDetail.STP_Request_Type__c == 'Email'){
            Date today = Date.today();
            Date sixMonthsAgo = today.addMonths(-6);
            if(asset.Last_Disbursement_Date__c!=null){
            	Date disbursalDate = asset.Last_Disbursement_Date__c;
                if(disbursalDate >= sixMonthsAgo){
                    result.status = 'Success';
                    result.response = 'Evaluation Success, Submit to get the Welcome Kit.';
                }
                else{
                    system.debug('Disbursal date more than 6 months');
                    List<ASF_Case_Category_Config__c> cccRecord = [SELECT Id, CCC_External_Id__c, Rejected_Case_Email_Template__c, 
                                                                  Rejected_Case_SMS_Metadata__c FROM ASF_Case_Category_Config__c
                                                                  WHERE CCC_External_Id__c =:caseRec.CCC_External_Id__c];
                	if(String.isNotBlank(caseRec.Channel__c) && caseRec.Channel__c == 'Digital'){
                    	//Send standard email template and close the case
                    	//PE_Logger__c peLogger = createPELoggerRecord(caseRecord, cccRecord[0].Rejected_Case_Email_Template__c, 
                                                                     //cccRecord[0].Rejected_Case_SMS_Metadata__c);
                        //Database.SaveResult platformEventResult = invokeCommunicationLogPlatformEvent(caseRecord,peLogger);
                        //Case caseRec =[SELECT Id, MoveToNext__c,Attachment_Status__c  FROM Case WHERE Id=:caseInteg.Case__c];
                        //if(caseRec!=null){
                            caseRec.MoveToNext__c = true;
                            //caseRec.Attachment_Status__c = 'Completed';
                            update caseRec;    
                        //}
                    	result.status = 'Error';
                        result.response = 'Evaluation failed. Disbursal date is > 6 months.';
                	}
                    else{
                        if(String.isNotBlank(caseRec.Source__c) && caseRec.Source__c == 'Email'){
                            //Send standard email template and close the case
                            //PE_Logger__c peLogger = createPELoggerRecord(caseRecord, cccRecord[0].Rejected_Case_Email_Template__c, 
                                                                     //cccRecord[0].Rejected_Case_SMS_Metadata__c);
                            //Database.SaveResult platformEventResult = invokeCommunicationLogPlatformEvent(caseRecord,peLogger);
                            caseRec.MoveToNext__c = true;
                            update caseRec;
                            result.status = 'Error';
                            result.response = 'Evaluation failed. Disbursal date is > 6 months.';
                        }
                        else{
                            //Show error response on the screen
                            system.debug('Channel is not Digital and source is not email');
                            result.status = 'Error';
                            result.response = 'Disbursal date is > 6 months. Please inform the customer that Welcome Kit cannot be provided';
                        }
                    }
                }
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
    * @Description - Invoked from the ASF_IntegrationsController class, this method runs the Welcome Kit integration and creates Case Integration record.
    *****************************************************************************************************************/
    public ASF_IntegrationsController.IntegrationWrapper run(ASF_Integration__c integ, Case caseRec){
        ASF_IntegrationsController.IntegrationWrapper wrap = new ASF_IntegrationsController.IntegrationWrapper();
		List<ASF_Case_Integration__c> existingCaseIntRecords = [SELECT Id, Status__c FROM ASF_Case_Integration__c
                                                               WHERE Case__c =:caseRec.Id 
                                                               AND Integration_Ext_Id__c =:integ.External_Id__c];
        if(existingCaseIntRecords.size()>0){
        	for(ASF_Case_Integration__c cInt : existingCaseIntRecords){
                cInt.Status__c = 'Canceled';
            }
            update existingCaseIntRecords;            
        }
                
        ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
        caseInt.Case__c  = caseRec.Id;
        caseInt.Integration_Ext_Id__c = integ.External_Id__c;
        caseInt.Status__c = 'Pending';
        caseInt.Response__c = 'Waiting for API response';
        insert caseInt;
        return wrap;
    }
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - processResponse
    * @param caseInteg - ASF_Case_Integration record.
    * @return - void.
    * @Description - Invoked from the Case Integration trigger, this method processes the response of the integration received.
    *****************************************************************************************************************/
    public void processResponse(ASF_Case_Integration__c caseInteg){
        system.debug('Inside process response welcome kit');
        if(caseInteg.Status__c=='Success'){
        	Case caseRec =[SELECT Id, MoveToNext__c,Attachment_Status__c  FROM Case WHERE Id=:caseInteg.Case__c];
            if(caseRec!=null){
                caseRec.MoveToNext__c = true;
                caseRec.Attachment_Status__c = 'Completed';
                update caseRec;    
            }    
        }     
    }
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - createPELoggerRecord
    * @param caseRec - Case record.
    * @param rejectionEmailTemplate - Rejection email template from Case Category Config record.
    * @param rejectionSmsMetadata - Rejection SMS metadata from Case Category Config record.
    * @return - PE_Logger__c.
    * @Description - Function to create a PE_Logger__c record for email and SMS communication.
    *****************************************************************************************************************/
    private PE_Logger__c createPELoggerRecord(Case caseRec, String rejectionEmailTemplate, String rejectionSmsMetadata){
        PE_Logger__c peLogger = new PE_Logger__c();
        peLogger.AccountId__c = caseRec.AccountId;
        peLogger.CCCExternalId__c = caseRec.CCC_External_Id__c;
        peLogger.Case__c = caseRec.Id;
        peLogger.ContactId__c = caseRec.ContactId;
        peLogger.PE_Name__c = 'CommunicationLog';
        peLogger.RecordID__c = caseRec.Id;
        peLogger.Retry_PE__c = true;
        peLogger.Status__c = 'Pending';
        peLogger.CustomMetadataName__c = rejectionSmsMetadata;
        peLogger.Email_Template_Name__c = rejectionEmailTemplate;
        
        insert peLogger;
        
        return peLogger;
    }
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - invokeCommunicationLogPlatformEvent
    * @param caseRec - Case record.
    * @param peLogger - PE_Logger__c record.
    * @return - Database.SaveResult.
    * @Description - Function to publish ASF_CommnunicationLog__e platform event.
    *****************************************************************************************************************/
    private Database.SaveResult invokeCommunicationLogPlatformEvent(Case caseRec, PE_Logger__c peLogger){
        ASF_CommnunicationLog__e commEvent = new ASF_CommnunicationLog__e();
        commEvent.CCCExternalId__c = caseRec.CCC_External_Id__c;
        commEvent.CustomMetadataName__c = 'Rejection_Reason_Available';
        commEvent.PELoggerId__c = peLogger.Id;
        commEvent.RecordID__c = caseRec.Id;
        //commEvent.Unique_Id__c = 
        Database.SaveResult eventResult = EventBus.publish(commEvent);
        return eventResult;
    }
}