/*********************************************************
*Class        :  ABHFL_CaseIntegrationHelper
*Author       :  Siddarth Jaitly
*Created Date :  12/06/2024
*Last Modified:
*Description  :  Case Integration Trigger Helper for ABSLI LOB
*History        :
*********************************************************/
public class ABSLI_CaseIntegrationHelper {
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
        System.debug('Inside ebtot');

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

        List<ContentDocumentLink> contentLinkToBeInserted = new List<ContentDocumentLink>();
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

        Database.SaveResult[] insertResult = Database.insert(contentLinkToBeInserted,false);

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

        if(ebotResponse.Email_Details.size() > 0){
            for(ABSLI_EbotWrapper.EmailDetailsWrapper emailWrapper : ebotResponse.Email_Details){
                List<String> staticAttachmentList = new List<String>();
                if(emailWrapper.Static_Attachment.size()>0){
                    for(ABSLI_EbotWrapper.StaticAttachmentWrapper attachment: emailWrapper.Static_Attachment){
                        staticAttachmentList.add(attachment.AttachmentName);
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
                if(emailWrapper.EmailCustomerFlag == 'Y'){
                    string templateId = '';
                    string attachmentIds = '';
                    if(emailWrapper.Is_Register_Customer == 'Y'){
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
                    caseDetail.Draft_AttachmentIds__c = staticAttachmentIds;
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
        caseRecord.FTR__c = String.isNotBlank(ebotResponse.FTR)?Boolean.valueOf(ebotResponse.FTR):false;
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
        }
        if(String.isNotBlank(ebotResponse.PolicyNo)){
            List<Asset> policyList = [Select Id from Asset where Policy_No__c =: ebotResponse.PolicyNo];
            if(policyList.size() > 0){
                caseRecord.AssetId = policyList[0].Id;
            }
        }

        if(Schema.sObjectType.Case.isUpdateable()){
            update caseRecord;
        }

        return caseRecord;
    }

    /**
	 * @description Change Date to in format of DD-MM-YYYY
     *
	 * @author Abinash Panigrahi
     * @date 2024-05-28
	 */
    public static String dateFormat(Date dt){
        return DateTime.newInstance(dt.year(),dt.month(),dt.day()).format('dd-MM-YYYY');
    }

    public class ContentRelationWrapper{
        public string registeredTemplateId;
        public string unregisteredTemplateId;
        public List<string> registeredAttachments;
        public List<string> unregisteredAttachments;
    }

}
