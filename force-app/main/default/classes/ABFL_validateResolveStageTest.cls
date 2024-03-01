/*********************************************************
*Class        :  ABFL_validateResolveStageTest
*Author       :  Sai Rahul
*Created Date :  09/02/2024
*Last Modified:
*Description  :  Test Class for ABFL_ValidateRequireFieldOnResolvedStage, ABFL_ComplaintsValidateOnResolvedStage
*********************************************************/
@isTest
Public class ABFL_validateResolveStageTest {

@TestSetup
    static void testData(){
        
        List<ASF_Case_Category_Config__c> caseCat = ABFL_TestDataFactory.createCaseCategoryConfig(true);
        caseCat[0].LOB__c = 'Corporate';
        update caseCat;
            
        List<ASF_Case_Stage_Config__c> caseStage = ABFL_TestDataFactory.createCaseStageConfigWithTwoStages(caseCat[0].Id, true);
            
            Account acc = ABFL_TestDataFactory.createAccount();
        	acc.Line_of_Business__c = 'ABFL';
        	update acc;
            List<ABFL_Case_Detail__c> caseDetList = ABFL_TestDataFactory.createCaseDetail('Corporate', true);
        	caseDetList[0].Resolution_Comments__c = '';
        	Update caseDetList;
        
        	 Id caseDetailId = caseDetList.isEmpty() ? null : caseDetList[0].Id;
            
             List<Case> caseList = ABFL_TestDataFactory.createCaseRecords(2, caseDetailId, true);
              caseList[0].Nature__c = 'Request';
              caseList[0].Technical_Source__c = 'LWC';
              caseList[0].OnCreateCloseSR__c = False;
              caseList[1].Nature__c = 'Complaint';
              caseList[1].Technical_Source__c = 'API';
              caseList[1].OnCreateCloseSR__c = False;
              update caseList;
}



@isTest
 static void testValidateOnResolvedStage(){
        List<Case> caseRecord = [SELECT Id,Nature__c,Technical_Source__c,LOB__c,Source__c,Business_Unit__c,CCC_External_Id__c,
                           ABFL_Case_Detail__r.Resolution_Comments__c,ABFL_Case_Detail__r.Case_Categorisation__c,OnCreateCloseSR__c,
                           ABFL_Case_Detail__r.Correct_Category__c,ABFL_Case_Detail__r.Correct_Call_Type__c,
                           ABFL_Case_Detail__r.Correct_Sub_Type__c,ABFL_Case_Detail__r.Voice_of_Customer__c,
                           ABFL_Case_Detail__r.Primary_Erring_Unit__c,ABFL_Case_Detail__r.Financial_Impact__c,
                           ABFL_Case_Detail__r.Diputed_Amount__c,ABFL_Case_Detail__r.Refund_Amount__c,
                           ABFL_Case_Detail__r.Action_Taken__c,ABFL_Case_Detail__r.Grievance_Type__c
	                       FROM Case];
     	ASF_Case_Category_Config__c ccc = [SELECT Id,LOB__c FROM ASF_Case_Category_Config__c 
                                           WHERE CCC_External_Id__c = :caseRecord[0].CCC_External_Id__c LIMIT 1];
     	
     	List<case> case1 = new List<case>();
     	case1.add(caseRecord[0]);
     
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> mCaseIdVsretCls =  ABFL_ValidateRequireFieldOnResolvedStage.beforeStageMovement(case1);
        ABFL_ValidateRequireFieldOnResolvedStage.afterStageMovement(case1);
     	ASF_CaseMovementHelper.CaseStageValidationWrapper retCls = mCaseIdVsretCls.get(case1[0].id);
        System.assertEquals('Error',retCls.Status);
     	
     	List<case> case2 = new List<case>();
     	case2.add(caseRecord[1]);
     
        Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> mCaseIdVsretCls1 =  ABFL_ValidateRequireFieldOnResolvedStage.beforeStageMovement(case2);
        ABFL_ValidateRequireFieldOnResolvedStage.afterStageMovement(case2);
     	ASF_CaseMovementHelper.CaseStageValidationWrapper retCls1 = mCaseIdVsretCls1.get(case2[0].id);
     	System.assertEquals('Error',retCls1.Status);
     
     	ABFL_Case_Detail__c caseDetail = [SELECT Id FROM ABFL_Case_Detail__c LIMIT 1];
     	caseDetail.Case_Categorisation__c = 'Incorrect';     	    	
     	caseDetail.Financial_Impact__c = 'Yes';     	
        Update caseDetail;
     
     	Map<Id, ASF_CaseMovementHelper.CaseStageValidationWrapper> mCaseIdVsretCls2 =  ABFL_ValidateRequireFieldOnResolvedStage.beforeStageMovement(case2);
     	ABFL_ValidateRequireFieldOnResolvedStage.afterStageMovement(case2);
     	ASF_CaseMovementHelper.CaseStageValidationWrapper retCls2 = mCaseIdVsretCls2.get(case2[0].id);
     	System.assertEquals('Error',retCls2.Status);
    	
    }
    
}