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
        UI_Component__c ,Visibility_Class__c ,When_to_Appear__c  FROM ASF_Integration__c WHERE C3ExternalId__c in : c3ExternalIds AND Type__c = 'UI Card' WITH SECURITY_ENFORCED];

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

}