public class ASF_BulkCsvDownloadHelper {

    public static List<String> selectedRecIdList = new List<String>();
    public static ASF_Bulk_Row_to_Record_Converter_Config__mdt configMetaRec = new ASF_Bulk_Row_to_Record_Converter_Config__mdt();
    
    public static Object generateCSVFileWithData(String strConfigName, String strURL, String strSelectedRecords, String strListViewId) {
       
        String strCSVFields = '';
        List<Map<String,String>> resultSobjectList = new List<Map<String,String>>();
        List<String> columnNames = new List<String>();
        if(String.isNotBlank(strSelectedRecords) && strSelectedRecords.length() > 2){
            strSelectedRecords = strSelectedRecords.replace('[','').replace(']','').replace(' ','');
            selectedRecIdList = strSelectedRecords.split(',');
        }      
        configMetaRec = ASF_Bulk_Row_to_Record_Converter_Config__mdt.getInstance(strConfigName);
        strCSVFields = String.isNotBlank(configMetaRec.Fields_Name__c)? configMetaRec.Fields_Name__c:'';
        columnNames = strCSVFields.split(',');

        if(strListViewId.contains('Recent')){
            strListViewId = getRecentViewID(configMetaRec.SObject_Name__c);
        }

        /*
        // Query on Basis of Selected record id
        if(selectedRecIdList !=null && !selectedRecIdList.isEmpty()){
            resultSobjectList = performSOQL(configMetaRec,'',selectedRecIdList);
        }
        // Get the query of the List View
        else if(String.isNotBlank(strListViewId)){
            resultSobjectList = getListViewSOQL(configMetaRec.SObject_Name__c,strListViewId,strCSVFields);
        }
        */

        Type customType = Type.forName(configMetaRec.Apex_Class_Name__c);
        ASF_BulkCSVToRecordConverter converter = (ASF_BulkCSVToRecordConverter)customType.newInstance();
        resultSobjectList = converter.prepareDownloadTemplate(columnNames, configMetaRec.SObject_Name__c, strListViewId, selectedRecIdList);
        


        // returns on field names if no data is present
        if(resultSobjectList == null || resultSobjectList.isEmpty()){
            return strCSVFields;
        } 
       
        return resultSobjectList; 
    }
    
    /** Return the SOQL query for a given List view and Object Name */
    public static String getListViewSOQL(String strObjectName, String strListViewId){
        String query;
        List<Sobject> resultSobjectList = new List<Sobject>();
        HttpRequest req = new HttpRequest();
        String baseUrl = URL.getOrgDomainURL().toExternalForm();
        String endPoinURL = baseUrl+'/services/data/v50.0/sobjects/'+ strObjectName +'/listviews/'+ strListViewId +'/describe';
        req.setEndpoint(endPoinURL);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        Http http = new Http();
        HttpResponse response = http.send(req);
        if( response.getStatusCode() == 200 ) {
            Map<String, Object> tokenResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            query = (String) tokenResponse.get('query');
        }
        return query;
    }

    /*
    public static List<Sobject> getListViewSOQL(String strObjectName, String strListViewId, String strCSVFields){
        List<Sobject> resultSobjectList = new List<Sobject>();
        HttpRequest req = new HttpRequest();
        String baseUrl = URL.getOrgDomainURL().toExternalForm();
        String endPoinURL = baseUrl+'/services/data/v50.0/sobjects/'+ strObjectName +'/listviews/'+ strListViewId +'/describe';
        req.setEndpoint(endPoinURL);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        Http http = new Http();
        HttpResponse response = http.send(req);
        if( response.getStatusCode() == 200 ) {
            Map<String, Object> tokenResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            String query = (String) tokenResponse.get('query');
            if(String.isNotBlank(query)){
                system.debug('Original Query --> '+query);
                List<Sobject> lstSobject=performSOQL(configMetaRec,query,selectedRecIdList);
                if(lstSobject!= null && !lstSobject.isEmpty()){
                    resultSobjectList = lstSobject;
                }
                else{
                    resultSobjectList = null;
                }
            }
        }
        return resultSobjectList;
    }
    */
    
    public static List<Sobject> performSOQL(ASF_Bulk_Row_to_Record_Converter_Config__mdt objMdt, String strQuery, 
                                            List<String> selectedRecIdList){
        String strFinalQuery = '';
        String strAddFilterCriteria = '';
        String strScope = '';
        String baseUrl = URL.getOrgDomainURL().toExternalForm();
        String strFields = objMdt.Fields_Name__c ;
        String strObjectName = objMdt.SObject_Name__c;
        String strUserID = UserInfo.getUserId();
        String UserID = UserInfo.getUserId();
        List<String> fieldsList = new List<String>();
        List<Sobject> resultSobjectList = new  List<Sobject>();
        
        if(String.IsNotBlank(strFields)){
            fieldsList = strFields.split(',');
        }
        
        if(String.isNotBlank(objMdt.SOQL_Where_Clause__c)){
            strAddFilterCriteria = objMdt.SOQL_Where_Clause__c;
        } 
        system.debug('inside soql method');
        
        // If IDs are selected
        if(selectedRecIdList!=null && !selectedRecIdList.isEmpty()){
            String strWhereClause = ' WHERE ID IN:selectedRecIdList';
            if(String.isNotBlank(strAddFilterCriteria)){
                strWhereClause = strWhereClause + ' AND ' + strAddFilterCriteria;
            }
            strFinalQuery = 'Select '+ strFields + ' FROM ' + strObjectName + strWhereClause;
        }
        // If List view has filter condition
        else if(strQuery.contains('WHERE') ){
            String strWhereClause = '';
            //check filter criteria
            if(String.isNotBlank(strAddFilterCriteria)){
                strWhereClause =  strAddFilterCriteria;
            }

            //check list view query
            String strWhere2 = strQuery.substringAfter('WHERE');

            //add list view query and filter criteria 
            if(String.isNotBlank(strWhereClause)){
                strWhereClause = strWhereClause + ' AND '  + strWhere2  ;
            }

            //if no filter query just add list view query
            else{
                strWhereClause =  strWhere2;
            }
            if(strQuery.contains('USING SCOPE')){
                strScope = ' USING SCOPE ' + strQuery.substringBetween('SCOPE ',' ') + ' ';
            }
            strFinalQuery = 'Select '+ strFields + ' FROM ' + strObjectName + strScope + ' WHERE '+ strWhereClause ;     
        } 
        // If List view has no filter condition
        else{
        	String strFromClause = strQuery.substringAfter('FROM');
            String strQueryAfter = strFromClause.substringAfter(strObjectName);
            //String strScope = '';
            String strWhereClause= '';
            String strOrderBy = '';
           
            if(strQueryAfter.contains('SCOPE') && strQueryAfter.contains('ORDER BY')){
                strScope = ' USING SCOPE ' + strQueryAfter.substringBetween('USING SCOPE','ORDER BY');
                strOrderBy = ' ORDER BY ' + strQueryAfter.substringAfter('ORDER BY');
            }
            //Check Filter Query
            if(String.isNotBlank(strAddFilterCriteria)){
                strWhereClause =  ' WHERE '+strAddFilterCriteria + ' ' ;
            }
            
            // Forming Query Select <Fields> FROM <Sobject> USING SCOPE <strScope> WHERE <strWhereClause> ORDER BY <strOrderBy>
            strFinalQuery = 'Select '+ strFields + ' FROM ' + strObjectName + strScope + strWhereClause + strOrderBy;
        }
       
        // Assigns the Field value 
        resultSobjectList = Database.query(strFinalQuery);
        if(resultSobjectList != null && !resultSobjectList.isEmpty()){
            for(Sobject obj:resultSobjectList){

                //Assigns the Space for the  SOQL field whose value is Null so that the field is visible in CSV
                if(fieldsList!= null && !fieldsList.isEmpty()){
                    for(String strField : fieldsList){
                        strField = strField.trim();
                        if(obj.get(strField) == null /*&& !strField.containsIgnoreCase('date')*/){
                            obj.put(strField, ' ');
                        }
                    }
                }
            }
        }
        return resultSobjectList;
    }

    public static List<Sobject> downloadUploadResults(Id bulkHeaderId) {
        List<Sobject> resultSobjectList = new List<Sobject>();
        if(bulkHeaderId != null){
            resultSobjectList = [select Result_JSON_Data__c, JSON_Data__c from ASF_Bulk_Upload_Line_Item__c where 
                                Bulk_Upload_Header__c =: bulkHeaderId order by name asc];
        }
        return resultSobjectList;
    }
    
    private static String getRecentViewID(String strSobjectName){
        String strListViewId = '';
        List<ListView> lstRecentView = [SELECT Id, DeveloperName, SobjectType FROM ListView Where SobjectType =: strSobjectName 
                                       AND DeveloperName LIKE 'RecentlyViewed%'];
        if(lstRecentView!=null && !lstRecentView.isEmpty()){
            strListViewId = lstRecentView[0].Id;
        }
        return strListViewId;
    }
    
}