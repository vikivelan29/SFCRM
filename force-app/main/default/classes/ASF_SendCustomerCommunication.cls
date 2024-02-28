public class ASF_SendCustomerCommunication {
    public static void sendCustomerCommunicationToSpecificEmailAndMobile(Case caseRec, String emailTemplate, String SpecificEmailId,String sms_CustomMetadataName, String specificMobileNumber){
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
        if(specificMobileNumber != null && specificMobileNumber != ''){
            peLogger.Send_To_Specific_Mobile__c = TRUE;
            peLogger.Specific_To_MobilePhone__c = specificMobileNumber;
            peLogger.CustomMetadataName__c = sms_CustomMetadataName;
        }
        peLogger.Send_To_Specific_Emails__c = True;
        peLogger.Specific_To_Address__c = SpecificEmailId;
        peLogger.Email_Template_Name__c = emailTemplate;
        if(Schema.sObjectType.PE_Logger__c.isCreateable())
        {
            insert peLogger;    
        }
        Database.SaveResult eventResult = invokeCommunicationLogPlatformEvent(caseRec, peLogger); 
    }
    
    private static Database.SaveResult invokeCommunicationLogPlatformEvent(Case caseRec, PE_Logger__c peLogger){
        ASF_CommnunicationLog__e commEvent = new ASF_CommnunicationLog__e();
        commEvent.CCCExternalId__c = caseRec.CCC_External_Id__c;
        commEvent.PELoggerId__c = peLogger.Id;
        commEvent.RecordID__c = caseRec.Id;
        DateTime dt = DateTime.now();
        commEvent.Unique_Id__c = 'CommunicationLog-'+UserInfo.getUserId()+'-'+System.currentTimeMillis();
        Database.SaveResult eventResult = EventBus.publish(commEvent);
        return eventResult;
    }
    
    
}