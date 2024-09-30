/*********************************************************
 *Class        :  ABSLAMC_Email2CaseHandler
 *Author       :  Udit Singhal
 *Created Date :  17/09/2024
 *Description  :  ABSLAMC Email-to-Case handler class
 *********************************************************/
public class ABSLAMC_Email2CaseHandler{

    /****************************************************************************************************************
     * @Function - handleAbslamcHwcEmails
     * @param - newEmailMsgList
     * @return - void
     * @Description - route ABSLAMC cases to PHD queue of customers flagged as handle with care (HWC)
     ***********************************************************/
    public static void handleAbslamcHwcEmails(List<EmailMessage> newEmailMsgList){
        Map<Id, Case> eligibleCasesToUpdateMap = new Map<Id, Case>();
        Set<Id> caseIdSet = new Set<Id>();

        for (EmailMessage msg : newEmailMsgList){
            if (msg.Incoming && msg.ParentId.getSObjectType() == Case.sObjectType){
                caseIdSet.add(msg.ParentId);
            }
        }

        List<Case> caseList = [SELECT Id, Business_Unit__c, Origin, AccountId, Account.Handle_With_Care_HWC__c, Account.HWC_Reason__c
                               FROM Case
                               WHERE Id IN:caseIdSet];

        List<Group> abslamcPhdQueue = [SELECT Id, DeveloperName
                                       FROM Group
                                       WHERE DeveloperName = :ABSLAMC_Constants.ABSLAMC_PHD_QUEUE AND Type = 'Queue'
                                       LIMIT 1];

        for (Case caseRecord : caseList){
            if (caseRecord.Business_Unit__c == ABSLAMC_Constants.ABSLAMCBU && caseRecord.Origin == ABSLAMC_Constants.ABSLAMC_CASE_ORIGIN && caseRecord.AccountId != null && caseRecord.Account.Handle_With_Care_HWC__c == ABSLAMC_Constants.Y && caseRecord.Account.HWC_Reason__c == ABSLAMC_Constants.ABSLAMC_HWC_REASON_SOCIAL_MEDIA){
                eligibleCasesToUpdateMap.put(caseRecord.Id, caseRecord);
            }
        }


        if (eligibleCasesToUpdateMap.size() > 0){
            for (Id caseId : eligibleCasesToUpdateMap.keySet()){
                Case caseRecord = eligibleCasesToUpdateMap.get(caseId);
                caseRecord.OwnerId = abslamcPhdQueue[0].Id;
                eligibleCasesToUpdateMap.put(caseRecord.Id, caseRecord);
            }

            update eligibleCasesToUpdateMap.values();
        }
    }

}