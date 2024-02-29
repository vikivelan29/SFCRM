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
    * @Function - fetchStpTemplates
    * @param templateString - Resolved and rejected templates string
    * @return - Map<String, String> .
    * @description - Get a map of template type and template value
    *****************************************************************************************************************/       
    public static Map<String, String> fetchStpTemplates(String templateString){

        Map<String, String> templateMap = new Map<String, String>();
        if(String.isNotBlank(templateString)) {
            List<String> pairs = templateString.split(',');
            for(String pair : pairs) {
                List<String> keyValue = pair.split(':');
                if(keyValue.size() == 2) {
                    templateMap.put(keyValue[0].trim(), keyValue[1].trim());
                }
            }
        }
        return templateMap;
    }
    
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
    public static Database.SaveResult createPELogAndinvokeCommPEevent(List<Case> caseRecs, Map<Id, String> emailTemplateMap, Map<Id, String> smsMetadataMap, Map<Id, Boolean> isTransferredMap){
        Map<Id, PE_Logger__c> loggerMap = new Map<Id, PE_Logger__c>();
        for(Case caseRec : caseRecs){
            PE_Logger__c peLogger = new PE_Logger__c();
            peLogger.AccountId__c = caseRec.AccountId;
            peLogger.CCCExternalId__c = caseRec.CCC_External_Id__c;
            peLogger.Case__c = caseRec.Id;
            peLogger.ContactId__c = caseRec.ContactId;
            peLogger.PE_Name__c = 'CommunicationLog';
            peLogger.RecordID__c = caseRec.Id;
            peLogger.Retry_PE__c = true;
            peLogger.Status__c = 'Pending';
            peLogger.CustomMetadataName__c = smsMetadataMap!= null?smsMetadataMap.get(caseRec.Id):null;
            peLogger.Email_Template_Name__c = emailTemplateMap != null?emailTemplateMap.get(caseRec.Id):null;
            peLogger.No_Auto_Communication__c = caseRec.No_Auto_Communication__c;
            Map<String,Object> caseFieldValMap = caseRec.getPopulatedFieldsAsMap();
            if(!caseFieldValMap.containsKey('Business_Unit__c') || !caseFieldValMap.containsKey('Lead__c')){
                Case caseRecord = [Select id,Business_Unit__c,Lead__c from Case where id =: caseRec.Id];
                peLogger.LOB__c = caseRecord.Business_Unit__c;
                peLogger.Lead__c = caseRecord.Lead__c;              
            } else {
                if(!caseFieldValMap.containsKey('Business_Unit__c')){
                    peLogger.LOB__c = caseRec.Business_Unit__c;    
                }
                if(!caseFieldValMap.containsKey('Lead__c')){
                    peLogger.LOB__c = caseRec.Lead__c;    
                }
            }
            if(isTransferredMap.get(caseRec.Id)){
                peLogger.Is_Attachment__c = true;
                //peLogger.Content_Version_Ids__c='0689I000001DJPFQA4';
            }
            loggerMap.put(caseRec.Id, peLogger);
        }

        insert loggerMap.values();

        invokeCommunicationLogPlatformEvent(caseRecs, loggerMap);
    }

    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - invokeCommunicationLogPlatformEvent
    * @param caseRec - Case record.
    * @param peLogger - PE_Logger__c record.
    * @return - Database.SaveResult.
    * @description - Function to publish ASF_CommnunicationLog__e platform event.
    *****************************************************************************************************************/
    private static List<Database.SaveResult> invokeCommunicationLogPlatformEvent(List<Case> caseRecs, Map<Id, PE_Logger__c> peLoggerMap){
        List<ASF_CommnunicationLog__e> commEventList = new List<ASF_CommnunicationLog__e>();
        for(Case caseRec : caseRecs){
            ASF_CommnunicationLog__e commEvent = new ASF_CommnunicationLog__e();
            commEvent.CCCExternalId__c = caseRec.CCC_External_Id__c;
            //commEvent.CustomMetadataName__c = 'Rejection_Reason_Available';
            commEvent.PELoggerId__c = peLoggerMap.get(caseRec.Id).Id;
            commEvent.RecordID__c = caseRec.Id;
            DateTime dt = DateTime.now();
            commEvent.Unique_Id__c = 'CommunicationLog-'+UserInfo.getUserId()+'-'+System.currentTimeMillis();
            commEventList.add(commEvent);
        }
        List<Database.SaveResult> eventResults = EventBus.publish(commEventList);
        return eventResults;
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
        Map<String,Object> caseFieldValMap = caseRec.getPopulatedFieldsAsMap();
        if(!caseFieldValMap.containsKey('Business_Unit__c') || !caseFieldValMap.containsKey('Lead__c')){
            Case caseRecord = [Select id,Business_Unit__c,Lead__c from Case where id =: caseRec.Id];
            peLogger.LOB__c = caseRecord.Business_Unit__c;
            peLogger.Lead__c = caseRecord.Lead__c;              
        } else {
            if(!caseFieldValMap.containsKey('Business_Unit__c')){
                peLogger.LOB__c = caseRec.Business_Unit__c;    
            }
            if(!caseFieldValMap.containsKey('Lead__c')){
                peLogger.LOB__c = caseRec.Lead__c;    
            }
        }
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
        Case caseRecord = [SELECT Id,Owner.Name,CaseNumber,CreatedById from Case WHERE Id =: caseRec.Id];
        CustomNotificationType templateInfo = [SELECT Id, DeveloperName, MasterLabel FROM CustomNotificationType 
                                                            WHERE DeveloperName = 'Case_Assignment_Change' Limit 1];
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
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - updateErrorMessage
    * @param caseIntegration - Case Integration record.
    * @description - Processes STP Response and Updated Error Message
    *****************************************************************************************************************/
    public static void updateErrorMessage(ASF_Case_Integration__c caseIntegration){
        try{
            ASF_Case_Integration__c  caseInt = [Select id,Error_Message__c,Request__c from ASF_Case_Integration__c where id =: caseIntegration.Id  limit 1];
            string eventName = '';
            if(String.isNotBlank(caseInt.Request__c)){
                Case_Integration_Outbound__e intEvent = (Case_Integration_Outbound__e)JSON.deserialize(caseInt.Request__c,Case_Integration_Outbound__e.class);
                eventName = intEvent.Integration_Name__c;
            }
            if(eventName == 'Sanction Letter'){
                reportingResponseWrapper response = (reportingResponseWrapper)JSON.deserialize(caseIntegration.Response__c,reportingResponseWrapper.class);
                if(response != null && response.returnCode != null && response.returnMessage != null && caseInt.Error_Message__c == null && response.returnCode != '1' ){
                    if(response.returnCode != '1'){
                        caseInt.Error_Message__c = response.returnMessage;
                        update caseInt;
                    }
                }
            }else {
                stpResponseWrapper response = (stpResponseWrapper)JSON.deserialize(caseIntegration.Response__c,stpResponseWrapper.class);
                if(response != null && response.operationStatus != null && response.operationMessage != null && caseInt.Error_Message__c == null && response.operationStatus != '1' ){
                    if(response.operationStatus == '0'){
                        caseInt.Error_Message__c = response.operationMessage;
                        update caseInt;
                    }
                }
            }
        }catch(exception e){}

    }

    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - transferFilesToDMS
    * @param recId - Case Record Id.
    * @description - Initiates File Transfer to DMS
    *****************************************************************************************************************/
    @InvocableMethod
    public static void transferFilesToDMS(List<Id> recIds){
        Case caseRecord = [Select id,Business_Unit__c,CaseNumber,Account.Client_Code__c,Type_Text__c,Sub_Type_Text__c,Nature__c,Lead__c,CreatedDate,Asset.LAN__c,Asset.Lead_Id__c,
                           Account.Phone,Account.PersonMobilePhone,Account.RecordType.Name  from Case where Id =: recIds[0]];
        List<ContentDocumentLink> contentDocumentList = [Select ContentDocumentId from ContentDocumentLink where LinkedEntityId =: caseRecord.Id];
        if(contentDocumentList.size() > 0){
            Set<Id> contentDocumentIds = new Set<Id>();
            for(ContentDocumentLink docLink : contentDocumentList){
                contentDocumentIds.add(docLink.ContentDocumentId);
            }
            List<ContentVersion> contentVersionList = [Select id,Title,ContentDocumentId,VersionNumber,FileExtension from ContentVersion where ContentDocumentId in: contentDocumentIds];
            Map<String,Integer> contentDocumentVersionMap = new Map<String,Integer>();
            for(ContentVersion version : contentVersionList){
                Integer count = 0;
                if(contentDocumentVersionMap.containsKey(version.ContentDocumentId)){
                    count = contentDocumentVersionMap.get(version.ContentDocumentId);
                }
                count += 1;
                contentDocumentVersionMap.put(version.ContentDocumentId,count);
            }
            List<DMS_Files__c> fileRecList = new List<DMS_Files__c>();
            for(ContentVersion fileVersion : contentVersionList){
                DMS_Files__c fileRec = new DMS_Files__c();
                Integer versionCount = contentDocumentVersionMap.get(fileVersion.ContentDocumentId);
                fileRec.ContentDocumentId__c = fileVersion.ContentDocumentId;
                fileRec.Case__c = caseRecord.Id;
                fileRec.ContentVersionId__c = fileVersion.Id;
                fileRec.File_Name__c = fileVersion.Title;
                fileRec.Has_Multiple_Versions__c = versionCount > 1 ? true : false;
                fileRec.Is_Latest_Version__c = versionCount == Integer.valueof(fileVersion.VersionNumber) ? true : false;
                fileRec.Status__c = ABHFL_Constants.PENDING;
                fileRec.Version_Number__c = fileVersion.VersionNumber;
                fileRec.Business_Unit__c = caseRecord.Business_Unit__c;
                DateTime currentDateTime = System.now();
                fileRec.DMS_External_ID__c = fileVersion.Id + '' + currentDateTime.getTime();
                fileRec.File_Extension__c = fileVersion.FileExtension;
                fileRec.Next_Retry__c = System.now().addMinutes(15);
                fileRecList.add(fileRec);
            }
            if(fileRecList.size() > 0){
                insert fileRecList;
                Set<Id> dmsFileIds = new Set<Id>();
                for(DMS_Files__c file : fileRecList){
                    dmsFileIds.add(file.Id);
                }
                //List<DMS_Files__c> dmsFiles = [Select id,Name,Business_Unit__c,ContentVersionId__c,File_Name__c,Is_Latest_Version__c,Version_Number__c,File_Extension__c,DMS_External_ID__c from DMS_Files__c where id in: dmsFileIds];
                List<DMS_File_Transfer__e> dmsEventList = new List<DMS_File_Transfer__e>();
                //string mobile = '';
                for(DMS_Files__c file : fileRecList){
                    dmsEventList.add(new DMS_File_Transfer__e(
                        Business_Unit__c = file.Business_Unit__c,
                        CaseNumber__c = caseRecord.CaseNumber,
                        ContentVersionId__c = file.ContentVersionId__c,
                        Customer_Client_Code__c = caseRecord.Account.Client_Code__c,
                        DMS_External_ID__c = file.DMS_External_ID__c,
                        File_Name__c = file.File_Name__c,
                        Is_Latest_Version__c = file.Is_Latest_Version__c,
                        Version_Number__c = file.Version_Number__c,
                        Application_ID__c = caseRecord.Asset.LAN__c,
                        Document_Type__c = caseRecord.Type_Text__c+'-'+caserecord.Sub_Type_Text__c+'-'+caseRecord.Nature__c,
                        File_Extension__c = file.File_Extension__c,
                        Doc_SubType__c = caseRecord.Sub_Type_Text__c,
                        Docgroup_Type__c = caseRecord.Nature__c.left(1) + '-' + caserecord.Type_Text__c,
                        Lead_ID__c = String.isNotBlank(caseRecord.Asset.Lead_Id__c) ? caseRecord.Asset.Lead_Id__c : String.isNotBlank(caseRecord.Lead__c) ? caseRecord.Lead__c : caseRecord.CaseNumber,
                        Contact_No__c = ABHFL_Constants.ACCOUNT_RECORDTYPE_NON_INDIVIDUAL == caseRecord.Account.RecordType.Name ? caseRecord.Account.Phone : caseRecord.Account.PersonMobilePhone,
                        Source__c = ASF_Constants.DMS_FILE_TRANSFER_SOURCE
                    ));
                }
                if(dmsEventList.size() > 0){
                    List<Database.SaveResult> eventResult = EventBus.publish(dmsEventList);
                }
            }
        }
    }

    public class stpResponseWrapper{
        public string operationStatus;
        public string operationMessage;
        public string binaryDataList;
        public string caseId;
        public string reportPath;
    }

    public class reportingResponseWrapper{
        public string returnCode;
        public string returnMessage;
    }
}