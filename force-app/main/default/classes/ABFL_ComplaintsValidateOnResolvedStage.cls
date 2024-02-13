/*********************************************************
*@Class        :  ABFL_ComplaintsValidateOnResolvedStage 
*@Author       :  Sai Rahul
*@Created Date :  02/09/2024
*@Last Modified:  02/09/2024
*@description  :  Class for Complaints Case Validation for ABFL
*********************************************************/

Public class ABFL_ComplaintsValidateOnResolvedStage {

/****************************************************************************************************************
    * @BusinessUnit - ABFL
    * @LOBs - 'Retail - Secured','Retail - Unsecured','Corporate','Digital','Not classified'
    * @Function - RCA Fields validation on Verification Stage for Complaints Cases except Wealth LOB
    * @param  - Case record 
    * @description - invoked when tried to Close case without filling RCA fields on Verification Stage
    *****************************************************************************************************************/
    public static Set<String> validateRCAfields(case caseRec)
    {
        

        Set<String> blankFields;

            Case caseR = [SELECT Business_Unit__c,
                            ABFL_Case_Detail__r.Case_Categorisation__c,
                            ABFL_Case_Detail__r.Correct_Category__c,
                            ABFL_Case_Detail__r.Correct_Call_Type__c,
                            ABFL_Case_Detail__r.Correct_Sub_Type__c,
                            ABFL_Case_Detail__r.Voice_of_Customer__c,
                            ABFL_Case_Detail__r.Primary_Erring_Unit__c,
                            ABFL_Case_Detail__r.Financial_Impact__c,
                            ABFL_Case_Detail__r.Diputed_Amount__c,
                            ABFL_Case_Detail__r.Refund_Amount__c,
                            ABFL_Case_Detail__r.Action_Taken__c,
                            ABFL_Case_Detail__r.Grievance_Type__c
                          FROM Case 
                          WHERE Id = :caseRec.Id WITH SECURITY_ENFORCED];

            ASF_Case_Category_Config__c cccRec = [select LOB__c,Business_Unit__c 
                                                  FROM ASF_Case_Category_Config__c
                                                  WHERE CCC_External_Id__c = :caseRec.CCC_External_Id__c WITH SECURITY_ENFORCED];           
 
            if(caseR.Business_Unit__c == ABFL_Constants.ABFL && ABFL_Constants.ABFL_LOB_COMPLAINT_RCA.contains(cccRec.LOB__c))
            {
                blankFields = new Set<String>();                

                if(String.isBlank(caseR.ABFL_Case_Detail__r.Case_Categorisation__c))
                {
                    blankFields.add('Case Categorization');               
                }
                else if(caseR.ABFL_Case_Detail__r.Case_Categorisation__c == 'Incorrect')
                {
                    if(String.isBlank(caseR.ABFL_Case_Detail__r.Correct_Category__c))
                        blankFields.add('Correct Category');                        
                    if(String.isBlank(caseR.ABFL_Case_Detail__r.Correct_Call_Type__c))  
                        blankFields.add('Correct Call Type'); 
                    if(String.isBlank(caseR.ABFL_Case_Detail__r.Correct_Sub_Type__c))
                        blankFields.add('Correct Sub Type');   
                }

                if(String.isBlank(caseR.ABFL_Case_Detail__r.Voice_of_Customer__c))
                {
                    blankFields.add('Voice of Customer');                    
                }
                if(String.isBlank(caseR.ABFL_Case_Detail__r.Primary_Erring_Unit__c))
                {
                    blankFields.add('Primary Erring Unit');                    
                }                

                if(String.isBlank(caseR.ABFL_Case_Detail__r.Financial_Impact__c))
                {
                    blankFields.add('Financial Impact'); 
                }
                else if(caseR.ABFL_Case_Detail__r.Financial_Impact__c == 'Yes')
                {
                    if((caseR.ABFL_Case_Detail__r.Diputed_Amount__c) == null)
                        blankFields.add('Diputed Amount');
                    if((caseR.ABFL_Case_Detail__r.Refund_Amount__c) == null)  
                        blankFields.add('Refund Amount');  
                }

                if(String.isBlank(caseR.ABFL_Case_Detail__r.Action_Taken__c))
                {
                    blankFields.add('Action Taken');                    
                }

                if(String.isBlank(caseR.ABFL_Case_Detail__r.Grievance_Type__c))
                {
                    blankFields.add('Grievance Type');                    
                }
                
            }

            return blankFields;            
    }
    

}