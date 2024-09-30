/**
 * @description       : This class is used to contain email communications suppression logic. 
 * @author            : rsinghnagar@salesforce.com
 * @group             : 
 * @last modified on  : 09-26-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   09-26-2024   rsinghnagar@salesforce.com   Initial Version
**/
public with sharing class MCRM_SuppressEmailHelper {
    public static void checkSuppressionLogic(List<ASF_CustomerEmailInvocable.EmailInputWrapper> inpArg,
                                             Map<Id, ASF_CustomerEmailInvocable.EmailOutputWrapper> allOutputs)
    {
        for(ASF_CustomerEmailInvocable.EmailInputWrapper inp : inpArg){
            // CREATE A DEFAULT STRUCTURE.
            ASF_CustomerEmailInvocable.EmailOutputWrapper output = new ASF_CustomerEmailInvocable.EmailOutputWrapper();
            output.supressEmail = System.Label.MCRMSupressCTSTs.contains(String.valueOf(inp.cccRecord.get('CCC_External_Id__c')));
            output.templateName = inp.templateName;
            allOutputs.put(inp.caseId,output);
        }
    }
}