/**
 * Interface to allow implement BU specific logic to convert the CSV rows into Sobjects
 */
public interface ASF_BulkCSVToRecordConverter {
    /** method to convert json rows to SObject records for framework to do the DML */
    ASF_BulkCaseProcessorUtility.ConvertionResult convertJSONRows(Map<Id, String> jsonRows);

    /** Method to prepare and return CSV template based on user selected template type
     * To get the SOQL for the listview, subscriber can use ASF_BulkCsvDownloadHelper.getListViewSOQL method
     */
    List<Map<String,String>> prepareDownloadTemplate(List<String> columnNames, String objectName, Id listViewId, List<String> selectedRecordIds);
    /** Method to prepare and return CSV template based on user selected template type
     * To get the SOQL for the listview, subscriber can use ASF_BulkCsvDownloadHelper.getListViewSOQL method
     */
    List<Map<String,String>> prepareCtstData(List<String> columnNames, String businessUnit);
}