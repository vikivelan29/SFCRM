/**
* @description       : Handler class for triggers of platform event ASF_Bulk_Case_Processor__e
* @author            : Salesforce.com
* @group             : 
* @last modified on  : 19-02-2024
* @last modified by  : Salesforce.com
**/

public with sharing class ASF_BulkCaseProcessorHandler extends ASF_VTriggerHandler {
    private String triggerName;
    public ASF_BulkCaseProcessorHandler(String triggerName){
        this.triggerName = triggerName;
    }
    private Boolean isTriggerDisabled(){
        return isDisabled('Bulk_Case_Processor');
    }

    public override void afterInsert(Map<Id, SObject> newMap) {
        if(isTriggerDisabled()){return;}

        //Fetch Trigger Config to check if active
        ASF_Bulk_Case_Processor_Trigger_Config__mdt configMDT = ASF_Bulk_Case_Processor_Trigger_Config__mdt.getInstance('BulkCaseProcessor_'+this.triggerName);
        if(configMDT != null && configMDT.Config_Active__c == true){
            System.debug('Total PE received'+newMap.size());
            //filter based on ReplayId's last character
            List<ASF_Bulk_Case_Processor__e> eligiblePERecs = new List<ASF_Bulk_Case_Processor__e>();
            eligiblePERecs = this.doLoadBalancing((List<ASF_Bulk_Case_Processor__e>)newMap.values());
            System.debug(this.triggerName+'trigger received '+eligiblePERecs.size());
            if(!eligiblePERecs.isEmpty()){
                //invoke Processor Utility
                ASF_BulkCaseProcessorUtility utility = new ASF_BulkCaseProcessorUtility(eligiblePERecs);
                utility.process(this.triggerName);
            }
        }
    }

    private List<ASF_Bulk_Case_Processor__e> doLoadBalancing(List<ASF_Bulk_Case_Processor__e> peChunk){
        /**
         * Algo - Round Robin
         * 1. Find out the running/active triggers out of 10 defined triggers - using table EventBusSubscriber
         * 2. order and index them based on trigger name - triggerEight, triggerFive, triggerSix etc.
         * 3. For each PE, find the last digit of replayId
         * 4. Find MOD(replayId/number of active triggers) = modNumber
         * 5. if the current trigger's index from step 2 is equal to modNumber, process this PE, else skip it
         */

         List<ASF_Bulk_Case_Processor__e> returnList = new List<ASF_Bulk_Case_Processor__e>();
         Map<String, Integer> triggerIndexMap = new Map<String,Integer>();
         Integer index = 0;
        for(EventBusSubscriber sub : [select Name,ExternalId from EventBusSubscriber where Type = 'ApexTrigger' and Topic = 'ASF_Bulk_Case_Processor__e' and Status = 'Running' order by Name]){
            triggerIndexMap.put(sub.Name, index);
            index++;
        }
        String fullTriggerName = 'ASF_BulkCaseProcessor'+this.triggerName;
        for(ASF_Bulk_Case_Processor__e peRec : peChunk){
            String lastChar = peRec.ReplayId.right(1);
            Integer modNumber = Math.mod(Integer.valueOf(lastChar), triggerIndexMap.size());
            System.debug('PE ID'+peRec.EventUuid);
            if(triggerIndexMap.containsKey(fullTriggerName) && triggerIndexMap.get(fullTriggerName) == modNumber){
                returnList.add(peRec);
            }
        }
        return returnList;
    }

    /**
     * Old afterInsert - commented out.
     * moved to a newer method of effective load balancing - 19Feb2024
     */
    /*
    public override void afterInsert(Map<Id, SObject> newMap) {
        if(isTriggerDisabled()){return;}

        //Fetch Trigger Config to check if active
        ASF_Bulk_Case_Processor_Trigger_Config__mdt configMDT = ASF_Bulk_Case_Processor_Trigger_Config__mdt.getInstance('BulkCaseProcessor_'+this.triggerName);
        if(configMDT != null && configMDT.Config_Active__c == true){
            List<String> allowedIndexes = configMDT.Index_Values__c.split(';');
            //filter based on ReplayId's last character
            List<ASF_Bulk_Case_Processor__e> eligiblePERecs = new List<ASF_Bulk_Case_Processor__e>();
            for(ASF_Bulk_Case_Processor__e peRec : (List<ASF_Bulk_Case_Processor__e>)newMap.values()){
                String lastChar = peRec.ReplayId.right(1);
                if(configMDT.Index_Values__c != null && allowedIndexes.contains(lastChar)){
                    eligiblePERecs.add(peRec);
                }
            }
            if(!eligiblePERecs.isEmpty()){
                //invoke Processor Utility
                ASF_BulkCaseProcessorUtility utility = new ASF_BulkCaseProcessorUtility(eligiblePERecs);
                utility.process();
            }
        }
    }
    */
    
}