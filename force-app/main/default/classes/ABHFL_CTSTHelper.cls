/*********************************************************
*@Class        :  ABHFL_CTSTHelper
*@Author       :  Dhinesh Kumar T
*@Created Date :  12/25/2023
*@Last Modified:  01/11/2024
*@description  :  Class for ABHFL Specific Methods. 
*********************************************************/
public class ABHFL_CTSTHelper {

    public static void OpenStageOwnershipChange(List<Case> caseList, Map<Id, Case> oldCaseMap) {
        // List of valid subTypes
        List<String> validSubTypes = new List<String>{'hfl060', 'RRSDPRSHFC01','hfcrepaprod','RREPEMIONHFC','ROVEOVSSHFC','hfl029','AC123470','HFCRARGI'};

        for (Case caseRecord : caseList) {
           	String previousStage = (String) oldCaseMap.get(caseRecord.Id).get('Stage__c');
            String currentStage = (String) caseRecord.get('Stage__c');
            String subType = (String) caseRecord.get('CCC_External_Id__c');

            // Check if the previous stage was not 'Open', the current stage is 'Open',
            // and the sub_Type_Text__c is one of the valid subTypes
            if (!'Open'.equals(previousStage) && 'Open'.equals(currentStage) && validSubTypes.contains(subType) && caseRecord.Business_Unit__c=='ABHFL') {
                assignCaseToQueue(caseRecord);
            }
        }
    }

    public static void assignCaseToQueue(Case caseRecord) {
        String subType = (String) caseRecord.get('CCC_External_Id__c');
        List<String> emailFinancialSubTypes =  new List<String>{'hfcrepaprod','RREPEMIONHFC','ROVEOVSSHFC','hfl029'};
        List<String> emailNonFinancialSubTypes =  new List<String>{'hfl060','AC123470','HFCRARGI'};
        Group emailNonFinancialQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Email_Non_Financial_Team' WITH SECURITY_ENFORCED LIMIT 1 ];
        Group emailFinancialQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'ABHFL_Email_Financial_Team' WITH SECURITY_ENFORCED LIMIT 1 ];
        // assign the case to a queue here 
        if(emailNonFinancialSubTypes.contains(subType)){
            if(caseRecord.Source__c == ABHFL_Constants.BRANCH){
                caseRecord.OwnerId = caseRecord.CreatedById;
            }else{
                caseRecord.OwnerId = emailNonFinancialQueue.Id;
            }
            
        }
        if(emailFinancialSubTypes.contains(subType)){
            if(caseRecord.Source__c == ABHFL_Constants.BRANCH){
                caseRecord.OwnerId = caseRecord.CreatedById;
            }else{
                caseRecord.OwnerId = emailFinancialQueue.Id;
            }
            
        }
        
        // for RRSDPRSHFC01 - else{
           // caseRecord.OwnerId = emailNonFinancialQueue.Id;
        //}
    }
    public static Case assignCaseToBranch(Case caseRecord) {
        Case caseRec = [SELECT Id, OwnerId,AssetId FROM Case WHERE Id = :caseRecord.Id WITH SECURITY_ENFORCED];
		Asset relatedAsset = [SELECT Id, Branch__r.Branch_Queue_Id__c FROM Asset WHERE Id =: caseRec.AssetId];
        if (relatedAsset.Branch__r.Branch_Queue_Id__c != null) {
            caseRec.OwnerId = relatedAsset.Branch__r.Branch_Queue_Id__c;
        }

        return caseRec;
    }
    public static Boolean validatePayments(Case caseRecord) {
        Case queriedCase = [SELECT Id FROM Case WHERE Id = :caseRecord.Id LIMIT 1];
		List<ABHFL_Payment__c> payments = [SELECT Id, Realization_Status__c FROM ABHFL_Payment__c WHERE Case__c = :queriedCase.Id WITH SECURITY_ENFORCED];
		// Check if every payment record has Realization_Status__c equal to 'Cleared'
        for (ABHFL_Payment__c payment : payments) {
            if (payment.Realization_Status__c != 'Cleared') {
                return false; // If any payment record is not cleared, return false
            }
        }

        return true; // All payment records have Realization_Status__c as 'Cleared'
    }
    
    

    public static void executeSpecificIntegrations(List<Case> newCases){
        Set<String> c3ExternalIds = new Set<String>();
        Map<String, List<ASF_Integration__c>> uiCardIntegrationMap = new Map<String, List<ASF_Integration__c>>();

        for(case cs : newCases){
            c3ExternalIds.add(cs.CCC_External_Id__c);
        }
        // List<String> asfIntegrationNames = new List<String>{'ABHFL_ASFIntg_REKYC', 'ABHFL_ASFIntg_BitlyUrl'};
        List<ASF_Integration__c> specificIntegrations = [SELECT ID, Auto_Run_on_Load__c ,C3ExternalId__c, Display_Name__c ,Display_Order__c ,STP_API_Identifier__c,
        External_Id__c,Mandatory_At_Stage_Movement__c ,Processing_Class__c ,STP_Processing_Class__c, Type__c,
        UI_Component__c ,Visibility_Class__c ,When_to_Appear__c  FROM ASF_Integration__c WHERE C3ExternalId__c in : c3ExternalIds AND Type__c = 'UI Card' WITH SECURITY_ENFORCED];

        for(ASF_Integration__c asfCaseInteg : specificIntegrations){
            if(!uiCardIntegrationMap.containsKey(asfCaseInteg.C3ExternalId__c)){
                uiCardIntegrationMap.put(asfCaseInteg.C3ExternalId__c, new List<ASF_Integration__c>());
            }
            uiCardIntegrationMap.get(asfCaseInteg.C3ExternalId__c).add(asfCaseInteg);
        }

        for(Case cs : newCases){
            if(cs.Business_Unit__c == 'ABHFL' && cs.Technical_Source__c != 'API' && uiCardIntegrationMap.containsKey(cs.CCC_External_Id__c)){
                ASF_CaseFrameworkHelper.runIntegrations(cs, uiCardIntegrationMap.get(cs.CCC_External_Id__c));
            }
        }
    }

    public void prePopulateFields(List<Case> newCaseList) {

        prePopulateABHFL_Case_Detail_Fields(newCaseList);
    }

    public void prePopulateABHFL_Case_Detail_Fields(List<Case> newCaseList) {
        
        List<String> cccExternalIdList = new List<String>();
        Map<String,String> mapOfCaseDetIdToCcccExtId = new Map<String,String>();
        Map<String, Doc_Charge__mdt> mapOf_CCCExternalId_To_DocChargeRec = new Map<String, Doc_Charge__mdt>();

        for(Case csRec : newCaseList) {

            String bussUnit = csRec.Business_Unit__c;
            String cccExtId = csRec.CCC_External_Id__c;
            String abflCasDetId = csRec.ABHFL_Case_Detail__c;

            if(bussUnit == 'ABHFL') {
                mapOfCaseDetIdToCcccExtId.put(abflCasDetId, cccExtId);
                cccExternalIdList.add(cccExtId);
            } 
        }

        List<Doc_Charge__mdt> docChargeMdtLst = [SELECT id, Amount__c, CCC_External_Id__c
                                                FROM Doc_Charge__mdt
                                                WHERE CCC_External_Id__c =:cccExternalIdList];

        for(Doc_Charge__mdt docChrge : docChargeMdtLst) {
            mapOf_CCCExternalId_To_DocChargeRec.put(docChrge.CCC_External_Id__c, docChrge);
        }

        List<ABHFL_Case_Detail__c> abhfl_CaseDetail_List = [SELECT id, Payable_Charges__c
                                                            FROM ABHFL_Case_Detail__c
                                                            WHERE id in :mapOfCaseDetIdToCcccExtId.keyset()];

        for(ABHFL_Case_Detail__c csDet : abhfl_CaseDetail_List) {

            String csDetId = csDet.Id;
            String cccExternal = mapOfCaseDetIdToCcccExtId.get(csDetId);
            Decimal roiSwitchFee =  mapOf_CCCExternalId_To_DocChargeRec.containsKey(cccExternal) ? mapOf_CCCExternalId_To_DocChargeRec.get(cccExternal).Amount__c : 0;

            csDet.Payable_Charges__c = roiSwitchFee;
        }

        if(abhfl_CaseDetail_List.size() > 0) {
            update abhfl_CaseDetail_List;    
        }
    }

    public void callLitmusApi(List<Case> newCaseList, Map<Id, Case> oldCases) {
        
        ABHFL_LitmusApi litmusApiObj = new ABHFL_LitmusApi();
        Case newCaseRec = newCaseList[0];

        ASF_IntegrationsController.IntegrationWrapper result = litmusApiObj.evaluate(newCaseRec);
        system.debug('result--'+JSON.serialize(result));
        if(result.status == 'Success') {
            ASF_IntegrationsController.IntegrationWrapper resultOfRun = litmusApiObj.run(new ASF_Integration__c(), newCaseRec);
        }
    }

    public static Case createCases(String clientCode, String lan, String ccc, String source, String techSource, Id parentCaseId) {
        Case parentCase = [SELECT Id, Nature__c, AccountId FROM Case WHERE Id =: parentCaseId WITH SECURITY_ENFORCED];
        Case caseRecord = new Case();
        caseRecord.Business_Unit__c = 'ABHFL';
        caseRecord.Client_Code_Text__c = clientCode;
        caseRecord.Source__c = source;
        caseRecord.Technical_Source__c = techSource;
        caseRecord.CCC_External_Id__c = ccc;
        caseRecord.LAN__C = lan;
        caseRecord.parentId = parentCaseId;
        return caseRecord;
    }
    
    public static void insertCases(List<Case> caseList) {
        if(!caseList.isempty()){
             insert caseList;
        }
    }
}