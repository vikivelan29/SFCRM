public class RNWL_Communications_Validations implements Callable {
    public Object call(String action, Map<String, Object> args) {
        String oppId = (String) args.get('opportunityId');
        Opportunity oppRecord;

        for (Opportunity each : [SELECT Id, Calling_Source__c, Policy_Expiry_Date__c FROM Opportunity WHERE Id = :oppId]) {
            oppRecord = each;
        }
        if (oppRecord == null) {
            return 'Couldn\'t check the validation criteria for this SMS. Please reach out to your admin.';
        }

        switch on action {
            when 'policyExpirySMSValidation', 'premiumDueSMSValidation' {
                if (oppRecord.Policy_Expiry_Date__c != null && Date.today() > oppRecord.Policy_Expiry_Date__c) {
                    return 'This policy has expired. You can no longer send this SMS';
                }
            }
            when 'winBackWhatsAppValidation' {
                if (oppRecord.Policy_Expiry_Date__c == null || Date.today() <= oppRecord.Policy_Expiry_Date__c || Date.today() > oppRecord.Policy_Expiry_Date__c.addDays(120)) {
                    return 'You can no longer send this message as this policy is more than 120 days old now and can no longer be renewed';
                } else if (oppRecord.Calling_Source__c <> 'CRM (In-House)') {
                    return 'You can send this message only for renewal requests with CRM (In-House) calling source';
                }
            }
            when 'winBackSMSValidation' {
                if (oppRecord.Policy_Expiry_Date__c == null || Date.today() <= oppRecord.Policy_Expiry_Date__c || Date.today() > oppRecord.Policy_Expiry_Date__c.addDays(120)) {
                    return 'You can no longer send this SMS as this policy is more than 120 days old now and can no longer be renewed';
                }
            }
            when else {
                throw new AuraHandledException('Invalid call. Please reach out to your admin.');
            }
        }
        return null;
    }
}