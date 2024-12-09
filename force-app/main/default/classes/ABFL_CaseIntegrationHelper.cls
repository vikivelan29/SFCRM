/*********************************************************
*Class        :  ABFL_CaseIntegrationHelper
*Author       :  Nikhil Patewar
*Created Date :  19/11/2024
*Last Modified:  
*Description  :  Case Integration Trigger Helper for ABFL LOB
*********************************************************/
public with sharing class ABFL_CaseIntegrationHelper {
    public static void unfydResponseHandler(String caseId, ABFL_UNFYDWrapper unfydResponse){
        try{
            ASF_Case_Category_Config__c caseCatConfig = [Select Id, Type__c,Sub_Type__c,CCC_External_Id__c,Business_Unit__c,Nature__c from ASF_Case_Category_Config__c Where CCC_External_Id__c=:unfydResponse.ISSUECODE AND Business_Unit__c='ABFL' LIMIT 1];
            //create ABFL_Case_Detail__c record
            ABFL_Case_Detail__c caseDetails = new ABFL_Case_Detail__c();
            caseDetails.Intent__c=String.isNotBlank(unfydResponse.INTENT)? unfydResponse.INTENT : '';
            caseDetails.Correct_Call_Type__c= caseCatConfig.Type__c;
            caseDetails.Correct_Sub_Type__c=caseCatConfig.Sub_Type__c;
            caseDetails.IsSMT__c = ( String.isNotBlank(unfydResponse.ISSMT) && unfydResponse.ISSMT == 'Yes') ? true : false;
            caseDetails.IsMultipleintent__c = (String.isNotBlank(unfydResponse.ISMULTIPLEINTENT) && unfydResponse.ISMULTIPLEINTENT == 'Yes') ? true : false;
            caseDetails.LOB__c=String.isNotBlank(unfydResponse.LOB)? unfydResponse.LOB : '';
            caseDetails.IsRegisteredCustomer__c=String.isNotBlank(unfydResponse.ISREGISTEREDCUSTOMER)? unfydResponse.ISREGISTEREDCUSTOMER : '';
            caseDetails.PayTmInteractionId__c=String.isNotBlank(unfydResponse.PAYTMINTERACTIONID)? unfydResponse.PAYTMINTERACTIONID : '';
            caseDetails.Priority__c=String.isNotBlank(unfydResponse.PRIORITY)? unfydResponse.PRIORITY : '';
            caseDetails.LAN__c=String.isNotBlank(unfydResponse.LAN)? unfydResponse.LAN : '';
            caseDetails.Moodstamp__c=String.isNotBlank(unfydResponse.MOODSTAMP)? unfydResponse.MOODSTAMP : '';
            caseDetails.Is_Potential_Complaint__c=(String.isNotBlank(unfydResponse.POTENTIALCOMPLAINT) && unfydResponse.POTENTIALCOMPLAINT == 'Yes') ? true : false;
            caseDetails.ConfidenceScore__c=Decimal.valueof(unfydResponse.CONFIDENCESCORE) != null ? Decimal.valueof(unfydResponse.CONFIDENCESCORE) : 0;
            caseDetails.IsTrailmail__c = (String.isNotBlank(unfydResponse.ISTRAILMAIL) && unfydResponse.ISTRAILMAIL == 'Yes') ? true : false;
            caseDetails.IsAttachmentFlag__c = (String.isNotBlank(unfydResponse.ISATTACHMENT) && unfydResponse.ISATTACHMENT == 'Yes') ? true : false;
            caseDetails.IsMultipleLAN__c = (String.isNotBlank(unfydResponse.ISMULTIPLELAN) && unfydResponse.ISMULTIPLELAN == 'Yes') ? true : false;
            caseDetails.Disposition__c=String.isNotBlank(unfydResponse.DISPOSITION)? unfydResponse.DISPOSITION : '';
            caseDetails.Comments__c=String.isNotBlank(unfydResponse.COMMENT)? unfydResponse.COMMENT : '';
            caseDetails.ABCOwner__c=String.isNotBlank(unfydResponse.OWNERFULLNAME)? unfydResponse.OWNERFULLNAME : '';
            caseDetails.Remarks__c=JSON.serialize(unfydResponse.REMARKS);
            //caseDetails.Remarks__c=(String)JSON.deserializeUntyped(unfydResponse.REMARKS);
            caseDetails.Case__c=caseId;
            if(Schema.sObjectType.ABFL_Case_Detail__c.isCreateable()) {
                insert caseDetails;
            }
            //AutoResponse Logic
            if(unfydResponse.AUTORESPONSE=='Yes'){
                sendEmailAndCaseUpdate(caseId,caseDetails.Id ,unfydResponse);
            }
            if(unfydResponse.AUTORESPONSE=='No'){
                publishUNFYDEmailEvent(caseId);
            }
            //Dedup Check
            if(String.isNotBlank(caseId) && caseCatConfig!= null){
                updateCase(caseId,unfydResponse,caseCatConfig);
            }
        }catch(exception ex){
            System.debug('Exception caught: ' + ex.getMessage());
        }
        
    }
    
    public static void updateCase(String caseId, ABFL_UNFYDWrapper unfydResponse,ASF_Case_Category_Config__c caseCatConfig){
        try{
            List<Case> parentCase= [SELECT Id,AccountId,Type_Text__c,Sub_Type_Text__c,Is_Duplicate__c,CaseNumber,ParentId from Case WHERE Type_Text__c=:caseCatConfig.Type__c AND Sub_Type_Text__c=:caseCatConfig.Sub_Type__c AND Status NOT IN ('Closed','Resolved','Closed Duplicate','Unresolved') AND LAN__c=:unfydResponse.LAN AND Source__c=:'Email' LIMIT 1];
            if(parentCase.size()>0 && unfydResponse.DEDUPE=='Yes'){
                Case caseUpdate = new Case();
                caseUpdate.Id = caseId;
                caseUpdate.ParentId= parentCase[0].Id;
                caseUpdate.CCC_External_Id__c=unfydResponse.ISSUECODE;
                caseUpdate.Nature__c=caseCatConfig.Nature__c;
                caseUpdate.LAN__c=String.isNotBlank(unfydResponse.LAN)? unfydResponse.LAN : '';
                caseUpdate.Client_Code_Text__c=String.isNotBlank(unfydResponse.CUSTOMERNO)? unfydResponse.CUSTOMERNO : '';
                //Update the status
                caseUpdate.Status='Closed Duplicate';
                Update caseUpdate;
                //Send email
            }else{
                Case caseUpdate = new Case();
                caseUpdate.Id = caseId;
                caseUpdate.CCC_External_Id__c=unfydResponse.ISSUECODE;
                caseUpdate.Nature__c=caseCatConfig.Nature__c;
                caseUpdate.LAN__c=String.isNotBlank(unfydResponse.LAN)? unfydResponse.LAN : '';
                caseUpdate.Client_Code_Text__c=String.isNotBlank(unfydResponse.CUSTOMERNO)? unfydResponse.CUSTOMERNO : '';
                Update caseUpdate;
            }
        }catch(exception ex){
            System.debug('Exception caught: ' + ex.getMessage());
        }
    }
    
    /****************************************************************************************************************
* @Function sendEmailAndCaseUpdate
* @param  caseId
* @param  caseDetailId
* @param  objResponseBody
* @description - Sends email and close the case according to flow mentioned on user story 
*****************************************************************************************************************/ 
    public static void sendEmailAndCaseUpdate(String caseId, String caseDetailId ,ABFL_UNFYDWrapper unfydResponse){
        if(String.isNotBlank(caseId) && String.isNotBlank(caseDetailId) && unfydResponse!=null ){
            ABFL_EBOT_Case_Email__mdt mdtEbotCase = ABFL_EBOT_Case_Email__mdt.getInstance('EBOT_Condition');
            List<case> recCase = [SELECT ID,AccountId,ContactId ,Business_Unit__c ,No_Auto_Communication__c , SuppliedEmail,CCC_External_Id__c ,Sub_Type_Text__c FROM CASE WHERE ID =:caseId WITH SYSTEM_MODE LIMIT 1 ];
            if(unfydResponse.ISSMT == 'YES'){
                sendSmtFlagYes(recCase[0],mdtEbotCase.SMT_Receiver_Address__c ); 
            }
            else if (unfydResponse.ISSMT == 'NO'){
                List<EmailMessage> emailMessages = [SELECT Id, ToAddress, Winning_Email__c FROM EmailMessage WHERE ParentId =: caseId WITH SYSTEM_MODE LIMIT 1];
                List<ASF_Case_Category_Config__c > cseCatConfig = [SELECT Id , EBOT_Auto_Close__c,EBOT_Auto_Response__c ,EBOT_Template__c ,EBOT_Registered_Template__c ,EBOT_Unregistered_Template__c , CCC_External_Id__c,Nature__c  FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c =: recCase[0].CCC_External_Id__c  WITH SYSTEM_MODE LIMIT 1];
                //IsPotentialComplaint
                if(checkIsPotentialCustomerYes(unfydResponse, mdtEbotCase)){
                    genericSendEmailAndCaseClose(cseCatConfig[0],recCase[0],false,caseDetailId,true,false,false,false,false,false,false,false,emailMessages);
                }
                /**Excluded Domain
else if(checkIsExcludedDomainYes(emailMessages[0],recCase[0],cseCatConfig[0], unfydResponse, mdtEbotCase)){
system.debug('multipleLead');
genericSendEmailAndCaseClose(cseCatConfig[0],recCase[0],false,caseDetailId,False,false,true,false,false,false,false,false,false,false,false,emailMessages);
}**/
                //ST=Lead
                else if(checkLeadSubtype(emailMessages[0],recCase[0],cseCatConfig[0],unfydResponse, mdtEbotCase)){
                    // system.debug('multipleLead');
                    genericSendEmailAndCaseClose(cseCatConfig[0],recCase[0],false,caseDetailId,false,true,false,false,false,false,false,false,emailMessages);
                }
                //IsMultiLAN
                else if(checkIsSmtAndMultipleLAN(emailMessages[0], recCase[0], cseCatConfig[0],unfydResponse, mdtEbotCase)){
                    //system.debug('multipleLAn');
                    genericSendEmailAndCaseClose(cseCatConfig[0],recCase[0],true,caseDetailId,false,false,true,false,false,false,false,false,emailMessages);
                }
                //ST=PAYTM
                else if(checkPaytmInteractionNull(emailMessages[0],recCase[0],cseCatConfig[0],unfydResponse, mdtEbotCase)){
                    //system.debug('paytmfired');
                    genericSendEmailAndCaseClose(cseCatConfig[0],recCase[0],true,caseDetailId,false,false,false,true,false,false,false,false,emailMessages);
                }
                //Is Register Customer
                else if(checkIsRegisteredCustomerNo(emailMessages[0], recCase[0],cseCatConfig[0], unfydResponse, mdtEbotCase)){
                    //system.debug('RegisteredCustomerNo');
                    genericSendEmailAndCaseClose(cseCatConfig[0],recCase[0],false,caseDetailId,false,false,false,false,false,false,false,false,emailMessages);
                }
                else if(checkIsRegisteredCustomerYes(emailMessages[0], recCase[0],cseCatConfig[0], unfydResponse, mdtEbotCase)){
                    //system.debug('RegisteredCustomeryes');
                    genericSendEmailAndCaseClose(cseCatConfig[0],recCase[0],false,caseDetailId,false,false,false,false,true,false,false,false,emailMessages);
                }
                //IsMulti Intent
                else if(checkIsMultipleIntentYes(unfydResponse, mdtEbotCase)){
                    genericSendEmailAndCaseClose(cseCatConfig[0],recCase[0],false,caseDetailId,false,false,false,false,false,true,false,false,emailMessages);
                }
                //IsAttachment
                else if(checkIsAttchmentYes(unfydResponse, mdtEbotCase)){
                    genericSendEmailAndCaseClose(cseCatConfig[0],recCase[0],false,caseDetailId,false,false,false,false,false,false,true,false,emailMessages);
                }
                /**
//IsTrailMail
else if(checkIsTrailMailYes(unfydResponse, mdtEbotCase)){
genericSendEmailAndCaseClose(cseCatConfig[0],recCase[0],false,caseDetailId,False,false,false,false,false,false,false,false,false,true,false,emailMessages);
}**/
                //Confidence score
                else if(confidenceScoreAndSubtypeCheck(emailMessages[0], recCase[0],cseCatConfig[0], unfydResponse, mdtEbotCase)){
                    //system.debug('ConfidenceScore');
                    genericSendEmailAndCaseClose(cseCatConfig[0],recCase[0],false,caseDetailId,false,false,false,false,false,false,false,true,emailMessages);
                }
            }
        }
        
    }
    
    /****************************************************************************************************************
* @Function sendSmtFlagYes
* @param  recCase
* @param  emailToAddress
* @description - Sends an email to contact if ISSMT response from ebot comes as YES
*****************************************************************************************************************/ 
    public static void sendSmtFlagYes(Case recCase,String emailToAddress){
        createPELogAndinvokeCommPEevent(recCase,'ABFL_SMT_Escalation_Template',emailToAddress);
    } 
    
    /****************************************************************************************************************
* @LOB - ABFL
* @param caseRec
* @param emailTemplate
* @param specificEmailId
* @Function - createPELogAndinvokeCommPEevent to send an email to specific email 
* @description - Function to create a PE_Logger__c record and invoke ASF_CommnunicationLog__e for email communication.
*****************************************************************************************************************/
    public static void createPELogAndinvokeCommPEevent(Case caseRec, String emailTemplate, String specificEmailId){
        PE_Logger__c peLogger = new PE_Logger__c();
        peLogger.AccountId__c = caseRec.AccountId;
        peLogger.CCCExternalId__c = caseRec.CCC_External_Id__c;
        peLogger.Case__c = caseRec.Id;
        peLogger.ContactId__c = caseRec.ContactId;
        peLogger.PE_Name__c = 'CommunicationLog';
        peLogger.RecordID__c = caseRec.Id;
        peLogger.Retry_PE__c = true;
        peLogger.Status__c = 'Pending';
        peLogger.LOB__c = 'ABFL';
        peLogger.Send_To_Specific_Emails__c = True;
        peLogger.No_Auto_Communication__c = caseRec.No_Auto_Communication__c;
        peLogger.Specific_To_Address__c = specificEmailId;
        peLogger.Email_Template_Name__c = emailTemplate;
        if(Schema.sObjectType.PE_Logger__c.isCreateable())
        {
            insert peLogger;    
        }
        Database.SaveResult eventResult = invokeCommunicationLogPlatformEvent(caseRec, peLogger);        
    }
    
    /****************************************************************************************************************
* @Function checkIsPotentialCustomerYes
* @param  objResponseBody
* @param  condition
* @return - Boolean .
* @description - Method is used to fetch the data from custommetadata and compare it with case and ASF_Case_Category_Config__c data for calling different scenarios mentioned on user story PR970457-132
*****************************************************************************************************************/
    public static Boolean checkIsPotentialCustomerYes(ABFL_UNFYDWrapper objResponseBody, ABFL_EBOT_Case_Email__mdt  condition) {
        return objResponseBody.POTENTIALCOMPLAINT != condition.ISPOTENTIALCOMPLAINT__c;
    }
    
    /****************************************************************************************************************
* @Function checkIsExcludedDomainYes
* @param  emailMessage
* @param  recCase
* @param  recCaseCatConfig
* @param  objResponseBody
* @param  condition
* @return - Boolean .
* @description - Method is used to fetch the data from custommetadata and compare it with case and ASF_Case_Category_Config__c data for calling different scenarios mentioned on user story PR970457-132
*****************************************************************************************************************/
    public static Boolean checkIsExcludedDomainYes(EmailMessage emailMessage, Case recCase,ASF_Case_Category_Config__c recCaseCatConfig, ABFL_UNFYDWrapper objResponseBody, ABFL_EBOT_Case_Email__mdt  condition) {
        List<String> allowedDomain = condition.ExcludedDomains__c.split(',');
        Boolean isExcludedDomain = false;
        for (String domain : allowedDomain) {
            if (recCase.SuppliedEmail.contains(domain.trim())) {
                isExcludedDomain = true;
                break;
            }
        }
        return isExcludedDomain;
    }
    
    /****************************************************************************************************************
* @Function checkLeadSubtype
* @param  objResponseBody
* @param  condition
* @return - Boolean .
* @description - Method is used to fetch the data from custommetadata and compare it with case and ASF_Case_Category_Config__c data for calling different scenarios mentioned on user story PR970457-132
*****************************************************************************************************************/
    public static Boolean checkLeadSubtype(EmailMessage emailMessage, Case recCase,ASF_Case_Category_Config__c recCaseCatConfig, ABFL_UNFYDWrapper objResponseBody, ABFL_EBOT_Case_Email__mdt  condition) {
        List<String> allowedDomain = condition.ExcludedDomains__c.split(',');
        List<String> allowedToAddress = condition.ToAddress__c.split(',');
        // system.debug('allowed domains '+ !allowedDomain.contains(recCase.SuppliedEmail));
        Boolean isExcludedDomain = false;
        Boolean isallowedToAddress = false;
        for (String toAdd : allowedToAddress) {
            if (emailMessage.Winning_Email__c != null && emailMessage.Winning_Email__c.contains(toAdd.trim() )) {
                isallowedToAddress = true;
                break;
            }
        }
        for (String domain : allowedDomain) {
            if (recCase.SuppliedEmail.contains(domain.trim())) {
                isExcludedDomain = true;
                break;
            }
        }
        return isallowedToAddress &&
            !isExcludedDomain &&
            objResponseBody.ISTRAILMAIL == condition.AUTOCLOSURE_IN_RR__c &&
            recCaseCatConfig.EBOT_Auto_Response__c == TRUE &&
            recCase.Sub_Type_Text__c == condition.Sub_Type_Text_Lead__c  &&
            recCase.Sub_Type_Text__c != condition.Sub_Type_Text_Paytm__c ;
        
    }
    
    /****************************************************************************************************************
* @Function checkIsSmtAndMultipleLAN
* @param  objResponseBody
* @param  condition
* @return - Boolean .
* @description - Method is used to fetch the data from custommetadata and compare it with case and ASF_Case_Category_Config__c data for calling different scenarios mentioned on user story PR970457-132
*****************************************************************************************************************/
    public static Boolean checkIsSmtAndMultipleLAN(EmailMessage emailMessage, Case recCase,ASF_Case_Category_Config__c recCaseCatConfig,ABFL_UNFYDWrapper objResponseBody, ABFL_EBOT_Case_Email__mdt  condition) {
        List<String> allowedDomain = condition.ExcludedDomains__c.split(',');
        List<String> allowedToAddress = condition.ToAddress__c.split(',');
        //system.debug('SuppliedEmail == '+ recCase.SuppliedEmail);
        Boolean isExcludedDomain = false;
        Boolean isallowedToAddress = false;
        for (String domain : allowedDomain) {
            if (recCase.SuppliedEmail.contains(domain.trim())) {
                isExcludedDomain = true;
                break;
            }
        }
        for (String toAdd : allowedToAddress) {
            if (emailMessage.Winning_Email__c != null && emailMessage.Winning_Email__c.contains(toAdd.trim() )) {
                isallowedToAddress = true;
                break;
            }
        }
        // system.debug('allowed domain '+ !recCase.SuppliedEmail.contains(condition.ExcludedDomains__c));
        return isallowedToAddress &&
            !isExcludedDomain &&
            objResponseBody.ISTRAILMAIL == condition.AUTOCLOSURE_IN_RR__c &&
            objResponseBody.ISATTACHMENT == condition.AUTOCLOSURE_IN_RR__c &&
            recCaseCatConfig.EBOT_Auto_Response__c == FALSE &&
            objResponseBody.ISMULTIPLELAN == condition.ISMULTIPLELAN__c;            
        
    }
    
    /****************************************************************************************************************
* @Function checkPaytmInteractionNotNull
* @param  objResponseBody
* @param  condition
* @return - Boolean .
* @description - Method is used to fetch the data from custommetadata and compare it with case and ASF_Case_Category_Config__c data for calling different scenarios mentioned on user story PR970457-132
*****************************************************************************************************************/
    public static Boolean checkPaytmInteractionNull(EmailMessage emailMessage, Case recCase,ASF_Case_Category_Config__c recCaseCatConfig,ABFL_UNFYDWrapper objResponseBody, ABFL_EBOT_Case_Email__mdt  condition) {
        List<String> allowedDomain = condition.ExcludedDomains__c.split(',');
        List<String> allowedToAddress = condition.ToAddress__c.split(',');
        //system.debug('allowed domain '+ !allowedDomain.contains(recCase.SuppliedEmail));
        Boolean isExcludedDomain = false;
        Boolean isallowedToAddress = false;
        for (String toAdd : allowedToAddress) {
            if (emailMessage.Winning_Email__c != null && emailMessage.Winning_Email__c.contains(toAdd.trim() )) {
                isallowedToAddress = true;
                break;
            }
        }
        for (String domain : allowedDomain) {
            if (recCase.SuppliedEmail.contains(domain.trim())) {
                isExcludedDomain = true;
                break;
            }
        }
        return isallowedToAddress &&
            !isExcludedDomain &&
            objResponseBody.ISTRAILMAIL == condition.AUTOCLOSURE_IN_RR__c &&
            recCaseCatConfig.EBOT_Auto_Response__c == TRUE &&
            recCase.Sub_Type_Text__c == condition.Sub_Type_Text_Paytm__c  &&
            objResponseBody.PAYTMINTERACTIONID == '';
    }
    
    /****************************************************************************************************************
* @Function checkIsRegisteredCustomerNo
* @param  recCaseCatConfig
* @param  objResponseBody
* @param  condition
* @return - Boolean .
* @description - Method is used to fetch the data from custommetadata and compare it with case and ASF_Case_Category_Config__c data for calling different scenarios mentioned on user story PR970457-132
*****************************************************************************************************************/
    public static Boolean checkIsRegisteredCustomerNo(EmailMessage emailMessage, Case recCase,ASF_Case_Category_Config__c recCaseCatConfig, ABFL_UNFYDWrapper objResponseBody, ABFL_EBOT_Case_Email__mdt  condition) {
        List<String> allowedDomain = condition.ExcludedDomains__c.split(',');
        List<String> allowedToAddress = condition.ToAddress__c.split(',');
        Boolean isExcludedDomain = false;
        Boolean isallowedToAddress = false;
        for (String toAdd : allowedToAddress) {
            if (emailMessage.Winning_Email__c != null && emailMessage.Winning_Email__c.contains(toAdd.trim() )) {
                isallowedToAddress = true;
                break;
            }
        }
        for (String domain : allowedDomain) {
            if (recCase.SuppliedEmail.contains(domain.trim())) {
                isExcludedDomain = true;
                break;
            }
        }
        return isallowedToAddress &&
            !isExcludedDomain &&
            objResponseBody.ISTRAILMAIL == condition.AUTOCLOSURE_IN_RR__c &&
            recCaseCatConfig.EBOT_Auto_Response__c == TRUE &&
            recCaseCatConfig.EBOT_Unregistered_Template__c != Null &&
            recCase.Sub_Type_Text__c != condition.Sub_Type_Text_Lead__c &&
            recCase.Sub_Type_Text__c != condition.Sub_Type_Text_Paytm__c &&
            objResponseBody.ISREGISTEREDCUSTOMER == condition.ISREGISTEREDCUSTOMER__c &&
            (recCaseCatConfig.Nature__c == 'Request' || recCaseCatConfig.Nature__c == 'Query');
    }
    
    /****************************************************************************************************************
* @Function checkIsRegisteredCustomerYes
* @param  recCaseCatConfig
* @param  objResponseBody
* @param  condition
* @return - Boolean .
* @description - Method is used to fetch the data from custommetadata and compare it with case and ASF_Case_Category_Config__c data for calling different scenarios mentioned on user story PR970457-132
*****************************************************************************************************************/
    public static Boolean checkIsRegisteredCustomerYes(EmailMessage emailMessage, Case recCase,ASF_Case_Category_Config__c recCaseCatConfig, ABFL_UNFYDWrapper objResponseBody, ABFL_EBOT_Case_Email__mdt  condition) {
        List<String> allowedSubtype = condition.Sub_Type_Text__c.split(',');
        List<String> allowedDomain = condition.ExcludedDomains__c.split(',');
        List<String> allowedToAddress = condition.ToAddress__c.split(',');
        Boolean isExcludedDomain = false;
        Boolean isallowedToAddress = false;
        for (String toAdd : allowedToAddress) {
            if (emailMessage.Winning_Email__c != null && emailMessage.Winning_Email__c.contains(toAdd.trim() )) {
                isallowedToAddress = true;
                break;
            }
        }
        for (String domain : allowedDomain) {
            if (recCase.SuppliedEmail.contains(domain.trim())) {
                isExcludedDomain = true;
                break;
            }
        }
        return isallowedToAddress &&
            !isExcludedDomain &&
            objResponseBody.ISTRAILMAIL == condition.AUTOCLOSURE_IN_RR__c &&
            recCaseCatConfig.EBOT_Auto_Response__c == TRUE &&
            recCase.Sub_Type_Text__c != condition.Sub_Type_Text_Lead__c &&
            recCase.Sub_Type_Text__c != condition.Sub_Type_Text_Paytm__c &&
            recCaseCatConfig.EBOT_Registered_Template__c != Null &&
            allowedSubtype.contains(recCase.Sub_Type_Text__c) &&
            objResponseBody.ISREGISTEREDCUSTOMER != condition.ISREGISTEREDCUSTOMER__c &&
            objResponseBody.ISATTACHMENT == condition.ISATTACHMENTFLAG__c &&
            String.valueOf(objResponseBody.CONFIDENCESCORE) >= condition.CONFIDENCESCORE__c &&
            (recCaseCatConfig.Nature__c == 'Request' || recCaseCatConfig.Nature__c == 'Query');
    }
    
    /****************************************************************************************************************
* @Function checkIsMultipleIntentYes
* @param  objResponseBody
* @param  condition
* @return - Boolean .
* @description - Method is used to fetch the data from custommetadata and compare it with case and ASF_Case_Category_Config__c data for calling different scenarios mentioned on user story PR970457-132
*****************************************************************************************************************/
    public static Boolean checkIsMultipleIntentYes(ABFL_UNFYDWrapper objResponseBody, ABFL_EBOT_Case_Email__mdt  condition) {
        return objResponseBody.ISMULTIPLEINTENT != condition.ISMULTIPLEINTENT__c;
    }
    
    /****************************************************************************************************************
* @Function checkIsAttchmentYes
* @param  objResponseBody
* @param  condition
* @return - Boolean .
* @description - Method is used to fetch the data from custommetadata and compare it with case and ASF_Case_Category_Config__c data for calling different scenarios mentioned on user story PR970457-132
*****************************************************************************************************************/
    public static Boolean checkIsAttchmentYes(ABFL_UNFYDWrapper objResponseBody, ABFL_EBOT_Case_Email__mdt  condition) {
        return objResponseBody.ISATTACHMENT != condition.ISATTACHMENTFLAG__c;
    }
    
    /****************************************************************************************************************
* @Function checkIsTrailMailYes
* @param  objResponseBody
* @param  condition
* @return - Boolean .
* @description - Method is used to fetch the data from custommetadata and compare it with case and ASF_Case_Category_Config__c data for calling different scenarios mentioned on user story PR970457-132
*****************************************************************************************************************/
    public static Boolean checkIsTrailMailYes(ABFL_UNFYDWrapper objResponseBody, ABFL_EBOT_Case_Email__mdt  condition) {
        return objResponseBody.ISTRAILMAIL == condition.AUTOCLOSURE_IN_RR__c;
    }
    
    /****************************************************************************************************************
* @Function - confidenceScoreAndSubtypeCheck
* @param  recCaseCatConfig
* @param  objResponseBody
* @param  condition
* @return  Boolean .
* @description - Method is used to fetch the data from custommetadata and compare it with case and ASF_Case_Category_Config__c data for calling different scenarios mentioned on user story PR970457-132
*****************************************************************************************************************/
    public static Boolean confidenceScoreAndSubtypeCheck(EmailMessage emailMessage, Case recCase,ASF_Case_Category_Config__c recCaseCatConfig, ABFL_UNFYDWrapper objResponseBody, ABFL_EBOT_Case_Email__mdt  condition) {
        List<String> allowedSubtype = condition.Sub_Type_Text__c.split(',');
        List<String> allowedDomain = condition.ExcludedDomains__c.split(',');
        List<String> allowedToAddress = condition.ToAddress__c.split(',');
        Boolean isExcludedDomain = false;
        Boolean isallowedToAddress = false;
        for (String toAdd : allowedToAddress) {
            if (emailMessage.Winning_Email__c != null && emailMessage.Winning_Email__c.contains(toAdd.trim() )) {
                isallowedToAddress = true;
                break;
            }
        }
        for (String domain : allowedDomain) {
            if (recCase.SuppliedEmail.contains(domain.trim())) {
                isExcludedDomain = true;
                break;
            }
        }
        return isallowedToAddress &&
            !isExcludedDomain &&
            objResponseBody.ISTRAILMAIL == condition.AUTOCLOSURE_IN_RR__c &&
            recCaseCatConfig.EBOT_Auto_Response__c == TRUE &&
            recCase.Sub_Type_Text__c != condition.Sub_Type_Text_Lead__c &&
            recCase.Sub_Type_Text__c != condition.Sub_Type_Text_Paytm__c &&
            recCaseCatConfig.EBOT_Registered_Template__c != Null &&
            !allowedSubtype.contains(recCase.Sub_Type_Text__c) &&  
            objResponseBody.ISREGISTEREDCUSTOMER != condition.ISREGISTEREDCUSTOMER__c &&
            objResponseBody.CONFIDENCESCORE >= condition.CONFIDENCESCORE__c ;
    }
    
    /****************************************************************************************************************
* @param caseCategConfig
* @param recCase
* @param closed
* @param abflCaseExtId
* @param templateName
* @param isRegistered
* @param isLead
* @param isPaytm
* @description - Sends an email to contact and closes the case according to the flow  mentioned on user story PR970457-132
*****************************************************************************************************************/
    public static void genericSendEmailAndCaseClose(ASF_Case_Category_Config__c caseCategConfig , Case recCase,Boolean closed,String abflCaseExtId,Boolean isPotentailComplaint,Boolean isLead,Boolean isMultiLAN,Boolean isPaytm,Boolean isRegistered,Boolean isMultiIntent,Boolean isAttachment,Boolean isConfidenceScore,List<EmailMessage> emailMessages){
        List<Case> lstUpdateCase = new List<Case>();
        List<ABFL_Case_Detail__c> lstUpdateCaseExt = new List<ABFL_Case_Detail__c>();
        List<ASF_Checklist__c> lstUpdateChecklist = new List<ASF_Checklist__c>();
        List<ABFL_Case_Detail__c> lstUpdateAbflExtension = new List<ABFL_Case_Detail__c>();
        List<Task> lstUpdateTask = new List<Task>();
        if(closed){
            // List<ABFL_Case_Detail__c> objABFL = [Select ID,Resolution_Comments__c,Resolved_Email_Sent__c FROM ABFL_Case_Detail__c WHERE Case__c =:recCase.Id  WITH SYSTEM_MODE LIMIT 1];
            ABFL_Case_Detail__c objUpdateCaseExt = new ABFL_Case_Detail__c();
            objUpdateCaseExt.Id = abflCaseExtId;
            objUpdateCaseExt.Resolution_Comments__c = 'Auto closed by EBOT';
            lstUpdateAbflExtension.add(objUpdateCaseExt);
            List<ASF_Checklist__c > objCheckList = [SELECT ID, Status__c ,Case__c from ASF_Checklist__c WHERE Case__c =:recCase.ID AND Status__c !='Completed' WITH SYSTEM_MODE];
            List<Task > objTask = [SELECT ID,Status,WhatId from Task WHERE WhatId =:recCase.ID AND Status !='Completed' WITH SYSTEM_MODE];
            if(!objCheckList.isEmpty()){
                for(ASF_Checklist__c checklist : objCheckList){
                    checklist.Status__c= 'Completed';
                    lstUpdateChecklist.add(checklist);   
                }
            }
            if(!objTask.isEmpty()){
                for(Task tsk : objTask){
                    tsk.Status= 'Completed';
                    lstUpdateTask.add(tsk);   
                }
            }
            Case objCase = new Case();
            objCase.Id = recCase.Id;
            objCase.OwnerId  = Userinfo.getuserId();
            objcase.typeSubTypeMismatch__c  = false;
            objcase.Type_Sub_Type_Mismatch_Reason__c = null;
            objCase.Stage__c = 'Resolved';
            lstUpdateCase.add(objCase);
            //system.debug('lstUpdateCaseasas '+lstUpdateCase);
            if(!lstUpdateAbflExtension.isEmpty()){
                Database.SaveResult[] updateResultAbflExt = Database.update(lstUpdateAbflExtension,false); 
            }
            if(!lstUpdateChecklist.isEmpty()){
                Database.SaveResult[] updateResultCheck = Database.update(lstUpdateChecklist,false); 
            }
            if(!lstUpdateTask.isEmpty()){
                Database.SaveResult[] updateResultTask = Database.update(lstUpdateTask,false); 
            }
            if(!lstUpdateCase.isEmpty()){
                Database.SaveResult[] updateResult = Database.update(lstUpdateCase,false); 
                if(updateResult[0].getId() != null){
                    //createPELoggerRecords(recCase,caseCategConfig);
                    //Calling the common PE logger class which creates PE logger record and fire platform even ASF_CommnunicationLog__e for sending an email.  
                    if(isMultiLAN){
                        ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(recCase,'ABFL_Multiple_Lan_Template',null,false);
                    }/**
else if(isLead){
ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(recCase,'ABFL_LEAD',null,false);
}**/
                    else if(isPaytm){
                        ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(recCase,'ABFL_PaytmAutorespon',null,false);
                    }/**
else if(!isRegistered){
ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(recCase,caseCategConfig.EBOT_Unregistered_Template__c ,null,false);

if(recCase.Business_Unit__c == 'ABFL'){
if(recCase.AccountId == null){
ABFL_WealthChatGeneratedCases.sendEmailWhenNotRegisteredCustomer(emailMessages,false);
}else{
ABFL_WealthChatGeneratedCases.sendEmailWhenNotRegisteredCustomer(emailMessages,true);
}

}

}
else if(isRegistered){
ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(recCase,caseCategConfig.EBOT_Registered_Template__c ,null,false);
}**/
                    
                }
            } 
        }
        else{
            ABFL_Case_Detail__c objUpdateCaseExt = new ABFL_Case_Detail__c();
            objUpdateCaseExt.Id = abflCaseExtId;
            //objUpdateCaseExt.Resolved_Email_Sent__c = TRUE;
            lstUpdateCaseExt.add(objUpdateCaseExt) ;
            if(!lstUpdateCaseExt.isEmpty()){
                Database.SaveResult[] updateResult = Database.update(lstUpdateCaseExt,false); 
                if(updateResult[0].getId() != null){
                    if(isRegistered){
                        ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(recCase,caseCategConfig.EBOT_Registered_Template__c,null,false);
                    }
                    else if(!isRegistered){
                        ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(recCase,caseCategConfig.EBOT_Unregistered_Template__c,null,false);
                    }
                    /**else if(isMultiIntent){
                        ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(recCase,caseCategConfig.EBOT_Unregistered_Template__c,null,false);
                	}
                    else if(isAttachment){
                        ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(recCase,caseCategConfig.EBOT_Unregistered_Template__c,null,false);
                    }
                    else if(isTrailMail){
                        ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(recCase,caseCategConfig.EBOT_Unregistered_Template__c,null,false);
                    }
                    else if(isConfidenceScore){
						ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(recCase,caseCategConfig.EBOT_Unregistered_Template__c,null,false);
                    }**/
                }
            }
        }   
        
    }
    
    /****************************************************************************************************************
* @LOB - ABFL
* @Function - invokeCommunicationLogPlatformEvent
* @param caseRec - Case record.
* @param peLogger - PE_Logger__c record.
* @return - Database.SaveResult.
* @description - Function to publish ASF_CommnunicationLog__e platform event.
*****************************************************************************************************************/
    private static Database.SaveResult invokeCommunicationLogPlatformEvent(Case caseRec, PE_Logger__c peLogger){
        ASF_CommnunicationLog__e commEvent = new ASF_CommnunicationLog__e();
        commEvent.CCCExternalId__c = caseRec.CCC_External_Id__c;
        //system.debug('entered here--');
        commEvent.PELoggerId__c = peLogger.Id;
        commEvent.RecordID__c = caseRec.Id;
        //DateTime dt = DateTime.now();
        commEvent.Unique_Id__c = 'CommunicationLog-'+UserInfo.getUserId()+'-'+System.currentTimeMillis();
        Database.SaveResult eventResult = EventBus.publish(commEvent);
        // system.debug('eventResult--- '+eventResult );
        return eventResult;
    }
    
    /****************************************************************************************************************
* @LOB - ABFL
* @Function - createExtUNFYDEvent
* @param caseId - Case record.
* @description - Function to publish EMAIL RESPONSE REQUEST platform event.
*****************************************************************************************************************/
    public static void publishUNFYDEmailEvent(String caseId){
        Map<String, String> fieldsMap = New Map<String, String>();
        Case caseRecord=[Select Id,CaseNumber,Type_Text__c,Sub_Type_Text__c,Nature__c,eBOT_Email_Draft__c FROM Case where Id=:caseId LIMIT 1];
        ABFL_Case_Detail__c caseDetails=[Select Id,Ebot_Feedback__c,Case__c From ABFL_Case_Detail__c where Case__r.Id =:caseRecord.Id LIMIT 1];
        if(caseRecord!= null && caseDetails!=null){
            
            //Insert ASF_Case_Integration__c
            ASF_Case_Integration__c caseInt = new ASF_Case_Integration__c();    
            caseInt.Case__c = caseRecord.Id;
            caseInt.Status__c = 'Pending';
            caseInt.Type__c = 'EMAILRESPONSE';
            
            if(Schema.sObjectType.ASF_Case_Integration__c.isCreateable()){
                insert caseInt;
            }
            
            fieldsMap.put('Case_Number__c',caseRecord.CaseNumber);
            fieldsMap.put('Case_Integration_ID__c',caseInt.Name);
            
            //Publish the platform event
            Database.SaveResult eventResult = ABHFL_CasePlatformEventHandler.publishPlatformEvent('CRM_to_UNFYD_Email_Event__e', fieldsMap);
        }
        
    }
    
    /****************************************************************************************************************
* @LOB - ABFL
* @Function - createExtUNFYDEvent
* @param caseId - Case record.
* @description - Function to publish EMAIL RESPONSE REQUEST platform event.
*****************************************************************************************************************/
    public static void unfydEmailResponseHandler(String caseId, ABFL_UNFYDEmailWrapper unfydResponse){
        Case caseRecord = [Select id, eBOT_Email_Draft_initial__c from case where id = :caseId];
        caseRecord.eBOT_Email_Draft_initial__c = unfydResponse.response;
        update caseRecord;
    }
}