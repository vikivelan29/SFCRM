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
}