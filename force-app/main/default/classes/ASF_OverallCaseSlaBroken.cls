/*********************************************************
*Class        :  ASF_OverallCaseSlaBroken
*Description  :  Class to Mark SLA Broken, when called from Scheduled Path Flow
*********************************************************/
public without sharing class ASF_OverallCaseSlaBroken {
    /**
     * This method is called from the Flow Case SLA Broken
     * which has a scheduled path for SLA broken (Overall Case Closure SLA).
     * When the path executes, this apex action is called with two parameters (caseId, isReopened)
     * For Regualr Cases, Regular SLA Broken fields are updated
     * For Reopen Cases, Reopen SLA fields are updated
     */
    @InvocableMethod(label='Mark Overall Case SLA Broken')
    public static void ASF_OverallCaseSlaBroken(List<Request> casesList) {

        list<Case> casesToBeUpdated = new list<Case>();

        for(Request s:casesList){
            case c = new case();
            c.Id = s.caseId;
            if(s.isReopened){
                c.Reopen_SLA_Broken__c = true;
                c.Reopen_SLA_Broken_Date_Time__c = System.now();
            }
            else{
                c.SLA_Broken__c = true;
                c.SLA_Broken_DateTime__c = System.now();
            }
            
            casesToBeUpdated.add(c);
        }

        ASF_TriggerSkipperUtility.markTriggerRun('Case');
        update casesToBeUpdated;

    }

    public class Request {
        @InvocableVariable(required=true)
         public String caseId;
        @InvocableVariable(required=true)
         public Boolean isReopened;
    }
}