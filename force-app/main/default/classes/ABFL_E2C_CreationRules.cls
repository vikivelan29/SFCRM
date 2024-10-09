/**
  * @description       : Logic to block creation of cases in certain scenerios
 * @author            : Rajender Kumar
 * @group             : 
 * @last modified on  : 10-09-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   01-02-2024   achuriwala@salesforce.com   Initial Version
* 2.0   02-04-2024   rajender.kumar@manras.com   areAllWordsPresent function created
 * 3.0   05-06-2024   aditya.mehrotra@salesforce.com    Included ABSLI BU and resolved defect in areAllWordsPresent()
 * 4.0   05-06-2024   aditya.mehrotra@salesforce.com    Added CC functionality
**/
// supressing this as the code is meant as a mini framework and thus might have below PMD issues
@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.AvoidDeeplyNestedIfStmts')
public with sharing class ABFL_E2C_CreationRules {
    /****************************************************************************
     * @Origin - ABFL/ABSLI
     * @Function - checkCreationRules
     * @param emailMessages - contains all incoming message.
     * @description - Main method for checking all creation rules
     ****************************************************************************/
    public static void checkCreationRules(List<EmailMessage> emailMessages) {
        if(!emailMessages.isEmpty()){
            // Find eligible records
            Set<Id> caseIds = new Set<Id>();
          //  Map<Id,EmailMessage> caseIdvsEmailMessage = new Map<Id,EmailMessage>();    // temporary logic added by vikas to block case creation from bounced emails.
            for (EmailMessage email : emailMessages) {
                // Check if the email is related to a case and is incoming
                caseIds.add(email.ParentId);
               // caseIdvsEmailMessage.put(email.ParentId,email);   // added by vikas
            }

            if (!caseIds.isEmpty()){
                // Set to store Case Ids related to ABFL Email
                 Set<Id> qualifiedCaseIds = new Set<Id>();
                //for (Case c : ABFL_SOQL_Case.getCaseOrginInfo(caseIds)) {
                    for (Case c : ASF_EmailMessageQueryHandler.getCaseRecords(caseIds)) {
                    // Check if the case origin is 'ABFL Email'
                    if (System.Label.ABCL_Case_Origin_for_E2C_Rules.split(',').contains(c.origin)) {
                        qualifiedCaseIds.add(c.Id);
                    }
                   else if(caseIdvsEmailMessage.get(c.Id).FromAddress.contains('microsoftexchange')){          // added by vikas
								abflCaseIds.add(c.Id);                                                               // added by vikas
                }
                }  

                if (!qualifiedCaseIds.isEmpty()) {
                    // Get rules from E2C_Creation_Rules__mdt records - Entity => List<CreationRules>
                    Map<String, List<E2C_Creation_Rules__mdt>> metadataMap = buildMetadataMap();
                    // Process each email message
                    for (EmailMessage emailMsg : emailMessages) {
			if (metadataMap.containsKey(emailMsg.Winning_Email__c)) {
                            List<String> senderAndccList = new List<String>();
                            senderAndccList.add(emailMsg.FromAddress);
                            if(!String.isBlank(emailMsg.CcAddress)){
                                senderAndccList.addAll(emailMsg.CcAddress.replaceAll('\\s', '').split(';'));
                            }
                            // Get creation rules for the mailbox and check conditions
                            for (E2C_Creation_Rules__mdt metadata : metadataMap.get(emailMsg.Winning_Email__c)) {
                                // Check conditions and throw an error if needed
                                Boolean creationNotAllowed = false;
                                switch on metadata.Field__c {
                                    when  'Sender','To Recipients'{
                                         for(String email : senderAndccList){
					creationNotAllowed = creationNotAllowed(metadata.Operator__c, metadata.Value__c, email);
                                            if(creationNotAllowed)break;
                                        }
                                    }
                                    when  'Subject'{
                                        if(emailMsg.Subject != null){
                                        	creationNotAllowed = creationNotAllowed(metadata.Operator__c, metadata.Value__c, emailMsg.Subject);

                                        }
                                        
                                    }
                                }
                                if (creationNotAllowed) {
				    String message = String.isNotBlank(metadata.Error_Message__c)?metadata.Error_Message__c:metadata.E2C_Creation_Scenarios__r.Error_Message__c;
                                    // Log the error
                                    ABCL_Logger.enableExceptionLogging();
                                    ABCL_Logger.push('ABFL_E2C_CreationRules: Case Generation failed');
                                    ABCL_Logger.message(message);
                                    ABCL_Logger.emit();
                                    // Throw error here - This will block further processing - Check for rule level message, then header level message
                                    //emailMsg.addError(String.isNotBlank(metadata.Error_Message__c)?metadata.Error_Message__c:metadata.E2C_Creation_Scenarios__r.Error_Message__c);
                                    //String message = String.isNotBlank(metadata.Error_Message__c)?metadata.Error_Message__c:metadata.E2C_Creation_Scenarios__r.Error_Message__c;
                                    // Log the error
                                    ABCL_Logger.enableExceptionLogging();
                                    ABCL_Logger.push('ABFL_E2C_CreationRules: Case Generation failed');
                                    ABCL_Logger.message(message);
                                    ABCL_Logger.emit();
                                    emailMsg.addError(message);
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
	List<String> allowedBuList = System.Label.ABCL_BU_for_E2C_Rules.split(',');

        for (E2C_Creation_Rules__mdt metadata : [SELECT Id, Field__c, Operator__c, Value__c, Error_Message__c,
                                                    E2C_Creation_Scenarios__r.ToAddress__c, E2C_Creation_Scenarios__r.Error_Message__c
                                                    FROM E2C_Creation_Rules__mdt WHERE 
                                                    E2C_Creation_Scenarios__r.Business_Unit__c IN :allowedBuList]) {
            if (!metadataMap.containsKey(metadata.E2C_Creation_Scenarios__r.ToAddress__c)) {
                metadataMap.put(metadata.E2C_Creation_Scenarios__r.ToAddress__c, new List<E2C_Creation_Rules__mdt>{metadata});
            }else{
                metadataMap.get(metadata.E2C_Creation_Scenarios__r.ToAddress__c).add(metadata);
            }
        }
        return metadataMap;
    }
/****************************************************************************
     * @function - creationNotAllowed\
     * @param operator - selected oprator.
     * @param expectedValue - expected value from custom metadata.
     * @param actualValue - actual value from email message.
     * @return Boolean 
     * @description -  Method to check the condition based on the operator
     ****************************************************************************/
    private static Boolean creationNotAllowed(String operator, String expectedValue, String actualValue) {
        Boolean retVal=false;
        actualValue=actualValue.toLowerCase();
        expectedValue=expectedValue.toLowerCase();
        switch on operator {
            when 'Does Not Contain'{
                retVal = areAllWordsPresent(expectedValue, actualValue);
            }
            when 'Not Equals To'{
                retVal = actualValue == expectedValue;
            }
        }
        return retVal;
    }
    
 /*********************************************************************************************************************************************************
     * @function - areAllWordsPresent
     * @param expectedValue - expected value from custom metadata.
     * @param actualValue - actual value from email message.
     * @return Boolean 
     * @description -  Check if all words from the expectedValue are present in the actualValue in the same order and return true if matched, otherwise false.
     *********************************************************************************************************************************************************/
    private static Boolean areAllWordsPresent(String expectedValue, String actualValue) {
        // Split strings into arrays of words
        List<String> expectedWords = new List<String>(expectedValue.toLowerCase().split(' '));
        List<String> actualWords = new List<String>(actualValue.toLowerCase().split(' '));

        // Index to keep track of position in expectedWords
        Integer expectedIndex = 0;

        // Iterate through words in actualValue
       	for (String word : actualWords) {
          	// Check if the current word matches the next word in expectedValue
            if (expectedIndex < expectedWords.size() && expectedWords.get(expectedIndex).equals(word)) {
               	expectedIndex++;
            }else{
                expectedIndex = 0;
            } 
            // If all words from expectedValue are found in actualValue, return true
            if (expectedIndex == expectedWords.size()) {
                return true;
            }
        }

        // If actualValue does not contain expectedValue, return false
        return false;
    } 
}