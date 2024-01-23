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
            throw e;//new AuraHandledException(e.getMessage());
        }
    }

    public static List<ColumnWrapper> getColumnData(ABHFL_Multiple_LAN__mdt lanMetadata, Boolean isChildTable){
        List<ColumnWrapper> columnList = new List<ColumnWrapper>();
        List<String> sfFieldList = new List<String>();
        sfFieldList = String.isNotBlank(lanMetadata.Asset_Fields__c) ? lanMetadata.Asset_Fields__c.split(',') : sfFieldList;

        Map<String,Schema.SObjectField> fieldSchemaMap = new Map<String,Schema.SObjectField>();
        if(isChildTable){
            fieldSchemaMap = Schema.Asset_Detail__c.SObjectType.getDescribe().fields.getMap();
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
        fieldSchemaMap = Schema.Asset_Detail__c.SObjectType.getDescribe().fields.getMap();
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
        fieldSchemaMap = Schema.Asset_Detail__c.SObjectType.getDescribe().fields.getMap();
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
        string assetDetailQueryStr = 'Select id,Asset__c,'+String.escapeSingleQuotes(childlanMetadata.Asset_Detail_Fields__c) + ',' + String.escapeSingleQuotes(childlanMetadata.Asset_Detail_Editable_Fields__c) + ' from Asset_Detail__c where Case__c =\''+String.escapeSingleQuotes(recId)+'\'';
        List<sObject> assetDetails = Database.Query(assetDetailQueryStr);
        Map<String,Asset_Detail__c> assetIdMap = new Map<String,Asset_Detail__c>();
        for(Asset_Detail__c assetDetail : (List<Asset_Detail__c>)assetDetails){
            assetIdMap.put(assetDetail.Asset__c,assetDetail);
        }
        for(Asset rec : (List<Asset>)assetRecords){
            AssetDetailWrapper assetDetailWrap = new AssetDetailWrapper();
            if(assetIdMap.containsKey(rec.Id)){
                assetDetailWrap.detail = assetIdMap.get(rec.Id);
            }else{
                Asset_Detail__c detailRec = new Asset_Detail__c();
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
    public static Asset_Detail__c fetchAssetDetailsExt(Asset assetRecord,String caseRecId){
        //ABHFL_DataServiceDetailsController.A3SSummaryData apiResponse = ABHFL_DataServiceDetailsController.executeDataServiceCallout();
        //Asset_Detail__c assetDetail = dataServiceConverter(apiResponse,assetRecord,caseRecId);
        return assetDetail;
    }

    public static Asset_Detail__c dataServiceConverter(String apiResponse,Asset assetRecord,String caseRecId){
        /*ABHFL_DataServiceDetailsController.LoanStatusRow loanStatusRow = apiResponse.Summary_Data[0].Loan_Status.rows[0];
        ABHFL_DataServiceDetailsController.LoanInfoRow loanInfoRow = apiResponse.Summary_Data[0].loan_info.rows[0];*/
        Asset_Detail__c assetDetail = new Asset_Detail__c();
        /*assetDetail.Product__c = loanStatusRow.PRODUCT;
        assetDetail.Last_Repricing_Date__c = Date.valueof(loanStatusRow.LAST_REPRICING);
        assetDetail.Is_Restructured__c = loanStatusRow.RESTRUCTURED == 'Yes'? true : false;
        assetDetail.Bounce__c = loanStatusRow.BOUNCE;
        assetDetail.Is_PDD__c = loanStatusRow.PDD == 'Yes'? true : false;
        assetDetail.Is_NACH__c = loanStatusRow.NACH == 'Yes'? true : false;
        assetDetail.Loan_Status__c = loanStatusRow.LOANSTATUS;
        assetDetail.Constitution__c = loanStatusRow.CONSTITUTION;
        assetDetail.Fixed_Period__c = loanStatusRow.FixedPeriod;
        assetDetail.VAN__c = loanStatusRow.VAN;
        assetDetail.MOB__c = Date.valueof(loanStatusRow.MOB);
        assetDetail.Account_Status__c = loanInfoRow.ACCOUNT_STATUS;
        assetDetail.Amount_Overdue__c = Decimal.valueof(loanInfoRow.AMOUNT_OVERDUE);
        assetDetail.Current_Balance__c = Decimal.valueof(loanInfoRow.CURRENT_BALANCE);
        assetDetail.LAN__c = assetRecord.LAN__c;//loanInfoRow.LOAN_ACCOUNT_NUMBER;
        assetDetail.Interest_Rate__c = Decimal.valueof(loanInfoRow.INTEREST_RATE.Left(4));
        system.debug('assetRecord---->'+assetRecord);
        assetDetail.Asset__c = assetRecord.Id;
        assetDetail.Case__c = caseRecId;*/
        return assetDetail;
    }

    @AuraEnabled
    public static List<Asset_Detail__c> upsertRecords(String assetDetails,String recId){
        try {
            system.debug(assetDetails);
            List<Asset_Detail__c> assetRecords = (List<Asset_Detail__c>)JSON.deserialize(assetDetails,List<Asset_Detail__c>.class);
            system.debug(assetRecords);
            for(Asset_Detail__c rec : assetRecords){
                rec.Case__c = recId;
            }
            if(Schema.sObjectType.Asset_Detail__c.isUpdateable() && Schema.sObjectType.Asset_Detail__c.isCreateable()){
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
            con.continuationMethod='chaining';
            DataServiceContinuationWrapper continuationWrapper = new DataServiceContinuationWrapper();
            continuationWrapper.caseRecId = caseRecId;
            continuationWrapper.assetRecords = assetList;
            con.state = continuationWrapper;
            ABCL_Integrations__mdt paytmLink = ABCL_Integrations__mdt.getInstance('Payment_Link');
            for(integer i=0; i < 3;i++){
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setEndpoint(paytmLink.EndPoint__c);
                string body = '"{\"custname\":\"SHARADBAJPAI\",\"LAN\":\"67487\",\"Amount\":\"2500\",\"emailId\":\"195@email.com\",\"mobileNumber\":\"1950000000\",\"type\":\"COLL\"}"';
                req.setBody(body);                
                con.addHttpRequest(req);
            }
            return con;

    }
    @AuraEnabled(continuation=true cacheable=true)
    public static Object chaining(List<String> labels, Object state){
        DataServiceContinuationWrapper continuationWrapper = (DataServiceContinuationWrapper)state;
        List<Asset_Detail__c> responseList = new List<Asset_Detail__c>();
        for(Integer i=0; i<labels.size() ; i++){
          system.debug('labels[i]'+labels[i]);
          HttpResponse response = Continuation.getResponse(labels[i]);
          //ABHFL_DataServiceDetailsController.A3SSummaryData apiResponse = ABHFL_DataServiceDetailsController.executeDataServiceCallout();
          String indexStr = labels[i].split('-')[1];
          Integer index = Integer.valueOf(indexStr) - 1;
          //Asset_Detail__c detailRecord = dataServiceConverter(apiResponse,continuationWrapper.assetRecords[index],continuationWrapper.caseRecId);
          //responseList.add(detailRecord);
          //responseList.add(response.getBody());
        }
        continuationWrapper.responseList = responseList;
        Continuation con1 = new Continuation(35);
            con1.continuationMethod='chaining1';

            con1.state = continuationWrapper;
            ABCL_Integrations__mdt paytmLink = ABCL_Integrations__mdt.getInstance('Payment_Link');
            for(integer i=0; i < 3;i++){
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setEndpoint(paytmLink.EndPoint__c);
                string body = '"{\"custname\":\"SHARADBAJPAI\",\"LAN\":\"67487\",\"Amount\":\"2500\",\"emailId\":\"195@email.com\",\"mobileNumber\":\"1950000000\",\"type\":\"COLL\"}"';
                req.setBody(body);
                con1.addHttpRequest(req);
            }
            return con1;
    }

    @AuraEnabled(continuation=true cacheable=true)
    public static Object chaining1(List<String> labels, Object state){
        DataServiceContinuationWrapper continuationWrapper = (DataServiceContinuationWrapper)state;
        system.debug(continuationWrapper.responseList);
        List<Asset_Detail__c> responseList = continuationWrapper.responseList;
        for(Integer i=0; i<labels.size() ; i++){
          system.debug('labels[i]'+labels[i]);
          HttpResponse response = Continuation.getResponse(labels[i]);
          //ABHFL_DataServiceDetailsController.A3SSummaryData apiResponse = ABHFL_DataServiceDetailsController.executeDataServiceCallout();
          String indexStr = labels[i].split('-')[1];
          Integer index = Integer.valueOf(indexStr) - 1;
          //Asset_Detail__c detailRecord = dataServiceConverter(apiResponse,continuationWrapper.assetRecords[index],continuationWrapper.caseRecId);
          //if(detailRecord != null){
            //responseList.add(detailRecord);
          //}
        }
        continuationWrapper.responseList = responseList;
        Continuation con2 = new Continuation(35);
            con2.continuationMethod='processResponse';
            con2.state = continuationWrapper;
            ABCL_Integrations__mdt paytmLink = ABCL_Integrations__mdt.getInstance('Payment_Link');
            for(integer i=0; i < 3;i++){
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setEndpoint(paytmLink.EndPoint__c);
                string body = '"{\"custname\":\"SHARADBAJPAI\",\"LAN\":\"67487\",\"Amount\":\"2500\",\"emailId\":\"195@email.com\",\"mobileNumber\":\"1950000000\",\"type\":\"COLL\"}"';
                req.setBody(body);
                con2.addHttpRequest(req);
            }
            return con2;
    }

    @AuraEnabled(cacheable=true)
    public static Object processResponse(List<String> labels, Object state) {
	  System.debug(' CurrState ' +state);
      DataServiceContinuationWrapper continuationWrapper = (DataServiceContinuationWrapper)state;
      List<Asset_Detail__c> responseList = new List<Asset_Detail__c>();
      for(Integer i=0; i<labels.size() ; i++){
        system.debug('labels[i]'+labels[i]);
        HttpResponse response = Continuation.getResponse(labels[i]);
        //ABHFL_DataServiceDetailsController.A3SSummaryData apiResponse = ABHFL_DataServiceDetailsController.executeDataServiceCallout();
        String indexStr = labels[i].split('-')[1];
        Integer index = Integer.valueOf(indexStr) - 1;
        //Asset_Detail__c detailRecord = dataServiceConverter(apiResponse,continuationWrapper.assetRecords[index],continuationWrapper.caseRecId);
        //responseList.add(detailRecord);
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
        public Asset_Detail__c detail;       
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
        public List<Asset_Detail__c> responseList;
    }
}