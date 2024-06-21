/**
 * @description - used to send communication to the customer
 */
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts,PMD.ExcessiveParameterList, PMD.UnusedLocalVariable')
public without sharing class ASF_SendCustomerCommunication {
    /**
     * @description - Sends an communication to specific Email & Mobile
     * @param caseRec - current case record
     * @param emailTemplate - Email template Name
     * @param specificEmailId - Specific email id
     * @param smsCustomMetadataName - Custom metadata name of SMS
     * @param specificMobileNumber - specfic mobile
     */
    public static void sendCustomerCommunicationToSpecificEmailAndMobile(Case caseRec, String emailTemplate, String specificEmailId,String smsCustomMetadataName, String specificMobileNumber){
        PE_Logger__c peLogger = new PE_Logger__c();
        peLogger.AccountId__c = caseRec.AccountId;
        peLogger.CCCExternalId__c = caseRec.CCC_External_Id__c;
        peLogger.Case__c = caseRec.Id;
        peLogger.ContactId__c = caseRec.ContactId;
        peLogger.PE_Name__c = 'CommunicationLog';
        peLogger.RecordID__c = caseRec.Id;
        peLogger.Retry_PE__c = true;
        peLogger.Status__c = 'Pending';
        peLogger.LOB__c = caseRec.Business_Unit__c;
        peLogger.No_Auto_Communication__c = caseRec.No_Auto_Communication__c;
        if(specificMobileNumber != null && specificMobileNumber != ''){
            peLogger.Send_To_Specific_Mobile__c = TRUE;
            peLogger.Specific_To_MobilePhone__c = specificMobileNumber;
            peLogger.CustomMetadataName__c = smsCustomMetadataName;
        }
        peLogger.Send_To_Specific_Emails__c = True;
        peLogger.Specific_To_Address__c = specificEmailId;
        peLogger.Email_Template_Name__c = emailTemplate;
        if(Schema.sObjectType.PE_Logger__c.isCreateable())
        {
            insert peLogger;    
        }
        Database.SaveResult eventResult = invokeCommunicationLogPlatformEvent(caseRec, peLogger); 
    }
    
    /**
     * @description - to invoke the platform event
     * @param caseRec - current case reord
     * @param peLogger - current pelogger record
     * @return Database.SaveResult
     */
    private static Database.SaveResult invokeCommunicationLogPlatformEvent(Case caseRec, PE_Logger__c peLogger){
        ASF_CommnunicationLog__e commEvent = new ASF_CommnunicationLog__e();
        commEvent.CCCExternalId__c = caseRec.CCC_External_Id__c;
        commEvent.PELoggerId__c = peLogger.Id;
        commEvent.RecordID__c = caseRec.Id;
        commEvent.Unique_Id__c = 'CommunicationLog-'+UserInfo.getUserId()+'-'+System.currentTimeMillis();
        Database.SaveResult eventResult = EventBus.publish(commEvent);
        return eventResult;
    }
    
    
}