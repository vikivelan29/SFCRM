/*********************************************************
*Class        :  ABHFL_RoiHistoryClass
*Author       :  Aditya Mehrotra
*Created Date :  13/02/2024
*Last Modified:  13/02/2024
*Description  :  Controller class for ROI History Details
*********************************************************/
public with sharing class ABHFL_RoiHistoryClass {

    @AuraEnabled(cacheable=true)
    public static RoiHistoryResponseWrapper fetchRoiHistory(String assetId){
        Asset at = [SELECT Id, LAN__c FROM Asset WHERE Id=:assetId LIMIT 1];
        RoiHistoryRequestWrapper roiHistoryRequest = new RoiHistoryRequestWrapper(at.LAN__c);
        String roiHistoryRequestBody = JSON.serialize(roiHistoryRequest);
        ABCL_IntegrationCallout.IntegrationResponseWrapper roiHistoryResponse = ABCL_IntegrationCallout.executeCallout(ABHFL_Constants.ROIHISTORY_INTEGRATION_METADATA,roiHistoryRequestBody,null);
        RoiHistoryResponseWrapper response = new RoiHistoryResponseWrapper();
        Map<String, Object> responseMap = new Map<String, Object>();
        if(roiHistoryResponse.statusCode == 200 && String.isNotBlank(roiHistoryResponse.responseBody)){
            response = (RoiHistoryResponseWrapper)JSON.deserialize(roiHistoryResponse.responseBody,RoiHistoryResponseWrapper.class);
            responseMap = (Map<String,Object>)JSON.deserializeUntyped(roiHistoryResponse.responseBody);
        }
        List<String> fields = Label.ABHFL_ROI_HIstory_Fields.split(',');
        List<RoiColumnWrapper> columnWrapperList = new List<RoiColumnWrapper>();
        for(String field: fields){
            RoiColumnWrapper col = new RoiColumnWrapper(field.split(':')[0],field.split(':')[1]);
            columnWrapperList.add(col);
        }
        if(response.data.size()>0){
            response.columns = columnWrapperList;
            return response;
        }else{
            return null;
        }
    }

    public class RoiHistoryRequestWrapper{

        public String loan_number;

        public RoiHistoryRequestWrapper(String lan){
            this.loan_number = lan;
        }
    }

    public class RoiHistoryResponseWrapper{
        public Boolean success;
        public String message;
        @AuraEnabled
        public ResponseData[] data;
        @AuraEnabled
        public List<RoiColumnWrapper> columns;
    }

    public class ResponseData{
        @AuraEnabled
        public Decimal RESCH_ID;
        @AuraEnabled
        public String RESCH_TYPE;
        @AuraEnabled
        public String REQUEST_DATE;
        @AuraEnabled
        public String RESCH_DATE;
        @AuraEnabled
        public String RESCH_EFF_DATE;
        @AuraEnabled
        public Decimal LOAN_ID;
        @AuraEnabled
        public String LOAN_NO;
        @AuraEnabled
        public String OLD_RATE;
        @AuraEnabled
        public String new_rate;
    }

    public class RoiColumnWrapper{
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String fieldName;
        @AuraEnabled
        public String type;
        
        public RoiColumnWrapper(String l, String f){
            this.label = l;
            this.fieldName = f;
        }
    }

}