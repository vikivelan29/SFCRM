/**
* @description       : To Send the acknowledgement Email when Case is created from email
* @author            : Sutanu Bose
* @Created on  		 : 11-04-2024
**/

public with sharing class ABML_SendCaseCreationEmail {
    @SuppressWarnings('PMD.ApexDoc, PMD.StdCyclomaticComplexity, PMD.AvoidDeeplyNestedIfStmts, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.NcssMethodCount')
    public static void sendEmailOnABMLCaseCreation(list<EmailMessage> emailMessageList){
		
        Set<Id> caseIdsToSendAcknowledgement = new Set<Id>();
        Map<Id , String> mapOfCaseIdAndEmailTemplate = new Map<Id , String>();
        Map<String , String> mapOfEmailIdAndTemplate = new Map<String , String>();
        
        String strGroupHelpline = System.Label.ABML_E2C;
        List<String> abmligE2CList = new List<String>();
        
        if(strGroupHelpline != ''){
            abmligE2CList = strGroupHelpline.split(',');
        }
        
        for(String e2c : abmligE2CList) {
            String emailId = e2c.split(':')[0];
            String emailTemplate = e2c.split(':')[1];

            mapOfEmailIdAndTemplate.put(emailId , emailTemplate);
        }
        
        if(emailMessageList != null){
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
                        if(msg.ParentId != null){
                        	caseIdsToSendAcknowledgement.add(msg.ParentId);
                        }
                        if(mapOfEmailIdAndTemplate.containsKey(msg.Winning_Email__c)){
                            mapOfCaseIdAndEmailTemplate.put(msg.ParentId , mapOfEmailIdAndTemplate.get(msg.Winning_Email__c));
                        }
                    }
                }
            }
        }
        
        if(caseIdsToSendAcknowledgement.size() > 0){
            for(case caseObj : ASF_EmailMessageQueryHandler.getCaseRecords(caseIdsToSendAcknowledgement)){
                if(caseObj.Origin == 'ABML Email' && caseObj.Business_unit__c == 'ABML'){
                    String templateDevName = '';
                    if(mapOfCaseIdAndEmailTemplate.containsKey(caseObj.Id))
                    {
                        templateDevName = mapOfCaseIdAndEmailTemplate.get(caseObj.Id);
                    }
                    ASF_SendCustomerCommunication.sendCustomerCommunicationToSpecificEmailAndMobile(caseobj, templateDevName, caseobj.SuppliedEmail, '', '');
                }
            }
        }
    }

}
