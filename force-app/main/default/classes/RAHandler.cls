public class RAHandler implements ASF_SRHandlerInterface {
    
    public void processSRData(Case caseObj){
     
     /* 	RA_Details__c raObject = [Select Id, Case_Type__c , Case_Subtype__c  from RA_Details__c 
                                  where Id =: caseObj.RA_Details__c];
       
       	CaseCategoryConfig__c ccc = [Select Id, Type__c, Sub_Type__c,CCC_External_Id__c 
                                     from CaseCategoryConfig__c 
                                     where CCC_External_Id__c =: caseObj.CCC_External_Id__c ];
        
       	try{
            raObject.Case_Type__c = ccc.Type__c;
            raObject.Case_Subtype__c = ccc.Sub_Type__c;
      		update raObject;
       	}
        catch(Exception e){
            throw e;
        }*/
    }
    public List<SObject> processSRDataBulk(List<Case> caseList,ASF_Case_Category_Config__c ccc){

		List<SObject> sObjectList = new List<SObject>();
        for(Case c:caseList){
          /*  RA_Details__c raInst = new RA_Details__c();
            raInst.Id = c.RA_Details__c;
            raInst.Case_Subtype__c = ccc.Sub_Type__c;
            raInst.Case_Type__c = ccc.Type__c;
            raInst.Case_Source__c = c.Source__c;
            sObjectList.add(raInst);  */
        }
        return sObjectList;
    }
    public void beforeInsertUpdateCaseData(List<Case> caseList){
        
    }

}