/**
* @description       : Class for Fund Value LWC
* @author            : Viren, dhinesh.t@salesforce.com
* @group             : 
* @last modified on  : 07-15-2024
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
* Modifications Log
* Ver   Date         Author                       Modification
* 1.0   06-03-2024   dhinesh.t@salesforce.com   Initial Version
**/
public with sharing class ABSLI_FundValueCompController {
    public static final string STR_METADATA_NAME = 'ABSLI_Fund_Value_Link';
    
    /****************************************************************************************************************
* @LOB - ABSLI
* @Function - getTemplateBody
* @param whatId  
* @param policyId
* @return String.
* @description - Method to get the Template Body
*****************************************************************************************************************/
    @AuraEnabled(cacheable=false)
    public static responseWrapper getTemplateBody(String whatId,String policyId){
        responseWrapper response = new responseWrapper();
        /* Fund Value API call, store the value in which field?*/
        Customer_Notification_Config__mdt commMdt= [SELECT ID,SMS_Template_Name__c FROM Customer_Notification_Config__mdt 
                                                    WHERE DeveloperName=: STR_METADATA_NAME WITH SECURITY_ENFORCED];
        response = getFundValueFromCore(policyId,whatId);
        return response;
    }
    
/****************************************************************************************************************
* @LOB - ABSLI
* @Function - generateMessageBody
* @param templateID
* @param whoID
* @param whatID
* @param isPlainText
* @return String
* @description - Method to generate Message Body
*****************************************************************************************************************/
    private static String generateMessageBody(String templateID, String whoID, STring whatID, Boolean isPlainText){
        Messaging.SingleEmailMessage msg = Messaging.renderStoredEmailTemplate(templateID, whoId, whatID, Messaging.AttachmentRetrievalOption.NONE); 
        String richTextMessage = msg.getHtmlBody(); 
        return isPlainText ? richTextMessage.StripHtmlTags() : richTextMessage;
    }
    
    /****************************************************************************************************************
* @LOB - ABSLI
* @Function - getPolicyColumns
* @return List<Map<String, String>> 
* @description - Method to get PolicyColumns from custom label
*****************************************************************************************************************/
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
        System.debug(LoggingLevel.INFO,columns);
        return columns;
    }
    
    /****************************************************************************************************************
* @LOB - ABSLI
* @Function - getAllRelatedAssets
* @param recordId
* @return List<Asset>
* @description - Method to get getAllRelatedAsset related to the account.
*****************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<Asset> getAllRelatedAssets(Id recordId) {
        // Fetch policy columns from custom label
        List<Map<String, String>> columns = getPolicyColumns();
        List<String> columnAPINames = new List<String>();
        for (Map<String, String> column : columns) {
            columnAPINames.add(column.get('fieldName'));
        }
        
        for (String columnName : columnAPINames) {
            if (!Pattern.matches('^[a-zA-Z0-9_]+$', columnName)) {
                throw new IllegalArgumentException('Invalid column name: ' + columnName);
            }
        }
        String columnNames = String.join(columnAPINames, ', ');
        // Construct SOQL query dynamically
        String query = 'SELECT ';
        query += columnNames + ' FROM Asset WHERE AccountId = :recordId AND Type__c = \'ULIP\' WITH SECURITY_ENFORCED';
        System.debug(LoggingLevel.INFO,Database.query(query));
        return Database.query(query);
    }	
    

    public static responseWrapper getFundValueFromCore(String policyId,String AccountId){
        Asset policy = [SELECT ID,Policy_No__c FROM Asset WHERE Id =: policyId AND Business_Unit__c =: 'ABSLI'];
        String message = '';
        
        responseWrapper cls = new responseWrapper();
        
        fundValueRequestWrapper fundValRequestWrapper = new fundValueRequestWrapper(policy.Policy_No__c); 
        string fundValRequestBody = JSON.serialize(fundValRequestWrapper);
        ABCL_IntegrationCallout.IntegrationResponseWrapper fundValResponse = ABCL_IntegrationCallout.executeCallout(ABSLI_Constants.FUND_VALUE_API_METADATA,fundValRequestBody,null);
        if(fundValResponse.statusCode == 200 && String.isNotBlank(fundValResponse.responseBody)){
            fundValueResponseWrapper resp = (fundValueResponseWrapper) JSON.deserialize(fundValResponse.responseBody, fundValueResponseWrapper.class);
            System.debug(resp);
            decimal sumVal = 0;
            integer iCounter = 0;
            decimal totalFundVal = 0;
            if(resp.BFID_RESPONSE.TOTAL_FUND_VALUE != null){
                totalFundVal = decimal.ValueOf(resp.BFID_RESPONSE.TOTAL_FUND_VALUE).setScale(2);
            }
            System.debug('totalFundVal --> '+totalFundVal);
            cls = createCommunicationLogRecord(AccountId,policy,totalFundVal);
        }
        else{
            System.debug(fundValResponse.statusCode +' -- '+fundValResponse.responseBody);
            throw new AuraException('Error occured from Get Fund Detail Api please contact System Administrator.');
        }
        return cls;
    }
    
    public class responseWrapper{
        @AuraEnabled
        public string message{get;set;}
        @AuraEnabled
        public string cLogId{get;set;}
    }
    
    private static responseWrapper createCommunicationLogRecord(String AccountId, Asset selectedPolicy,decimal totalFundVal){
        Contact c = [SELECT ID,MobilePhone,Name,Salutation,Full_Name__c FROM Contact WHERE AccountId = : AccountId LIMIT 1];
        Customer_Notification_Config__mdt commMdt= [SELECT ID,SMS_Entity_Id__c,
                                                    SMS_Sender_Id__c,SMS_Template_Name__c,external_templateID__c,
                                                    Email_Template_Name__c 
                                                    FROM Customer_Notification_Config__mdt 
                                                    WHERE DeveloperName=: STR_METADATA_NAME ];
        EMAILTemplate eTemplate = [SELECT ID,HTMLValue FROM EMAILTemplate WHERE DeveloperName =: commMdt.SMS_Template_Name__c];
        
        responseWrapper cls = new responseWrapper();
        
        if(c.MobilePhone != null && c.MobilePhone != ''){
            List<ASF_Communication_Log__c> masterLogs = new List<ASF_Communication_Log__c>();
            
            ASF_Communication_Log__c cLog = new ASF_Communication_Log__c();
            cLog.Account__c = AccountId;
            cLog.Contact__c = c.Id;
            cLog.Contact_Name__c = (c.Salutation != null ? c.Salutation : '') + c.Full_Name__c;
            cLog.SMS_Entity_Id__c = commMdt.SMS_Entity_Id__c;
            cLog.SMS_Sender_Id__c = commMdt.SMS_Sender_Id__c;
            cLog.SMS_LT_Name__c = commMdt.SMS_Template_Name__c;
            cLog.External_Template_ID__c = commMdt.external_templateID__c;
            cLog.Status__c = ABSLI_Constants.COMM_LOG_DEFAULT_STATUS;
            cLog.Policy_No__c = selectedPolicy.Policy_No__c;
            cLog.LOB__c = ABSLI_Constants.BUSINESS_UNIT;
            cLog.Phone__c = c.MobilePhone;
            cLog.SMS_Merge_Field1__c = String.valueOf(totalFundVal);
            cLog.Email_template_Name__c = commMdt.Email_Template_Name__c;
            insert cLog;
            
            String retVal = generateMessageBody(eTemplate.Id,UserInfo.getUserId(), cLog.Id,true);
            System.debug(retVal);
            cLog.SMS_Msg_Body__c = retVal;
            update cLog;
            cls.message = retVal;
            cls.cLogId = cLog.Id;
            System.debug('cls.cLogId --> '+cls.cLogId);
            return cls;
            
        }
        else{
            throw new AuraException('Trying to send SMS to Customer without mobile number.');
        }
        
    }
    
    
    /****************************************************************************************************************
* @LOB - ABSLI
* @Function - sendCommunication
* @param accountId
* @param policyId
* @param unregisteredNumber
* @return void
* @description - Method to sendCommunication
*****************************************************************************************************************/
    @AuraEnabled
    public static void sendCommunication(string accountId,string policyId,string cLogId){
        Contact c = [SELECT ID,MobilePhone,Name FROM Contact WHERE AccountId = : accountId WITH SECURITY_ENFORCED LIMIT 1];
        Customer_Notification_Config__mdt commMdt= [SELECT ID,SMS_Entity_Id__c,
                                                    SMS_Sender_Id__c,SMS_Template_Name__c,external_templateID__c
                                                    FROM Customer_Notification_Config__mdt 
                                                    WHERE DeveloperName=: STR_METADATA_NAME WITH SECURITY_ENFORCED];
        
        ASF_Communication_Log__c cLog = [SELECT ID,Case__c,External_Template_ID__c,Phone__c,
                                         SMS_Msg_Body__c,LOB__c,SMS_Entity_Id__c,SMS_Sender_Id__c 
                                         FROM ASF_Communication_Log__c WHERE Id=:cLogId];
        
        List<Outbound_Communication__e> eventList = new List<Outbound_Communication__e>();
            eventList.add(createOutboundCommunication(cLog,'SMS'));
            List<Database.SaveResult> results = EventBus.publish(eventList);
            System.debug(LoggingLevel.INFO,results);
    }         
        /****************************************************************************************************************
* @LOB - ABSLI
* @Function - sendCommunication
* @param log
* @param msgType
* @return Outbound_Communication__e
* @description - Method to createOutboundCommunication
*****************************************************************************************************************/    
    private static Outbound_Communication__e createOutboundCommunication(ASF_Communication_Log__c log,String msgType){
        System.debug(LoggingLevel.INFO,'***createOutboundCommunication --> ');
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
    public class fundValueRequestWrapper{
        public String policy_id{get;set;}
        public String effective_date{get;set;}	//
        public String source{get;set;}	//0
        public fundValueRequestWrapper(String polNum){
            this.policy_id = polNum;
            System.debug(polNum);
            this.effective_date = ABCL_IntegrationCommonUtility.dateFormat(System.today(), 'dd-MM-YYYY');
            this.source = ABSLI_Constants.ESB_SOURCE_ID;
        }
    }
    public class fundValueResponseWrapper{
        public root BFID_RESPONSE;
        public List<detail> FUND_DETAILS;
    }
    public class root{
        public String TOTAL_FUND_VALUE{get;set;}
    }
    public class detail{
        public decimal NAV{get;set;}
        public String FUND_NAME{get;set;}
        public decimal FUND_VALUE{get;set;} 
        public decimal TOT_UNITS{get;set;}
    }
}