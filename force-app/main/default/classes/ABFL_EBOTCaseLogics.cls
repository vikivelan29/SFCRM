/*********************************************************
*Class        :  ABFL_EBOTCaseLogics
*Author       :  Shubham Sinha 
*Created Date :  19/12/2023
*Last Modified:  19/12/2023
*@description  :  ABFL_EBOTCaseLogics updates case and Case details field and ebot flow logic related to story no PR970457-132 
*********************************************************/
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.ExcessiveParameterList,PMD.NcssMethodCount,PMD.StdCyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts')
public with sharing class ABFL_EBOTCaseLogics {
    /****************************************************************************************************************
    * @param  caseId
    * @param  objResponseBody
    * @description - Updates the fields of ABFL Case Detail and Case object.
    *****************************************************************************************************************/ 
    public static void updateCaseDetailExtension(String caseId ,ABFL_EbotWrapper.EbotResponseWrapper objResponseBody){
       // try {
            List<ABFL_Case_Detail__c > lstInsertAbflCaseDetail = new List<ABFL_Case_Detail__c>();
            String insertedId;
            if(String.isNotBlank(caseId) && objResponseBody!=null ){
                ABFL_Case_Detail__c objABFL = new ABFL_Case_Detail__c();
                objABFL.Case__c = caseId; 
                objABFL.ConfidenceScore__c = objResponseBody.CONFIDENCESCORE==''?0:Decimal.valueOf(objResponseBody.CONFIDENCESCORE);
                objABFL.Autoclosure_IN_RR__c = objResponseBody.AUTOCLOSURE_IN_RR == 'NO' ? FALSE : TRUE;
                objABFL.IsRegisteredCustomer__c = objResponseBody.ISREGISTEREDCUSTOMER;
                objABFL.Moodstamp__c = objResponseBody.MOODSTAMP != null ? objResponseBody.MOODSTAMP : '';
                objABFL.Priority__c = objResponseBody.PRIORITY != null ? objResponseBody.PRIORITY : '';
                objABFL.IsSMT__c = objResponseBody.ISSMT == 'NO' ? FALSE : TRUE;
                objABFL.IsMultipleLAN__c = objResponseBody.ISMULTIPLELAN == 'NO' ? FALSE : TRUE;
                objABFL.IsAttachmentFlag__c = objResponseBody.ISATTACHMENTFLAG == 'NO' ? FALSE : TRUE;
                objABFL.PayTmInteractionId__c = objResponseBody.PAYTMINTERACTIONID != null ? objResponseBody.PAYTMINTERACTIONID : '';
                objABFL.Disposition__c = objResponseBody.DISPOSITION != null ? objResponseBody.DISPOSITION : '';

                // objABFL.CustomerNo__c = objResponseBody.CUSTOMERNO != null ? objResponseBody.CUSTOMERNO : '';
                lstInsertAbflCaseDetail.add(objABFL);
            }  
              if(lstInsertAbflCaseDetail.size() > 0){
                    Database.SaveResult[] updateResult = Database.insert(lstInsertAbflCaseDetail,false); 
                    for (Database.SaveResult sr : updateResult) {
                    if (sr.isSuccess()) {
                        insertedId = sr.getId();
                    }
                  }
                  updateCase(caseId,insertedId,objResponseBody);
              }
            
       // }catch (Exception e) {
        //    System.debug('Execption :'+ e.getMessage() + e.getStackTraceString());
       // }
    }
    /****************************************************************************************************************
    * @param   caseId 
   * @param   caseDetailId 
   * @param   objResponseBody
    * @description - Updates the fields of  Case object according to ebot response.
    *****************************************************************************************************************/ 
    public static void updateCase(String caseId, String caseDetailId ,ABFL_EbotWrapper.EbotResponseWrapper objResponseBody){
        List<Case>lstCase = new List<Case>();
        if(String.isNotBlank(caseId) && String.isNotBlank(caseDetailId) && objResponseBody!=null ){
            LIST<Asset> recAsset;
            if(String.isNotBlank(objResponseBody.LAN)){
                recAsset = [SELECT ID,LAN__c  FROM ASSET WHERE LAN__c =:objResponseBody.LAN WITH SYSTEM_MODE LIMIT 1];
            }
           Case objCase = new Case();
           //Case objCase = [SELECT ID FROM CASE WHERE ID =: caseId  LIMIT 1 FOR UPDATE];
            objCase.Id = caseId;
            objCase.ABFL_Case_Detail__c = caseDetailId;
            objCase.CCC_External_Id__c = objResponseBody.CASESUBTYPE;
            objCase.Comments = objResponseBody.COMMENT;
            objCase.Sent_to_EBOT__c  = TRUE;
            objCase.Case_Stage_Change_Date__c = system.now();
            objCase.LAN__c =  String.isNotBlank(objResponseBody.LAN)? objResponseBody.LAN : '';
            objCase.Client_Code_Text__c = objResponseBody.CUSTOMERNO != null ? objResponseBody.CUSTOMERNO : '';
            if(recAsset!=null && recAsset.size()>0){
                objCase.AssetId = recAsset[0].Id;
            }
            objCase.RecordTypeId = ASF_Constants.RT_FRAMEWORK;
            lstCase.add(objCase);
        }
         if(!lstCase.isEmpty()){
           Database.SaveResult[] updateResult = Database.update(lstCase,false); 
            //System.debug('updateResultCase'+ updateResult[0].getId());      
            //System.debug('updateResultCaseerrr'+updateResult[0].getErrors()); 
             if(updateResult[0].getId() != null){
               sendEmailAndCaseUpdate(caseId,caseDetailId,objResponseBody);     
             }
        }
    }
    /****************************************************************************************************************
    * @param  caseId
    * @param  caseDetailId
    * @param  objResponseBody
    * @description - Sends email and close the case according to flow mentioned on user story PR970457-132
    *****************************************************************************************************************/ 
    public static void sendEmailAndCaseUpdate(String caseId, String caseDetailId ,ABFL_EbotWrapper.EbotResponseWrapper objResponseBody){
        if(String.isNotBlank(caseId) && String.isNotBlank(caseDetailId) && objResponseBody!=null ){
            ABFL_EBOT_Case_Email__mdt mdtEbotCase = ABFL_EBOT_Case_Email__mdt.getInstance('EBOT_Condition'); 
            List<case> recCase = [SELECT ID,AccountId,ContactId ,Business_Unit__c ,No_Auto_Communication__c , SuppliedEmail,CCC_External_Id__c ,Sub_Type_Text__c FROM CASE WHERE ID =:caseId WITH SYSTEM_MODE LIMIT 1 ];
            if(objResponseBody.ISSMT == 'YES'){
                sendSmtFlagYes(recCase[0],mdtEbotCase.SMT_Receiver_Address__c ); 
            }
            else if (objResponseBody.ISSMT == 'NO'){
                List<EmailMessage> emailMessages = [SELECT Id, ToAddress, Winning_Email__c, Incoming, ParentId, Headers, ReplyToEmailMessageId FROM EmailMessage WHERE ParentId =: caseId WITH SYSTEM_MODE LIMIT 1];
                List<ASF_Case_Category_Config__c > cseCatConfig = [SELECT Id , EBOT_Auto_Close__c,EBOT_Auto_Response__c ,EBOT_Template__c ,EBOT_Registered_Template__c ,EBOT_Unregistered_Template__c , CCC_External_Id__c  FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c =: recCase[0].CCC_External_Id__c  WITH SYSTEM_MODE LIMIT 1];
                //system.debug('emailMessagesfound '+ emailMessages);
                //system.debug('cseCatConfigfound '+ cseCatConfig);
                if(checkIsSmtAndMultipleLAN(emailMessages[0], recCase[0], cseCatConfig[0],objResponseBody, mdtEbotCase)){
                    //system.debug('multipleLAn');
                    genericSendEmailAndCaseClose(cseCatConfig[0],recCase[0],true,caseDetailId,True,false,false,false,emailMessages);
                }
                else if(checkPaytmInteractionNotNull(emailMessages[0],recCase[0],cseCatConfig[0], objResponseBody, mdtEbotCase)){
                    //system.debug('paytmfired');
                    genericSendEmailAndCaseClose(cseCatConfig[0],recCase[0],true,caseDetailId,False,false,false,true,emailMessages);
                }
                else if(checkLeadSubtype(emailMessages[0],recCase[0],cseCatConfig[0], objResponseBody, mdtEbotCase)){
                   // system.debug('multipleLead');
                    genericSendEmailAndCaseClose(cseCatConfig[0],recCase[0],false,caseDetailId,False,false,true,false,emailMessages);
                }
                else if(checkIsRegisteredCustomerNo(emailMessages[0], recCase[0],cseCatConfig[0], objResponseBody, mdtEbotCase)){
                    //system.debug('RegisteredCustomerNo');
                    genericSendEmailAndCaseClose(cseCatConfig[0],recCase[0],true,caseDetailId,False,false,false,false,emailMessages);
                }
                 else if(checkIsRegisteredCustomerYes(emailMessages[0], recCase[0],cseCatConfig[0], objResponseBody, mdtEbotCase)){
                    //system.debug('RegisteredCustomeryes');
                    genericSendEmailAndCaseClose(cseCatConfig[0],recCase[0],true,caseDetailId,False,true,false,false,emailMessages);
                }
                else if(ConfidenceScoreAndSubtypeCheck(emailMessages[0], recCase[0],cseCatConfig[0], objResponseBody, mdtEbotCase)){
                    //system.debug('ConfidenceScore');
                    genericSendEmailAndCaseClose(cseCatConfig[0],recCase[0],true,caseDetailId,False,true,false,false,emailMessages);
                }
            }
        }

    }
    /****************************************************************************************************************
    * @param  recCase
    * @param  emailToAddress
    * @description - Sends an email to contact if ISSMT response from ebot comes as YES
    *****************************************************************************************************************/ 
    public static void sendSmtFlagYes(Case recCase,String emailToAddress){
        createPELogAndinvokeCommPEevent(recCase,'ABFL_SMT_Escalation_Template',emailToAddress);
    }  
    /****************************************************************************************************************
    * @param caseCategConfig
    * @param recCase
    * @param closed
    * @param abflCaseExtId
    *  @param templateName
    * @param isRegistered
    * @param isLead
    * @param isPaytm
    * @description - Sends an email to contact and closes the case according to the flow  mentioned on user story PR970457-132
    *****************************************************************************************************************/
       public static void genericSendEmailAndCaseClose(ASF_Case_Category_Config__c caseCategConfig , Case recCase,Boolean closed, String abflCaseExtId,Boolean templateName,Boolean isRegistered,Boolean isLead,Boolean isPaytm, List<EmailMessage> emailMessages){
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
                     if(templateName){
                        ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(recCase,'ABFL_Multiple_Lan_Template',null,false);
                     }
                      else if(isLead){
                        ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(recCase,'ABFL_LEAD',null,false);
                     }
                      else if(isPaytm){
                        ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(recCase,'ABFL_PaytmAutorespon',null,false);
                     }
                     else if(!isRegistered){
                         if(recCase.Business_Unit__c != 'ABFL'){
                         	ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(recCase,caseCategConfig.EBOT_Unregistered_Template__c ,null,false);    
                         }
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
                     }
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
                     }
                }
           }   
     }
      /****************************************************************************************************************
    * @param  emailMessage
    * @param  recCase
    * @param  recCaseCatConfig
    * @param  objResponseBody
    * @param  condition
    * @return - Boolean .
    * @description - Method is used to fetch the data from custommetadata and compare it with case and ASF_Case_Category_Config__c data for calling different scenarios mentioned on user story PR970457-132
    *****************************************************************************************************************/
        public static Boolean checkIsSmtAndMultipleLAN(EmailMessage emailMessage, Case recCase,ASF_Case_Category_Config__c recCaseCatConfig, ABFL_EbotWrapper.EbotResponseWrapper objResponseBody, ABFL_EBOT_Case_Email__mdt  condition) {
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
               objResponseBody.AUTOCLOSURE_IN_RR == condition.AUTOCLOSURE_IN_RR__c &&
               recCaseCatConfig.EBOT_Auto_Response__c == FALSE &&
               objResponseBody.ISMULTIPLELAN == condition.ISMULTIPLELAN__c;            
        }
      /****************************************************************************************************************
   * @param  emailMessage
    * @param  recCase
    * @param  recCaseCatConfig
    * @param  objResponseBody
    * @param  condition
    * @return - Boolean .
    * @description - Method is used to fetch the data from custommetadata and compare it with case and ASF_Case_Category_Config__c data for calling different scenarios mentioned on user story PR970457-132
    *****************************************************************************************************************/
        public static Boolean checkPaytmInteractionNotNull(EmailMessage emailMessage, Case recCase,ASF_Case_Category_Config__c recCaseCatConfig, ABFL_EbotWrapper.EbotResponseWrapper objResponseBody, ABFL_EBOT_Case_Email__mdt  condition) {
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
               objResponseBody.AUTOCLOSURE_IN_RR == condition.AUTOCLOSURE_IN_RR__c &&
               recCaseCatConfig.EBOT_Auto_Response__c == TRUE &&
               recCase.Sub_Type_Text__c == condition.Sub_Type_Text_Paytm__c  &&
               objResponseBody.PAYTMINTERACTIONID == '';            
        }
      /****************************************************************************************************************
   * @param  emailMessage
    * @param  recCase
    * @param  recCaseCatConfig
    * @param  objResponseBody
    * @param  condition
    * @return - Boolean .
    * @description - Method is used to fetch the data from custommetadata and compare it with case and ASF_Case_Category_Config__c data for calling different scenarios mentioned on user story PR970457-132
    *****************************************************************************************************************/
        public static Boolean checkLeadSubtype(EmailMessage emailMessage, Case recCase,ASF_Case_Category_Config__c recCaseCatConfig, ABFL_EbotWrapper.EbotResponseWrapper objResponseBody, ABFL_EBOT_Case_Email__mdt  condition) {
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
               //!condition.ExcludedDomains__c.split(';').contains(recCase.SuppliedEmail) &&
               !isExcludedDomain &&
               objResponseBody.AUTOCLOSURE_IN_RR == condition.AUTOCLOSURE_IN_RR__c &&
               recCaseCatConfig.EBOT_Auto_Response__c == TRUE &&
               recCase.Sub_Type_Text__c == condition.Sub_Type_Text_Lead__c  &&
               recCase.Sub_Type_Text__c != condition.Sub_Type_Text_Paytm__c ;

        }
      /****************************************************************************************************************
   * @param  emailMessage
    * @param  recCase
    * @param  recCaseCatConfig
    * @param  objResponseBody
    * @param  condition
    * @return - Boolean .
    * @description - Method is used to fetch the data from custommetadata and compare it with case and ASF_Case_Category_Config__c data for calling different scenarios mentioned on user story PR970457-132
    *****************************************************************************************************************/
        public static Boolean checkIsRegisteredCustomerNo(EmailMessage emailMessage, Case recCase,ASF_Case_Category_Config__c recCaseCatConfig, ABFL_EbotWrapper.EbotResponseWrapper objResponseBody, ABFL_EBOT_Case_Email__mdt  condition) {
            //List<String> allowedSubtype = condition.Sub_Type_Text__c.split(',');
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
                objResponseBody.AUTOCLOSURE_IN_RR == condition.AUTOCLOSURE_IN_RR__c &&
                recCaseCatConfig.EBOT_Auto_Response__c == TRUE &&
                recCaseCatConfig.EBOT_Unregistered_Template__c != Null &&
                recCase.Sub_Type_Text__c != condition.Sub_Type_Text_Lead__c &&
                recCase.Sub_Type_Text__c != condition.Sub_Type_Text_Paytm__c &&
                objResponseBody.ISREGISTEREDCUSTOMER == condition.ISREGISTEREDCUSTOMER__c ;
        }
      /****************************************************************************************************************
    * @param  emailMessage
    * @param  recCase
    * @param  recCaseCatConfig
    * @param  objResponseBody
    * @param  condition
    * @return - Boolean .
    * @description - Method is used to fetch the data from custommetadata and compare it with case and ASF_Case_Category_Config__c data for calling different scenarios mentioned on user story PR970457-132
    *****************************************************************************************************************/
        public static Boolean checkIsRegisteredCustomerYes(EmailMessage emailMessage, Case recCase,ASF_Case_Category_Config__c recCaseCatConfig, ABFL_EbotWrapper.EbotResponseWrapper objResponseBody, ABFL_EBOT_Case_Email__mdt  condition) {
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
               objResponseBody.AUTOCLOSURE_IN_RR == condition.AUTOCLOSURE_IN_RR__c &&
               recCaseCatConfig.EBOT_Auto_Response__c == TRUE &&
               recCase.Sub_Type_Text__c != condition.Sub_Type_Text_Lead__c &&
               recCase.Sub_Type_Text__c != condition.Sub_Type_Text_Paytm__c &&
               recCaseCatConfig.EBOT_Registered_Template__c != Null &&
               allowedSubtype.contains(recCase.Sub_Type_Text__c) &&
               objResponseBody.ISREGISTEREDCUSTOMER != condition.ISREGISTEREDCUSTOMER__c &&
               objResponseBody.ISATTACHMENTFLAG == condition.ISATTACHMENTFLAG__c &&
               objResponseBody.CONFIDENCESCORE >= condition.CONFIDENCESCORE__c ;
        }
      /****************************************************************************************************************
    * @Function - confidenceScoreAndSubtypeCheck
    * @param emailMessage
    * @param recCase
    * @param  recCaseCatConfig
    * @param  objResponseBody
    * @param  condition
    * @return  Boolean .
    * @description - Method is used to fetch the data from custommetadata and compare it with case and ASF_Case_Category_Config__c data for calling different scenarios mentioned on user story PR970457-132
    *****************************************************************************************************************/
        public static Boolean confidenceScoreAndSubtypeCheck(EmailMessage emailMessage, Case recCase,ASF_Case_Category_Config__c recCaseCatConfig, ABFL_EbotWrapper.EbotResponseWrapper objResponseBody, ABFL_EBOT_Case_Email__mdt  condition) {
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
               objResponseBody.AUTOCLOSURE_IN_RR == condition.AUTOCLOSURE_IN_RR__c &&
               recCaseCatConfig.EBOT_Auto_Response__c == TRUE &&
               recCase.Sub_Type_Text__c != condition.Sub_Type_Text_Lead__c &&
               recCase.Sub_Type_Text__c != condition.Sub_Type_Text_Paytm__c &&
               recCaseCatConfig.EBOT_Registered_Template__c != Null &&
               !allowedSubtype.contains(recCase.Sub_Type_Text__c) &&  
               objResponseBody.ISREGISTEREDCUSTOMER != condition.ISREGISTEREDCUSTOMER__c &&
               objResponseBody.CONFIDENCESCORE >= condition.CONFIDENCESCORE__c ;
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
        //Set<Id> peIds = new Set<Id>();
        //peIds.add(peLogger.Id);
        //List<PE_Logger__c> peLoggerList = ASF_CommPETriggerQueryHandler.getPELoggerRecords(peIds,'Completed');
        //ASF_CommPETriggerHelper.executeContructor(peLoggerList);
        //Database.SaveResult platformEventResult = ABCL_IntegrationCommonUtility.createPELogAndinvokeCommPEevent(caseRecord, cccRecord[0].Resolved_Case_Email_Template__c, null, isTransferred);
        Database.SaveResult eventResult = invokeCommunicationLogPlatformEvent(caseRec, peLogger);        


        
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
}
