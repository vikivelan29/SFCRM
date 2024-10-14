public class RNWL_RenewalWrapper{
     
    @AuraEnabled public Integer Id; ///Random Id
    @AuraEnabled public String Policy_renewal_date; //09/01/2025
    @AuraEnabled public String Upsell_Flag; //Yes
    @AuraEnabled public String Renewable_Flag;  //Yes
    @AuraEnabled public String Renewed_Flag;    //Yes
    @AuraEnabled public String sumInsuredtype;  //family
    @AuraEnabled public String Renewal_Net_Premium; //47266.4
    @AuraEnabled public String Renewal_Gross_Premium;   //47266.4
    @AuraEnabled public String Upsell_Net_Premium;  //47266.4
    @AuraEnabled public String Upsell_Gross_Premium;    //47266.4  
    @AuraEnabled public String Nominee_Name;    //Mona
    @AuraEnabled public String Nominee_Address; //
    @AuraEnabled public String Nominee_Contact_No;
    @AuraEnabled public String Is_cross_sell = '';
    @AuraEnabled public String Cross_sell_Reference_Number;    
    @AuraEnabled public String ErrorCode;
    @AuraEnabled public String ErrorMessage;
    
    @AuraEnabled public cls_Members[] Members;  
    
    public class cls_Members {
        @AuraEnabled public String Name;    //Vishwas Varma
        @AuraEnabled public String SumInsured;  //2000000
        @AuraEnabled public String Upsell_SumInsured;   //
        @AuraEnabled public String healthReturn;    //.00
        @AuraEnabled public String DoB; //03/30/1974
        @AuraEnabled public String Gender;  //M
        @AuraEnabled public String Email;   //rahul.ghimire@qualitykiosk.com
        @AuraEnabled public String Mobile_Number;   //7912073232
        @AuraEnabled public String Relation;    //Father
        @AuraEnabled public String Chronic; //
        @AuraEnabled public String CB;  //3000000
    }
     
}