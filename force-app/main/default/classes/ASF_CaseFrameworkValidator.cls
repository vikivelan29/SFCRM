/**
* Class For Validator Methods of Framework related to 
* Verification - Validating various rules and completions
*/
public with sharing class ASF_CaseFrameworkValidator {
    
    /**
    * Evaluates a Case Rule, by evaluating eacj Rule Entry
    * for the provided condition and the data used from case
    * No SOQL, No DML - hence not bulkifiying
    */
    public static Boolean evaluateCaseRule(string condition, List<ASF_Case_Rule_Entry__c> ruleEntries, Case caseRecord) {
        
        Boolean result = false;
        List<Integer> numberList = new List<Integer>();
        String temp = condition;
        Integer i = 0;
        do {
            if (i < temp.length()) {
                string stringNumber = temp.substring(i, i + 1);
                if (stringNumber.isNumeric()) {
                    numberList.add(Integer.valueOf(stringNumber));
                }
            }
            i = i + 1;
        } while (i < temp.length());
        
        Map<Integer, ASF_Case_Rule_Entry__c> numberRuleEntryMap = new Map<Integer, ASF_Case_Rule_Entry__c>();
        // Number__c
        for (ASF_Case_Rule_Entry__c cre : ruleEntries) {
            if (!numberRuleEntryMap.containsKey(Integer.valueOf(cre.Number__c))) {
                numberRuleEntryMap.put(Integer.valueOf(cre.Number__c), cre);
            }
        }
        
        Map<Integer, Boolean> values = new Map<Integer, Boolean>();
        system.debug('Aditya numberList:'+numberList);
        system.debug('Aditya numberRuleEntryMap:'+numberRuleEntryMap);
        for (Integer numInt : numberList) {
            ASF_Case_Rule_Entry__c cre = numberRuleEntryMap.get(numInt);
            String caseRecordValue;
            String comparsonValue='';
            if(cre.Value__c !=null && cre.Value__c !=''){
                comparsonValue = cre.Value__c;
            }
            
            
            Boolean comparisonResult;
            
            Boolean ruleEvaluate = false;
            //Check if the fieldApiName contains dot.
            if (cre.Field_Api_Name__c.contains('.')) {
                List<string> fieldList = cre.Field_Api_Name__c.split('\\.');
                String fieldCheckStr = fieldList[0].contains('__r')
                    ? fieldList[0].replace('__r','__c')
                    : fieldList[0] + 'Id';
                if (caseRecord.get(fieldCheckStr) != null) {
                    //if(fieldList[0].contains('__r')){
                        sobject rs = caseRecord.getSobject(fieldList[0]);
                        caseRecordValue = rs == null ? null : (rs.get(fieldList[1]) == null ? '' : String.valueOf(rs.get(fieldList[1])));
                    //}
                }else{
                    caseRecordValue = '0';
                }
            }
            else{
                caseRecordValue = String.valueOf(caseRecord.get(cre.Field_Api_Name__c));
                caseRecordValue = caseRecordValue==null?'':caseRecordValue;
            }
            
            cre.Data_Type__c = cre.Data_Type__c.toLowerCase();
            cre.Operator__c = cre.Operator__c.toLowerCase();
            
            switch on cre.Data_Type__c {
                when 'boolean' {
                    switch on cre.Operator__c {
                        when '=' {
                            comparisonResult =
                                Boolean.valueOf(caseRecordValue) ==
                                Boolean.valueOf(comparsonValue);
                        }
                        when '!=' {
                            comparisonResult =
                                Boolean.valueOf(caseRecordValue) !=
                                Boolean.valueOf(comparsonValue);
                        }
                        when else {
                            comparisonResult = false;
                        }
                    }
                }
                when 'string' {
                    switch on cre.Operator__c {
                        when '=' {
                            comparisonResult = caseRecordValue == comparsonValue;
                        }
                        when '!=' {
                            comparisonResult = caseRecordValue != comparsonValue;
                        }
                        when 'contains' {
                            comparisonResult = caseRecordValue.contains(comparsonValue);
                        }
                        when 'not in'{
                            //split the string by comma -> check if any string prensent -> false -> else true
                            //comparisonResult = comparsonValue.indexOf(caseRecordValue) == -1 ? true:false;
                            comparisonResult = comparsonValue.split(',').contains(caseRecordValue)?false:true;
                        }
                        when 'in'{
                            //split the string by comma -> check if any string prensent -> true -> else false
                            //comparisonResult = comparsonValue.indexOf(caseRecordValue) != -1 ? true:false;
                            comparisonResult = comparsonValue.split(',').contains(caseRecordValue)?true:false;
                        }
                        when else {
                            comparisonResult = false;
                        }
                    }
                }
                //Applied for currency,percentage, number, integer
                when 'decimal' {
                    //< > <= >= = !=
                    switch on cre.Operator__c {
                        when '<' {
                            comparisonResult =
                                Decimal.valueOf(caseRecordValue) <
                                Decimal.valueOf(comparsonValue);
                        }
                        when '!=' {
                            comparisonResult =
                                Decimal.valueOf(caseRecordValue) !=
                                Decimal.valueOf(comparsonValue);
                        }
                        when '>' {
                            comparisonResult =
                                Decimal.valueOf(caseRecordValue) >
                                Decimal.valueOf(comparsonValue);
                        }
                        when '<=' {
                            comparisonResult =
                                Decimal.valueOf(caseRecordValue) <=
                                Decimal.valueOf(comparsonValue);
                        }
                        when '>=' {
                            comparisonResult =
                                Decimal.valueOf(caseRecordValue) >=
                                Decimal.valueOf(comparsonValue);
                        }
                        when '=' {
                            comparisonResult =
                                Decimal.valueOf(caseRecordValue) ==
                                Decimal.valueOf(comparsonValue);
                        }
                        when else {
                            comparisonResult = false;
                        }
                    }
                }
            }
            values.put(numInt, comparisonResult);
        }
        
        result = ASF_BooleanExpression.evaluateAdvanceLogic(condition, values);
        return result;
    }
    
    /**
    * Validate if Incomplete Checklists are present
    * For this Case at this stage
    * Bulkified
    */
    public static Map<Id, Boolean> validateChecklists(List<Case> currentCases, Map<Id, String> currentStageMap){
        Map<Id, Boolean> caseIdToReturnFlagMap = new Map<Id, Boolean>();
        Set<Id> caseIds = new Set<Id>();
        Set<String> caseStages = new Set<String>();
        Map<Id, Set<String>> skipperFlagMap = ASF_CaseTriggerModularHelper.getSkipperFlagMap();
        for(Case caseRec : currentCases){
            Id skipperMapKey = ASF_CaseTriggerModularHelper.relObjName == null ? null : 
                   (ASF_CaseTriggerModularHelper.relObjName == '' ? caseRec.Id : (Id)caseRec.get(ASF_CaseTriggerModularHelper.relObjName));
            if(skipperMapKey != null && skipperFlagMap.containsKey(skipperMapKey) && skipperFlagMap.get(skipperMapKey).contains(ASF_Constants.SKIP_VALIDATE_CHECKLISTS)){
                caseIdToReturnFlagMap.put(caseRec.Id, true);
            }else{
                caseIds.add(caseRec.Id);
                caseStages.add(caseRec.Stage__c);
            }
        }
        if(!caseIds.isEmpty()){
            // Get Incomplete, Mandatory Checklist from Query Handler for this Case and Stage
            List<ASF_Checklist__c> incompleteCasesChecklists 
            = ASF_CaseQueryHandler.getIncompleteCaseChecklists(caseIds, new Set<String>(currentStageMap.values()));
            Map<Id, List<ASF_Checklist__c>> caseToChecklistMap = new Map<Id, List<ASF_Checklist__c>>();
            for(ASF_Checklist__c checkRec : incompleteCasesChecklists){
                if(caseToChecklistMap.containsKey(checkRec.Case__c)){
                    caseToChecklistMap.get(checkRec.Case__c).add(checkRec);
                }else{
                    caseToChecklistMap.put(checkRec.Case__c, new List<ASF_Checklist__c>{checkRec});
                }
            }
        
            for(Case caseRec : currentCases){
                caseIdToReturnFlagMap.put(caseRec.Id, true);
                if(caseToChecklistMap.containsKey(caseRec.Id)){
                    for(ASF_Checklist__c checkRec : caseToChecklistMap.get(caseRec.Id)){
                        if(checkRec.Stage_Name__c == currentStageMap.get(caseRec.Id)){
                            caseIdToReturnFlagMap.put(caseRec.Id, false);
                            break;
                        }
                    }
                }
            }
        }
        return caseIdToReturnFlagMap;
    }

    /**
     * Bulkified
     */
    public static Map<Id, String> validateValidations(List<Case> currentCases, Map<Id, ASF_Case_Stage_Config__c> caseIdToCurrentStageConfigMap){
        Set<String> cccExternalIds = new Set<String>();
        Map<Id, List<ASF_Case_Rule__c>> caseIdToCaseRulesForCurrentStage = new Map<Id, List<ASF_Case_Rule__c>>();
        Map<Id, Set<String>> skipperFlagMap = ASF_CaseTriggerModularHelper.getSkipperFlagMap();
        for(Case caseRec : currentCases){
            Id skipperMapKey = ASF_CaseTriggerModularHelper.relObjName == null ? null : 
                   (ASF_CaseTriggerModularHelper.relObjName == '' ? caseRec.Id : (Id)caseRec.get(ASF_CaseTriggerModularHelper.relObjName));
            if(!(skipperMapKey != null && skipperFlagMap.containsKey(skipperMapKey) && skipperFlagMap.get(skipperMapKey).contains(ASF_Constants.SKIP_VALIDATION_CHECKS))){
         		cccExternalIds.add(caseRec.CCC_External_Id__c);
            }            
        }
        if(!cccExternalIds.isEmpty()){
            List<ASF_Case_Rule__c> allCaseRules = ASF_CaseQueryHandler.getCaseRuleWithHierarchy(cccExternalIds);
            Map<String, List<ASF_Case_Rule__c>> externalIdToCaseRulesMap = new Map<String, List<ASF_Case_Rule__c>>();
            for(ASF_Case_Rule__c caseRule : allCaseRules){
                if(externalIdToCaseRulesMap.containsKey(caseRule.C3ExternalId__c)){
                    externalIdToCaseRulesMap.get(caseRule.C3ExternalId__c).add(caseRule);
                }else{
                    externalIdToCaseRulesMap.put(caseRule.C3ExternalId__c, new List<ASF_Case_Rule__c>{caseRule});
                }
            }
            for(Case caseRec : currentCases){
                if(externalIdToCaseRulesMap.containsKey(caseRec.CCC_External_Id__c)){
                    for(ASF_Case_Rule__c caseRule : externalIdToCaseRulesMap.get(caseRec.CCC_External_Id__c)){
                        ASF_Case_Stage_Config__c currentStageConfig = caseIdToCurrentStageConfigMap.get(caseRec.Id);
                        if(currentStageConfig != null && caseRule.Case_Stage_Config__c == currentStageConfig.Id){
                            if(caseIdToCaseRulesForCurrentStage.containsKey(caseRec.Id)){
                                caseIdToCaseRulesForCurrentStage.get(caseRec.Id).add(caseRule);
                            }else{
                                caseIdToCaseRulesForCurrentStage.put(caseRec.Id, new List<ASF_Case_Rule__c>{caseRule});
                            }
                        }
                    }
                }
            }
    	}

        return ASF_CaseFrameworkHelper.runValidationRules(currentCases, caseIdToCaseRulesForCurrentStage);
    }
    
    /**
    * Validate if Incomplete Checklists are present
    * For this Case at this stage
    * Bulkified
    */
    public static Map<Id, Boolean> validateTasks(List<Case> currentCases, Map<Id, String> currentStageMap){
        Map<Id, Boolean> caseIdToReturnFlagMap = new Map<Id, Boolean>();
        Set<Id> caseIds = new Set<Id>();
        Set<String> caseStages = new Set<String>();
        Map<Id, Set<String>> skipperFlagMap = ASF_CaseTriggerModularHelper.getSkipperFlagMap();
        for(Case caseRec : currentCases){
            Id skipperMapKey = ASF_CaseTriggerModularHelper.relObjName == null ? null : 
                   (ASF_CaseTriggerModularHelper.relObjName == '' ? caseRec.Id : (Id)caseRec.get(ASF_CaseTriggerModularHelper.relObjName));
            if(skipperMapKey != null && skipperFlagMap.containsKey(skipperMapKey) && skipperFlagMap.get(skipperMapKey).contains(ASF_Constants.SKIP_VALIDATE_TASKS)){
                caseIdToReturnFlagMap.put(caseRec.Id, true);
            }else{
                caseIds.add(caseRec.Id);
                caseStages.add(caseRec.Stage__c);
            }
        }
        if(!caseIds.isEmpty()){
            // Get Incomplete, Mandatory Checklist from Query Handler for this Case and Stage
            List<Task> incompleteTaskslists 
            = ASF_CaseQueryHandler.getIncompleteCaseTasks(caseIds, new Set<String>(currentStageMap.values()));
            Map<Id, List<Task>> caseToTaskMap = new Map<Id, List<Task>>();
            for(Task taskRec : incompleteTaskslists){
                if(caseToTaskMap.containsKey(taskRec.WhatId)){
                    caseToTaskMap.get(taskRec.WhatId).add(taskRec);
                }else{
                    caseToTaskMap.put(taskRec.WhatId, new List<Task>{taskRec});
                }
            }
            for(Case caseRec : currentCases){
                caseIdToReturnFlagMap.put(caseRec.Id, true);
                if(caseToTaskMap.containsKey(caseRec.Id)){
                    for(Task taskRec : caseToTaskMap.get(caseRec.Id)){
                        if(taskRec.Case_Stage__c == currentStageMap.get(caseRec.Id)){
                            caseIdToReturnFlagMap.put(caseRec.Id, false);
                            break;
                        }
                    }
                }
            }
        }
        return caseIdToReturnFlagMap;
    }
    
    /**
    * Validates if all Case Integrations have been Successful
    * Returns a String of Names of Integrations which are not successful (for error reporting)
    * Else, returns the string 'Success'
    * Bulkified
    */
    public static Map<Id, String> validateIntegrations(List<Case> currentCases, Map<Id, ASF_Case_Stage_Config__c> caseIdToCurrentStageConfigMap){
        // Get Incomplete, Mandatory Integrations from Query Handler for this
        String result = 'Success';
        Map<String, Map<String, ASF_Integration__c>> asfIntExtIds = new Map<String, Map<String, ASF_Integration__c>>();
        Map<Id, String> resultMap = new Map<Id, String>();
		Map<Id, Set<String>> skipperFlagMap = ASF_CaseTriggerModularHelper.getSkipperFlagMap();
        Set<Id> caseIds = new Set<Id>();
        Set<Id> stageConfigIds = new Set<Id>();
        
        for(Case caseRec : currentCases){
            Id skipperMapKey = ASF_CaseTriggerModularHelper.relObjName == null ? null : 
                   (ASF_CaseTriggerModularHelper.relObjName == '' ? caseRec.Id : (Id)caseRec.get(ASF_CaseTriggerModularHelper.relObjName));
            if(skipperMapKey != null && skipperFlagMap.containsKey(skipperMapKey) && skipperFlagMap.get(skipperMapKey).contains(ASF_Constants.SKIP_INTEGRATION_CHECKS)){
                resultMap.put(caseRec.Id, result);
            }else{
            	caseIds.add(caseRec.Id);
            }
        }
        for(Id caseId : caseIdToCurrentStageConfigMap.keySet()){
            System.debug('Check here Case Id --> '+caseId);
            ASF_Case_Stage_Config__c stageConfig = caseIdToCurrentStageConfigMap.get(caseId);
            if(caseIds.contains(caseId)){
                stageConfigIds.add(stageConfig.Id);
            }
        }
        if(!stageConfigIds.isEmpty()){
            List<ASF_Integration__c> mandatoryIntegrations = ASF_CaseQueryHandler.getIntegrationsFromConfig(stageConfigIds);
            for (ASF_Integration__c mandatoryInt :  mandatoryIntegrations){
                if(!asfIntExtIds.containsKey(mandatoryInt.C3ExternalId__c)){
                    asfIntExtIds.put(mandatoryInt.C3ExternalId__c, new Map<String, ASF_Integration__c>());
                }
                asfIntExtIds.get(mandatoryInt.C3ExternalId__c).put(mandatoryInt.External_Id__c, mandatoryInt);
            }
    	}
        
        if(asfIntExtIds.size() >0){
            Set<String> intExtIds = new Set<String>();
            for(Map<String, ASF_Integration__c> eachMap : asfIntExtIds.values()){
                intExtIds.addAll(eachMap.keySet());
            }
            // Get Case Integration Records for the above Integrations, to Determin if Validated Successfully
            List<ASF_Case_Integration__c> caseIntegrations = ASF_CaseQueryHandler.getCaseRelatedIntegrations(intExtIds, caseIds);
            Map<String, boolean> caseIntSuccessMap = new Map<String, boolean>();
            for(ASF_Case_Integration__c caseInt : caseIntegrations){
                String key = caseInt.Case__c+caseInt.Integration_Ext_Id__c;
                if(!caseIntSuccessMap.containsKey(key)){
                    caseIntSuccessMap.put(key, caseInt.Is_Validation_Success__c);
                }
            } 
            
            Map<Id, List<String>> invalidIntegrationsPerCase = new Map<Id, List<String>>();
            for(Case caseRec : currentCases){
                resultMap.put(caseRec.Id, result);//Defaulting to success
                if(asfIntExtIds.containsKey(caseRec.CCC_External_Id__c)){
                    Map<String, ASF_Integration__c> asfIntExtIdsPerCase = asfIntExtIds.get(caseRec.CCC_External_Id__c);
                    for(string extId : asfIntExtIdsPerCase.keySet()){
                        String key = caseRec.Id+extId;
                        if(!caseIntSuccessMap.containsKey(key) || !caseIntSuccessMap.get(key)){
                            if(invalidIntegrationsPerCase.containsKey(caseRec.Id)){
                                invalidIntegrationsPerCase.get(caseRec.Id).add(asfIntExtIdsPerCase.get(extId).Display_Name__c);
                            }else {
                                invalidIntegrationsPerCase.put(caseRec.Id, new List<String>{asfIntExtIdsPerCase.get(extId).Display_Name__c});
                            }
                        }
                    }
                }
            }
            
            if(!invalidIntegrationsPerCase.isEmpty()){
                for(Id caseId : invalidIntegrationsPerCase.keySet()){
                    if(invalidIntegrationsPerCase.containsKey(caseId)){
                        resultMap.put(caseId, String.join(invalidIntegrationsPerCase.get(caseId), ','));
                    }
                }
            }
        }
        
        return resultMap;
    }

    /**
     * Validates if the Case Approval, if any, is Approved for
     * the stage movement
     * Bulkified
     */
    public static Map<Id, Boolean> validateApprovals(List<Case> currentCases, Map<Id, String> currentStageMap){
        Map<Id, Boolean> caseIdToReturnFlagMap = new Map<Id, Boolean>();
        Set<Id> caseIds = new Set<Id>();
        Set<String> caseStages = new Set<String>();
        Map<Id, Set<String>> skipperFlagMap = ASF_CaseTriggerModularHelper.getSkipperFlagMap();
        for(Case caseRec : currentCases){
            Id skipperMapKey = ASF_CaseTriggerModularHelper.relObjName == null ? null : 
                   (ASF_CaseTriggerModularHelper.relObjName == '' ? caseRec.Id : (Id)caseRec.get(ASF_CaseTriggerModularHelper.relObjName));
            if(skipperMapKey != null && skipperFlagMap.containsKey(skipperMapKey) && skipperFlagMap.get(skipperMapKey).contains(ASF_Constants.SKIP_APPROVAL_CHECKS)){
                caseIdToReturnFlagMap.put(caseRec.Id, true);
            }else{
                caseIds.add(caseRec.Id);
                caseStages.add(caseRec.Stage__c);
            }
        }
        if(!caseIds.isEmpty()){
            List<ASF_Case_Approv__c> allCaseApprovals = ASF_CaseQueryHandler.getCaseApprovals(caseIds, new Set<String>(currentStageMap.values()));
            Map<Id, ASF_Case_Approv__c> caseToApprovalMap = new Map<Id, ASF_Case_Approv__c>();
            for(ASF_Case_Approv__c approvRec : allCaseApprovals){
                //Take only the first record per case
                if(!caseToApprovalMap.containsKey(approvRec.SR__c)){
                    caseToApprovalMap.put(approvRec.SR__c, approvRec);
                }
            }
            for(Case caseRec : currentCases){
                if(caseToApprovalMap.containsKey(caseRec.Id)){
                    caseIdToReturnFlagMap.put(caseRec.Id, caseToApprovalMap.get(caseRec.Id).Approval_Status__c == 'Approved');
                }else{
                    caseIdToReturnFlagMap.put(caseRec.Id, true);
                }
            }
    	}
        return caseIdToReturnFlagMap;        
    }
}