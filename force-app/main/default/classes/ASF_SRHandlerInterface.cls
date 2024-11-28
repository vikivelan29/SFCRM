public interface ASF_SRHandlerInterface {
    
    void processSRData(Case c);
    
    // used to update the extension object details after case update
    List<SObject> processSRDataBulk(List<Case> c,ASF_Case_Category_Config__c ccc);
    void beforeInsertUpdateCaseData(List<Case> c);
   // void beforeUpdateHandler(List<Case> newCaseList);

}