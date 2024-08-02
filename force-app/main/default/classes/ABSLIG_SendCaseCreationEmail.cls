/*********************************************************
*Class        :  ABSLIG_SendCaseCreationEmail
*Author       :  Virendra Patil
*Created Date :  24/July/2024
*Last Modified:  25/July/2024
*@description  :  Class for sending case creation email.  
*********************************************************/

@SuppressWarnings('PMD.StdCyclomaticComplexity')
public class ABSLIG_SendCaseCreationEmail {

    @SuppressWarnings('PMD.ApexDoc, PMD.StdCyclomaticComplexity, PMD.AvoidDeeplyNestedIfStmts, PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.NcssMethodCount')
    public static void sendEmailOnCaseCreation(list<EmailMessage> emailMessageList){

        Set<Id> caseIdsToSendAcknowledgement = new Set<Id>();
        Map<Id,String> mCaseEmailTemplateName = new Map<Id,String>();
        Map<String,String> mEmailAddressToTemplate = new Map<String,String>();

        String absligGroupHelpline = System.Label.ABSLIG_E2C;
        List<String> absligE2CList = absligGroupHelpline.split(',');
        
        for(String e2c : absligE2CList) {

            String emailId = e2c.split(':')[0];
            String emailTemplate = e2c.split(':')[1];

            mEmailAddressToTemplate.put(emailId,emailTemplate);
        }

        for(EmailMessage msg : emailMessageList){
            if( msg.Incoming && msg.ParentId.getSObjectType() == Case.sObjectType ){
                boolean bEligible = false;
                if((msg.Headers != null && msg.Headers.contains('In-Reply-To:') && msg.ReplyToEmailMessageId == null )){
                    bEligible = true;
                }
                else if(msg.Headers != null && msg.Headers.contains('In-Reply-To:')){
                    bEligible = false;
                }
                else{
                    bEligible = true;
                }
                if(bEligible){
                    caseIdsToSendAcknowledgement.add(msg.ParentId);
                    if(mEmailAddressToTemplate.containsKey(msg.Winning_Email__c)){
                        mCaseEmailTemplateName.put(msg.ParentId,mEmailAddressToTemplate.get(msg.Winning_Email__c));
                    }
                }
            }
        }
        if(caseIdsToSendAcknowledgement.size()>0){
            for(case caseobj: ASF_EmailMessageQueryHandler.getCaseRecords(caseIdsToSendAcknowledgement)){
                if(caseobj.Origin == 'ABSLIG Email' && caseobj.Business_unit__c == 'ABSLIG'){
                    String templateDevName = '';
                    if(mCaseEmailTemplateName.containsKey(caseobj.Id)){
                        templateDevName = mCaseEmailTemplateName.get(caseobj.Id);
                    }
                    ASF_SendCustomerCommunication.sendCustomerCommunicationToSpecificEmailAndMobile(caseobj, templateDevName, caseobj.SuppliedEmail, '', '');
                }
            }
        }
    }

}