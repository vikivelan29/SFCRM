/*********************************************************
*@Class        :  ABFL_ComplaintsValidateOnResolvedStage 
*@Author       :  Sai Rahul
*@Created Date :  02/09/2024
*@Last Modified:  03/15/2024 - APEX PMD fixes - Code Refactored - Sankashu
*@description  :  Class for Complaints Case Validation for ABFL
*********************************************************/
public with sharing class ABFL_ComplaintsValidateOnResolvedStage {
    
    /****************************************************************************************************************
* @BusinessUnit - ABFL
* @LOBs - 'Retail - Secured','Retail - Unsecured','Corporate','Digital','Not classified'
* @Function - RCA Fields validation on Verification Stage for Complaints Cases except Wealth LOB
* @param  - Case record 
* @description - invoked when tried to Close case without filling RCA fields on Verification Stage
*****************************************************************************************************************/
    public static Map<Id,Set<String>> validateRCAfields(Set<Id> caseIds)
    {   
        Map<Id,Set<String>> mCaseIdVsBlankFields = new Map<Id,Set<String>>();
        
        
        List<String> cccExtIds = new List<String>();
        
        if(!(caseIds.size()>0)){
            return new Map<Id,Set<String>>();
        }
        
        Map<Id,Case> cases = new Map<Id,Case>(ABFL_SOQL_Case.getCasedetails(caseIds));
        
        for(Case c : cases.values()){
            cccExtIds.add(c.CCC_External_Id__c);
        }
        
        List<ASF_Case_Category_Config__c> ccRecords = ASF_CaseQueryHandler.getCaseCategoryConfigs(cccExtIds);
        
        Map<String,ASF_Case_Category_Config__c> mCCCExtIdVsCCCRecord = new Map<String,ASF_Case_Category_Config__c>();
        
        for(ASF_Case_Category_Config__c cccRecord : ccRecords){
            if(!mCCCExtIdVsCCCRecord.containsKey(cccRecord.CCC_External_Id__c))
            {
                mCCCExtIdVsCCCRecord.put(cccRecord.CCC_External_Id__c,cccRecord);
            }
        }
        /*ASF_Case_Category_Config__c cccRec = [select LOB__c,Business_Unit__c 
FROM ASF_Case_Category_Config__c
WHERE CCC_External_Id__c = :caseRec.CCC_External_Id__c WITH SECURITY_ENFORCED];           
*/
        
        for(Case caseR : cases.values()){
            ASF_Case_Category_Config__c cccRec = mCCCExtIdVsCCCRecord.containsKey(caseR.CCC_External_Id__c) ? mCCCExtIdVsCCCRecord.get(caseR.CCC_External_Id__c) : null;
            if(cccRec == null){
                continue;
            }
            if(caseR.Business_Unit__c == ABFL_Constants.ABFL && ABFL_Constants.ABFL_LOB_COMPLAINT_RCA.contains(cccRec.LOB__c))
            {
                Set<String> blankFields = new Set<String>();  
                
                if(String.isBlank(caseR.ABFL_Case_Detail__r.Case_Categorisation__c))
                {
                    blankFields.add('Case Categorization');               
                }
                else if(caseR.ABFL_Case_Detail__r.Case_Categorisation__c == 'Incorrect')
                {   
                    Map<String, String> fieldsExtensionMap1 = new Map<String, String>{
                        'Correct Category' => caseR.ABFL_Case_Detail__r.Correct_Category__c,
                        'Correct Call Type' => caseR.ABFL_Case_Detail__r.Correct_Call_Type__c ,
                        'Correct Sub Type' => caseR.ABFL_Case_Detail__r.Correct_Sub_Type__c 
                    };

                    for(String fieldExt :fieldsExtensionMap1.keySet())
                    {
                        
                        if(String.isBlank(fieldsExtensionMap1.get(fieldExt)))
                        {
                            blankFields.add(fieldExt);
                        }
                    }
                    fieldsExtensionMap1.clear();// emptying the Map
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
                    Map<String, Decimal> fieldsExtensionMap2 = new Map<String, Decimal>{
                        'Diputed Amount' => caseR.ABFL_Case_Detail__r.Diputed_Amount__c,
                        'Refund Amount' => caseR.ABFL_Case_Detail__r.Refund_Amount__c  
                    };
                    
                    for(String field :fieldsExtensionMap2.keySet()){
                        
                        if(fieldsExtensionMap2.get(field) == null)
                        {
                            blankFields.add(field);
                        }
                    }
                    fieldsExtensionMap2.clear();//emptying the Map
                }
                
                if(String.isBlank(caseR.ABFL_Case_Detail__r.Action_Taken__c))
                {
                    blankFields.add('Action Taken');                    
                }
                
                if(String.isBlank(caseR.ABFL_Case_Detail__r.Grievance_Type__c))
                {
                    blankFields.add('Grievance Type');                    
                }
                
                if(!mCaseIdVsBlankFields.containsKey(caseR.Id)){
                    mCaseIdVsBlankFields.put(caseR.Id,blankFields);
                }
                
            }
            
        }
        
        
        return mCaseIdVsBlankFields;            
    }
    
    
}