@isTest
public class ASF_OppCommPETriggerHelperTest {
    @TestSetup
    public static void setup(){
        Account acc = ASF_TestDataFactory.insertBusinessAccount('test', 'strCRN');
        acc.Phone = '9052437031';
        update acc;
        Contact con = ASF_TestDataFactory.insertContact('Joshna', 'jpalla@salesforce.com');
        Contact con2 = ASF_TestDataFactory.insertContact('Joshna Palla', 'jpalla@salesforce.com');
        con.AccountId = acc.Id;
        update con;
        Asset asset = ASF_TestDataFactory.createAsset(acc.Id,'');  
        Opportunity oppRec = RNWL_TestDataFactory.createOpportunityRecords(acc.Id, asset.Id);
    }
    
    @IsTest
    private static void testEmailNotifications(){
        Opportunity oppRecord = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Contact contactRecord = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        PE_Logger__c peLoggerRecord = new PE_Logger__c(AccountId__c = oppRecord.AccountId, ContactId__c = contactRecord?.Id, Opportunity_ID__c = oppRecord.Id,
                RecordID__c = oppRecord.Id, PE_Name__c = 'Communication Log', Status__c = 'Pending', LOB__c = 'ABHI', CustomMetadataName__c = 'RNWL_Change_in_personal_details',
                Send_To_Specific_Mobile__c = false, Specific_To_MobilePhone__c = null, Send_To_Specific_Emails__c = false, Specific_To_Address__c = null,
                CC_Addresses__c = null, Email_Template_Name__c = 'RNWL_Change_in_personal_details');
            insert peLoggerRecord;
        ASF_CommnunicationLog__e communicationLog = new ASF_CommnunicationLog__e(CustomMetadataName__c = 'RNWL_Change_in_personal_details', PELoggerId__c = peLoggerRecord.Id,
            RecordID__c = oppRecord.Id);
        Eventbus.publish(communicationLog);
        Test.stopTest();
    }

    @IsTest
    private static void testEmailNotificationsSpecificMail(){
        Opportunity oppRecord = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Contact contactRecord = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        PE_Logger__c peLoggerRecord = new PE_Logger__c(AccountId__c = oppRecord.AccountId, ContactId__c = contactRecord?.Id, Opportunity_ID__c = oppRecord.Id,
                RecordID__c = oppRecord.Id, PE_Name__c = 'Communication Log', Status__c = 'Pending', LOB__c = 'ABHI', CustomMetadataName__c = 'RNWL_Change_in_personal_details',
                Send_To_Specific_Mobile__c = false, Specific_To_MobilePhone__c = null, Send_To_Specific_Emails__c = true,
                Specific_To_Address__c = 'joshnareddy90@gmail.com;joshnareddy902@gmail.com',
                CC_Addresses__c = 'jpalla@salesforce2.com;jpalla@salesforce3.com', Email_Template_Name__c = 'RNWL_Change_in_personal_details');
            insert peLoggerRecord;
        ASF_CommnunicationLog__e communicationLog = new ASF_CommnunicationLog__e(CustomMetadataName__c = 'RNWL_Change_in_personal_details', PELoggerId__c = peLoggerRecord.Id,
            RecordID__c = oppRecord.Id);
        Eventbus.publish(communicationLog);
        Test.stopTest();
    }

    @IsTest
    private static void testSMSNotifications(){
        Opportunity oppRecord = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Contact contactRecord = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        PE_Logger__c peLoggerRecord = new PE_Logger__c(AccountId__c = oppRecord.AccountId, ContactId__c = contactRecord?.Id, Opportunity_ID__c = oppRecord.Id,
                RecordID__c = oppRecord.Id, PE_Name__c = 'Communication Log', Status__c = 'Pending', LOB__c = 'ABHI', CustomMetadataName__c = 'RNWL_DHA',
                Send_To_Specific_Mobile__c = false, Specific_To_MobilePhone__c = null, Send_To_Specific_Emails__c = false, Specific_To_Address__c = null,
                CC_Addresses__c = null, Email_Template_Name__c = null);
            insert peLoggerRecord;
        ASF_CommnunicationLog__e communicationLog = new ASF_CommnunicationLog__e(CustomMetadataName__c = 'RNWL_DHA', PELoggerId__c = peLoggerRecord.Id,
            RecordID__c = oppRecord.Id);
        Eventbus.publish(communicationLog);
        Test.stopTest(); 
    }

    @IsTest
    private static void testSMSNotificationsSpecific(){
        Opportunity oppRecord = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Contact contactRecord = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        PE_Logger__c peLoggerRecord = new PE_Logger__c(AccountId__c = oppRecord.AccountId, ContactId__c = contactRecord?.Id, Opportunity_ID__c = oppRecord.Id,
                RecordID__c = oppRecord.Id, PE_Name__c = 'Communication Log', Status__c = 'Pending', LOB__c = 'ABHI', CustomMetadataName__c = 'RNWL_DHA',
                Send_To_Specific_Mobile__c = true, Specific_To_MobilePhone__c = '8639113532', Send_To_Specific_Emails__c = false, Specific_To_Address__c = null,
                CC_Addresses__c = null, Email_Template_Name__c = null);
            insert peLoggerRecord;
        ASF_CommnunicationLog__e communicationLog = new ASF_CommnunicationLog__e(CustomMetadataName__c = 'RNWL_DHA', PELoggerId__c = peLoggerRecord.Id,
            RecordID__c = oppRecord.Id);
        Eventbus.publish(communicationLog);
        Test.stopTest(); 
    }

    @IsTest
    private static void testSMSNotificationsNoContact(){
        Opportunity oppRecord = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Contact contactRecord = [SELECT Id FROM Contact LIMIT 1];
        delete contactRecord;

        Test.startTest();
        PE_Logger__c peLoggerRecord = new PE_Logger__c(AccountId__c = oppRecord.AccountId, ContactId__c = contactRecord?.Id, Opportunity_ID__c = oppRecord.Id,
                RecordID__c = oppRecord.Id, PE_Name__c = 'Communication Log', Status__c = 'Pending', LOB__c = 'ABHI', CustomMetadataName__c = 'RNWL_DHA',
                Send_To_Specific_Mobile__c = false, Specific_To_MobilePhone__c = null, Send_To_Specific_Emails__c = false, Specific_To_Address__c = null,
                CC_Addresses__c = null, Email_Template_Name__c = null);
            insert peLoggerRecord;
        ASF_CommnunicationLog__e communicationLog = new ASF_CommnunicationLog__e(CustomMetadataName__c = 'RNWL_DHA', PELoggerId__c = peLoggerRecord.Id,
            RecordID__c = oppRecord.Id);
        Eventbus.publish(communicationLog);
        Test.stopTest(); 
    }

    @IsTest
    private static void testWhatsAppNotifications(){
        Opportunity oppRecord = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Contact contactRecord = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        PE_Logger__c peLoggerRecord = new PE_Logger__c(AccountId__c = oppRecord.AccountId, ContactId__c = contactRecord?.Id, Opportunity_ID__c = oppRecord.Id,
                RecordID__c = oppRecord.Id, PE_Name__c = 'Communication Log', Status__c = 'Pending', LOB__c = 'ABHI', CustomMetadataName__c = 'RNWL_Winback_Whatsapp',
                Send_To_Specific_Mobile__c = false, Specific_To_MobilePhone__c = null, Send_To_Specific_Emails__c = false, Specific_To_Address__c = null,
                CC_Addresses__c = null, Email_Template_Name__c = null);
            insert peLoggerRecord;
        ASF_CommnunicationLog__e communicationLog = new ASF_CommnunicationLog__e(CustomMetadataName__c = 'RNWL_Winback_Whatsapp', PELoggerId__c = peLoggerRecord.Id,
            RecordID__c = oppRecord.Id);
        Eventbus.publish(communicationLog);
        Test.stopTest(); 
    }
}