public class ABFL_CreateCaseWithTypeControllerHelper {
    public static List<ASF_Case_Category_Config__c> filterCTSTBasedOnBULogic(List<ASF_Case_Category_Config__c> cccList,String inpArg){
        List<ASF_Case_Category_Config__c> returnVal = new List<ASF_Case_Category_Config__c>();
        Map<String,String> mInpArg = new Map<String,String>();
        
        if(inpArg != null){
            mInpArg = (Map<String,String>) JSON.deserialize(inpArg, Map<String,String>.Class);
        }
        for(ASF_Case_Category_Config__c ccc : cccList){
            //IF ACCOUNT LOB IS WEALTH THEN ONLY RETURN WEALTH CTSTs, OTHERWISE RETURN ALL FROM PARENT METHOD.
            if(mInpArg.containsKey('accountLOB')){
                if(mInpArg.get('accountLOB') == ABFL_Constants.WEALTHLOB && ccc.LOB__c == ABFL_Constants.WEALTHLOB){
                    returnVal.add(ccc);
                }
                else if(ccc.LOB__c != ABFL_Constants.WEALTHLOB) {
                    returnVal.add(ccc); 
                }
            }
        }
        
        
        return returnVal;
        
    }
}