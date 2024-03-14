/**
 * @description       : Class to handle Real Time API integration
 * @author            : rsinghnagar@salesforce.com
 * @group             : ABFL
 * @last modified on  : 28-02-2024
 * @last modified by  : rsinghnagar@salesforce.com
 * Modifications Log
 * Ver      Date           Author                            Modification
 * 1.0      28-12-2023     rsinghnagar@salesforce.com      Initial Version
 * 2.0      28-02-2024     udit.singhal@salesforce.com     updated logic for the real time API
 **/
@SuppressWarnings('PMD.CognitiveComplexity')
public without sharing class ABFL_RetailController{
    /****************************************************************************************************************
     * @LOB - ABFL
     * @Function - getDynamicScreen
     * @param String apiName - apiName of the Real Time API
     * @param Id assetId - Id of the asset record
     * @return ResponseWrapper - response wrapper for the LWC component
     * @Description - Method to get the response for the Real Time Details UI component
     *****************************************************************************************************************/
    @AuraEnabled(Cacheable = false)
    public static ResponseWrapper getDynamicScreen(String apiName, Id assetId){
        String title;
        String requestPayload = generateRequestPayload(apiName, assetId);
        ABCL_IntegrationCallout.IntegrationResponseWrapper intResponseWrapper = new ABCL_IntegrationCallout.IntegrationResponseWrapper();
        
        System.debug('requestPayload: '+requestPayload);

        switch  on apiName{
            when 'RTL_RealTime_LoanDetails'{
                intResponseWrapper = (ABCL_IntegrationCallout.executeCallout(ABFL_Constants.RTL_LOANDETAILS_INTEGRATION_METADATA, requestPayload, null));
            }
            when 'RTL_RealTime_BasicCustInfo'{
                intResponseWrapper = (ABCL_IntegrationCallout.executeCallout(ABFL_Constants.RTL_BASICCUSTINFO_INTEGRATION_METADATA, requestPayload, null));
            }
            when 'RTL_RealTIme_GCCPropertyDetails'{
                intResponseWrapper = (ABCL_IntegrationCallout.executeCallout(ABFL_Constants.RTL_GCCPROPERTYDETAILS_INTEGRATION_METADATA, requestPayload, null));
            }
            when 'RTL_RealTime_LoanMIS'{
                intResponseWrapper = (ABCL_IntegrationCallout.executeCallout(ABFL_Constants.RTL_LOANMIS_INTEGRATION_METADATA, requestPayload, null));
            }
            when 'RTL_RealTime_InstallPmntDtls'{
                intResponseWrapper = (ABCL_IntegrationCallout.executeCallout(ABFL_Constants.RTL_INSTALLPMNTDTLS_INTEGRATION_METADATA, requestPayload, null));
            }
        }

        System.debug('status code: '+intResponseWrapper.statusCode);
        System.debug('response body: '+intResponseWrapper.responseBody);

        // Prepare map of sections with left/right fields
        Map<String, List<Dynamic_Screen_Details__mdt>> mDynamicScreenDetails = new Map<String, List<Dynamic_Screen_Details__mdt>>();
        
        for (Dynamic_Screen_Details__mdt rec : [SELECT MasterLabel, Attribute_Mapping__c, DynamicScreenHeader__c, Order__c, Section_Name__c, Type__c, 
                                                DynamicScreenHeader__r.External_Key__c, DynamicScreenHeader__r.Title__c, Table_Columns__c, Table_Page_Size__c
                                                FROM Dynamic_Screen_Details__mdt
                                                WHERE DynamicScreenHeader__r.External_Key__c = :apiName
                                                WITH SYSTEM_MODE
                                                ORDER BY Order__c asc]){
            if (title == null){
                title = rec.DynamicScreenHeader__r.Title__c;
            }

            String sectionName = rec.Section_Name__c != null ? rec.Section_Name__c : ABFL_Constants.NO_SECTION;
            if (mDynamicScreenDetails.containsKey(sectionName)){
                mDynamicScreenDetails.get(sectionName).add(rec);
            } else if (rec.Section_Name__c != null){
                mDynamicScreenDetails.put(sectionName, new List<Dynamic_Screen_Details__mdt>{ rec });
            } else{
                mDynamicScreenDetails.put(ABFL_Constants.NO_SECTION, new List<Dynamic_Screen_Details__mdt>{ rec });
            }
        }
        System.debug('***title:' + title);
        System.debug('***mDynamicScreenDetails:' + mDynamicScreenDetails);

        // Prepare wrapper structure that will be passed to caller
        List<SectionWrap> sectionWrapList = new List<SectionWrap>();

        for (String section : mDynamicScreenDetails.keyset()){
            SectionWrap sw = new SectionWrap();
            List<Fields> fieldsLeft = new List<Fields>();
            List<Fields> fieldsRight = new List<Fields>();
            List<Fields> lTables = new List<Fields>();

            for (Dynamic_Screen_Details__mdt reci : mDynamicScreenDetails.get(section)){
                if (reci.Type__c == 'LeftSide'){
                    fieldsLeft.add(new Fields(reci.MasterLabel, reci.Attribute_Mapping__c));
                }
                if (reci.Type__c == 'RightSide'){
                    fieldsRight.add(new Fields(reci.MasterLabel, reci.Attribute_Mapping__c));
                }
                if (reci.Type__c == 'Table'){
                    lTables.add(new Fields(reci.Table_Columns__c, reci.Attribute_Mapping__c,  reci.Table_Page_Size__c, true));
                }
            }
            sw.label = section;
            sw.showSection = section != ABFL_Constants.NO_SECTION ? true : false;
            sw.fieldsLeft = fieldsLeft;
            sw.fieldsRight = fieldsRight;
            sw.lTables = lTables;
            sectionWrapList.add(sw);
        }
        System.debug('***sectionWrapList:' + sectionWrapList);
        return new ResponseWrapper(title, intResponseWrapper.statusCode, intResponseWrapper.responseBody, sectionWrapList);
    }

    /****************************************************************************************************************
     * @LOB - ABFL
     * @Function - generateRequestPayload
     * @param String apiName - apiName of the Real Time API
     * @param Id assetId - Id of the asset record
     * @return String - request payload for the Real Time API
     * @Description - Method to generate requestPayload based on apiName and assetId
     *****************************************************************************************************************/
    private static String generateRequestPayload(String apiName, Id assetId){
        Map<String, String> requestPayload = new Map<String, String>();

        Asset assetRecord = ABFL_SOQL_Util.getAssetInfo(assetid);

        if (assetRecord != null){
            List<String> validValues = new List<String>{'RTL_RealTIme_GCCPropertyDetails', 'RTL_RealTime_LoanMIS', 'RTL_RealTime_InstallPmntDtls'};
            // Generate request payload based on apiName
            if (apiName == 'RTL_RealTime_LoanDetails' && String.isNotBlank(assetRecord.LAN__c)){
                requestPayload.put('CCC', '');
                requestPayload.put('LAN', assetRecord.LAN__c);
            } else if (apiName == 'RTL_RealTime_BasicCustInfo' && String.isNotBlank(assetRecord.Account.PAN__c)){
                requestPayload.put('PAN', assetRecord.Account.PAN__c);
            } else if (validValues.contains(apiName) && String.isNotBlank(assetRecord.LAN__c)){
                requestPayload.put('LoanAccountNo', assetRecord.LAN__c);
            }
        }
        return JSON.serialize(requestPayload);
    }

    public Class ResponseWrapper{
        @AuraEnabled
        public String title;
        @AuraEnabled
        public Integer statusCode;
        @AuraEnabled
        public String payload;
        @AuraEnabled
        public List<SectionWrap> secWrap;
        public ResponseWrapper(String title, Integer statusCode, String res, List<SectionWrap> sr){
            this.title = title;
            this.statusCode = statusCode;
            this.payload = res;
            this.secWrap = sr;
        }
    }

    public Class SectionWrap{
        @AuraEnabled
        public String label;
        @AuraEnabled
        public boolean showSection;
        @AuraEnabled
        public List<Fields> fieldsLeft;
        @AuraEnabled
        public List<Fields> fieldsRight;
        @AuraEnabled
        public List<Fields> lTables;
    }

    public Class Fields{
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String value;
        @AuraEnabled
        public Decimal pageSize;
        @AuraEnabled
        public Boolean isRenderDatatable;

        public Fields(String lab, String nam){
            System.debug('***nam:' + nam);
            label = lab;
            value = nam;
            pageSize = 10;
            isRenderDatatable = false;
        }

        public Fields(String lab, String nam, Decimal pageSize, Boolean isRenderDatatable){
            System.debug('***nam:' + nam);
            label = lab;
            value = nam;
            this.pageSize = pageSize;
            this.isRenderDatatable = isRenderDatatable;
        }
    }
}