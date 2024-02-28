/*********************************************************
*Class        :  ABFL_WealthChatGeneratedCases
*Author       :  Salesforce 
*Created Date :  23/02/2024
*Last Modified:  28/02/2024
*Description  :  To update the Email Id and mobile on the Case.SuppliedEmail & Case.SuppliedPhone and then send and acknowledgement Email and SMS to Customer
*********************************************************/
public with sharing class ABFL_WealthChatGeneratedCases {
    public static void execute(list<EmailMessage> emailMessageList){
        Map<Id,String> mapCaseIdToEmailId = new  Map<Id,String>(); // Map to hold Case Ids with the EmailId
        Map<Id,String> mapCaseIdToMobile = new  Map<Id,String>(); // Map to hold Case Ids with the EmailId
        for(EmailMessage msg : emailMessageList){
            if( msg.Incoming && msg.ParentId.getSObjectType() == Case.sObjectType ){
                boolean bEligible = false;
                if(msg.Headers != null){
                    if(!msg.Headers.contains('In-Reply-To:')){
                        bEligible = true;
                    }
                }
                else{
                    bEligible = true;
                }
                if(bEligible){
                    String inputText = msg.TextBody;
                    String extractedEmail;
                    String extractedMobile;
                    if(inputText != null && inputText != ''){
                        extractedEmail = extractEmail(inputText);
                        extractedMobile = extractMobile(inputText);
                        System.debug('Extracted Email => '+extractedEmail);
                    }
                    if(extractedEmail != null || extractedEmail !=''){
                        mapCaseIdToEmailId.put(msg.ParentId, extractedEmail);
                    }
                    if(extractedMobile != null || extractedMobile != ''){
                        mapCaseIdToMobile.put(msg.ParentId, extractedMobile);
                    }
                } 
            }
        }

        List<Case> casesToUpdate = new List<Case>();
        for(Case c : ASF_EmailMessageQueryHandler.getCaseRecords(mapCaseIdToEmailId.Keyset())){
            System.debug('inside case=> '+c+'   ABFL_Constants.WMCHATCASEORIGIN ==> '+ABFL_Constants.WMCHATCASEORIGIN);
            if(c.Origin == ABFL_Constants.WMCHATCASEORIGIN){
                c.SuppliedEmail = mapCaseIdToEmailId.get(c.Id) !=null ? mapCaseIdToEmailId.get(c.Id) : c.SuppliedEmail ;
                c.SuppliedPhone = mapCaseIdToMobile.get(c.Id) !=null ? mapCaseIdToMobile.get(c.Id) : c.SuppliedPhone;
                casesToUpdate.add(c);
            }
        }
        //Check if the casesToUpdate list is empty or not
        if(!casesToUpdate.isEmpty() && casesToUpdate.size()>0){
            ASF_TriggerSkipperUtility.markTriggerRun('Case'); // to disable the trigger
            System.debug('CasesToUpdate =>'+casesToUpdate);
            update casesToUpdate;
            for(Case c: casesToUpdate){
                // Platform Event trigger to send Email and SMS to the Supplied Email & Phone
                ASF_SendCustomerCommunication.sendCustomerCommunicationToSpecificEmailAndMobile(c, ABFL_Constants.WMEMAILTEMPLATENAME, c.SuppliedEmail, ABFL_Constants.WMSMSTEMPLATENAME, c.SuppliedPhone);
                System.debug('after PELogandinvoe &&&&&&&&&&&&& => ');
            } 
        }    
    }
    
    public static String extractEmail(String inputText) {
        String patternString = 'Email ID: (\\S+@\\S+)';
        Pattern pattern = Pattern.compile(patternString);
        Matcher matcher = pattern.matcher(inputText);
        
        if (matcher.find()) {
            return matcher.group(1);
        } else {
            return null; // No match found
        }
    }
    
       
    public static String extractMobile(String inputText) {
        String patternString = 'Mobile No\\.\\s*:\\s*(\\d{10})';
        Pattern pattern = Pattern.compile(patternString);
        Matcher matcher = pattern.matcher(inputText);
        
        if (matcher.find()) {
            return matcher.group(1);
        } else {
            return null; // No match found
        }
    }
    
}