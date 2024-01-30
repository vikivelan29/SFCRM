/*********************************************************
*@Class        :  ABHFL_CTSTHelper
*@Author       :  Dhinesh Kumar T
*@Created Date :  12/25/2023
*@Last Modified:  01/11/2024
*@description  :  Class for ABHFL Specific Methods. 
*********************************************************/
public without sharing class ABHFL_CTSTHelper {
    
    public static void executeSpecificIntegrations(List<Case> newCases){
        Set<String> c3ExternalIds = new Set<String>();
        Map<String, List<ASF_Integration__c>> uiCardIntegrationMap = new Map<String, List<ASF_Integration__c>>();

        for(case cs : newCases){
if(cs.Business_Unit__c == 'ABHFL' && cs.Technical_Source__c != 'API' ){
            c3ExternalIds.add(cs.CCC_External_Id__c);
}            
        }
        // List<String> asfIntegrationNames = new List<String>{'ABHFL_ASFIntg_REKYC', 'ABHFL_ASFIntg_BitlyUrl'};
        List<ASF_Integration__c> specificIntegrations = [SELECT ID, Auto_Run_on_Load__c ,C3ExternalId__c, Display_Name__c ,Display_Order__c ,STP_API_Identifier__c,
        External_Id__c,Mandatory_At_Stage_Movement__c ,Processing_Class__c ,STP_Processing_Class__c, Type__c,
        UI_Component__c ,Visibility_Class__c ,When_to_Appear__c  FROM ASF_Integration__c WHERE C3ExternalId__c in : c3ExternalIds AND Type__c = 'UI Card'];

        for(ASF_Integration__c asfCaseInteg : specificIntegrations){
            if(!uiCardIntegrationMap.containsKey(asfCaseInteg.C3ExternalId__c)){
                uiCardIntegrationMap.put(asfCaseInteg.C3ExternalId__c, new List<ASF_Integration__c>());
            }
            uiCardIntegrationMap.get(asfCaseInteg.C3ExternalId__c).add(asfCaseInteg);
        }

        for(Case cs : newCases){
            if(uiCardIntegrationMap.containsKey(cs.CCC_External_Id__c)){
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
        String businessUnit = newCaseRec.Business_Unit__c;
        
        if(businessUnit == 'ABHFL') {
            ASF_IntegrationsController.IntegrationWrapper result = litmusApiObj.evaluate(newCaseRec);
            if(result.status == 'Success') {
                ASF_IntegrationsController.IntegrationWrapper resultOfRun = litmusApiObj.run(new ASF_Integration__c(), newCaseRec);
            }
        }
    }

    public void populateFieldsInAfterContext(List<Case> newCaseList) {
        populateFieldsOfABHFL_CaseDetail(newCaseList);
    }

    public void populateFieldsOfABHFL_CaseDetail(List<Case> newCaseList) {
        
        List<String> caseDetIdList = new List<String>();
        List<ABHFL_Case_Detail__c> caseDetListToUpdate = new List<ABHFL_Case_Detail__c>();

        for(Case cs : newCaseList) {

            String technicalSource = cs.Technical_Source__c;
            String businessUnt = cs.Business_Unit__c;
            String csDetId = cs.ABHFL_Case_Detail__c;

            if(technicalSource == 'API' && businessUnt == 'ABHFL') {
                if(String.isNotBlank(csDetId)) {
                    caseDetIdList.add(csDetId);
                }
            }
        }

        List<ABHFL_Case_Detail__c> csDetList = [SELECT From_Year__c, To_Year__c, Financial_Year__c
                                                FROM ABHFL_Case_Detail__c
                                                WHERE id in :caseDetIdList];
        
        for(ABHFL_Case_Detail__c csDet : csDetList) {

            String fromYr = csDet.From_Year__c;
            String toYr   = csDet.To_Year__c;

            if(String.isNotBlank(fromYr) && String.isNotBlank(toYr)) {
                String lastTwoDigitOfToYr = toYr.right(2);
                csDet.Financial_Year__c = fromYr + '-' + lastTwoDigitOfToYr;
                caseDetListToUpdate.add(csDet);
            }
        }

        if(caseDetListToUpdate.size() > 0) {
            update caseDetListToUpdate;
        }

    }
    
}