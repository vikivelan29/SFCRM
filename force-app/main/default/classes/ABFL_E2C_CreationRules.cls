/**
 * @description       : ABFL_E2C_CreationRules
 * @author            : Rajender Kumar
 * @group             : 
 * @last modified on  : 02-09-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   01-02-2024   achuriwala@salesforce.com   Initial Version
**/
public class ABFL_E2C_CreationRules {
    // Main entry point to handle blocked email  messages
    public static void checkCreationRules(List<EmailMessage> emailMessages) {
        System.debug('***emailMessages:' + emailMessages);
        if(!emailMessages.isEmpty()){
            // Find eligible records
            Set<Id> caseIds = new Set<Id>();
            for (EmailMessage email : emailMessages) {
                // Check if the email is related to a case and is incoming
                caseIds.add(email.ParentId);
            }
            System.debug('***caseIds:' + caseIds);

            if (!caseIds.isEmpty()){
                // Set to store Case Ids related to ABFL Email
                Set<Id> abflCaseIds = new Set<Id>();
                //Comments as causing Dependent Class Failure. Rajender Kumar to check this. 31-Jan-2024 
                for (Case c : ABFL_SOQL_Case.getCaseOrginInfo(caseIds)) {
                    System.debug('***c:' + c);
                    // Check if the case origin is 'ABFL Email'
                    if (c.origin == 'ABFL Email') {
                        abflCaseIds.add(c.Id);
                    }
                }  

                if (!abflCaseIds.isEmpty()) {
                    // Get rules from E2C_Creation_Rules__mdt records - Entity => List<CreationRules>
                    Map<String, List<E2C_Creation_Rules__mdt>> metadataMap = buildMetadataMap();
                    System.debug('***metadataMap:' + metadataMap);

                    // Map to store ToAddress__c and corresponding Error_Message__c from E2C_Creation_Scenarios__mdt
                // Map<String, String> mailboxErrorMap = buildMailboxErrorMap();
                    //System.debug('***mailboxErrorMap:' + mailboxErrorMap);

                    // Process each email message
                    for (EmailMessage emailMsg : emailMessages) {
                        System.debug('***emailMsg.ToAddress:' + emailMsg.ToAddress);
                        if (metadataMap.containsKey(emailMsg.ToAddress)) {
                            System.debug('***emailMsg.ToAddress:' + emailMsg.ToAddress);
                            // Get creation rules for the mailbox and check conditions
                            for (E2C_Creation_Rules__mdt metadata : metadataMap.get(emailMsg.ToAddress)) {
                                // Check conditions and throw an error if needed
                                Boolean creationNotAllowed = false;
                                System.debug('***metadata.Field__c:' + metadata.Field__c);
                                switch on metadata.Field__c {
                                    when  'Sender','To Recipients'{
                                        creationNotAllowed = creationNotAllowed(metadata.Operator__c, metadata.Value__c, emailMsg.FromAddress);
                                        System.debug('***Sender:' + creationNotAllowed);
                                    }
                                    when  'Subject'{
                                        creationNotAllowed = creationNotAllowed(metadata.Operator__c, metadata.Value__c, emailMsg.Name);
                                    }
                                }
                                if (creationNotAllowed) {
                                    // Throw error here - This will block further processing - Check for rule level message, then header level message
                                    emailMsg.addError(String.isNotBlank(metadata.Error_Message__c)?metadata.Error_Message__c:metadata.E2C_Creation_Scenarios__r.Error_Message__c);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Method to build a map of E2C_Creation_Rules__mdt records
    private static Map<String, List<E2C_Creation_Rules__mdt>> buildMetadataMap() {
        Map<String, List<E2C_Creation_Rules__mdt>> metadataMap = new Map<String, List<E2C_Creation_Rules__mdt>>();

        for (E2C_Creation_Rules__mdt metadata : [SELECT Id, Field__c, Operator__c, Value__c, Error_Message__c,
                                                    E2C_Creation_Scenarios__r.ToAddress__c, E2C_Creation_Scenarios__r.Error_Message__c
                                                    FROM E2C_Creation_Rules__mdt WHERE 
                                                    E2C_Creation_Scenarios__r.Business_Unit__c = :ABFL_Constants.ABFL]) {
            if (!metadataMap.containsKey(metadata.E2C_Creation_Scenarios__r.ToAddress__c)) {
                metadataMap.put(metadata.E2C_Creation_Scenarios__r.ToAddress__c, new List<E2C_Creation_Rules__mdt>{metadata});
            }else{
                metadataMap.get(metadata.E2C_Creation_Scenarios__r.ToAddress__c).add(metadata);
            }
        }
        return metadataMap;
    }

    // Method to check the condition based on the operator
    private static Boolean creationNotAllowed(String operator, String expectedValue, String actualValue) {
        System.debug('***creationNotAllowed:' +':'+operator+':'+expectedValue+':'+actualValue);
        Boolean retVal=false;
        switch on operator {
            when 'Does Not Contain'{
                retVal = actualValue.contains(expectedValue);
            }
            when 'Not Equals To'{
                retVal = actualValue == expectedValue;
            }
        }
        return retVal;
    }
}