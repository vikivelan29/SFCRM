/**
* @description       : To Send the acknowledgement Email when Case is created from email
* @author            : Sutanu Bose
* @Created on  		 : 11-04-2024
**/

public class ABML_SendCaseCreationEmail {
    @SuppressWarnings('PMD.ApexDoc, PMD.StdCyclomaticComplexity, PMD.AvoidDeeplyNestedIfStmts, PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.NcssMethodCount')
    public static void sendEmailOnABMLCaseCreation(list<EmailMessage> emailMessageList){
		
        system.debug('emailMessageList is ::: '+emailMessageList);
        
        Set<Id> caseIdsToSendAcknowledgement = new Set<Id>();
        Map<Id,String> mCaseEmailTemplateName = new Map<Id,String>();
        Map<String,String> mEmailAddressToTemplate = new Map<String,String>();
        
        String abmligGroupHelpline = System.Label.ABML_E2C;
        system.debug('abmligGroupHelpline is ::: '+abmligGroupHelpline);
        List<String> abmligE2CList = abmligGroupHelpline.split(',');
        //system.debug('abmligE2CList is ::: '+abmligE2CList);
        
        for(String e2c : abmligE2CList) {
            String emailId = e2c.split(':')[0];
            String emailTemplate = e2c.split(':')[1];

            mEmailAddressToTemplate.put(emailId,emailTemplate);
            system.debug('mEmailAddressToTemplate is ::: '+mEmailAddressToTemplate);
        }
        
        for(EmailMessage msg : emailMessageList){
            if( msg.Incoming && msg.ParentId.getSObjectType() == Case.sObjectType ){
                
                system.debug('Winning_Email__c is ::: '+msg.Winning_Email__c);
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
                    system.debug('Winning_Email__c 2 is ::: '+mEmailAddressToTemplate.containsKey(msg.Winning_Email__c));
                    if(mEmailAddressToTemplate.containsKey(msg.Winning_Email__c)){
                        mCaseEmailTemplateName.put(msg.ParentId,mEmailAddressToTemplate.get(msg.Winning_Email__c));
                        system.debug('mCaseEmailTemplateName is ::: '+mCaseEmailTemplateName);
                    }
                }
            }
        }
        if(caseIdsToSendAcknowledgement.size()>0){
            for(case caseobj: ASF_EmailMessageQueryHandler.getCaseRecords(caseIdsToSendAcknowledgement)){
                system.debug('caseobj is ::: '+caseobj);
                if(caseobj.Origin == 'ABML Email' && caseobj.Business_unit__c == 'ABML'){
                    String templateDevName = '';
                    if(mCaseEmailTemplateName.containsKey(caseobj.Id)){
                        templateDevName = mCaseEmailTemplateName.get(caseobj.Id);
                        system.debug('templateDevName is ::: '+templateDevName);
                    }
                    ASF_SendCustomerCommunication.sendCustomerCommunicationToSpecificEmailAndMobile(caseobj, templateDevName, caseobj.SuppliedEmail, '', '');
                }
            }
        }
    }


}