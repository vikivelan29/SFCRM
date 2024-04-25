public class ABCL_CaseDeDupeCheckLWC {
    @AuraEnabled
    public static void getDuplicateCases(List<Case> cases, String businessUnit,String transactionNo){
        if(businessUnit == 'Payments'){
            PAY_CaseDeDupeCheckLWC.getDuplicateCases(cases, transactionNo); 
        }
    }

}
