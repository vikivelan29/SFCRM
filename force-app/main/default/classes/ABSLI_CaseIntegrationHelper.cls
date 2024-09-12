/*********************************************************
*Class        :  ABHFL_CaseIntegrationHelper
*Author       :  Siddarth Jaitly
*Created Date :  12/06/2024
*Last Modified:
*Description  :  Case Integration Trigger Helper for ABSLI LOB
*History        :
*********************************************************/
public class ABSLI_CaseIntegrationHelper {
    public static Set<String> requestsForStageMovement = new Set<String>{'PEMT042','PEMT024'};
    /****************************************************************************************************************
    * @LOB - ABSLI
    * @Function - eBotHandler
    * @param caseId - Case Record ID
    * @param ebotResponse - Ebot Response Wrapper
    * @param recordAfter - ASF Case Integration record after context
    * @return - void .
    * @Description - Processing Ebot Response
    *****************************************************************************************************************/
    public static void eBotResponseHandler(String caseId,ABSLI_EbotWrapper.EbotResponseWrapper ebotResponse,ASF_Case_Integration__c recordAfter){
        ContentRelationWrapper contentRelation = transferAttachmentToCase(recordAfter);
        ABSLI_Case_Detail__c caseDetail = handleEmailMessages(caseId,ebotResponse,contentRelation);
        Case caseRecord = updateCase(caseId,ebotResponse,caseDetail);

    }
    /****************************************************************************************************************
    * @LOB - ABSLI
    * @Function - transferAttachmentToCase
    * @param caseIntegration - Case Integration Record
    * @return - void
    * @Description - Transfer Attachment to Case
    *****************************************************************************************************************/
    public static ContentRelationWrapper transferAttachmentToCase(ASF_Case_Integration__c caseIntegration){
        ContentRelationWrapper contentRelation = new ContentRelationWrapper();
		List<ContentDocumentLink> relatedAttachments = [Select LinkedEntityId,ContentDocumentId from ContentDocumentLink
                                                        where LinkedEntityId =: caseIntegration.Id WITH SECURITY_ENFORCED];

        Set<Id> contentDocumentIds = new Set<Id>();
        for(ContentDocumentLink attachment : relatedAttachments){
            contentDocumentIds.add(attachment.ContentDocumentId);
        }

        List<ContentVersion> contentList = [Select id,Is_Email_Body__c,For_Registered_Customer__c,ContentDocumentId
                                            from ContentVersion where ContentDocumentId in: contentDocumentIds WITH SECURITY_ENFORCED];

        Map<String,ContentVersion> contentDocumentVersionMap = new Map<String,ContentVersion>();
        List<String> registeredAttachments = new List<String>();
        List<String> unregisteredAttachments = new List<String>();
        for(ContentVersion content : contentList){
            contentDocumentVersionMap.put(content.ContentDocumentId,content);
            if(content.Is_Email_Body__c && content.For_Registered_Customer__c){
                contentRelation.registeredTemplateId = content.ContentDocumentId;
            }
            if(content.Is_Email_Body__c && !content.For_Registered_Customer__c){
                contentRelation.unregisteredTemplateId = content.ContentDocumentId;
            }
            if(!content.Is_Email_Body__c && content.For_Registered_Customer__c){
                registeredAttachments.add(content.Id);
            }
            if(!content.Is_Email_Body__c && !content.For_Registered_Customer__c){
                unregisteredAttachments.add(content.Id);
            }
        }
        contentRelation.registeredAttachments = registeredAttachments;
        contentRelation.unregisteredAttachments = unregisteredAttachments;

        /*List<ContentDocumentLink> contentLinkToBeInserted = new List<ContentDocumentLink>();
        if(relatedAttachments.size() > 0){
            for(ContentDocumentLink contentLink : relatedAttachments){
                if(!contentDocumentVersionMap.get(contentLink.ContentDocumentId).Is_Email_Body__c){
                    ContentDocumentLink link = new ContentDocumentLink();
                    link.LinkedEntityId = caseIntegration.Case__c;
                    link.ContentDocumentId= contentLink.ContentDocumentId;
                    link.ShareType = 'V';
                    contentLinkToBeInserted.add(link);
                }
            }
        }

        Database.SaveResult[] insertResult = Database.insert(contentLinkToBeInserted,false);*/

        return contentRelation;

    }

    /****************************************************************************************************************
    * @LOB - ABSLI
    * @Function - handleEmailMessages
    * @param caseId - Case Record ID
    * @param ebotResponse - Ebot Response Wrapper
    * @return - ABSLI_Case_Detail__c
    * @Description - Handle Email Message
    *****************************************************************************************************************/
    public static ABSLI_Case_Detail__c handleEmailMessages(String caseId,
                                                           ABSLI_EbotWrapper.EbotResponseWrapper ebotResponse,
                                                           ContentRelationWrapper contentRelation){

		ABSLI_Case_Detail__c caseDetail = new ABSLI_Case_Detail__c();
        caseDetail.From_Date__c = String.isNotBlank(ebotResponse.FromDate)?Date.valueOf(ebotResponse.FromDate):null;
        caseDetail.To_Date__c = String.isNotBlank(ebotResponse.ToDate)?Date.valueOf(ebotResponse.ToDate):null;
        caseDetail.Ebot_Email_in_Draft__c  = false;
        caseDetail.Source_Request_submitted_by__c = ABSLI_Constants.EMAIL_SOURCE_REQ_BY;

        if(ebotResponse.Email_Details.size() > 0){
            for(ABSLI_EbotWrapper.EmailDetailsWrapper emailWrapper : ebotResponse.Email_Details){
                List<String> staticAttachmentList = new List<String>();
                if(emailWrapper.Static_Attachment.size()>0){
                    for(String attachment: emailWrapper.Static_Attachment){
                        staticAttachmentList.add(attachment);
                    }
                }
                String staticAttachmentIds = String.join(staticAttachmentList,',');
                List<ContentWorkSpace> contentWorkSpace = [Select id from ContentWorkSpace where Name = 'ABSLI Static Forms'];
                Map<String,String> attachmentIdContentDocumentMap = new Map<String,String>();
                if(contentWorkSpace.size() > 0){
                    List<ContentVersion> contentList = [Select id,EBOT_Attachment_ID__c, ContentDocumentId  from ContentVersion
                                                        where ContentDocument.ParentId =: contentWorkSpace[0].Id];
                    for(ContentVersion content : contentList){
                        attachmentIdContentDocumentMap.put(content.EBOT_Attachment_ID__c,content.Id);
                    }
                }
                List<String> staticAttachmentDocumentIds = new List<String>();
                for(String attachment : staticAttachmentList){
                    if(attachmentIdContentDocumentMap.containsKey(attachment)){
                        staticAttachmentDocumentIds.add(attachmentIdContentDocumentMap.get(attachment));
                    }
                }
                if(emailWrapper.EmailCustomerFlag != null && emailWrapper.EmailCustomerFlag/* == 'Y'*/){
                    string templateId = '';
                    string attachmentIds = '';
                    if(emailWrapper.Is_Register_Customer != null && emailWrapper.Is_Register_Customer/* == 'Y'*/){
                        templateId = contentRelation.registeredTemplateId;
                        staticAttachmentDocumentIds.addAll(contentRelation.registeredAttachments);
                    } else {
                        templateId = contentRelation.unregisteredTemplateId;
                        staticAttachmentDocumentIds.addAll(contentRelation.unregisteredAttachments);
                    }
                    if(staticAttachmentDocumentIds.size() > 0){
                        attachmentIds = String.join(staticAttachmentDocumentIds,',');
                    }
                    sendAutoMail(emailWrapper.EmailTo,
                                 emailWrapper.EmailSubject,
                                 templateId,
                                 attachmentIds,
                                 caseId);
                }else{
                    caseDetail.Draft_To_Address__c = emailWrapper.EmailTo;
                    caseDetail.Draft_Subject__c = emailWrapper.EmailSubject;
                    if(emailWrapper.Is_Register_Customer != null && emailWrapper.Is_Register_Customer/* == 'Y'*/){
                        staticAttachmentDocumentIds.addAll(contentRelation.registeredAttachments);
                    } else {
                        staticAttachmentDocumentIds.addAll(contentRelation.unregisteredAttachments);
                    }
                    caseDetail.Draft_AttachmentIds__c = String.join(staticAttachmentDocumentIds,',');
                    if(emailWrapper.Is_Register_Customer != null && emailWrapper.Is_Register_Customer/* == 'Y'*/){
                        caseDetail.Ebot_Email_in_Draft__c  = true;
                    }
                }
            }
        }

        if(Schema.sObjectType.ABSLI_Case_Detail__c.isCreateable()){
            insert caseDetail;
        }

		return caseDetail;
    }

    /****************************************************************************************************************
    * @LOB - ABSLI
    * @Function - sendAutoMail
    * @param emailWrapper - Email To Address
    * @param emailWrapper - Email Subject
    * @param emailWrapper - Email TemplateId
    * @param emailWrapper - Email Attachment Ids
    * @param caseId - Case Record Id
    * @return - void
    * @Description - Send Auto Email
    *****************************************************************************************************************/
    public static void sendAutoMail(String toAddress,String subject,String templateId,String attachmentId,String caseId){
        PE_Logger__c peLogger = new PE_Logger__c();
        peLogger.PE_Name__c = 'CommunicationLog';
        peLogger.Retry_PE__c = true;
        peLogger.Status__c = 'Pending';
        peLogger.RecordID__c = caseId;
        peLogger.LOB__c = ABSLI_Constants.BUSINESS_UNIT;
        peLogger.Case__c = caseId;
        peLogger.TakeBodyFromContentDoc__c = true;
        peLogger.Subject__c = subject;
        peLogger.Content_Version_Ids__c = attachmentId;
        peLogger.HTMLBody_Con_Doc_Id__c = templateId;
        peLogger.Specific_To_Address__c = toAddress;
        if(Schema.sObjectType.PE_Logger__c.isCreateable())
        {
            insert peLogger;

            ASF_CommnunicationLog__e commEvent = new ASF_CommnunicationLog__e();
            commEvent.PELoggerId__c = peLogger.Id;
            commEvent.RecordID__c = caseId;
            DateTime dt = DateTime.now();
            commEvent.Unique_Id__c = 'CommunicationLog-'+UserInfo.getUserId()+'-'+System.currentTimeMillis();
            Database.SaveResult eventResult = EventBus.publish(commEvent);
        }
    }

    /****************************************************************************************************************
    * @LOB - ABSLI
    * @Function - updateCase
    * @param caseId - Case Record ID
    * @param caseDetail - ABSLI Case Detail Record
    * @param ebotResponse - Ebot Response Wrapper
    * @return - Case Record
    * @Description - Update Case
    *****************************************************************************************************************/
    public static Case updateCase(String caseId,ABSLI_EbotWrapper.EbotResponseWrapper ebotResponse, ABSLI_Case_Detail__c caseDetail){
        Case caseRecord = new Case();
        caseRecord.Id = caseId;
        caseRecord.ABSLI_Case_Detail__c = caseDetail.Id;
        caseRecord.CCC_External_Id__c = ebotResponse.CaseSubSubType;
        caseRecord.Comments = ebotResponse.Comments;
        caseRecord.Issue_Type__c = ebotResponse.Issue_Type;
        if(ebotResponse.FTR != null){
            caseRecord.FTR__c = ebotResponse.FTR;//String.isNotBlank(ebotResponse.FTR)?Boolean.valueOf(ebotResponse.FTR):false;
        }
        if(String.isNotBlank(ebotResponse.CaseSubSubType)){
            List<ASF_Case_Category_Config__c> cccList = [SELECT Id
                                                         FROM ASF_Case_Category_Config__c
                                                         WHERE CCC_External_Id__c = :ebotResponse.CaseSubSubType
                                                         AND Business_Unit__c =: ABSLI_Constants.BUSINESS_UNIT];
            if(!cccList.isEmpty()){
                //Valid External Id provided, hence convert.
                caseRecord.RecordTypeId = ASF_Constants.RT_FRAMEWORK;
            }
        }
        if(String.isNotBlank(ebotResponse.ClientId)){
            List<Account> customerList = [Select Id from Account where Client_Code__c =: ebotResponse.ClientId];
            if(customerList.size() > 0){
                caseRecord.AccountId = customerList[0].Id;
            }
        }else{
            caseRecord.AccountId = NULL;
            caseRecord.ContactId = NULL;
            caseRecord.Client_Code_Text__c = NULL;
        }
        if(String.isNotBlank(ebotResponse.PolicyNo)){
            List<Asset> policyList = [Select Id from Asset where Policy_No__c =: ebotResponse.PolicyNo];
            if(policyList.size() > 0){
                caseRecord.AssetId = policyList[0].Id;
            }
        }else{
            caseRecord.AssetId = NULL;
        }

        if(Schema.sObjectType.Case.isUpdateable()){
            update caseRecord;
        }

        if(caseRecord.FTR__c){
            caseRecord.MoveToNext__c = true;  
            if(Schema.sObjectType.Case.isUpdateable()){
                update caseRecord;
            }
        }

        if(requestsForStageMovement.contains(caseRecord.CCC_External_Id__c)){
            caseRecord.MoveToNext__c = true;  
            if(Schema.sObjectType.Case.isUpdateable()){
                update caseRecord;
            }         
        }

        return caseRecord;
    }
    /****************************************************************************************************************
    * @LOB - ABSLI
    * @Function - ebotEmailComposerHandler
    * @param recId - Case Record ID
    * @return - EmailComposerWrapper
    * @Description - Load Draft Email Template
    *****************************************************************************************************************/
    @AuraEnabled
    public static EmailComposerWrapper ebotEmailComposerHandler(String recId){
        EmailComposerWrapper emailWrapper = new EmailComposerWrapper();
        Case caseRecord = [Select id,ABSLI_Case_Detail__r.Draft_Email_Sent__c,ABSLI_Case_Detail__r.Draft_AttachmentIds__c,ABSLI_Case_Detail__r.Draft_Subject__c,
                           ABSLI_Case_Detail__r.Draft_To_Address__c,
                           (Select id from ASF_Case_Integrations__r where Type__c = 'eBOT' and Status__c = 'Success')
                           from Case where id =: recId Limit 1];
        if(caseRecord.ASF_Case_Integrations__r.size() > 0){
            List<ContentDocumentLink> documentLink = [Select id,ContentDocumentId 
                                                      from ContentDocumentLink where LinkedEntityId =: caseRecord.ASF_Case_Integrations__r[0].Id];
            Set<Id> documentIds = new Set<Id>();
            for(ContentDocumentLink docLink : documentLink){
                documentIds.add(docLink.ContentDocumentId);
            }
            if(documentIds.size() > 0){
                emailWrapper.emailSubject = caseRecord.ABSLI_Case_Detail__r.Draft_Subject__c;
                emailWrapper.emailToAddress = caseRecord.ABSLI_Case_Detail__r.Draft_To_Address__c;
                emailWrapper.emailAttachmentIds = caseRecord.ABSLI_Case_Detail__r.Draft_AttachmentIds__c;
                emailWrapper.caseDetailId = caseRecord.ABSLI_Case_Detail__c;
                emailWrapper.emailTemplateId = documentLink[0].ContentDocumentId;
                List<String> attachmentList = String.isNotBlank(emailWrapper.emailAttachmentIds)?emailWrapper.emailAttachmentIds.split(','): new List<String>();
                String queryStr = 'SELECT VersionData,ContentDocumentId,Is_Email_Body__c,For_Registered_Customer__c,Id,PathOnClient FROM ContentVersion WHERE ';
                if(documentIds.size() > 0){
                    queryStr += ' ContentDocumentId IN: documentIds ';
                }
                if(attachmentList.size() > 0){
                    if(queryStr.contains('ContentDocumentId')){
                        queryStr += ' or id in: attachmentList';
                    } else {
                        queryStr += ' id in: attachmentList';
                    }
                }
                List<ContentVersion> contentVersionList = Database.query(queryStr);
                //List<ContentVersion> contentVersionList = [SELECT VersionData,ContentDocumentId,Is_Email_Body__c,For_Registered_Customer__c,Id,PathOnClient FROM ContentVersion 
                //                                     WHERE ContentDocumentId in: documentIds or id in: attachmentList];
                List<EmailAttachmentWrapper> attachmentWrapperList = new List<EmailAttachmentWrapper>();
                for(ContentVersion doc : contentVersionList){
                    if(doc.Is_Email_Body__c && doc.For_Registered_Customer__c){
                        emailWrapper.emailBody = doc.versionData.toString();
                        emailWrapper.emailTemplateId = doc.ContentDocumentId;
                    }else{
                        if(attachmentList.contains(doc.Id)){
                            EmailAttachmentWrapper attachmentWrapper = new EmailAttachmentWrapper();
                            attachmentWrapper.contentDocumentId = doc.ContentDocumentId;
                            attachmentWrapper.contentVersionId = doc.Id;
                            attachmentWrapper.fileName = doc.PathOnClient;
                            attachmentWrapperList.add(attachmentWrapper);
                        }
                    }
                }
                emailWrapper.emailAttachmentList = attachmentWrapperList;
            }
        }
        /*if(caseRecord.Business_Unit__c == ABSLI_Constants.BUSINESS_UNIT && caseRecord.Technical_Source__c == 'Email' &&
           String.isNotBlank(caseRecord.ABSLI_Case_Detail__r.Email_Body__c) && !caseRecord.ABSLI_Case_Detail__r.Ebot_Email_Sent__c ){
               emailWrapper.displayMessage = true;
               return emailWrapper;
           }*/
        
        return emailWrapper;
    }
    /****************************************************************************************************************
    * @LOB - ABSLI
    * @Function - sendMail
    * @param recId - Case Record ID
    * @param emailWrapper - Email Wrapper String
    * @return - Boolean
    * @Description - Send Email
    *****************************************************************************************************************/
    @AuraEnabled
    public static Boolean sendMail(String recId,string emailWrapperStr){
        Boolean isSuccess = true;
        if(String.isNotBlank(emailWrapperStr)){
            EmailComposerWrapper emailWrapper = (EmailComposerWrapper)JSON.deserialize(emailWrapperStr,EmailComposerWrapper.class);
            Case caseRecord = [Select id,ABSLI_Case_Detail__c,ABSLI_Case_Detail__r.Draft_Email_Sent__c,
                              (Select id from ASF_Case_Integrations__r where Type__c = 'eBOT' and Status__c = 'Success') 
                              from Case where id =: recId Limit 1];
            List<ContentVersion> content = [Select id,VersionData,Title,PathonClient,ContentDocumentId 
                                            from ContentVersion where ContentDocumentId =:emailWrapper.emailTemplateId and islatest = true];
            if(emailWrapper.emailBody != content[0].VersionData.toString()){
                Blob binaryData = Blob.valueOf(emailWrapper.emailBody);
                ContentVersion newVersion = new ContentVersion();
                newVersion.Title = content[0].Title + '_SentVersion';
                newVersion.PathOnClient = content[0].PathonClient;
                newVersion.VersionData = binaryData;
                newVersion.IsMajorVersion = true;
                if(Schema.sObjectType.ContentVersion.isCreateable()){
                    insert newVersion;
                }
                ContentVersion newContent = [Select id,VersionData,Title,PathonClient,ContentDocumentId 
                                                from ContentVersion where id =:newVersion.Id];
                ContentDocumentLink contentLink = new ContentDocumentLink();
                contentLink.ContentDocumentId = newContent.ContentDocumentId;
                contentLink.LinkedEntityId = caseRecord.ASF_Case_Integrations__r[0].Id;
                contentLink.ShareType = 'V';
                if(Schema.sObjectType.ContentDocumentLink.isCreateable()){
                    insert contentLink;
                }
                emailWrapper.emailTemplateId = newContent.ContentDocumentId;
            }
            sendAutoMail(emailWrapper.emailToAddress,
            emailWrapper.emailSubject,
            emailWrapper.emailTemplateId,
            emailWrapper.emailAttachmentIds,
            recId);
            ABSLI_Case_Detail__c caseDetail = new ABSLI_Case_Detail__c();
            caseDetail.Id = caseRecord.ABSLI_Case_Detail__c;
            caseDetail.Draft_Email_Sent__c = true;
            if(Schema.sObjectType.ABSLI_Case_Detail__c.isUpdateable()){
                update caseDetail;
            }
        }
        return isSuccess;
    }

/****************************************************************************************************************
    * @LOB - ABSLI
    * @Function - changeAttachment
    * @param recId - Case Record Id
    * @param attachmentId - Attachment Id
    * @param deleteAttachment - Add or Remove Attachment
    * @return - EmailComposerWrapper
    * @Description - Add or Remove Attachment
    *****************************************************************************************************************/
    @AuraEnabled
    public static EmailComposerWrapper changeAttachments(String recId,String attachmentId,Boolean deleteAttachment){
        ABSLI_Case_Detail__c caseDetail = [ Select id,Draft_AttachmentIds__c 
                                            from ABSLI_Case_Detail__c 
                                            where Id in (Select ABSLI_Case_Detail__c from Case where id =: recId) Limit 1];
        if(deleteAttachment){
            if(caseDetail != null){
                if(String.isNotBlank(caseDetail.Draft_AttachmentIds__c)){
                    List<String> attachmentIds = caseDetail.Draft_AttachmentIds__c.split(',');
                    for(integer i=0;i < attachmentIds.size();i++){
                        if(attachmentIds[i] == attachmentId){
                            attachmentIds.remove(i);
                            caseDetail.Draft_AttachmentIds__c = String.join(attachmentIds,',');
                            if(Schema.sObjectType.ABSLI_Case_Detail__c.isUpdateable()){
                                update caseDetail;
                            }
                            break;
                        }
                    }
                }
            }
        }else{
            if(caseDetail != null){
                if(String.isNotBlank(caseDetail.Draft_AttachmentIds__c)){
                    List<String> attachmentIds = new List<String>();
                    attachmentIds = caseDetail.Draft_AttachmentIds__c.split(',');
                    attachmentIds.add(attachmentId);
                    caseDetail.Draft_AttachmentIds__c = String.join(attachmentIds,',');
                    if(Schema.sObjectType.ABSLI_Case_Detail__c.isUpdateable()){
                        update caseDetail;
                    }
                }
            }
        }
        return ebotEmailComposerHandler(recId);
    }

    public class ContentRelationWrapper{
        public string registeredTemplateId;
        public string unregisteredTemplateId;
        public List<string> registeredAttachments;
        public List<string> unregisteredAttachments;
    }

    public class EmailComposerWrapper{
        @AuraEnabled
        public String emailBody;
        @AuraEnabled
        public String emailSubject;
        @AuraEnabled
        public String emailToAddress;
        @AuraEnabled
        public String emailTemplateId;
        @AuraEnabled
        public String emailAttachmentIds;
        @AuraEnabled
        public List<EmailAttachmentWrapper> emailAttachmentList;
        @AuraEnabled
        public string caseDetailId;
    }

    public class EmailAttachmentWrapper{
        @AuraEnabled
        public String contentDocumentId;
        @AuraEnabled
        public String contentVersionId;
        @AuraEnabled
        public String fileName;
    }

}