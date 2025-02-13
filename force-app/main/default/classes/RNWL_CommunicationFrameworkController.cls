/************************************************************************************
*Class          :  RNWL_CommunicationFrameworkController
*Author         :  Gaurav Sharma
*Created Date   :  21/10/2024
*Last Modified  :  21/10/2024
*@description   :  Class is used for RNWL communication templates on renewal Request
************************************************************************************/
public with sharing class RNWL_CommunicationFrameworkController {
    
    @AuraEnabled
    public static List<RNWL_Communications__mdt> fetchCommunicationMDT() {
        List<RNWL_Communications__mdt> mdt = [SELECT Id, Email__c, Entity__c, SMS__c, Metadata_Name__c, User_Friendly_Name__c, WhatsApp__c, Class_Name__c, Method_Name__c
            FROM RNWL_Communications__mdt
            WHERE Entity__c = 'Opportunity' AND
            Is_Active__c = TRUE
            LIMIT 50000];
        return mdt;
    }

    @AuraEnabled
    public static String notifyUsers(String requestJSON) {
        try {
            RequestWrapper requestInst = (RequestWrapper) JSON.deserialize(requestJSON, RequestWrapper.class);
            if (String.isBlank(requestInst.opportunityId)) {
                return null;
            }
            Opportunity oppRecord = [SELECT Id, AccountId FROM Opportunity WHERE Id = :requestInst.opportunityId];
            Contact contactRecord;
            // LIMIT 1 is used because all ABHI Accounts have only one contact
            for (Contact each : [SELECT Id FROM Contact WHERE AccountId = :oppRecord.AccountId LIMIT 1]) {
                contactRecord = each;
            }
            
            String errorMessage = validateNotificationLimit(oppRecord.Id , requestInst.selectedTemplate);
            if(String.isNotBlank(errorMessage)){
                throw new AuraHandledException(errorMessage);
            }

            if (requestInst.className != null && requestInst.methodName != null) {
                Callable validationInstance = (Callable) Type.forName(requestInst.className).newInstance();
                String result = (String) validationInstance.call(requestInst.methodName, new Map<String, Object>{'opportunityId' => requestInst.opportunityId});
                if (result != null) {
                    throw new AuraHandledException(result);
                }
            }

            Customer_Notification_Config__mdt notificationMD = Customer_Notification_Config__mdt.getInstance(requestInst.selectedTemplate);
            PE_Logger__c peLoggerRecord = new PE_Logger__c(AccountId__c = oppRecord.AccountId, ContactId__c = contactRecord?.Id, Opportunity_ID__c = oppRecord.Id,
                RecordID__c = oppRecord.Id, PE_Name__c = 'Communication Log', Status__c = 'Pending', LOB__c = 'ABHI', CustomMetadataName__c = requestInst.selectedTemplate,
                Send_To_Specific_Mobile__c = String.isNotBlank(requestInst.alternateMobile), Specific_To_MobilePhone__c = requestInst.alternateMobile,
                Send_To_Specific_Emails__c = String.isNotBlank(requestInst.toAddresses), Specific_To_Address__c = requestInst.toAddresses,
                CC_Addresses__c = requestInst.ccAddresses, Email_Template_Name__c = notificationMD.Email_Template_Name__c);
            insert peLoggerRecord;
            ASF_CommnunicationLog__e communicationLog = new ASF_CommnunicationLog__e(CustomMetadataName__c = requestInst.selectedTemplate, PELoggerId__c = peLoggerRecord.Id,
                RecordID__c = oppRecord.Id);
            Eventbus.publish(communicationLog);
        } catch (Exception e) {
            throw e;
        }
        return 'Initiated communication successfully';
    }
    
    private static String validateNotificationLimit(Id oppId, String metadataName){
        String errorMessage = '';
        List<PE_Logger__c> peLoggers = [SELECT Id,CreatedDate FROM PE_Logger__c WHERE Opportunity_ID__c =:oppId AND CustomMetadataName__c = :metadataName];

        if(peLoggers != null && peLoggers.size() > 0){
            Integer currentPECount=0;
            Integer totalPECount = peLoggers.size();                
            
            for(PE_Logger__c logger : peLoggers){
                if(date.today().isSameDay(logger.CreatedDate.Date())){
                    ++currentPECount;
                }
            }

            List<RNWL_Communications__mdt> mdt = [SELECT id, DeveloperName, Metadata_Name__c, Frequency_per_Day__c, Frequency_per_Renewal_Request__c 
               FROM RNWL_Communications__mdt WHERE Metadata_Name__c=:metadataName LIMIT 1];
            
            if(mdt[0].Frequency_per_Day__c != null && currentPECount >= (Integer)mdt[0].Frequency_per_Day__c){
                errorMessage += System.Label.RNWL_CommunicationDailyFreq+'\n';
            }
            if(mdt[0].Frequency_per_Renewal_Request__c != null && totalPECount >= (Integer)mdt[0].Frequency_per_Renewal_Request__c){
                errorMessage += System.Label.RNWL_CommunicationOverallFreq;
            }
            
            return errorMessage; 
        }
        
        return errorMessage;
    }
    
    public class RequestWrapper {
        public String selectedTemplate;
        public String notificationMode;
        public String alternateMobile;
        public String toAddresses;
        public String ccAddresses;
        public String opportunityId;
        public String className;
        public String methodName;
    }
}