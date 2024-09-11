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
    //public static Set<String> stpList = new Set<String>{'QLOANDUSNDC','hfl004','hfl042','hfl037','hfl078','hfl071','hfl005','hfl073','QLOANDRSTAWEITHFCUSNDC'};
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - eBotHandler
    * @param caseId - Case Record ID
    * @param ebotResponse - Ebot Response Wrapper
    * @return - void .
    * @Description - Processing Ebot Response
    *****************************************************************************************************************/   
    public static void eBotResponseHandler(String caseId,ABHFL_EbotWrapper.EbotResponseWrapper ebotResponse){
        
        List<String> validSubTypesForMovetoNext = new List<String>{'hfl069','RRESRONTHFC','RRESROONHFC','RLOAPRONHFC','REFCL001'};
        ABHFL_Case_Detail__c caseDetails = new ABHFL_Case_Detail__c();
        caseDetails.Ebot_Owner_Full_Name__c  = ebotResponse.OWNERFULLNAME;
        caseDetails.Confidence_Score__c  = ebotResponse.CONFIDENCESCORE != null ? Decimal.valueof(ebotResponse.CONFIDENCESCORE) : 0;
       
       //Added By Vishal
        caseDetails.As_On_Date__c = String.isNotBlank(ebotResponse.ASONDATE) ? Date.valueof(ebotResponse.ASONDATE) : null;
        caseDetails.From_Date__c = String.isNotBlank(ebotResponse.FROMDATE) ? Date.valueof(ebotResponse.FROMDATE) : null;
        caseDetails.From_Year__c = ebotResponse.FROMYEAR;
        caseDetails.To_Date__c = String.isNotBlank(ebotResponse.TODATE)? Date.valueof(ebotResponse.TODATE) : null;
        caseDetails.To_Year__c = ebotResponse.TOYEAR;
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
        //caseDetails.Skip_Dedupe__c = true;
       //End
        if(String.isNotBlank(ebotResponse.CASESUBTYPE)){
            if(ebotResponse.ISREGISTRED == 'No'){
                    caseDetails.Is_FTR__c = true;
                }
                if(Schema.sObjectType.ABHFL_Case_Detail__c.isCreateable()){
                    insert caseDetails;
                }
                List<ASF_Case_Category_Config__c> cccList = [SELECT Id
                                                        FROM ASF_Case_Category_Config__c 
                                                        WHERE CCC_External_Id__c = :ebotResponse.CASESUBTYPE AND Business_Unit__c = 'ABHFL'];
                Case caseRecord = new Case();
                caseRecord.Id = caseId;
                caseRecord.ABHFL_Case_Detail__c = caseDetails.Id;
                caseRecord.CCC_External_Id__c = ebotResponse.CASESUBTYPE;
                caseRecord.Comments = ebotResponse.COMMENT;
                if(!cccList.isEmpty()){
                    //Valid External Id provided, hence convert.
                    caseRecord.RecordTypeId = ASF_Constants.RT_FRAMEWORK;
                    caseRecord.Skip_Dedupe__c = true;
                }

                if( ebotResponse.ISREPEAT == 'Yes'){
                    caseRecord.Technical_Source__c = 'LWC';
                }
                
            //Added By Vishal
                Map<String,Id> lanWithAssetIdMap = new Map<String,Id>();
                if(ebotResponse.EBOTLAN != null && ebotResponse.EBOTLAN.size() > 0){
                    for(Asset ast : [SELECT Id,LAN__c FROM Asset WHERE LAN__c IN: ebotResponse.EBOTLAN WITH SECURITY_ENFORCED]){
                        if(caseRecord.AssetId != null){
                            lanWithAssetIdMap.put(ast.LAN__c,ast.Id);
                        }else{
                            caseRecord.AssetId = ast.Id;
                            ebotResponse.EBOTLAN.remove(ebotResponse.EBOTLAN.indexOf(ast.LAN__c));
                        }
                    }            
                }
            //End
            if(ebotResponse.ISREGISTRED == 'No'){
                    caseRecord.Attachment_Status__c ='NA';
                    caseRecord.Technical_Source__c = 'API';
                }
                if(Schema.sObjectType.Case.isUpdateable()){
                    update caseRecord;
                }
                        Case caseRec = [SELECT Id,RecordTypeId,Is_Duplicate__c,CCC_External_Id__c,Stage__c,MoveToNext__c FROM Case WHERE Id =: caseRecord.Id];
                //Do rest of the things only if Case was converted to Framework
                if(caseRec.RecordTypeId == ASF_Constants.RT_FRAMEWORK){
                //Added by Dhinesh for Preclosure - when categorized land on next stage.
                if(validSubTypesForMovetoNext.contains(caseRecord.CCC_External_Id__c) && !caseRec.Is_Duplicate__c && caseRec.Stage__c !='Duplicate'){
                    List<ASF_Checklist__c> paymentChecklists = [SELECT Id, Status__c FROM ASF_Checklist__c WHERE Case__c = :caseRec.Id AND Label__c = 'Create Payment' LIMIT 1];
                    if (!paymentChecklists.isEmpty()) {
                        // Checklist found, update checklist status to 'Completed'
                        ASF_Checklist__c paymentChecklist = paymentChecklists[0];
                        paymentChecklist.Status__c = 'Completed';
                        update paymentChecklist;
                    }
                    caseRec.MoveToNext__c = TRUE;
                    caseRec.typeSubTypeMismatch__c=false;
                    update caseRec;
                } 
                        /*ASF_Case_Category_Config__c categoryConfig = [Select Nature__c from ASF_Case_Category_Config__c 
                                                            where CCC_External_Id__c =: ebotResponse.CASESUBTYPE Limit 1];
                if(categoryConfig.Nature__c == 'Complaint'){
                    caseRecord.MoveToNext__c = true;
                    update caseRecord;
                }*/
                if(ebotResponse.ISREGISTRED == 'No' && !caseRec.Is_Duplicate__c && caseRec.Stage__c !='Duplicate'){
                    caseRecord.Stage__c ='Resolved';
                    update caseRecord;
                }

                if(ebotResponse.EBOTLAN != null && ebotResponse.EBOTLAN.size() > 0){
                    createMultipleCaseWithLAN(caseRecord.Id,caseDetails.Id,lanWithAssetIdMap,ebotResponse);
                }
            }
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
