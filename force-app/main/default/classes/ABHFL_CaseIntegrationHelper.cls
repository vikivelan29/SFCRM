/*********************************************************
*Class        :  ABHFL_CaseIntegrationHelper
*Author       :  Siddarth Jaitly
*Created Date :  28/11/2023
*Last Modified:  
*Description  :  Case Integration Trigger Helper for ABHFL LOB
*History        :
 Name                Date                  Change Description
 Siddarth Jaitly     28/11/2023            Initial
 Vishal Gangwar      05/01/2024            MultiLAN - eBot response processing(PR970457-271)
*********************************************************/
public with sharing class ABHFL_CaseIntegrationHelper {
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - eBotHandler
    * @param caseId - Case Record ID
    * @param ebotResponse - Ebot Response Wrapper
    * @return - void .
    * @Description - Processing Ebot Response
    *****************************************************************************************************************/   
    public static void eBotResponseHandler(String caseId,ABHFL_EbotWrapper.EbotResponseWrapper ebotResponse){
        
        ABHFL_Case_Detail__c caseDetails = new ABHFL_Case_Detail__c();
        caseDetails.Ebot_Owner_Full_Name__c  = ebotResponse.OWNERFULLNAME;
        caseDetails.Confidence_Score__c  = ebotResponse.CONFIDENCESCORE != null ? Decimal.valueof(ebotResponse.CONFIDENCESCORE) : 0;
       
       //Added By Vishal
        caseDetails.As_On_Date__c = ebotResponse.ASONDATE != null ? Date.valueof(ebotResponse.ASONDATE) : null;
        caseDetails.From_Date__c = ebotResponse.FROMDATE != null ? Date.valueof(ebotResponse.FROMDATE) : null;
        caseDetails.From_Year__c = ebotResponse.FROMYEAR != null ? String.valueof(ebotResponse.FROMYEAR) : '';
        caseDetails.To_Date__c = ebotResponse.TODATE != null ? Date.valueof(ebotResponse.TODATE) : null;
        caseDetails.To_Year__c = ebotResponse.TOYEAR != null ? String.valueof(ebotResponse.TOYEAR) : '';
        caseDetails.Disburstment_Type__c = ebotResponse.DISBURSTMENTTYPE;
        caseDetails.Is_Corrupted__c = ebotResponse.ISCORRUPTED;
        caseDetails.Is_Multilan__c = ebotResponse.ISMULTILAN;
        caseDetails.Is_Multiple_Date_Formate__c = ebotResponse.ISMULTIPLEDATEFORMATE;
        caseDetails.Is_Registred__c = ebotResponse.ISREGISTRED;
        caseDetails.Is_Regulator__c = ebotResponse.ISREGULATOR;
        caseDetails.Is_Repeat__c = ebotResponse.ISREPEAT;
        caseDetails.Is_Smt__c = ebotResponse.ISSMT;
        caseDetails.Is_Trail__c = ebotResponse.ISTRAIL;
        caseDetails.Lan_Comment__c = ebotResponse.LANCOMMENT;
        caseDetails.Unregistered_Category__c = ebotResponse.UNREGISTEREDCATEGORY;
       //End

        if(Schema.sObjectType.ABHFL_Case_Detail__c.isCreateable()){
            insert caseDetails;
        }

        Case caseRecord = new Case();
        caseRecord.Id = caseId;
        caseRecord.ABHFL_Case_Detail__c = caseDetails.Id;
        caseRecord.CCC_External_Id__c = ebotResponse.CASESUBTYPE;
        caseRecord.Comments = ebotResponse.COMMENT;
        caseRecord.RecordTypeId = ASF_Constants.RT_FRAMEWORK;

        if(ebotResponse.ISREGISTRED == 'Yes' && ebotResponse.ISREPEAT == 'Yes'){
            caseRecord.Technical_Source__c = 'LWC';
        }
        
       //Added By Vishal
        Map<String,Id> lanWithAssetIdMap = new Map<String,Id>();
        if(ebotResponse.LAN_NOS != null && ebotResponse.LAN_NOS.size() > 0){
            for(Asset ast : [SELECT Id,LAN__c FROM Asset WHERE LAN__c IN: ebotResponse.LAN_NOS WITH SECURITY_ENFORCED]){
                if(caseRecord.AssetId != null){
                    lanWithAssetIdMap.put(ast.LAN__c,ast.Id);
                }else{
                    caseRecord.AssetId = ast.Id;
                    ebotResponse.LAN_NOS.remove(ebotResponse.LAN_NOS.indexOf(ast.LAN__c));
                }
            }            
        }
       //End
       if(ebotResponse.ISREGISTRED == 'Yes'){
            ASF_TriggerSkipperUtility.markTriggerRun('Case');
            caseRecord.Stage__c = 'Resolved';
        }
        if(Schema.sObjectType.Case.isUpdateable()){
            update caseRecord;
        }
        /*ASF_Case_Category_Config__c categoryConfig = [Select Nature__c from ASF_Case_Category_Config__c 
                                                      where CCC_External_Id__c =: ebotResponse.CASESUBTYPE Limit 1];
        if(categoryConfig.Nature__c == 'Complaint'){
            caseRecord.MoveToNext__c = true;
            update caseRecord;
        }*/

        if(ebotResponse.LAN_NOS != null && ebotResponse.LAN_NOS.size() > 0){
            createMultipleCaseWithLAN(caseRecord.Id,caseDetails.Id,lanWithAssetIdMap,ebotResponse);
        }
    }

    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - createMultipleCaseWithLAN
    * @param parentCaseId - Parent Case Record ID
    * @param caseDetailsId - Case Detail Record ID
    * @param lanNoWithAssetIdMap - Map With Lan Number and Asset Id
    * @param ebotResponse - Ebot Response Wrapper
    * @return - void
    * @description - Creating Case with Multiple Lan number getting from Response
    *****************************************************************************************************************/
    private static void createMultipleCaseWithLAN(Id parentCaseId, Id caseDetailsId, Map<String,Id> lanNoWithAssetIdMap, ABHFL_EbotWrapper.EbotResponseWrapper ebotResponseWrp){
        
        ABHFL_CloneCase.createCloneCase(parentCaseId, caseDetailsId, lanNoWithAssetIdMap, ebotResponseWrp);
        
    }
}