/*********************************************************
*@Class        :  ABHFL_CloneCase 
*@Author       :  Vishal Gangwar
*@Created Date :  16/01/2024
*@Last Modified:  
*@description  :  Class for Create Multiple Case with Lan no
*********************************************************/
public With Sharing class ABHFL_CloneCase{
    
    /****************************************************************************************************************
    * @Function - fetchCommonFieldsToCopy
    * @param none
    * @return -  FieldListWrapper - The method returns a list of fields with their object API names 
                from the custom metadata ASF_CaseCloneCommonField__mdt without any filters applied.
    * @Description - This method fetches all the entries from ASF_CaseCloneCommonField__mdt custom metadata 
                in a wrapper containing field API name and related object API Name.
    *****************************************************************************************************************/
    
    public static FieldListWrapper fetchCommonFieldsToCopy(){
        FieldListWrapper outerWrap = new FieldListWrapper();
        outerWrap.fieldList = new List<FieldWrapper>();
        try {
            List<ASF_CaseCloneCommonField__mdt> commonFields = ASF_CaseCloneCommonField__mdt.getAll().values();
            for(ASF_CaseCloneCommonField__mdt field : commonFields){
                FieldWrapper wrap = new FieldWrapper();
                wrap.objectAPIName = field.ASF_ObjectAPIName__c;
                wrap.fieldAPIName = field.ASF_FieldAPIName__c;
                outerWrap.fieldList.add(wrap);
            }
            return outerWrap;
        } catch (Exception e) {
            return null;
        }
    }
    
    
    /****************************************************************************************************************
    * @Function - fetchCaseDetailsWithExtension
    * @param caseId - Input caseId
    * @param fieldsToCopy - Consolidated list of all the fields to be copied from original case to the cloned case.
    * @return - Case
    * @description - Fetching case data
    *****************************************************************************************************************/
   
    public static case fetchCaseDetails(List<FieldWrapper> fieldsToCopy, Id caseId){
        CaseDetailWrapper wrap = new CaseDetailWrapper();
        try {
            String caseQuery = 'SELECT ';
            
            for(FieldWrapper field : fieldsToCopy){
                if(field.objectAPIName == 'Case'){
                    caseQuery += String.escapeSingleQuotes(field.fieldAPIName)+', ';
                }
            }
            
            caseQuery += 'Id FROM Case WHERE Id =:caseId';

             Case caseRecord = Database.query(String.escapeSingleQuotes(caseQuery));
             return caseRecord;
        } catch (Exception e) {
           return null;
        }
    }
    
    
    /****************************************************************************************************************
    * @Function - createCloneCase
    * @param originalCaseId - Original Case Id which is being cloned.
    * @param cloneCaseRecord - All cloneable fields populated instance of the cloned Case.
    * @param clonedCaseExtnRecords - Map of case's extension object api name to cloneable fields populated instance of the extension record.
    * @return - Void
    * @Description - Copying Case from parent and Inserting multiple case with multiple lan
    *****************************************************************************************************************/
    
    Public static Void createCloneCase(Id parentCaseId, Id caseDetailsId, Map<String,Id> lanNoWithAssetIdMap, ABHFL_EbotWrapper.EbotResponseWrapper ebotResponseWrp){
        Try{
            List<Case> caseList = new List<Case>();
            
            ABHFL_CloneCase.FieldListWrapper flw = ABHFL_CloneCase.fetchCommonFieldsToCopy();
            
            case caseObj = ABHFL_CloneCase.fetchCaseDetails(flw.fieldList,parentCaseId);
             
            Case caseRec = [SELECT Id, CCC_External_Id__c, Origin, Nature__c, OwnerId, AccountId, BusinessHoursId, RecordTypeId,Stage__c
                                //, Customer_Friendly_Verbiage__c 
                                FROM Case WHERE Id =: parentCaseId LIMIT 1];
             /*List<ASF_Case_Category_Config__c> cccRecs = [SELECT Id, First_Stage__c,Reopen_Days__c, 
                                                        //Reopen_Days__c, Customer_Friendly_Name__c, 
                                                        ASF_Is_Cloneable__c, Type__c, Sub_Type__c  
                                                        FROM ASF_Case_Category_Config__c WHERE CCC_External_Id__c = :caseRec.CCC_External_Id__c];*/
            
            for(String lanNo : ebotResponseWrp.EBOTLAN){
                Case cloneCaseRecord = new Case ();
                cloneCaseRecord  = caseObj.clone(false,true,false,false);
                cloneCaseRecord.Cloned_From__c = caseRec.Id;
                //cloneCaseRecord.ParentId = parentCaseId;   //commenting line to avoid parenting of cloning case with parentcaseid
                cloneCaseRecord.ABHFL_Case_Detail__c = caseDetailsId;
                cloneCaseRecord.CCC_External_Id__c = ebotResponseWrp.CASESUBTYPE;
                cloneCaseRecord.Comments = ebotResponseWrp.COMMENT;
                cloneCaseRecord.Technical_Source__c = ABHFL_Constants.API;
                cloneCaseRecord.OwnerId = caseRec.OwnerId;
                cloneCaseRecord.Stage__c = ABHFL_Constants.OPEN;
                
                if(lanNoWithAssetIdMap.containsKey(lanNo)){
                    cloneCaseRecord.AssetId = lanNoWithAssetIdMap.get(lanNo);
                }
                
                caseList.add(cloneCaseRecord);
            }
    
            if(!caseList.isEmpty() && Schema.sObjectType.Case.isCreateable()){
                INSERT caseList;
            }
        }Catch(Exception e){
            System.debug('Error=='+e.getMessage());
        }
    }
    
    Public class FieldWrapper{
        public String objectAPIName;
        public String fieldAPIName;
    }

    Public class FieldListWrapper{
        public List<FieldWrapper> fieldList;
        public String messageIfListIsEmpty;
    }
    
    Public class CaseDetailWrapper{
        public Case caseRecord;
        public Map<String, SObject> extnRecords;
        public String messageIfAny;
        public Boolean resultFlag;
    }
    
}