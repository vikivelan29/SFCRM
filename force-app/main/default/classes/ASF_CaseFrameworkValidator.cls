/**
* Class For Validator Methods of Framework related to 
* Verification - Validating various rules and completions
*/
public with sharing class ASF_CaseFrameworkValidator {
    
    /**
    * Evaluates a Case Rule, by evaluating eacj Rule Entry
    * for the provided condition and the data used from case
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
                    if(fieldList[0].contains('__r')){
                        sobject rs = caseRecord.getSobject(fieldList[0]);
                        caseRecordValue = rs == null ? null :  String.valueOf(rs.get(fieldList[1]));
                    }
                }else{
                    caseRecordValue = '0';
                }
            }
            else{
                caseRecordValue = String.valueOf(caseRecord.get(cre.Field_Api_Name__c));
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
                            caseRecordValue = caseRecordValue==null?'':caseRecordValue;
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
                            comparisonResult = comparsonValue.indexOf(caseRecordValue) == -1 ? true:false;
                        }
                        when 'in'{
                            //split the string by comma -> check if any string prensent -> true -> else false
                            comparisonResult = comparsonValue.indexOf(caseRecordValue) != -1 ? true:false;
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
    */
    public static Boolean validateChecklists(Case currentCase){
        
        // Get Incomplete, Mandatory Checklist from Query Handler for this Case and Stage
        List<ASF_Checklist__c> incompleteCasesChecklists 
            = ASF_CaseQueryHandler.getIncompleteCaseChecklists(new Set<Id>{currentCase.Id}, new Set<String>{currentCase.Stage__c});
        return (incompleteCasesChecklists.size() == 0);
    }

    public static String validateValidations(Case currentCase, ASF_Case_Stage_Config__c currentStageConfig){
        List<ASF_Case_Rule__c> allCaseRules = ASF_CaseQueryHandler.getCaseRuleWithHierarchy(new Set<String>{currentCase.CCC_External_Id__c});
        
        List<ASF_Case_Rule__c> caseRulesForCurrentStage = new List<ASF_Case_Rule__c>();
        for(ASF_Case_Rule__c caseRule : allCaseRules){
            if(caseRule.Case_Stage_Config__c == currentStageConfig.Id){
                caseRulesForCurrentStage.add(caseRule);
            }
        }

        return ASF_CaseFrameworkHelper.runValidationRules(currentCase, caseRulesForCurrentStage);
    }
    
    /**
    * Validate if Incomplete Checklists are present
    * For this Case at this stage
    */
    public static Boolean validateTasks(Case currentCase){
        
        List<Task> incompleteTaskslists 
            = ASF_CaseQueryHandler.getIncompleteCaseTasks(new Set<Id>{currentCase.Id}, new Set<String>{currentCase.Stage__c});
        return (incompleteTaskslists.size() == 0);
    }
    
    /**
    * Validates if all Case Integrations have been Successful
    * Returns a String of Names of Integrations which are not successful (for error reporting)
    * Else, returns the string 'Success'
    */
    public static String validateIntegrations(Case currentCase, ASF_Case_Stage_Config__c currentStageConfig){
        // Get Incomplete, Mandatory Integrations from Query Handler for this
        String result = 'Success';
        Map<String, ASF_Integration__c> asfIntExtIds = new Map<String, ASF_Integration__c>();
        Map<String, boolean> caseIntSuccessMap = new Map<String, boolean>();
        
        if(currentStageConfig != null){
            Id currentStageConfigIdVal = currentStageConfig.Id;
            List<ASF_Integration__c> mandatoryIntegrations = ASF_CaseQueryHandler.getIntegrationsFromConfig(new Set<Id>{currentStageConfig.Id});
            
            
            
            for (ASF_Integration__c mandatoryInt :  mandatoryIntegrations){
                asfIntExtIds.put(mandatoryInt.External_Id__c, mandatoryInt);
            }
        }
        
        
        if(asfIntExtIds.size() >0){
            
            // Get Case Integration Records for the above Integrations, to Determin if Validated Successfully
            List<ASF_Case_Integration__c> caseIntegrations = 
                ASF_CaseQueryHandler.getCaseRelatedIntegrations(asfIntExtIds.keySet(), new Set<Id>{currentCase.Id});
            system.debug('asfIntExtIds.keySet()--'+asfIntExtIds.keySet()+currentCase.Id);
            system.debug('result asfIntExtIds--'+caseIntegrations);
            for(ASF_Case_Integration__c caseInt : caseIntegrations){
                
                if(!caseIntSuccessMap.containsKey(caseInt.Integration_Ext_Id__c)){
                    caseIntSuccessMap.put(caseInt.Integration_Ext_Id__c, caseInt.Is_Validation_Success__c);
                }
            } 
            
            List<String> invalidIntegrations = new List<String>();
            for(string extId : asfIntExtIds.keySet()){
                
                if(!caseIntSuccessMap.containsKey(extId) ||  !caseIntSuccessMap.get(extId)){
                    invalidIntegrations.add(asfIntExtIds.get(extId).Display_Name__c);
                }
            }
            
            if(invalidIntegrations.size() > 0){
                result = String.join(invalidIntegrations, ',');
            }
        }
        
        return result;
    }

    /**
     * Validates if the Case Approval, if any, is Approved for
     * the stage movement
     */
    public static Boolean validateApprovals(Case currentCase){
        
        List<ASF_Case_Approv__c> allCaseApprovals 
            = ASF_CaseQueryHandler.getCaseApprovals(new Set<Id>{currentCase.Id}, new Set<String>{currentCase.Stage__c});
        
        if(allCaseApprovals.size() == 0 || allCaseApprovals[0].Approval_Status__c == 'Approved'){
            return true;
        }

        return false;
        
    }
}