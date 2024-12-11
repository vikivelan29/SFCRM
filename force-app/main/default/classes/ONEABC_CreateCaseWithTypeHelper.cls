public class ONEABC_CreateCaseWithTypeHelper {
    public static List<ASF_Case_Category_Config__c> filterCTSTBasedOnBULogic(List<ASF_Case_Category_Config__c> cccList,String inpArg){
        List<ASF_Case_Category_Config__c> returnVal = new List<ASF_Case_Category_Config__c>();
        String accountBu = '';
        
        if(String.isNotBlank(inpArg)){
            Map<String,String> mInpArg = (Map<String,String>) JSON.deserialize(inpArg, Map<String,String>.Class);
            if(mInpArg.containsKey('accountLOB')){
                accountBu = mInpArg.get('accountLOB');
            }
        }
        for(ASF_Case_Category_Config__c cccRec : cccList){ 
            //RETURN CCC THAT MATCHES WITH ACCOUNT'S BU
            if(String.isNotBlank(accountBu)){
                if(cccRec.Business_Unit__c.equalsIgnoreCase(accountBu)){
                returnVal.add(cccRec);
                }
                else if(accountBu != ASF_Constants.ABCD_BU &&
                        cccRec.Business_Unit__c.equalsIgnoreCase(ASF_Constants.ONEABC_BU)){
                    returnVal.add(cccRec);
                }
            }
        }
        
        
        return returnVal;
        
    }
}