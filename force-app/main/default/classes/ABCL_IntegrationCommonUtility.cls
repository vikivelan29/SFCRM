/*********************************************************
*Class        :  ABCL_IntegrationCommonUtility
*Author       :  Siddarth Jaitly
*Created Date :  12/12/2023
*Last Modified:  12/12/2023
*@description  :  General Utility Class for Integration 
*********************************************************/
public with sharing class ABCL_IntegrationCommonUtility {
    
    /****************************************************************************************************************
    * @LOB - Common
    * @Function - transferAttachments
    * @param caseIntegration - case integration record
    * @return - Boolean .
    * @description - Transfers Attachments from ASF_Case_Integration__c to Case
    *****************************************************************************************************************/       
    public static Boolean transferAttachments(ASF_Case_Integration__c caseIntegration){
        Boolean isSuccess = true;
        List<ContentDocumentLink> relatedAttachments = [Select LinkedEntityId,ContentDocumentId from ContentDocumentLink 
                                                        where LinkedEntityId =: caseIntegration.Id WITH SECURITY_ENFORCED];
        List<ContentDocumentLink> contentLinkToBeInserted = new List<ContentDocumentLink>();
        if(relatedAttachments.size() > 0){
            Set<Id> contentDocumentIds = new Set<Id>();
            for(ContentDocumentLink contentLink : relatedAttachments){
                ContentDocumentLink link = new ContentDocumentLink();
                link.LinkedEntityId = caseIntegration.Case__c;
                link.ContentDocumentId= contentLink.ContentDocumentId;
                link.ShareType = 'V';
                contentLinkToBeInserted.add(link);
                contentDocumentIds.add(contentLink.ContentDocumentId);
            }
            
            List<ContentVersion> contentList = [Select id from ContentVersion where ContentDocumentId in: contentDocumentIds WITH SECURITY_ENFORCED];
            for(ContentVersion file : contentList){
                file.IsSTP__c = true;
            }
            
            Database.SaveResult[] updateResult = Database.update(contentList,false);
            for(Database.SaveResult result : updateResult){
                if(!result.isSuccess()){
                    isSuccess = false;
                    break;
                }
            }
            
            Database.SaveResult[] insertResult = Database.insert(contentLinkToBeInserted,false); 
            
            for(Database.SaveResult result : insertResult){
                if(!result.isSuccess()){
                    isSuccess = false;
                    break;
                }
            }
        } else {
            isSuccess = false;
        }
        
        return isSuccess;
    }
     /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - createPELogAndinvokeCommPEevent
    * @param caseRec - Case record.
    * @param rejectionEmailTemplate - Rejection email template from Case Category Config record.
    * @param rejectionSmsMetadata - Rejection SMS metadata from Case Category Config record.
    * @param isTransferred
    * @return - Database.SaveResult.
    * @description - Function to create a PE_Logger__c record and invoke ASF_CommnunicationLog__e for email and SMS communication.
    *****************************************************************************************************************/
    public static Database.SaveResult createPELogAndinvokeCommPEevent(Case caseRec, String emailTemplate, String smsMetadata, Boolean isTransferred){
        PE_Logger__c peLogger = new PE_Logger__c();
        peLogger.AccountId__c = caseRec.AccountId;
        peLogger.CCCExternalId__c = caseRec.CCC_External_Id__c;
        peLogger.Case__c = caseRec.Id;
        peLogger.ContactId__c = caseRec.ContactId;
        peLogger.PE_Name__c = 'CommunicationLog';
        peLogger.RecordID__c = caseRec.Id;
        peLogger.Retry_PE__c = true;
        peLogger.Status__c = 'Pending';
        peLogger.CustomMetadataName__c = smsMetadata;
        peLogger.Email_Template_Name__c = emailTemplate;
        peLogger.No_Auto_Communication__c = caseRec.No_Auto_Communication__c;
        if(isTransferred){
            peLogger.Is_Attachment__c = true;
            //peLogger.Content_Version_Ids__c='0689I000001DJPFQA4';
        }
        if(Schema.sObjectType.PE_Logger__c.isCreateable())
        {
            insert peLogger;    
        }
        
        Database.SaveResult eventResult = invokeCommunicationLogPlatformEvent(caseRec, peLogger);        
        return eventResult;
    }
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - invokeCommunicationLogPlatformEvent
    * @param caseRec - Case record.
    * @param peLogger - PE_Logger__c record.
    * @return - Database.SaveResult.
    * @description - Function to publish ASF_CommnunicationLog__e platform event.
    *****************************************************************************************************************/
    private static Database.SaveResult invokeCommunicationLogPlatformEvent(Case caseRec, PE_Logger__c peLogger){
        ASF_CommnunicationLog__e commEvent = new ASF_CommnunicationLog__e();
        commEvent.CCCExternalId__c = caseRec.CCC_External_Id__c;
        //commEvent.CustomMetadataName__c = 'Rejection_Reason_Available';
        commEvent.PELoggerId__c = peLogger.Id;
        commEvent.RecordID__c = caseRec.Id;
        DateTime dt = DateTime.now();
        commEvent.Unique_Id__c = 'CommunicationLog-'+UserInfo.getUserId()+'-'+System.currentTimeMillis();
        Database.SaveResult eventResult = EventBus.publish(commEvent);
        return eventResult;
    }
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - branchAssignmentNotification
    * @param caseRec - Case record.
    * @param stpName - STP flow name.
    * @param title
    * @description - Creates a Custom Notification to Case Creator on Assignment of Branch
    *****************************************************************************************************************/
    public static void branchAssignmentNotification(Case caseRec,String stpName,String title){
        Set<String> recepientIds = new Set<String>();
        recepientIds.add(caseRec.CreatedById);
        Case caseRecord = [SELECT Id,Owner.Name,CaseNumber,CreatedById from Case WHERE Id =: caseRec.Id WITH SECURITY_ENFORCED];
        CustomNotificationType templateInfo = [SELECT Id, DeveloperName, MasterLabel FROM CustomNotificationType 
                                                            WHERE DeveloperName = 'Case_Assignment_Change' WITH SECURITY_ENFORCED Limit 1];
        if(Title == Null){
            Title = templateInfo.MasterLabel;
        }
        // Create a new custom notification
        Messaging.CustomNotification currNotification = new Messaging.CustomNotification();
        currNotification.setTitle(Title);
        currNotification.setBody('Failed to Retrieve '+ stpName + ' Documents. Case ' + caseRecord.CaseNumber + ' has been assigned to '+caseRecord.Owner.Name);               
        currNotification.setNotificationTypeId(templateInfo.Id);        
        currNotification.setTargetId(caseRec.Id);                    
        currNotification.send(recepientIds);                 
    }    
}