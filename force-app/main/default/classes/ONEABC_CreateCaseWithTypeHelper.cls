public class ONEABC_CreateCaseWithTypeHelper {
    public static List<ASF_Case_Category_Config__c> filterCTSTBasedOnBULogic(List<ASF_Case_Category_Config__c> cccList,String inpArg){
        List<ASF_Case_Category_Config__c> returnVal = new List<ASF_Case_Category_Config__c>();
        String accountLob = '';
        String accountBu = '';
        String reqFrom = ''; 
        String closeCaseWithoutCust = '';
        Map<String, String> buMapping = new Map<String,String>{
            'ABWM'=>'Wealth',
            'ABSLAMC'=>'AMC'
        };
            
        if(String.isNotBlank(inpArg)){
            Map<String,String> mInpArg = (Map<String,String>) JSON.deserialize(inpArg, Map<String,String>.Class);
            if(mInpArg.containsKey('accountLOB')){
                accountLob = mInpArg.get('accountLOB');
            }
            if(mInpArg.containsKey('requestFrom')){
                reqFrom = mInpArg.get('requestFrom');
            }
            if(mInpArg.containsKey('businessUnit')){
                accountBu = mInpArg.get('businessUnit');
            }
            if(mInpArg.containsKey('closeCaseWithoutCusButton')){
                closeCaseWithoutCust = mInpArg.get('closeCaseWithoutCusButton');
            }
        }
        for(ASF_Case_Category_Config__c cccRec : cccList){ 
            //RETURN CCC THAT MATCHES WITH ACCOUNT'S BU
            if(String.isNotBlank(accountLob)){
                if(cccRec.Business_Unit__c.equalsIgnoreCase(accountLob)){
                returnVal.add(cccRec);
                }
                else if(accountLob != ASF_Constants.ABCD_BU &&
                        cccRec.Business_Unit__c.equalsIgnoreCase(ASF_Constants.ONEABC_BU) &&
                       	(String.isNotBlank(accountBu) && (cccRec.LOB__c.equalsIgnoreCase(accountBu) || 
                        (buMapping.containsKey(accountBu) && cccRec.LOB__c.equalsIgnoreCase(buMapping.get(accountBu)))))){
                    returnVal.add(cccRec);
                }
            } else if(String.isNotBlank(reqFrom)){
                if(reqFrom == 'Lead' && (cccRec.Business_Unit__c.equalsIgnoreCase(ASF_Constants.ONEABC_BU) || 
                                         cccRec.Business_Unit__c.equalsIgnoreCase(ASF_Constants.ABCD_BU))){
                    returnVal.add(cccRec);
                }
            } else if(String.isNotBlank(closeCaseWithoutCust) && closeCaseWithoutCust == 'true'){
                if(cccRec.Business_Unit__c.equalsIgnoreCase(ASF_Constants.ABCD_BU)){
                	returnVal.add(cccRec);
                }
            }
        }
        
        
        return returnVal;
        
    }
}