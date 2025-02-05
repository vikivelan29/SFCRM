public class ASF_BulkDownloadVFController {

    public List<sObject> selectedRecordsList {get; set;}
    public String strRecIds {get; set;}
    
    /****************************************************************************************************
     * @Description - StandardSetController Constructor
    *****************************************************************************************************/

    public ASF_BulkDownloadVFController(ApexPages.StandardSetController cntlr){
        selectedRecordsList = cntlr.getSelected(); //get selected records from cases list view
        strRecIds = '';
          
        //build list of ids string concatenated with comma  
           for(sObject obj : selectedRecordsList){
            strRecIds += obj.Id + ',';                        
            }
            strRecIds = strRecIds.removeEnd(',');
        
   } 

}