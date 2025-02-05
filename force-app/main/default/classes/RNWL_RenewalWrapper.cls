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
    @AuraEnabled public String Loading_Rate;
    @AuraEnabled public String Loading_Reason;  
    @AuraEnabled public String ErrorCode;
    @AuraEnabled public String ErrorMessage;

    // combi policy related fields:
    
    @AuraEnabled public Boolean combi_Policy_Flag;
    @AuraEnabled public String Combi_Policy_Number; 
    @AuraEnabled public cls_CombiPolicy[] CombiPolicies;

    public class cls_CombiPolicy{
        @AuraEnabled public String Combi_Policy_Number;
        @AuraEnabled public String combi_Policy_Owner;
        @AuraEnabled public String combi_Policy_StartDate;
        @AuraEnabled public String combi_Policy_EndDate;
        @AuraEnabled public String combi_Policy_Status;
        @AuraEnabled public String combi_Policy_Variant;
        @AuraEnabled public String combi_Policy_Product;
        @AuraEnabled public String combi_Policy_SubPlan;
        @AuraEnabled public String combi_Policy_ProductType;
    }

    @AuraEnabled public Boolean combi_Policy_Disposition_Flag;
    
    @AuraEnabled public cls_RelatedDispositions[] CombiDispostions;

    public class cls_RelatedDispositions{
        @AuraEnabled public String Disposition_Url;
        @AuraEnabled public String Disposition_Name;
        @AuraEnabled public String Combi_Policy_Number;
        @AuraEnabled public String Next_CallBack_Datetime;
        @AuraEnabled public String Disostion_L1;
        @AuraEnabled public String Disostion_L2;
        @AuraEnabled public String Disostion_L3;
        @AuraEnabled public String Call_DateTime;
        @AuraEnabled public String Agent_Name;
        @AuraEnabled public String Remark;
        @AuraEnabled public String Calling_Unit;
        @AuraEnabled public String Calling_Mode;
    }
    
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
        @AuraEnabled public String MemberId;  //3000000        
        @AuraEnabled public String Chronic_Disease; 
        @AuraEnabled public String PED;  
    }
     
}