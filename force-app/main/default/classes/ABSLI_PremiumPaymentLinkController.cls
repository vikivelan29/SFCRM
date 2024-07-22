/**
 * @description       : Class for premium Payment LWC
 * @author            : Viren, dhinesh.t@salesforce.com
 * @group             : 
 * @last modified on  : 07-15-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   06-03-2024   dhinesh.t@salesforce.com   Initial Version
**/
public with sharing class ABSLI_PremiumPaymentLinkController {

    public static final string STR_METADATA_NAME = 'ABSLI_Premium_Payment_Link';
    
    /****************************************************************************************************************
     * @LOB - ABSLI
     * @Function - getTemplateBody
     * @param whatId 
     * @param policyId 
     * @return String.
     * @description - Method to get the Template Body
     *****************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static String getTemplateBody(String whatId,String policyId){
        Customer_Notification_Config__mdt commMdt= [SELECT ID,SMS_Template_Name__c FROM Customer_Notification_Config__mdt 
                                                    WHERE DeveloperName=: STR_METADATA_NAME WITH SECURITY_ENFORCED];
        EMAILTemplate eTemplate = [SELECT ID,HTMLValue FROM EMAILTemplate WHERE DeveloperName =: commMdt.SMS_Template_Name__c WITH SECURITY_ENFORCED];
        String retVal = generateMessageBody(eTemplate.Id,UserInfo.getUserId(), policyId,true);
        return retVal;
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
	    System.debug(columns);
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

    	// Construct SOQL query dynamically
    	String query = 'SELECT ';
    	query += String.join(columnAPINames, ', ') + ' FROM Asset WHERE AccountId = :recordId';
        System.debug(Database.query(query));
    	return Database.query(query);
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
     * @Function - sendCommunication
     * @param accountId
     * @param policyId
     * @param unregisteredNumber
     * @return void
     * @description - Method to sendCommunication
     *****************************************************************************************************************/
    @AuraEnabled
    public static void sendCommunication(string accountId,string policyId,string unregisteredNumber){
        Contact c = [SELECT ID,MobilePhone,Name FROM Contact WHERE AccountId = : accountId WITH SECURITY_ENFORCED LIMIT 1];
        Customer_Notification_Config__mdt commMdt= [SELECT ID,SMS_Entity_Id__c,
                                                    SMS_Sender_Id__c,SMS_Template_Name__c,external_templateID__c
                                                    FROM Customer_Notification_Config__mdt 
                                                    WHERE DeveloperName=: STR_METADATA_NAME WITH SECURITY_ENFORCED];
        if((c.MobilePhone != null && c.MobilePhone != '') || (unregisteredNumber != null && unregisteredNumber != '')){
            List<ASF_Communication_Log__c> masterLogs = new List<ASF_Communication_Log__c>();
            String templateBody = getTemplateBody(accountId,policyId);
            ASF_Communication_Log__c cLog = new ASF_Communication_Log__c();
            cLog.Account__c = accountId;
            cLog.Contact__c = c.Id;
            cLog.Contact_Name__c = c.Name;
            cLog.SMS_Entity_Id__c = commMdt.SMS_Entity_Id__c;
            cLog.SMS_Sender_Id__c = commMdt.SMS_Sender_Id__c;
            cLog.SMS_LT_Name__c = commMdt.SMS_Template_Name__c;
            cLog.External_Template_ID__c = commMdt.external_templateID__c;
            cLog.Status__c = 'In Progress';
            cLog.SMS_Msg_Body__c = templateBody;
            cLog.Phone__c = c.MobilePhone;
            if(unregisteredNumber != null && unregisteredNumber != ''){
                cLog.Phone__c = unregisteredNumber;
            }
            
            cLog.LOB__c = 'ABSLI';
             if (Schema.sObjectType.ASF_Communication_Log__c.isCreateable()) {
    			insert cLog;
			}
            System.debug('record Inserted...'+cLog.Id);
            
            List<Outbound_Communication__e> eventList = new List<Outbound_Communication__e>();
            eventList.add(createOutboundCommunication(cLog,'SMS'));
            List<Database.SaveResult> results = EventBus.publish(eventList);
            System.debug(results);
        }
        else{
            throw new AuraException('Mobile number is not present for this record.');
        }
        
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
    
}