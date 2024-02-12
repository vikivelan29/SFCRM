public class ASF_BulkDownloadVFController {
	
    public List<Case> selectedCasesList {get; set;}
    public String strCaseIds {get; set;}
    
    /****************************************************************************************************
     * @Description - StandardSetController Constructor
    *****************************************************************************************************/

    public ASF_BulkDownloadVFController(ApexPages.StandardSetController cntlr){
        selectedCasesList = cntlr.getSelected(); //get selected records from cases list view
        strCaseIds = '';
          
        //build list of ids string concatenated with comma  
           for(Case objCase : selectedCasesList){
            strCaseIds += objCase.Id + ',';                        
            }
            strCaseIds = strCaseIds.removeEnd(',');
        
   } 

}