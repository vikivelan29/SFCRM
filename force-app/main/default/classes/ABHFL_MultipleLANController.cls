/*********************************************************
*Class        :  ABHFL_NDCSTPHandler
*Author       :  Siddarth Jaitly
*Created Date :  09/01/2023
*Last Modified:  09/01/2023
*Description  :  Class for Multiple LAN 
*********************************************************/
public with sharing class ABHFL_MultipleLANController {
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - getAssetRecords
    * @param recId - Case record Id from Framework.
    * @return - List<Asset>.
    * @Description - Invoked from the abhfl_MultipleLan LWC, this method fetches Asset Records related to the Case Customer.
    *****************************************************************************************************************/
    @AuraEnabled
    public static MultipleLanWrapper getLanDataAndMetadata(string recId){
        try {
            MultipleLanWrapper lanWrapper = new MultipleLanWrapper();
            Case caseRecord = [Select id,CCC_External_Id__c,AccountId from Case where id =: recId WITH SECURITY_ENFORCED];
            ABHFL_Multiple_LAN__mdt lanMetadata = ABHFL_Multiple_LAN__mdt.getInstance(caseRecord.CCC_External_Id__c);
            ABHFL_Multiple_LAN__mdt childLanMetadata = ABHFL_Multiple_LAN__mdt.getInstance(caseRecord.CCC_External_Id__c+'_Detail');
            if(lanMetadata != null){
                lanWrapper.displayMultipleLan = true;
                lanWrapper.columnData = getColumnData(lanMetadata,false);
                if(childLanMetadata != null){
                    lanWrapper.childColumnData = getColumnData(childLanMetadata,true);
                }
                lanWrapper.assetDetailRecords = getAssetDetailRecords(lanMetadata,childLanMetadata,recId);
            }
            return lanWrapper;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static List<ColumnWrapper> getColumnData(ABHFL_Multiple_LAN__mdt lanMetadata, Boolean isChildTable){
        List<ColumnWrapper> columnList = new List<ColumnWrapper>();
        List<String> sfFieldList = new List<String>();
        sfFieldList = String.isNotBlank(lanMetadata.Asset_Fields__c) ? lanMetadata.Asset_Fields__c.split(',') : sfFieldList;

        Map<String,Schema.SObjectField> fieldSchemaMap = new Map<String,Schema.SObjectField>();
        if(isChildTable){
            fieldSchemaMap = Schema.ABHFL_Asset_Detail__c.SObjectType.getDescribe().fields.getMap();
        }else {
            fieldSchemaMap = Schema.Asset.SObjectType.getDescribe().fields.getMap();
        }

        if(sfFieldList != null && sfFieldList.size() > 0){
            for(String field : sfFieldList){
                ColumnWrapper column = new ColumnWrapper();
                Schema.DescribeFieldResult fieldResult = fieldSchemaMap.get(field).getDescribe();
                column.label = fieldResult.getLabel();
                if(isChildTable){
                    column.name = field;
                } else {
                    column.name = 'asset.'+field;
                }
                column.type = String.valueof(fieldResult.getType());
                column.isEditable = false;
                columnList.add(column);         
            }
        }

        List<String> intFieldList = new List<String>();
        intFieldList = String.isNotBlank(lanMetadata.Asset_Detail_Fields__c) ? lanMetadata.Asset_Detail_Fields__c.split(',') : intFieldList;
        fieldSchemaMap = Schema.ABHFL_Asset_Detail__c.SObjectType.getDescribe().fields.getMap();
        if(intFieldList != null && intFieldList.size() > 0){
            for(String field : intFieldList){
                ColumnWrapper column = new ColumnWrapper();
                Schema.DescribeFieldResult fieldResult = fieldSchemaMap.get(field).getDescribe();
                column.label = fieldResult.getLabel();
                column.name = field;
                column.type = String.valueof(fieldResult.getType());
                column.isEditable = false;
                columnList.add(column);       
            }
        }

        List<String> editableFieldList = new List<String>();
        editableFieldList = String.isNotBlank(lanMetadata.Asset_Detail_Editable_Fields__c) ? lanMetadata.Asset_Detail_Editable_Fields__c.split(',') : editableFieldList;
        fieldSchemaMap = Schema.ABHFL_Asset_Detail__c.SObjectType.getDescribe().fields.getMap();
        if(editableFieldList != null && editableFieldList.size() > 0){
            for(String field : editableFieldList){
                ColumnWrapper column = new ColumnWrapper();
                Schema.DescribeFieldResult fieldResult = fieldSchemaMap.get(field).getDescribe();
                column.label = fieldResult.getLabel();
                column.name = field;
                column.type = String.valueof(fieldResult.getType());
                column.isEditable = true;
                if(column.type == 'PICKLIST'){
                    List < Schema.PicklistEntry > pickListValues = fieldSchemaMap.get(field).getDescribe().getPickListValues();
                    List<PicklistWrapper> enteriesWrapper = new List<PicklistWrapper>();
                    for (Schema.PicklistEntry entry : pickListValues) {
                        PicklistWrapper entryWrapper = new PicklistWrapper();
                        entryWrapper.label = entry.getLabel();
                        entryWrapper.value = entry.getValue();
                        enteriesWrapper.add(entryWrapper);
                    }
                    column.options = enteriesWrapper;
                }
                columnList.add(column);       
            }
        }
        return columnList;
    }

    public static List<AssetDetailWrapper> getAssetDetailRecords(ABHFL_Multiple_LAN__mdt lanMetadata,ABHFL_Multiple_LAN__mdt childLanMetadata,String recId){
        List<AssetDetailWrapper> assetDetailRecords = new List<AssetDetailWrapper>();
        string queryStr = 'Select id,Account.Client_Code__c,'+String.escapeSingleQuotes(lanMetadata.Asset_Fields__c) + ' from Asset where AccountId in (Select AccountId from Case where id =\''+String.escapeSingleQuotes(recId)+ '\')';
        List<sObject> assetRecords = Database.Query(queryStr);
        string assetDetailQueryStr = 'Select id,Asset__c';
        if(String.isNotBlank(childlanMetadata.Asset_Detail_Fields__c)){
            assetDetailQueryStr = assetDetailQueryStr + ',' + String.escapeSingleQuotes(childlanMetadata.Asset_Detail_Fields__c);
        }
        if(String.isNotBlank(childlanMetadata.Asset_Detail_Editable_Fields__c)){
            assetDetailQueryStr = assetDetailQueryStr + ',' + String.escapeSingleQuotes(childlanMetadata.Asset_Detail_Editable_Fields__c);
        }       
        assetDetailQueryStr = assetDetailQueryStr + ' from ABHFL_Asset_Detail__c where Case__c =\''+String.escapeSingleQuotes(recId)+'\'';
        List<sObject> assetDetails = Database.Query(assetDetailQueryStr);
        Map<String,ABHFL_Asset_Detail__c> assetIdMap = new Map<String,ABHFL_Asset_Detail__c>();
        for(ABHFL_Asset_Detail__c assetDetail : (List<ABHFL_Asset_Detail__c>)assetDetails){
            assetIdMap.put(assetDetail.Asset__c,assetDetail);
        }
        for(Asset rec : (List<Asset>)assetRecords){
            AssetDetailWrapper assetDetailWrap = new AssetDetailWrapper();
            if(assetIdMap.containsKey(rec.Id)){
                assetDetailWrap.detail = assetIdMap.get(rec.Id);
            }else{
                ABHFL_Asset_Detail__c detailRec = new ABHFL_Asset_Detail__c();
                detailRec.Asset__c = rec.Id;
                detailRec.LAN__c = rec.LAN__c;
                assetDetailWrap.detail = detailRec;
            }
            assetDetailWrap.asset = rec;
            assetDetailRecords.add(assetDetailWrap);
        }
        return assetDetailRecords;
    }
    @AuraEnabled
    public static ABHFL_Asset_Detail__c fetchAssetDetailsExt(Asset assetRecord,String caseRecId){
        try{
            ABHFL_DataServiceDetailsController.A3SSummaryData apiResponse = ABHFL_DataServiceDetailsController.executeDataServiceCallout();
            ABHFL_Asset_Detail__c assetDetail = dataServiceConverter(apiResponse,assetRecord,caseRecId);
            return assetDetail;
        }catch (Exception e) {
            throw e;//new AuraHandledException(e.getMessage());
        }
    }

    public static ABHFL_Asset_Detail__c dataServiceConverter(ABHFL_DataServiceDetailsController.A3SSummaryData apiResponse,Asset assetRecord,String caseRecId){
        ABHFL_DataServiceDetailsController.LoanStatusRow loanStatusRow = apiResponse.Summary_Data[0].Loan_Status.rows[0];
        ABHFL_DataServiceDetailsController.LoanInfoRow loanInfoRow = apiResponse.Summary_Data[0].loan_info.rows[0];
        ABHFL_Asset_Detail__c assetDetail = new ABHFL_Asset_Detail__c();
        assetDetail.Product__c = loanStatusRow.PRODUCT;
        assetDetail.Last_Repricing_Date__c = Date.valueof(loanStatusRow.LAST_REPRICING).daysBetween(System.Today()) < 180 ? 'Last repricing <6 months' : 'Last repricing >6 months';
        assetDetail.Is_Restructured__c = loanStatusRow.RESTRUCTURED == 'Yes'? 'Re-structured Not Done' : 'Re-structured Done';
        assetDetail.Bounce__c = Decimal.valueOf(loanStatusRow.BOUNCE) > 0 ? 'Bounce > 0' : 'Bounce < 0';
        assetDetail.Is_PDD__c = loanStatusRow.PDD == 'Yes'? 'PDD Pending' : 'PDD Not Pending';
        assetDetail.Is_NACH__c = loanStatusRow.NACH == 'Yes'? 'NACH Registered' : 'NACH Not Registered';
        assetDetail.Loan_Status__c = loanStatusRow.LOANSTATUS;
        assetDetail.Constitution__c = loanStatusRow.CONSTITUTION;
        assetDetail.Fixed_Period__c = Decimal.valueOf(loanStatusRow.FixedPeriod) > 0 ? 'Fixed Period > 0' : '';
        assetDetail.VAN__c = loanStatusRow.VAN;
        assetDetail.MOB__c = Date.valueof(loanStatusRow.MOB).daysBetween(System.Today()) < 180 ? 'MOB < 6 months' : 'MOB > 6 months';
        assetDetail.Account_Status__c = loanStatusRow.LOANSTATUS != 'Standard' ? 'Not Standard' : 'Standard';
        assetDetail.Amount_Overdue__c = Decimal.valueof(loanInfoRow.AMOUNT_OVERDUE);
        assetDetail.Overdues__c = assetDetail.Amount_Overdue__c > 0 ? 'Overdue Pending' : 'No Overdue Pending';
        assetDetail.Current_Balance__c = Decimal.valueof(loanInfoRow.CURRENT_BALANCE);
        assetDetail.LAN__c = assetRecord.LAN__c;//loanInfoRow.LOAN_ACCOUNT_NUMBER;
        assetDetail.Interest_Rate__c = Decimal.valueof(loanInfoRow.INTEREST_RATE.Left(4));
        assetDetail.ARR__c = Decimal.valueof(loanStatusRow.BPLR.Left(4));
        system.debug('assetRecord---->'+assetRecord);
        assetDetail.Asset__c = assetRecord.Id;
        assetDetail.Case__c = caseRecId;
        return assetDetail;
    }

    @AuraEnabled
    public static List<ABHFL_Asset_Detail__c> upsertRecords(String assetDetails,String recId){
        try {
            system.debug(assetDetails);
            List<ABHFL_Asset_Detail__c> assetRecords = (List<ABHFL_Asset_Detail__c>)JSON.deserialize(assetDetails,List<ABHFL_Asset_Detail__c>.class);
            system.debug(assetRecords);
            for(ABHFL_Asset_Detail__c rec : assetRecords){
                rec.Case__c = recId;
            }
            if(Schema.sObjectType.ABHFL_Asset_Detail__c.isUpdateable() && Schema.sObjectType.ABHFL_Asset_Detail__c.isCreateable()){
                upsert assetRecords;
            }
            return assetRecords;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(continuation=true cacheable=true)
    public static Object fetchAllLANDetails(List<Asset> assetList,String caseRecId){
        system.debug('assetList'+assetList);
            Continuation con = new Continuation(60);
            con.continuationMethod='continuationChaining';
            integer requestSize = 3;
            if(assetList.size() <= 3){
                requestSize = assetList.size();
                con.continuationMethod='processResponse';
            }
            ABCL_Integrations__mdt dataServiceDetails = ABCL_Integrations__mdt.getInstance('Data_Service_Details');
            for(integer i=0; i < requestSize;i++){
                HttpRequest req = new HttpRequest();
                req.setMethod(dataServiceDetails.Protocol__c);
                req.setEndpoint(dataServiceDetails.EndPoint__c);
                ABHFL_DataServiceDetailsController.DataServiceRequestWrapper dataServiceRequest = new ABHFL_DataServiceDetailsController.DataServiceRequestWrapper();
                dataServiceRequest.CLIENT_CODE = assetList[i].Account.Client_Code__c;
                dataServiceRequest.LAN = assetList[i].LAN__c;
                string body = JSON.serialize(dataServiceRequest);
                req.setBody(body);                
                con.addHttpRequest(req);
            }
            DataServiceContinuationWrapper continuationWrapper = new DataServiceContinuationWrapper();
            continuationWrapper.caseRecId = caseRecId;
            continuationWrapper.assetRecords = assetList;
            continuationWrapper.counter = requestSize;
            con.state = continuationWrapper;
            return con;

    }
    @AuraEnabled(continuation=true cacheable=true)
    public static Object continuationChaining(List<String> labels, Object state){
        DataServiceContinuationWrapper continuationWrapper = (DataServiceContinuationWrapper)state;
        List<Asset> assetList = continuationWrapper.assetRecords;
        Integer counter = continuationWrapper.counter;
        List<ABHFL_Asset_Detail__c> responseList = new List<ABHFL_Asset_Detail__c>();
        for(Integer i=0; i<labels.size() ; i++){
          system.debug('labels[i]'+labels[i]);
          HttpResponse response = Continuation.getResponse(labels[i]);
          ABHFL_DataServiceDetailsController.A3SSummaryData apiResponse = new ABHFL_DataServiceDetailsController.A3SSummaryData();
          if(response.getStatusCode() == 200){
            apiResponse = (ABHFL_DataServiceDetailsController.A3SSummaryData)JSON.deserialize(response.getBody(),ABHFL_DataServiceDetailsController.A3SSummaryData.class);
          }else{
            apiResponse = ABHFL_DataServiceDetailsController.executeDataServiceCallout();
          }          
          String indexStr = labels[i].split('-')[1];
          Integer index = Integer.valueOf(indexStr) - 1;
          ABHFL_Asset_Detail__c detailRecord = dataServiceConverter(apiResponse,continuationWrapper.assetRecords[index],continuationWrapper.caseRecId);
          responseList.add(detailRecord);
          //responseList.add(response.getBody());
        }
        Continuation con = new Continuation(60);
        con.continuationMethod='chainingContinuation';
        integer requestSize = 3;
        if(assetList.size() <= (counter + 3)){
            requestSize = assetList.size() - counter;
            con.continuationMethod='processResponse';
        }
        ABCL_Integrations__mdt dataServiceDetails = ABCL_Integrations__mdt.getInstance('Data_Service_Details');
        for(integer i=0; i < requestSize;i++){
            integer tempCount = i + counter;
            HttpRequest req = new HttpRequest();
            req.setMethod(dataServiceDetails.Protocol__c);
            req.setEndpoint(dataServiceDetails.EndPoint__c);
            ABHFL_DataServiceDetailsController.DataServiceRequestWrapper dataServiceRequest = new ABHFL_DataServiceDetailsController.DataServiceRequestWrapper();
            dataServiceRequest.CLIENT_CODE = assetList[tempCount].Account.Client_Code__c;
            dataServiceRequest.LAN = assetList[tempCount].LAN__c;
            string body = JSON.serialize(dataServiceRequest);
            req.setBody(body);                
            con.addHttpRequest(req);
        }
        DataServiceContinuationWrapper continuationResponse = new DataServiceContinuationWrapper();
        continuationResponse.assetRecords = assetList;
        continuationResponse.counter = requestSize + counter;
        continuationResponse.responseList = responseList;
        con.state = continuationResponse;
        return con;
    }

    @AuraEnabled(continuation=true cacheable=true)
    public static Object chainingContinuation(List<String> labels, Object state){
        DataServiceContinuationWrapper continuationWrapper = (DataServiceContinuationWrapper)state;
        List<Asset> assetList = continuationWrapper.assetRecords;
        Integer counter = continuationWrapper.counter;
        List<ABHFL_Asset_Detail__c> responseList = new List<ABHFL_Asset_Detail__c>();
        for(Integer i=0; i<labels.size() ; i++){
          system.debug('labels[i]'+labels[i]);
          HttpResponse response = Continuation.getResponse(labels[i]);
          ABHFL_DataServiceDetailsController.A3SSummaryData apiResponse = new ABHFL_DataServiceDetailsController.A3SSummaryData();
          if(response.getStatusCode() == 200){
            apiResponse = (ABHFL_DataServiceDetailsController.A3SSummaryData)JSON.deserialize(response.getBody(),ABHFL_DataServiceDetailsController.A3SSummaryData.class);
          }else{
            apiResponse = ABHFL_DataServiceDetailsController.executeDataServiceCallout();
          }          
          String indexStr = labels[i].split('-')[1];
          Integer index = Integer.valueOf(indexStr) - 1;
          ABHFL_Asset_Detail__c detailRecord = dataServiceConverter(apiResponse,continuationWrapper.assetRecords[index],continuationWrapper.caseRecId);
          responseList.add(detailRecord);
          //responseList.add(response.getBody());
        }
        Continuation con = new Continuation(60);
        con.continuationMethod='processResponse';
        integer requestSize = 3;
        if(assetList.size() <= (counter + 3)){
            requestSize = assetList.size() - counter;
        }
        ABCL_Integrations__mdt dataServiceDetails = ABCL_Integrations__mdt.getInstance('Data_Service_Details');
        for(integer i=0; i < requestSize;i++){
            integer tempCount = i + counter;
            HttpRequest req = new HttpRequest();
            req.setMethod(dataServiceDetails.Protocol__c);
            req.setEndpoint(dataServiceDetails.EndPoint__c);
            ABHFL_DataServiceDetailsController.DataServiceRequestWrapper dataServiceRequest = new ABHFL_DataServiceDetailsController.DataServiceRequestWrapper();
            dataServiceRequest.CLIENT_CODE = assetList[tempCount].Account.Client_Code__c;
            dataServiceRequest.LAN = assetList[tempCount].LAN__c;
            string body = JSON.serialize(dataServiceRequest);
            req.setBody(body);                
            con.addHttpRequest(req);
        }
        DataServiceContinuationWrapper continuationResponse = new DataServiceContinuationWrapper();
        continuationResponse.assetRecords = assetList;
        continuationResponse.counter = requestSize + counter;
        continuationResponse.responseList = responseList;
        con.state = continuationResponse;
        return con;
    }

    @AuraEnabled(cacheable=true)
    public static Object processResponse(List<String> labels, Object state) {
	  System.debug(' CurrState ' +state);
      DataServiceContinuationWrapper continuationWrapper = (DataServiceContinuationWrapper)state;
      List<ABHFL_Asset_Detail__c> responseList = new List<ABHFL_Asset_Detail__c>();
      for(Integer i=0; i<labels.size() ; i++){
        system.debug('labels[i]'+labels[i]);
        HttpResponse response = Continuation.getResponse(labels[i]);
        ABHFL_DataServiceDetailsController.A3SSummaryData apiResponse = new ABHFL_DataServiceDetailsController.A3SSummaryData();
        if(response.getStatusCode() == 200){
          apiResponse = (ABHFL_DataServiceDetailsController.A3SSummaryData)JSON.deserialize(response.getBody(),ABHFL_DataServiceDetailsController.A3SSummaryData.class);
        }else{
          apiResponse = ABHFL_DataServiceDetailsController.executeDataServiceCallout();
        }          
        String indexStr = labels[i].split('-')[1];
        Integer index = Integer.valueOf(indexStr) - 1;
        ABHFL_Asset_Detail__c detailRecord = dataServiceConverter(apiResponse,continuationWrapper.assetRecords[index],continuationWrapper.caseRecId);
        responseList.add(detailRecord);
        //responseList.add(response.getBody());
      }
      responseList.addAll(continuationWrapper.responseList);
      return responseList;
    }
    public class MultipleLanWrapper{
        @AuraEnabled
        public List<AssetDetailWrapper> assetDetailRecords;
        @AuraEnabled
        public List<ColumnWrapper> columnData;
        @AuraEnabled
        public List<ColumnWrapper> childColumnData;
        @AuraEnabled
        public Boolean displayMultipleLan;
    }

    public class ColumnWrapper{
        @AuraEnabled
        public string label;
        @AuraEnabled
        public string name;
        @AuraEnabled
        public string type;
        @AuraEnabled
        public Boolean isEditable;
        @AuraEnabled
        public List<PicklistWrapper> options;
    }

    public class AssetDetailWrapper{
        @AuraEnabled
        public Asset asset;
        @AuraEnabled
        public ABHFL_Asset_Detail__c detail;       
    }

    public class PicklistWrapper{
        @AuraEnabled
        public string label;
        @AuraEnabled
        public string value;
    }

    public class DataServiceContinuationWrapper{
        public List<Asset> assetRecords;
        public string caseRecId;
        public List<ABHFL_Asset_Detail__c> responseList;
        public Integer counter;
    }
}