/*********************************************************
*Class        :  ABCL_IntegrationCommonUtility
*Author       :  Siddarth Jaitly
*Created Date :  12/12/2023
*Last Modified:  12/12/2023
*@description  :  General Utility Class for Integration
*********************************************************/
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.ExcessiveParameterList,PMD.NcssMethodCount,PMD.StdCyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts')
public with sharing class ABCL_IntegrationCommonUtility {
    public static final List<String> DMS_LINE_OF_BUSINESS = new List<String>{'ABHFL','ABFL','ABWM','ABSLI'};
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
    * @param caseRecs - Case record.
    * @param emailTemplateMap - Rejection email template from Case Category Config record.
    * @param smsMetadataMap - Rejection SMS metadata from Case Category Config record.
    * @param isTransferredMap
    * @return - Database.SaveResult.
    * @description - Function to create a PE_Logger__c record and invoke ASF_CommnunicationLog__e for email and SMS communication.
    *****************************************************************************************************************/
    public static List<Database.SaveResult> createPELogAndinvokeCommPEevent(List<Case> caseRecs, Map<Id, String> emailTemplateMap, Map<Id, String> smsMetadataMap, Map<Id, Boolean> isTransferredMap){
        Map<Id, PE_Logger__c> loggerMap = new Map<Id, PE_Logger__c>();
        Set<Id> setOfCaseIds = new Set<Id>();

        for(Case caseRec : caseRecs){
            setOfCaseIds.add(caseRec.Id);
        }
        List<Case> csList = [Select id,Business_Unit__c,Lead__c,AccountId, CCC_External_Id__c, contactId, No_Auto_Communication__c FROM Case WHERE Id in :setOfCaseIds WITH SYSTEM_MODE];

        for(Case caseRec : csList){
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
            peLogger.LOB__c = caseRec.Business_Unit__c;
            peLogger.Lead__c = caseRec.Lead__c;
           // Map<String,Object> caseFieldValMap = caseRec.getPopulatedFieldsAsMap();

            if(isTransferredMap.get(caseRec.Id)){
                peLogger.Is_Attachment__c = true;
                //peLogger.Content_Version_Ids__c='0689I000001DJPFQA4';
            }
            loggerMap.put(caseRec.Id, peLogger);
        }

        insert loggerMap.values();

        return invokeCommunicationLogPlatformEvent(caseRecs, loggerMap);
    }

    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - invokeCommunicationLogPlatformEvent
    * @param caseRecs - Case record.
    * @param peLoggerMap - PE_Logger__c record.
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
            //DateTime dt = DateTime.now();
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
    * @param emailTemplate - Rejection email template from Case Category Config record.
    * @param smsMetadata
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
            Case caseRecord = [Select id,Business_Unit__c,Lead__c from Case where id =: caseRec.Id WITH SYSTEM_MODE];
            peLogger.LOB__c = caseRecord.Business_Unit__c;
            peLogger.Lead__c = caseRecord.Lead__c;
        } else {
            if(!caseFieldValMap.containsKey('Business_Unit__c')){
                peLogger.LOB__c = caseRec.Business_Unit__c;
            }
            if(!caseFieldValMap.containsKey('Lead__c')){
                peLogger.Lead__c = caseRec.Lead__c;
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
       // DateTime dt = DateTime.now();
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
        Case caseRecord = [SELECT Id,Owner.Name,CaseNumber,CreatedById from Case WHERE Id =: caseRec.Id WITH SYSTEM_MODE];
        CustomNotificationType templateInfo = [SELECT Id, DeveloperName, MasterLabel FROM CustomNotificationType
                                                            WHERE DeveloperName = 'Case_Assignment_Change' WITH SYSTEM_MODE Limit 1];
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
            ASF_Case_Integration__c  caseInt = [Select id,Error_Message__c,Request__c from ASF_Case_Integration__c where id =: caseIntegration.Id WITH SYSTEM_MODE limit 1];
            string eventName = '';
            if(String.isNotBlank(caseInt.Request__c)){
                Case_Integration_Outbound__e intEvent = (Case_Integration_Outbound__e)JSON.deserialize(caseInt.Request__c,Case_Integration_Outbound__e.class);
                eventName = intEvent.Integration_Name__c;
            }
            if(eventName == 'Sanction Letter'){
                ReportingResponseWrapper response = (ReportingResponseWrapper)JSON.deserialize(caseIntegration.Response__c,ReportingResponseWrapper.class);
                if(response != null && response.returnCode != null && response.returnMessage != null && caseInt.Error_Message__c == null && response.returnCode != '1' ){
                    if(response.returnCode != '1' &&  Schema.sObjectType.ASF_Case_Integration__c.isUpdateable()){
                        caseInt.Error_Message__c = response.returnMessage;
                        update caseInt;
                    }
                }
            }else {
                stpResponseWrapper response = (stpResponseWrapper)JSON.deserialize(caseIntegration.Response__c,stpResponseWrapper.class);
                if(response != null && response.operationStatus != null && response.operationMessage != null && caseInt.Error_Message__c == null && response.operationStatus != '1' ){
                    if(response.operationStatus == '0' &&  Schema.sObjectType.ASF_Case_Integration__c.isUpdateable()){
                        caseInt.Error_Message__c = response.operationMessage;
                        update caseInt;
                    }
                }
            }
        }catch(exception e){
            ABCL_Logger.message(e.getMessage());
        }

    }

    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - transferFilesToDMS
    * @param recIds - Case Record Id.
    * @description - Initiates File Transfer to DMS
    *****************************************************************************************************************/
    @InvocableMethod
    public static void transferFilesToDMS(List<Id> recIds){
        if(recIds.size() == 1){
            Case caseRecord = [Select id,Business_Unit__c,CaseNumber,Account.Client_Code__c,Type_Text__c,Sub_Type_Text__c,Nature__c,Lead__c,CreatedDate,Asset.LAN__c,Asset.Lead_Id__c, Asset.Application_Number__c, Asset.Policy_No__c, LAN__c, CCC_External_Id__c,
                            Account.Phone,Account.PersonMobilePhone,Account.RecordType.Name  from Case where Id =: recIds[0] and Business_Unit__c in: DMS_LINE_OF_BUSINESS WITH SYSTEM_MODE];
            // Custom Logic handling for ABSLI Business Unit
            String dmsFolderId = '', businessFileName = '', policyNumber = '', applicationId = '';
            Boolean isABSLIBusiness = false;
            if (caseRecord.Business_Unit__c == ABSLI_Constants.BUSINESS_UNIT) {
                isABSLIBusiness = true;
                policyNumber = caseRecord.Asset.Policy_No__c != '' ? caseRecord.Asset.Policy_No__c : caseRecord.LAN__c;
                List<ASF_Case_Category_Config__c> cccRecord = [
                    SELECT Id, CCC_External_Id__c, DMS_Folder_Id__c
                    FROM ASF_Case_Category_Config__c
                    WHERE CCC_External_Id__c = :caseRecord.CCC_External_Id__c
                    WITH SECURITY_ENFORCED
                ];
                dmsFolderId = cccRecord[0].DMS_Folder_Id__c;
                applicationId = caseRecord.Asset.Application_Number__c;
                businessFileName =
                    applicationId +'_' +policyNumber +'_' +dmsFolderId +'_' +
                    Datetime.now().format('ddMMyyyy');
            }
            List<ContentDocumentLink> contentDocumentList = [Select ContentDocumentId from ContentDocumentLink where LinkedEntityId =: caseRecord.Id WITH SYSTEM_MODE];
            if(contentDocumentList.size() > 0){
                Set<Id> contentDocumentIds = new Set<Id>();
                for(ContentDocumentLink docLink : contentDocumentList){
                    contentDocumentIds.add(docLink.ContentDocumentId);
                }
                List<ContentVersion> contentVersionList = [Select id,Title,ContentDocumentId,VersionNumber,FileExtension from ContentVersion where ContentDocumentId in: contentDocumentIds WITH SYSTEM_MODE ];
                Map<String,Integer> contentDocumentVersionMap = new Map<String,Integer>();
                for(ContentVersion version : contentVersionList){
                    Integer count = 0;
                    if(contentDocumentVersionMap.containsKey(version.ContentDocumentId)){
                        count = contentDocumentVersionMap.get(version.ContentDocumentId);
                    }
                    count += 1;
                    contentDocumentVersionMap.put(version.ContentDocumentId,count);
                }
                string leadId = '';
                if(caseRecord.Asset.Lead_Id__c != null){
                    leadId = caseRecord.Asset.Lead_Id__c;
                } else if(caseRecord.Lead__c != null){
                    leadId = caseRecord.Lead__c;
                }
                List<DMS_Files__c> fileRecList = new List<DMS_Files__c>();
                for(ContentVersion fileVersion : contentVersionList){
                    DMS_Files__c fileRec = new DMS_Files__c();
                    Integer versionCount = contentDocumentVersionMap.get(fileVersion.ContentDocumentId);
                    fileRec.ContentDocumentId__c = fileVersion.ContentDocumentId;
                    fileRec.Case__c = caseRecord.Id;
                    fileRec.ContentVersionId__c = fileVersion.Id;
                    fileRec.Has_Multiple_Versions__c = versionCount > 1 ? true : false;
                    fileRec.Is_Latest_Version__c = versionCount == Integer.valueof(fileVersion.VersionNumber) ? true : false;
                    fileRec.Version_Number__c = fileVersion.VersionNumber;
                    fileRec.Business_Unit__c = caseRecord.Business_Unit__c;
                    DateTime currentDateTime = System.now();
                    fileRec.DMS_External_ID__c = fileVersion.Id + '' + currentDateTime.getTime();
                    fileRec.File_Extension__c = fileVersion.FileExtension;
                    if(String.isBlank(leadId) && !isABSLIBusiness){
                        fileRec.Status__c = ABHFL_Constants.CANCELED;
                        fileRec.Error_Description__c = ABHFL_Constants.ERROR_DESC_FOR_CANCELLED_DMS;
                    } else {
                        fileRec.Status__c = ABHFL_Constants.PENDING;
                    }
                    // Modified Attribute for ABSLI specific Business Unit
                    fileRec.File_Name__c = isABSLIBusiness ? businessFileName : fileVersion.Title;
                    fileRec.DMS_Folder_Id__c = isABSLIBusiness ? dmsFolderId : '';
                    fileRec.Application_ID__c = isABSLIBusiness ? applicationId : caseRecord.Asset.LAN__c;
                    fileRec.Policy_No__c = isABSLIBusiness ? policyNumber : '';
                    fileRec.Next_Retry__c = isABSLIBusiness ? null : System.now().addMinutes(15);
                    fileRecList.add(fileRec);
                }
                if(fileRecList.size() > 0 && Schema.sObjectType.DMS_Files__c.isCreateable()){
                    insert fileRecList;
                    Set<Id> dmsFileIds = new Set<Id>();
                    for(DMS_Files__c file : fileRecList){
                        dmsFileIds.add(file.Id);
                    }
                    //List<DMS_Files__c> dmsFiles = [Select id,Name,Business_Unit__c,ContentVersionId__c,File_Name__c,Is_Latest_Version__c,Version_Number__c,File_Extension__c,DMS_External_ID__c from DMS_Files__c where id in: dmsFileIds];
                    List<DMS_File_Transfer__e> dmsEventList = new List<DMS_File_Transfer__e>();
                    string mobile = '';
                    if(ABHFL_Constants.ACCOUNT_RECORDTYPE_INDIVIDUAL == caseRecord.Account.RecordType.Name){
                        mobile = caseRecord.Account.PersonMobilePhone;
                    }else {
                        mobile = caseRecord.Account.Phone;
                    }
                    for(DMS_Files__c file : fileRecList){
                        if(file.Status__c == ABHFL_Constants.PENDING){
                            dmsEventList.add(new DMS_File_Transfer__e(
                                Business_Unit__c = file.Business_Unit__c,
                                CaseNumber__c = caseRecord.CaseNumber,
                                ContentVersionId__c = file.ContentVersionId__c,
                                Customer_Client_Code__c = caseRecord.Account.Client_Code__c,
                                DMS_External_ID__c = file.DMS_External_ID__c,
                                File_Name__c = file.File_Name__c,
                                Is_Latest_Version__c = file.Is_Latest_Version__c,
                                Version_Number__c = file.Version_Number__c,
                                Application_ID__c = file.Application_ID__c,
                                DMS_Folder_Id__c = file.DMS_Folder_Id__c,
                                Policy_No__c = file.Policy_No__c,
                                Document_Type__c = caseRecord.Type_Text__c+'-'+caserecord.Sub_Type_Text__c+'-'+caseRecord.Nature__c,
                                File_Extension__c = file.File_Extension__c,
                                Doc_SubType__c = caseRecord.Sub_Type_Text__c,
                                Docgroup_Type__c = caseRecord.Nature__c.left(1) + '-' + caserecord.Type_Text__c,
                                Lead_ID__c = leadId,
                                Contact_No__c = mobile,
                                Source__c = ASF_Constants.DMS_FILE_TRANSFER_SOURCE
                            ));
                        }
                    }
                    if(dmsEventList.size() > 0){
                        List<Database.SaveResult> eventResult = EventBus.publish(dmsEventList);
                    }
                }
            }
        } else {
            transferToDMSBulk(recIds);
        }
    }

    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - transferToDMSBulk
    * @param  recIds - Case Record Ids.
    * @description - Initiates File Transfer to DMS for Bulk Operations
    *****************************************************************************************************************/
    public static void transferToDMSBulk(List<Id> recIds){
        Map<Id,Case> caseRecordMap = new Map<Id,Case>([Select id,Business_Unit__c,CaseNumber,Account.Client_Code__c,
                                    Type_Text__c,Sub_Type_Text__c,Nature__c,Lead__c,CreatedDate,Asset.LAN__c,
                                    Asset.Lead_Id__c,Asset.Application_Number__c, Asset.Policy_No__c, LAN__c, CCC_External_Id__c,Account.Phone,Account.PersonMobilePhone,Account.RecordType.Name
                                    from Case where Id =: recIds and Business_Unit__c in: DMS_LINE_OF_BUSINESS]);

        // Custom Logic handling for ABSLI Business Unit
        Map<String,ASF_Case_Category_Config__c> cccRecord = new Map<String,ASF_Case_Category_Config__c>();
        Set<String> cccExternalIds = new Set<String>();
        for(Case cs : caseRecordMap.values()){
            if(cs.Business_Unit__c == ABSLI_Constants.BUSINESS_UNIT){
                cccExternalIds.add(cs.CCC_External_Id__c);
            }
        }
        for (ASF_Case_Category_Config__c ccc : [
            SELECT Id, CCC_External_Id__c, DMS_Folder_Id__c
            FROM ASF_Case_Category_Config__c
            WHERE CCC_External_Id__c IN :cccExternalIds
            WITH SECURITY_ENFORCED
        ]) {
            cccRecord.put(ccc.CCC_External_Id__c, ccc);
        }

        List<ContentDocumentLink> contentDocumentList = [Select ContentDocumentId,LinkedEntityId from ContentDocumentLink
                                                         where LinkedEntityId in: caseRecordMap.keySet()  WITH SYSTEM_MODE];
        if(contentDocumentList.size() > 0){

            Map<Id,Case> contentDocumentCaseMap = new Map<Id,Case>();
            for(ContentDocumentLink docLink : contentDocumentList){
                contentDocumentCaseMap.put(docLink.ContentDocumentId,caseRecordMap.get(docLink.LinkedEntityId));
            }

            List<ContentVersion> contentVersionList = [ Select id,Title,ContentDocumentId,VersionNumber,FileExtension
                                                        from ContentVersion where ContentDocumentId in: contentDocumentCaseMap.keySet()  WITH SYSTEM_MODE ];

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
                Case relatedCase = contentDocumentCaseMap.get(fileVersion.ContentDocumentId);

                // Custom Logic handling for ABSLI Business Unit
                String dmsFolderId = '', businessFileName = '', policyNumber = '', applicationId = '';
                Boolean isABSLIBusiness = false;
                if (relatedCase.Business_Unit__c == ABSLI_Constants.BUSINESS_UNIT) {
                    isABSLIBusiness = true;
                    policyNumber = relatedCase.Asset.Policy_No__c != '' ? relatedCase.Asset.Policy_No__c : relatedCase.LAN__c;
                    dmsFolderId = cccRecord.get(relatedCase.CCC_External_Id__c).DMS_Folder_Id__c;
                    applicationId = relatedCase.Asset.Application_Number__c;
                    businessFileName =
                        applicationId +'_' +policyNumber +'_' +dmsFolderId +'_' +
                        Datetime.now().format('ddMMyyyy');
                }

                string leadId = '';
                if(relatedCase.Asset.Lead_Id__c != null){
                    leadId = relatedCase.Asset.Lead_Id__c;
                } else if(relatedCase.Lead__c != null){
                    leadId = relatedCase.Lead__c;
                }
                Integer versionCount = contentDocumentVersionMap.get(fileVersion.ContentDocumentId);

                fileRec.ContentDocumentId__c = fileVersion.ContentDocumentId;
                fileRec.Case__c = relatedCase.Id;
                fileRec.ContentVersionId__c = fileVersion.Id;
                fileRec.Has_Multiple_Versions__c = versionCount > 1 ? true : false;
                fileRec.Is_Latest_Version__c = versionCount == Integer.valueof(fileVersion.VersionNumber) ? true : false;
                fileRec.Version_Number__c = fileVersion.VersionNumber;
                fileRec.Business_Unit__c = relatedCase.Business_Unit__c;
                DateTime currentDateTime = System.now();
                fileRec.DMS_External_ID__c = fileVersion.Id + '' + currentDateTime.getTime();
                fileRec.File_Extension__c = fileVersion.FileExtension;
                fileRec.Next_Retry__c = System.now().addMinutes(15);
                if(String.isBlank(leadId) && !isABSLIBusiness){
                    fileRec.Status__c = ABHFL_Constants.CANCELED;
                    fileRec.Error_Description__c = ABHFL_Constants.ERROR_DESC_FOR_CANCELLED_DMS;
                } else {
                    fileRec.Status__c = ABHFL_Constants.PENDING;
                }
                // Modified Attribute for ABSLI specific Business Unit
                fileRec.File_Name__c = isABSLIBusiness ? businessFileName : fileVersion.Title;
                fileRec.DMS_Folder_Id__c = isABSLIBusiness ? dmsFolderId : '';
                fileRec.Application_ID__c = isABSLIBusiness ? applicationId : relatedCase.Asset.LAN__c;
                fileRec.Policy_No__c = isABSLIBusiness ? policyNumber : '';
                fileRecList.add(fileRec);
            }

            if(fileRecList.size() > 0 && Schema.sObjectType.DMS_Files__c.isCreateable()){
                insert fileRecList;

                List<DMS_File_Transfer__e> dmsEventList = new List<DMS_File_Transfer__e>();
                for(DMS_Files__c file : fileRecList){
                    if(file.Status__c == ABHFL_Constants.PENDING){
                        Case relatedCase = contentDocumentCaseMap.get(file.ContentDocumentId__c);
                        string mobile = '';
                        if(ABHFL_Constants.ACCOUNT_RECORDTYPE_INDIVIDUAL == relatedCase.Account.RecordType.Name){
                            mobile = relatedCase.Account.PersonMobilePhone;
                        }else {
                            mobile = relatedCase.Account.Phone;
                        }
                        string leadId = '';
                        if(relatedCase.Asset.Lead_Id__c != null){
                            leadId = relatedCase.Asset.Lead_Id__c;
                        } else if(relatedCase.Lead__c != null){
                            leadId = relatedCase.Lead__c;
                        }

                        dmsEventList.add(new DMS_File_Transfer__e(
                            Business_Unit__c = file.Business_Unit__c,
                            CaseNumber__c = relatedCase.CaseNumber,
                            ContentVersionId__c = file.ContentVersionId__c,
                            Customer_Client_Code__c = relatedCase.Account.Client_Code__c,
                            DMS_External_ID__c = file.DMS_External_ID__c,
                            File_Name__c = file.File_Name__c,
                            Is_Latest_Version__c = file.Is_Latest_Version__c,
                            Version_Number__c = file.Version_Number__c,
                            Application_ID__c = file.Application_ID__c,
                            DMS_Folder_Id__c = file.DMS_Folder_Id__c,
                            Policy_No__c = file.Policy_No__c,
                            Document_Type__c = relatedCase.Type_Text__c+'-'+relatedCase.Sub_Type_Text__c+'-'+relatedCase.Nature__c,
                            File_Extension__c = file.File_Extension__c,
                            Doc_SubType__c = relatedCase.Sub_Type_Text__c,
                            Docgroup_Type__c = relatedCase.Nature__c.left(1) + '-' + relatedCase.Type_Text__c,
                            Lead_ID__c = leadId,
                            Contact_No__c = mobile,
                            Source__c = ASF_Constants.DMS_FILE_TRANSFER_SOURCE
                        ));
                    }
                }

                if(dmsEventList.size() > 0){
                    List<Database.SaveResult> eventResult = EventBus.publish(dmsEventList);
                }
            }
        }
    }

    public static void caseIntegrationLogger(String caseId,
                                             String request,
                                             String respose,
                                             String intExtId,
                                             String status){
                                                 ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();
                                                 caseInt.Case__c = caseId;
                                                 caseInt.Request__c = request;
                                                 caseInt.Response__c = respose;
                                                 caseInt.Status__c = status;
                                                 caseInt.Integration_Ext_Id__c = intExtId;
                                                 if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
                                                     insert caseInt;
                                                 }


    }

    /**
	 * @description Change Date to in format of DD-MM-YYYY
     *
	 * @author Abinash Panigrahi
     * @date 2024-05-28
	 */
    public static String dateFormat(Date dt, String formatted){
        return DateTime.newInstance(dt.year(),dt.month(),dt.day()).format(formatted);
    }

/*********************************************************
*@description  :  wrapper class
*********************************************************/
    public class StpResponseWrapper{
        public string operationStatus;
        public string operationMessage;
        public string binaryDataList;
        public string caseId;
        public string reportPath;
    }
/*********************************************************
*@description  :  wrapper class
*********************************************************/
    public class ReportingResponseWrapper{
        public string returnCode;
        public string returnMessage;
    }
}