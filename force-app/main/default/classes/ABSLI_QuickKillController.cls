/**
* @description       : 
* @author            : Virendra Patil
* @group             : 
* @last modified on  : 26-05-2024
* @last modified by  : Laxman
* Modifications Log
* Ver   Date         Author                       Modification
* 1.0   01-17-2024   Virendra Patil   Initial Version
**/

public with sharing class ABSLI_QuickKillController {
    
    /* THIS METHOD IS USED TO DELETE THE RECORD, WHEN SOMEONE PROCESS THE DYNAMINC LINK AND JUST BEFORE CLICKING ON SEND
CLICKING ON CANCEL BUTTON. THAT MEANS NOT ACTUALLY SENDING THE MESSAGE BUT CANCELLING IT.
*/
    @AuraEnabled (cacheable = false)
    public static boolean deleteDraftLogs(String commLogId){
        if(commLogId != null && commLogId != ''){
            Id cLogId = Id.valueOf(commLogId);
            ASF_Communication_Log__c cLog = new ASF_Communication_Log__c(Id=cLogId);
            try{
                delete cLog;
            }
            catch(exception ex){
                return false;
            }
            return true;
        }
        return true;
    }
    
    /* THIS METHOD IS USED TO GET THE POLICY TABLES COLUMNS FOR QUICK LINKS. 
* IN CASE OF MULTIPLE POLICIES, SERVICE AGENT IS SUPPOSED TO SELECT THE POLICY FIRST AND THEN PROCEED WITH
* FUNCTION SELECTION.
*/
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getPolicyColumns() {
        List<Map<String, String>> columns = new List<Map<String, String>>();
        // Fetching custom label value
        String columnMetadata = System.Label.ABSLI_Policy_Search_Columns;
        if (String.isNotBlank(columnMetadata)) {
            String[] columnLabels = columnMetadata.split(';'); // Splitting columns and labels
            for (String columnLabel : columnLabels) {
                String[] columnData = columnLabel.split(':'); // Splitting label and API name
                if (columnData.size() == 2) {
                    Map<String, String> columnMap = new Map<String, String>();
                    columnMap.put('label', columnData[0].trim()); // Label
                    columnMap.put('fieldName', columnData[1].trim()); // API Name
                    columnMap.put('type', 'text'); // Assuming type is text, you can adjust as per your requirement
                    columns.add(columnMap);
                }	
            }
        }
        System.debug(columns);
        return columns;
    }
    
    
    /* THIS METHOD IS USED TO GET THE POLICY RECORDS FOR QUICK LINKS. 
* IN CASE OF MULTIPLE POLICIES, SERVICE AGENT IS SUPPOSED TO SELECT THE POLICY FIRST AND THEN PROCEED WITH
* FUNCTION SELECTION.
*/
    @AuraEnabled(cacheable=true)
    public static List<Asset> getAllRelatedAssets(Id recordId) {
        // Fetch policy columns from custom label
        List<Map<String, String>> columns = getPolicyColumns();
        List<String> columnAPINames = new List<String>();
        for (Map<String, String> column : columns) {
            columnAPINames.add(column.get('fieldName'));
        }
        
        // Construct SOQL query dynamically
        String query = 'SELECT ';
        query += String.join(columnAPINames, ', ') + ' FROM Asset WHERE AccountId = :recordId';
        System.debug(Database.query(query));
        return Database.query(query);
    }
    
    
    /* THIS METHOD IS USED TO GENERATE THE POLICY LINK. 
* IT TAKES FUNCTION NAME LIKE ADDRUP, ACCOUNTID AND POLICYID
* THEN FIRST CREATE A COMMUNICATION LOG RECORD, CALLS THE ENCRYPTION URL BASED ON ASE256 ALGORITHM.
* THIS ENCRYPTION URL IS STORE IN COMMUNICATION LOG TINY URL FIELD.
* CREATED COMMUNICATION LOG RECORD ID IS SENT AS A RESPONSE OF THIS METHOD TO LWC COMPONENT.
*/
    @AuraEnabled
    public static String generateLink(string functionName,String accountId,String policyId){
        String CRMReportID = '';// COMM LOG RECORD ID
        String clientId = ''; // COMMON CLIENT CODE ID
        String PolicyNo = ''; // Policy Number from Asset.
        String functionCode = functionName;
        String timeStamp = '';
        //"CRMReportID=" + CRMReportID + "&ClientID=" + Client_Code + "&PolicyNumber=" + PolicyNo + "&FunctionCode=" + FunctionCode + "&Source=" + source + "&TimeStamp=" + timestamp + "";
        Account selectedCustomer = getCustomerDetails(accountId);
        Asset selectedPolicy = getPolicyDetails(policyId);
        
        if(selectedCustomer != null){
            clientId = selectedCustomer.Client_Code__c;
        }
        if(selectedPolicy != null){
            PolicyNo = selectedPolicy.Name;
        }
        System.debug('clientId --> '+clientId);
        System.debug('PolicyNo --> '+PolicyNo);        
        String retVal = createCommunicationLogRecord(selectedCustomer,selectedPolicy,functionName);
        return retVal;
        
    }
    private static Account getCustomerDetails(String accountId){
        return [SELECT ID,Client_Code__c FROM Account WHERE Id =: accountId];
    }
    private static Asset getPolicyDetails(String policyId){
        return [SELECT ID,Name,Plan_Name__c FROM Asset WHERE Id =: policyId];
    }
    
    /* THIS METHOD IS USE FOR CREATING THE COMMUNICATION LOG RECORD. 
* CALLED FROM METHOD - generateLink
*/
    private static String createCommunicationLogRecord(Account selectedCustomer, Asset selectedPolicy,String funcCode){
        ASF_Quick_Link_Config__mdt qkCommMdt = [SELECT ID, FunctionName__c ,FunctionCode__c,SMSMetadataName__c 
                                                FROM ASF_Quick_Link_Config__mdt WHERE FunctionCode__c =: funcCode];
        
        Contact c = [SELECT ID,MobilePhone,Name,Salutation,Full_Name__c FROM Contact WHERE AccountId = : selectedCustomer.Id LIMIT 1];
        Customer_Notification_Config__mdt commMdt= [SELECT ID,SMS_Entity_Id__c,
                                                    SMS_Sender_Id__c,SMS_Template_Name__c,external_templateID__c,
                                                    Email_Template_Name__c 
                                                    FROM Customer_Notification_Config__mdt 
                                                    WHERE DeveloperName=: qkCommMdt.SMSMetadataName__c ];
        if(c.MobilePhone != null && c.MobilePhone != ''){
            List<ASF_Communication_Log__c> masterLogs = new List<ASF_Communication_Log__c>();
            
            ASF_Communication_Log__c cLog = new ASF_Communication_Log__c();
            cLog.Account__c = selectedCustomer.Id;
            cLog.Contact__c = c.Id;
            cLog.Contact_Name__c = (c.Salutation != null ? c.Salutation : '') + c.Full_Name__c;
            cLog.SMS_Entity_Id__c = commMdt.SMS_Entity_Id__c;
            cLog.SMS_Sender_Id__c = commMdt.SMS_Sender_Id__c;
            cLog.SMS_LT_Name__c = commMdt.SMS_Template_Name__c;
            cLog.External_Template_ID__c = commMdt.external_templateID__c;
            cLog.Status__c = ABSLI_Constants.COMM_LOG_DEFAULT_STATUS;
            cLog.Function_Name__c = qkCommMdt.FunctionName__c;
            cLog.Loan_Type__c = selectedPolicy.Plan_Name__c;
            cLog.Policy_No__c = selectedPolicy.Name;
            cLog.LOB__c = ABSLI_Constants.BUSINESS_UNIT;
            cLog.Phone__c = c.MobilePhone;
            cLog.Email_template_Name__c = commMdt.Email_Template_Name__c;
            insert cLog;
            
            //String templateBody = getTemplateBody(cLog.Id);
            String encryptedURL = getEncryptedURL(cLog.Id,selectedCustomer.Client_Code__c,selectedPolicy.Name,funcCode,'4170703839');
            cLog.Encrypted_URL__c = encryptedURL;
            update cLog;
            System.debug(encryptedURL);
            return cLog.Id;
            
        }
        else{
            throw new AuraException('Trying to send SMS to Customer without mobile number.');
        }
        
    }
    
    /* THIS METHOD IS USE FOR GETTING THE TEMPLATE HTML BODY BASED ON THE FUNCTION CODE AND WHAT ID.
* IT CHECKS THE SMS METADATA FROM ASF_QUICK_LINK_CONFIG__MDT CUSTOM METADATA.
* THIS RETURNED SMS METADATA IS SEARCHED IN CUSTOMER_NOTIFICATION_CONFIG__MDT CUSTOM METADATA.
* FROM THERE WE GET SMS TEMPLATE TO CONVERT TO HTML BODY.
*/
    public static String getTemplateBody(String whatId,String funcCode){
        ASF_Quick_Link_Config__mdt qkCommMdt = [SELECT ID, FunctionName__c ,FunctionCode__c,SMSMetadataName__c 
                                                FROM ASF_Quick_Link_Config__mdt WHERE FunctionCode__c =: funcCode];
        
        Customer_Notification_Config__mdt commMdt= [SELECT ID,SMS_Template_Name__c FROM Customer_Notification_Config__mdt 
                                                    WHERE DeveloperName=: qkCommMdt.SMSMetadataName__c ];
        EMAILTemplate eTemplate = [SELECT ID,HTMLValue FROM EMAILTemplate WHERE DeveloperName =: commMdt.SMS_Template_Name__c];
        String retVal = generateMessageBody(eTemplate.Id,UserInfo.getUserId(), whatId,true);
        return retVal;
    }
    
    /* TO GENERATE EITHER HTML BODY OR PLAIN TEXT BODY FROM EMAIL TEMPLATE.
*/
    private static String generateMessageBody(String templateID, String whoID, STring whatID, Boolean isPlainText){
        Messaging.SingleEmailMessage msg = Messaging.renderStoredEmailTemplate(templateID, whoId, whatID, Messaging.AttachmentRetrievalOption.NONE); 
        String richTextMessage = msg.getHtmlBody(); 
        return isPlainText ? richTextMessage.StripHtmlTags() : richTextMessage;
    }
    
    /* THIS METHOD IS USED TO GET THE ENCRYPTED URL CREATED.
* ENCRYPTION IS BASED ON AES256, FOR WHICH KEY AND IV IS PROVIDED BY CUSTOMER PORTAL.
* THE SAME KEY AND IV IS USED BY CUSTOMER PORTAL WHILE DECRYPTING THE URL SENT IN EMAIL OR SMS FROM CRM SIDE.
* CALLING METHOD - createCommunicationLogRecord
*/
    private static String getEncryptedURL(String commLogId,String clientCode,String polNumber,String funcCode,String sourceVal){
        DateTime currentDateTime = DateTime.Now();
        
        String staticUrl = Label.ABSLI_STATICURL;
        String endPoint ='CRMReportID='+commLogId+'&';
        endPoint += 'ClientID='+clientCode+'&';
        endPoint += 'PolicyNumber='+polNumber+'&';
        endPoint += 'FunctionCode='+funcCode+'&';  
        endPoint += 'Source=CRM&';
        endPoint += 'TimeStamp='+ currentDateTime.Day()+currentDateTime.Month()+currentDateTime.Year()+currentDateTime.Hour()+currentDateTime.Minute()+currentDateTime.Second()+'000';
        Blob exampleIv = Blob.valueOf(Label.ABSLI_Ivkey);
        Blob key = Blob.ValueOf(Label.ABSLI_key);
        Blob data = Blob.valueOf(endPoint);
        Blob encrypted = Crypto.encrypt('AES256', key, exampleIv, data);
        String encyrptedString = EncodingUtil.base64Encode (encrypted);
        /*Blob decrypted = Crypto.decrypt('AES256', key, exampleIv, encrypted);
String decryptedString = decrypted.toString();
System.debug(decryptedString);*/
        staticUrl += encyrptedString;
        System.debug(staticUrl);
        return staticUrl;
    }
    
    /* THIS METHOD IS USED TO GET THE TINY URL CREATED FROM BITLY INTEGRATION.
* THIS INTEGRATION IS REAL TIME INTEGRATION, IN RESPONSE THE TINY URL IS STORED IN COMM LOG RECORD.
* THIS URL STORED IN TINY_URL__C IS FURTHER USED IN EMAIL TEMPLATE AND SMS TEMPLATE.
*/
    @AuraEnabled
    public static String generateBitlyLink(String cLogId,String funcCode){
        String retVal = '';
        ASF_Communication_Log__c commLog = [SELECT ID,Encrypted_URL__c FROM ASF_Communication_Log__c WHERE Id=:cLogId];
        System.debug('commLog::::'+commLog);
        List<ASF_Communication_Log__c> updatecommLogList = new List<ASF_Communication_Log__c>();
        // BITLY Integration Code here.
        //BitlyRequest bitlyReqWrapper = new BitlyRequest(commLog.Encrypted_URL__c);
        BitlyRequestWrapper bitlyRequestWrapper = new BitlyRequestWrapper(commLog.Encrypted_URL__c);
        string bitlyRequestBody = JSON.serialize(bitlyRequestWrapper);
        ABCL_IntegrationCallout.IntegrationResponseWrapper bitlyResponse = ABCL_IntegrationCallout.executeCallout(ABSLI_Constants.BITLYLINK_INTEGRATION_METADATA,bitlyRequestBody,null);
        if(bitlyResponse.statusCode == 200 && String.isNotBlank(bitlyResponse.responseBody)){
            BitlyResponseWrapper bitlyResp = (BitlyResponseWrapper) JSON.deserialize(bitlyResponse.responseBody, BitlyResponseWrapper.class);
            commLog.Tiny_URL__c = bitlyResp.URLReturned;
            updatecommLogList.add(commLog);
        }
        else{
            throw new AuraException('Error occured from BitlyApi please contact System Administrator.');
        }
        
        if(!updatecommLogList.isEmpty()){
            update updatecommLogList;
            retVal = getTemplateBody(cLogId,funcCode);
        }
        
        return retVal;
    }
    @AuraEnabled
    public static void sendCommunication(string cLogId,String smsTxt,String unregisteredNumber){
        ASF_Communication_Log__c cLog = [SELECT ID,Account__c ,Case__c,External_Template_ID__c,Phone__c,Email_template_Name__c,
                                         SMS_Msg_Body__c,LOB__c,SMS_Entity_Id__c,SMS_Sender_Id__c
                                         FROM ASF_Communication_Log__c WHERE Id =:cLogId];
        cLog.SMS_Msg_Body__c = smsTxt;
        if(unregisteredNumber != null && unregisteredNumber != ''){
            cLog.Phone__c = unregisteredNumber;
        }
        update cLog;
        
        List<Outbound_Communication__e> eventList = new List<Outbound_Communication__e>();
        eventList.add(createOutboundCommunication(cLog,'SMS'));
        List<Database.SaveResult> results = EventBus.publish(eventList);
        
        sendEmailCommunication(cLog);
        System.debug(results);
        
    }
    private static void sendEmailCommunication(ASF_Communication_Log__c cLog){
        PE_Logger__c peLogger = new PE_Logger__c();
        peLogger.AccountId__c = cLog.Account__c;
        peLogger.ContactId__c = getContactIdForAccountId(cLog.Account__c);
        peLogger.PE_Name__c = 'CommunicationLog';
        peLogger.Retry_PE__c = true;
        peLogger.Status__c = 'Pending';
        peLogger.RecordID__c = cLog.Id;
        peLogger.Email_Template_Name__c = cLog.Email_template_Name__c;
        peLogger.LOB__c = ABSLI_Constants.BUSINESS_UNIT;
        if(Schema.sObjectType.PE_Logger__c.isCreateable())
        {
            insert peLogger;  
            
            ASF_CommnunicationLog__e commEvent = new ASF_CommnunicationLog__e();
            commEvent.PELoggerId__c = peLogger.Id;
            commEvent.RecordID__c = cLog.Account__c;
            DateTime dt = DateTime.now();
            commEvent.Unique_Id__c = 'CommunicationLog-'+UserInfo.getUserId()+'-'+System.currentTimeMillis();
            Database.SaveResult eventResult = EventBus.publish(commEvent);
        }
        
    }
    private static Id getContactIdForAccountId(Id accountId){
        return [SELECT ID FROM Contact WHERE AccountId =: accountId AND Primary__c = true]?.Id;
    }
    private static Outbound_Communication__e createOutboundCommunication(ASF_Communication_Log__c log,String msgType){
        System.debug('***createOutboundCommunication --> ');
        Outbound_Communication__e event = new Outbound_Communication__e(LogID__c  =log.id,
                                                                        Case__c = log.Case__c,
                                                                        Template_ID__c  = log.External_Template_ID__c ,
                                                                        Phone__c  =log.Phone__c,
                                                                        Txt_Msg__c = log.SMS_Msg_Body__c,
                                                                        LOB__c = log.LOB__c,
                                                                        Type__c = msgType,
                                                                        SMS_Entity_Id__c = log.SMS_Entity_Id__c,
                                                                        SMS_Sender_Id__c = log.SMS_Sender_Id__c
                                                                       );
        
        return event;
    }
    
    @AuraEnabled(cacheable=true)
    public static boolean checkforvalidforRPJ(Id AssetId) {
        Asset policy = [SELECT ID,Policy_Flag__c FROM Asset WHERE Id =: AssetId]; 
        return policy.Policy_Flag__c == null ? true : false;
    }
    
    public class BitlyRequestWrapper{
        public String LongURL{get;set;}	// LINK+ENCRYPTED_DATA 
        public String LOB{get;set;}	//
        public Integer ExpiryDay{get;set;}	//0
        public String Source{get;set;}	//CRM
        public String ClientIPAddress{get;set;}	//
        public  BitlyRequestWrapper(String longurl){
            this.LongURL = longurl;
            this.LOB = Label.ABSLI_BITLY_LOB_VAL;
            this.ExpiryDay = ABSLI_Constants.EXPIRY_DAY;
            this.Source = 'WYH';
            this.ClientIPAddress = ABSLI_Constants.BITLY_CLIENT_IP;
        }
    }
    public class BitlyResponseWrapper{
        public string LoginId{get;set;}
        public string ReturMessage{get;set;}
        public string ReturnCode{get;set;}
        public string UDP{get;set;}
        public string Identifier{get;set;}
        public string URLReturned{get;set;}        
    }
    
    
    @AuraEnabled(cacheable = true)
    public static String getCustomerPhoneNumber(String recordId){
        List<Contact> contacts = [SELECT ID,MobilePhone FROM Contact WHERE AccountId =: recordId AND Primary__c = true];
        if(contacts.size()>0){
            return contacts[0].MobilePhone;
        }
        else{
            return null;
        }
    }
    
}