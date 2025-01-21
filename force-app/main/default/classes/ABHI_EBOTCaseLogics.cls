/*********************************************************
*Class        :  ABHI_EBOTCaseLogics
*Author       :  Shubham Sinha 
*Created Date :  12/11/2024
*@description  :  ABHI_EBOTCaseLogics updates case and Case details field 
*********************************************************/
public class ABHI_EBOTCaseLogics {
/****************************************************************************************************************
* @param  caseId
* @description - Updates the fields of ABHI Case Detail and Case object.
*****************************************************************************************************************/ 
    public static void updateCaseExtension(String caseId, UpdateCaseWrapper objResponseBody ){
        List<ABHI_Case_Detail__c > lstInsertAbhiCaseDetail = new List<ABHI_Case_Detail__c>();
        String insertedId;
        if(String.isNotBlank(caseId) && objResponseBody!=null ){
            ABHI_Case_Detail__c objExt = new ABHI_Case_Detail__c();
            lstInsertAbhiCaseDetail.add(objExt);        
        }
         if(lstInsertAbhiCaseDetail.size() > 0){
            Database.SaveResult[] insertResult = Database.insert(lstInsertAbhiCaseDetail,false); 
                for (Database.SaveResult sr : insertResult) {
                    if (sr.isSuccess()) {
                        insertedId = sr.getId();
                    }
                 }
            updateCase(caseId,insertedId,objResponseBody);
          }
    }
   /****************************************************************************************************************
    * @param   caseId 
   * @param   caseDetailId 
   * @param   objResponseBody
    * @description - Updates the fields of  Case object according to ebot response.
    *****************************************************************************************************************/ 
    public static void updateCase(String caseId, String caseDetailId ,UpdateCaseWrapper objResponseBody){
        List<Case>lstCase = new List<Case>();
         string policyNumber ;
        System.debug('@@@@caseId'+caseId+' '+caseDetailId);
        if(String.isNotBlank(caseId) && String.isNotBlank(caseDetailId) && objResponseBody!=null ){
            List<Asset> recAsset;
            if(String.isNotBlank(objResponseBody.UpdateCase.UpdateCaseInput.PolicyNumber)){ 
                            policyNumber = objResponseBody.UpdateCase.UpdateCaseInput.PolicyNumber;
                //recAsset = [SELECT ID,LAN__c ,Policy_No__c FROM ASSET WHERE LAN__c =:policyNumber OR Policy_No__c =:policyNumber WITH SYSTEM_MODE LIMIT 1];
            }
           Case objCase = new Case();
            objCase.Id = caseId;
            objCase.ABHI_Case_Detail__c = caseDetailId;
            objCase.CCC_External_Id__c = objResponseBody.UpdateCase.UpdateCaseInput.CASESUBTYPECODE;
            objCase.Sent_to_EBOT__c  = TRUE;
            objCase.LAN__c =  String.isNotBlank(policyNumber)? policyNumber : '';
            //objCase.Client_Code_Text__c = objResponseBody.CUSTOMERNO != null ? objResponseBody.CUSTOMERNO : '';
            if(recAsset!=null && recAsset.size()>0){
                //objCase.AssetId = recAsset[0].Id;
            }
                     System.debug('@@@@lstCase2'+lstCase);
            objCase.RecordTypeId = ASF_Constants.RT_FRAMEWORK;
                     System.debug('@@@@lstCase3'+lstCase);
            lstCase.add(objCase);
        }
         System.debug('@@@@lstCase'+lstCase);
         if(!lstCase.isEmpty()){
                      System.debug('@@@@lstCase1'+lstCase);
           Database.SaveResult[] updateResult = Database.update(lstCase,false); 
             
             System.debug('@@@@updateResult'+updateResult);
            //System.debug('updateResultCase'+ updateResult[0].getId());      
            //System.debug('updateResultCaseerrr'+updateResult[0].getErrors()); 
        }
    }
    public class UpdateCaseWrapper {
        public UpdateCase UpdateCase { get; set; }
    }
    public class UpdateCase {
        public UpdateCaseInput UpdateCaseInput { get; set; }
        public Table table { get; set; }
    }

    public class UpdateCaseInput {
        public String CALLERCALLEE { get; set; }
        public String CASENO { get; set; }
        public String CASESUBTYPECODE { get; set; }
        public String CASETYPECODE { get; set; }
        public String CONFSCORE { get; set; }
        public String ISSUCCESS { get; set; }
        public String AlternateContact { get; set; }
        public String PrimaryContact { get; set; }
        public String Email { get; set; }
        public String NomineeName { get; set; }
        public String NomineeRelationship { get; set; }
        public String NomineeContact { get; set; }
        public String PanNo { get; set; }
        public String AadharNo { get; set; }
        public String Country { get; set; }
        public String InternationalContactNo { get; set; }
        public String InternationalAddress { get; set; }
        public String PolicyNumber { get; set; }
        public string CancellationDate { get; set; }
        public String CancellationReason { get; set; }
        public Boolean SendEmail { get; set; }
    }

    public class Table {
        public List<EmailInput> EmailInput { get; set; }
    }

    public class EmailInput {
        public List<AttachmentData> AttachmentData { get; set; }
        public String DESCRIPTION { get; set; }
        public String SUBJECT { get; set; }
        public String ToEmailId { get; set; }
    }

    public class AttachmentData {
        public String ATTACHEMNTBODY { get; set; }
        public String ATTACHEMNTEXT { get; set; }
        public String ATTACHEMNTFILENAME { get; set; }
    }
}