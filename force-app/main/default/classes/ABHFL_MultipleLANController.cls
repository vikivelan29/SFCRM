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
    public static MultipleLanWrapper getLanDataAndMetadata(string recId, string loggedInUserId){
        try {
            MultipleLanWrapper lanWrapper = new MultipleLanWrapper();
            Case caseRecord = [Select id,CCC_External_Id__c,AccountId,Stage__c,OwnerId from Case where id =: recId ];
            //ABHFL_Multiple_LAN__mdt lanMetadata = ABHFL_Multiple_LAN__mdt.getInstance(caseRecord.CCC_External_Id__c);
            List<ABHFL_Multiple_LAN__mdt> lanMetadataList = [ SELECT Id, DeveloperName, MasterLabel, Language, NamespacePrefix, Label,Impact_Option_Logic__c, QualifiedApiName, SystemModstamp, 
                                                    Asset_Fields__c, Asset_Detail_Fields__c, Asset_Detail_Editable_Fields__c, Stages_Allowing_Field_Edit__c,Asset_Additional_Fields__c, 
                                                    Stages_Allowing_Fetch_All__c, Stages_Allowing_Add_Rows__c, Stages_Allowing_Delete_Rows__c, Stages_Allowing_File_Upload__c 
                                                    FROM ABHFL_Multiple_LAN__mdt where DeveloperName =: caseRecord.CCC_External_Id__c];

            ABHFL_Multiple_LAN__mdt lanMetadata = new ABHFL_Multiple_LAN__mdt();
            if(lanMetadataList.size() > 0){
                lanMetadata = lanMetadataList[0];
            }
            lanWrapper.impactLogic = lanMetadata.Impact_Option_Logic__c;

            ABHFL_Multiple_LAN__mdt childLanMetadata = ABHFL_Multiple_LAN__mdt.getInstance(caseRecord.CCC_External_Id__c+'_Detail');
            Boolean validLoggedInUser = false;
            if(caseRecord.OwnerId.getSObjectType().getDescribe().getName() == 'User'){
                if(caseRecord.OwnerId == loggedInUserId){
                    validLoggedInUser = true;
                }
            }else {
                List<GroupMember> groupMember = [SELECT UserOrGroupId FROM GroupMember where GroupId =: caseRecord.OwnerId ];
                if(groupMember.size() > 0 && groupMember[0].UserOrGroupId.getSObjectType().getDescribe().getName() != 'User'){
                    List<GroupMember> userMember = [SELECT GroupId,Id,SystemModstamp,UserOrGroupId FROM GroupMember where GroupId =: groupMember[0].UserOrGroupId and UserOrGroupId =: loggedInUserId ];
                    if(userMember.size() > 0){
                        validLoggedInUser = true;
                    }
                }
            }
            if(lanMetadata.Id != null){
                if(String.isNotBlank(lanMetadata.Stages_Allowing_Fetch_All__c)){
                    List<String> stagesAllowed = lanMetadata.Stages_Allowing_Fetch_All__c.split(',');
                    lanWrapper.stagesAllowingFetchAll = stagesAllowed;
                    if(stagesAllowed.contains(caseRecord.Stage__c)){
                        lanWrapper.displayFetchAll = true;
                    }
                }
                lanWrapper.displayMultipleLan = true;
                lanWrapper.columnData = getColumnData(lanMetadata,false);
                lanWrapper.additionalColumnData = getAdditionalColumnData(lanMetadata,false);
                if(validLoggedInUser){
                    if(String.isNotBlank(lanMetadata.Stages_Allowing_Field_Edit__c)){
                        List<String> stagesAllowed = lanMetadata.Stages_Allowing_Field_Edit__c.split(',');
                        lanWrapper.stagesAllowingFieldEdit = stagesAllowed;
                        if(stagesAllowed.contains(caseRecord.Stage__c)){
                            lanWrapper.disableFieldEdit = false;
                        }
                    }
                    if(String.isNotBlank(lanMetadata.Stages_Allowing_Add_Rows__c)){
                        List<String> stagesAllowed = lanMetadata.Stages_Allowing_Add_Rows__c.split(',');
                        lanWrapper.stagesAllowingAddRows = stagesAllowed;
                        if(stagesAllowed.contains(caseRecord.Stage__c)){
                            lanWrapper.displayAddRows = true;
                        }
                    }
                    if(String.isNotBlank(lanMetadata.Stages_Allowing_Delete_Rows__c)){
                        List<String> stagesAllowed = lanMetadata.Stages_Allowing_Delete_Rows__c.split(',');
                        lanWrapper.stagesAllowingDeleteRows = stagesAllowed;
                        if(stagesAllowed.contains(caseRecord.Stage__c)){
                            lanWrapper.displayDeleteRows = true;
                        }
                    }
                    if(String.isNotBlank(lanMetadata.Stages_Allowing_File_Upload__c)){
                        List<String> stagesAllowed = lanMetadata.Stages_Allowing_File_Upload__c.split(',');
                        lanWrapper.stagesAllowingFileUpload = stagesAllowed;
                        if(stagesAllowed.contains(caseRecord.Stage__c)){
                            lanWrapper.displayFileUpload = true;
                        }
                    }
                } else {
                    if(String.isNotBlank(lanMetadata.Stages_Allowing_Field_Edit__c)){
                        List<String> stagesAllowed = lanMetadata.Stages_Allowing_Field_Edit__c.split(',');
                        lanWrapper.stagesAllowingFieldEdit = stagesAllowed;
                    }
                    if(String.isNotBlank(lanMetadata.Stages_Allowing_Add_Rows__c)){
                        List<String> stagesAllowed = lanMetadata.Stages_Allowing_Add_Rows__c.split(',');
                        lanWrapper.stagesAllowingAddRows = stagesAllowed;
                    }
                    if(String.isNotBlank(lanMetadata.Stages_Allowing_Delete_Rows__c)){
                        List<String> stagesAllowed = lanMetadata.Stages_Allowing_Delete_Rows__c.split(',');
                        lanWrapper.stagesAllowingDeleteRows = stagesAllowed;
                    }
                    if(String.isNotBlank(lanMetadata.Stages_Allowing_Fetch_All__c)){
                        List<String> stagesAllowed = lanMetadata.Stages_Allowing_Fetch_All__c.split(',');
                        lanWrapper.stagesAllowingFetchAll = stagesAllowed;
                    }
                    if(String.isNotBlank(lanMetadata.Stages_Allowing_File_Upload__c)){
                        List<String> stagesAllowed = lanMetadata.Stages_Allowing_File_Upload__c.split(',');
                        lanWrapper.stagesAllowingFileUpload = stagesAllowed;
                    }
                }
                if(childLanMetadata != null){
                    lanWrapper.childColumnData = getColumnData(childLanMetadata,true);
                }
                lanWrapper.assetDetailRecords = getAssetDetailRecords(lanMetadata,childLanMetadata,recId);
            }
            return lanWrapper;
        } catch (Exception e) {
            throw e;//throw new AuraHandledException(e.getMessage());
        }
    }
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - getColumnData
    * @param lanMetadata - Metadata Record for Parent Table Display.
    * @param isChildTable - Boolean to check if its child table or parent table.
    * @return - List<ColumnWrapper>.
    * @Description - Fetches Column Level Data for Multiple LAN Component.
    *****************************************************************************************************************/
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
                if(fieldSchemaMap.containsKey(field)){
                    ColumnWrapper column = new ColumnWrapper();
                    Schema.DescribeFieldResult fieldResult = fieldSchemaMap.get(field).getDescribe();
                    column.label = fieldResult.getLabel();
                    column.name = field;
                    column.type = String.valueof(fieldResult.getType());
                    column.isEditable = false;
                    columnList.add(column);       
                }
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
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - getAdditionalColumnData
    * @param lanMetadata - Metadata Record for Parent Table Display.
    * @param isChildTable - Boolean to check if its child table or parent table.
    * @return - List<ColumnWrapper>.
    * @Description - Fetches Column Level Data for Multiple LAN Component.
    * @Author-Yogesh Wagh[PR970457-2144]
    *****************************************************************************************************************/
    
    public static List<ColumnWrapper> getAdditionalColumnData(ABHFL_Multiple_LAN__mdt lanMetadata, Boolean isChildTable){
        List<ColumnWrapper> columnList = new List<ColumnWrapper>();
        List<String> sfFieldList = new List<String>();
        sfFieldList = String.isNotBlank(lanMetadata.Asset_Additional_Fields__c) ? lanMetadata.Asset_Additional_Fields__c.split(',') : sfFieldList;

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
        return columnList;
    }
    
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - getAssetDetailRecords
    * @param lanMetadata - Metadata Record for Parent Table Display.
    * @param childLanMetadata -  Metadata Record for Child Table Display.
    * @param recId - Case record Id from Framework.
    * @return - List<AssetDetailWrapper>.
    * @Description - Fetches LAN data for Multiple LAN Component.
    *****************************************************************************************************************/
    public static List<AssetDetailWrapper> getAssetDetailRecords(ABHFL_Multiple_LAN__mdt lanMetadata,ABHFL_Multiple_LAN__mdt childLanMetadata,String recId){
        List<AssetDetailWrapper> assetDetailRecords = new List<AssetDetailWrapper>();
        List<LAN_Mapping__c> lanMappingList = [Select LAN__c from LAN_Mapping__c where Customer__c in (Select AccountId from Case where id =: recId) ];
        Set<String> lanIds = new Set<String>();
        if(lanMappingList.size() > 0){
            for(LAN_Mapping__c lanMap : lanMappingList){
                lanIds.add(lanMap.LAN__c);
            }
        }
        string queryStr = 'Select id,Account.Client_Code__c,Loan_Disbursement_Status__c,'+String.escapeSingleQuotes(lanMetadata.Asset_Fields__c) +','+String.escapeSingleQuotes(lanMetadata.Asset_Additional_Fields__c) + ' from Asset where Id in: lanIds';
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
        Set<Id> assetDetailIds = new Set<Id>();
        for(ABHFL_Asset_Detail__c assetDetail : (List<ABHFL_Asset_Detail__c>)assetDetails){
            assetIdMap.put(assetDetail.Asset__c,assetDetail);
            assetDetailIds.add(assetDetail.Id);
        }

        Map<Id,Id> assetDetailIdContentIdMap = new Map<Id,Id>();
        if(assetDetailIds.size() > 0){
            List<ContentDocumentLink> contentDocLinkList = [Select id,LinkedEntityId,ContentDocumentId from ContentDocumentLink where LinkedEntityId in: assetDetailIds];

            for(ContentDocumentLink docLink : contentDocLinkList){
                assetDetailIdContentIdMap.put(docLink.LinkedEntityId,docLink.ContentDocumentId);
            }

        }

        for(Asset rec : (List<Asset>)assetRecords){
            AssetDetailWrapper assetDetailWrap = new AssetDetailWrapper();
            if(assetIdMap.containsKey(rec.Id)){
                assetDetailWrap.detail = assetIdMap.get(rec.Id);
                if(assetDetailIdContentIdMap.containsKey(assetDetailWrap.detail.Id)){
                    assetDetailWrap.attachmentStatus = true;
                }
            }else{
                ABHFL_Asset_Detail__c detailRec = new ABHFL_Asset_Detail__c();
                detailRec.Asset__c = rec.Id;
                detailRec.LAN__c = rec.LAN__c;
                assetDetailWrap.detail = detailRec;
                assetDetailWrap.attachmentStatus = false;
            }
            assetDetailWrap.asset = rec;
            assetDetailRecords.add(assetDetailWrap);
        }
        return assetDetailRecords;
    }
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - fetchAssetDetailsExt
    * @param assetRecord -  Asset Record.
    * @param caseRecId - Case record Id from Framework.
    * @return - ABHFL_Asset_Detail__c.
    * @Description - Fetches Asset Detail for Multiple LAN Component from the DataService API.
    *****************************************************************************************************************/
    @AuraEnabled
    public static ABHFL_Asset_Detail__c fetchAssetDetailsExt(Asset assetRecord,String caseRecId){
        try{
            //ABHFL_DataServiceDetailsController.A3SSummaryData apiResponse = ABHFL_DataServiceDetailsController.executeDataServiceCallout();
            ABHFL_Asset_Detail__c assetDetail = new ABHFL_Asset_Detail__c();
            ABHFL_DataServiceDetailsController.DataServiceRequestWrapper dataServiceRequest = new ABHFL_DataServiceDetailsController.DataServiceRequestWrapper();
            dataServiceRequest.CLIENT_CODE =assetRecord.Account.Client_Code__c;
            dataServiceRequest.LAN = assetRecord.LAN__c;
            String dataServiceRequestBody = JSON.serialize(dataServiceRequest);
            system.debug('dataServiceRequestBody'+dataServiceRequestBody);
            ABCL_IntegrationCallout.IntegrationResponseWrapper dataServiceResponse = ABCL_IntegrationCallout.executeCallout(ABHFL_Constants.DATASERVICE_INTEGRATION_METADATA,dataServiceRequestBody,null);
            if(dataServiceResponse.statusCode == 200 && String.isNotBlank(dataServiceResponse.responseBody)){
                system.debug('dataServiceResponse.responseBody'+dataServiceResponse.responseBody);
                ABHFL_DataServiceDetailsController.A3SSummaryData dataServiceResponseWrapper = (ABHFL_DataServiceDetailsController.A3SSummaryData)JSON.deserialize(dataServiceResponse.responseBody,ABHFL_DataServiceDetailsController.A3SSummaryData.class);
                assetDetail = dataServiceConverter(dataServiceResponseWrapper,assetRecord,caseRecId);
            }
            return assetDetail;
        }catch (Exception e) {
            throw e;//new AuraHandledException(e.getMessage());
        }
    }
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - dataServiceConverter
    * @param apiResponse -  DataService Response.
    * @param assetRecord - Asset Record.
    * @param caseRecId - Case record Id from Framework.
    * @return - ABHFL_Asset_Detail__c.
    * @Description - Transforms DataService Response into a wrapper
    *****************************************************************************************************************/
    public static ABHFL_Asset_Detail__c dataServiceConverter(ABHFL_DataServiceDetailsController.A3SSummaryData apiResponse,Asset assetRecord,String caseRecId){
        ABHFL_DataServiceDetailsController.LoanStatusRow loanStatusRow = apiResponse.Summary_Data[0].Loan_Status.rows[0];
        ABHFL_DataServiceDetailsController.LoanInfoRow loanInfoRow = apiResponse.Summary_Data[0].loan_info.rows[0];
        ABHFL_Asset_Detail__c assetDetail = new ABHFL_Asset_Detail__c();
        assetDetail.Product__c = loanStatusRow.PRODUCT;
        assetDetail.Last_Repricing_Date__c = String.isNotBlank(loanStatusRow.LAST_REPRICING) ? Date.valueof(loanStatusRow.LAST_REPRICING) : null;
        //assetDetail.Last_Repricing_Date__c = Date.valueof(loanStatusRow.LAST_REPRICING).daysBetween(System.Today()) < 180 ? 'Last repricing <6 months' : 'Last repricing >6 months';
        assetDetail.Is_Restructured__c = loanStatusRow.RESTRUCTURED == 'Yes'? 'Re-structured Not Done' : 'Re-structured Done';
        assetDetail.Bounce__c = loanStatusRow.BOUNCE != null ? Decimal.valueOf(loanStatusRow.BOUNCE) : null; 
        //assetDetail.Bounce__c = Decimal.valueOf(loanStatusRow.BOUNCE) > 0 ? 'Bounce > 0' : 'Bounce < 0';
        assetDetail.Is_PDD__c = loanStatusRow.PDD == 'Yes'? 'PDD Pending' : 'PDD Not Pending';
        assetDetail.Is_NACH__c = loanStatusRow.NACH == 'Yes'? 'NACH Registered' : 'NACH Not Registered';
        assetDetail.Loan_Status__c = loanStatusRow.LOANSTATUS;
        assetDetail.Constitution__c = loanStatusRow.CONSTITUTION;
        assetDetail.Fixed_Period__c = loanStatusRow.FixedPeriod != null ? Decimal.valueOf(loanStatusRow.FixedPeriod) : null;
        //assetDetail.Fixed_Period__c = Decimal.valueOf(loanStatusRow.FixedPeriod) > 0 ? 'Fixed Period > 0' : '';
        assetDetail.VAN__c = loanStatusRow.VAN;
        assetDetail.MOB__c = String.isNotBlank(loanStatusRow.MOB)? Date.valueof(loanStatusRow.MOB) : null;
        //assetDetail.MOB__c = Date.valueof(loanStatusRow.MOB).daysBetween(System.Today()) < 180 ? 'MOB < 6 months' : 'MOB > 6 months';
        assetDetail.Account_Status__c = loanStatusRow.LOANSTATUS;
        //assetDetail.Account_Status__c = loanStatusRow.LOANSTATUS != 'Standard' ? 'Not Standard' : 'Standard';
        assetDetail.Amount_Overdue__c = loanInfoRow.AMOUNT_OVERDUE != null ? Decimal.valueof(loanInfoRow.AMOUNT_OVERDUE) : null;
        //assetDetail.Overdues__c = assetDetail.Amount_Overdue__c > 0 ? 'Overdue Pending' : 'No Overdue Pending';
        assetDetail.Current_Balance__c = loanInfoRow.CURRENT_BALANCE != null ? Decimal.valueof(loanInfoRow.CURRENT_BALANCE) : null;
        assetDetail.LAN__c = assetRecord.LAN__c;//loanInfoRow.LOAN_ACCOUNT_NUMBER;
        assetDetail.Interest_Rate__c = loanInfoRow.INTEREST_RATE != null ? Decimal.valueof(loanInfoRow.INTEREST_RATE.Substring(0,loanInfoRow.INTEREST_RATE.length()-1)) : null;
        system.debug('loanInfoRow.INTEREST_RATE after'+assetDetail.Interest_Rate__c);
        assetDetail.ARR__c = loanStatusRow.BPLR != null ? Decimal.valueof(loanStatusRow.BPLR.Substring(0,loanStatusRow.BPLR.length()-1)) : null;
        assetDetail.Asset__c = assetRecord.Id;
        assetDetail.Case__c = caseRecId;
        assetDetail.Failure_Reason__c = failureReasonDetermination(assetDetail);
        return assetDetail;
    }
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - failureReasonDetermination
    * @param assetDetail -  Asset Detail Record.
    * @return - string.
    * @Description - Determines the Failure Reason based on logic.
    *****************************************************************************************************************/
    public static string failureReasonDetermination(ABHFL_Asset_Detail__c assetDetail){
        string failureReason = '';
        if(assetDetail.Account_Status__c != 'Standard'){
            failureReason = 'Not Standard';
        }
        if(assetDetail.MOB__c != null && assetDetail.MOB__c.daysBetween(System.Today()) < 180){
            failureReason = 'MOB < 6 months';
        }
        if(assetDetail.Last_Repricing_Date__c != null && assetDetail.Last_Repricing_Date__c.daysBetween(System.Today()) < 180){
            failureReason = 'Last repricing <6 months';
        }
        if(assetDetail.Is_NACH__c == 'NACH Not Registered'){
            failureReason = 'NACH Not Registered';
        }
        if(assetDetail.Is_Restructured__c == 'Re-structured Not Done'){
            failureReason = 'Re-structured Not Done';
        }
        if(assetDetail.Amount_Overdue__c > 0){
            failureReason = 'Overdue Pending';
        }
        if(assetDetail.Bounce__c > 0){
            failureReason = 'Bounce > 0';
        }
        if(assetDetail.Fixed_Period__c > 0){
            failureReason = 'Fixed Period > 0';
        }
        if(assetDetail.Is_PDD__c == 'PDD Pending'){
            failureReason = 'PDD Pending';
        }
        return failureReason;
    }
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - upsertRecords
    * @param assetDetails -  Serialized Asset Detail Record.
    * @param recId - Case record Id from Framework.
    * @return - List<ABHFL_Asset_Detail__c>.
    * @Description - Upsert Asset Detail Record.
    *****************************************************************************************************************/
    @AuraEnabled
    public static List<ABHFL_Asset_Detail__c> upsertRecords(String assetDetails,String recId){
        try {

            List<ABHFL_Asset_Detail__c> existingAssetRecords = [Select id,Asset__c from ABHFL_Asset_Detail__c where Case__c =: recId];
            Map<String,String> assetIdAssetDetailIdMap = new Map<String,String>();
            if(existingAssetRecords.size() > 0){
                for(ABHFL_Asset_Detail__c assetDetail : existingAssetRecords){
                    assetIdAssetDetailIdMap.put(assetDetail.Asset__c,assetDetail.Id);
                }
            }

            List<ABHFL_Asset_Detail__c> assetRecords = (List<ABHFL_Asset_Detail__c>)JSON.deserialize(assetDetails,List<ABHFL_Asset_Detail__c>.class);
            for(ABHFL_Asset_Detail__c rec : assetRecords){
                rec.Case__c = recId;
                if(assetIdAssetDetailIdMap.containsKey(rec.Asset__c)){
                    rec.Id = assetIdAssetDetailIdMap.get(rec.Asset__c);
                }
            }

            if(Schema.sObjectType.ABHFL_Asset_Detail__c.isUpdateable() && Schema.sObjectType.ABHFL_Asset_Detail__c.isCreateable()){
                upsert assetRecords;
            }
            List<ASF_Checklist__c> checklist = [Select id,Status__c,Label__c from ASF_Checklist__c 
                                                where Case__c =: recId and Label__c = 'Add LAN(s) and provide necessary details.'];
                                   
            return assetRecords;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - fetchAllLANDetails
    * @param assetDetails -  List of Asset Detail Record.
    * @param caseRecId - Case record Id from Framework.
    * @return - Object.
    * @Description - Fetch LAN Details from DataService API.
    *****************************************************************************************************************/
    @AuraEnabled(continuation=true cacheable=true)
    public static Object fetchAllLANDetails(List<Asset> assetList,String caseRecId){
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
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - continuationChaining
    * @param labels -  List of Labels for Continuation Response Handling.
    * @param state - Variable to store stateful data.
    * @return - Object.
    * @Description - Fetch LAN Details from DataService API.
    *****************************************************************************************************************/
    @AuraEnabled(continuation=true cacheable=true)
    public static Object continuationChaining(List<String> labels, Object state){
        DataServiceContinuationWrapper continuationWrapper = (DataServiceContinuationWrapper)state;
        List<Asset> assetList = continuationWrapper.assetRecords;
        Integer counter = continuationWrapper.counter;
        List<ABHFL_Asset_Detail__c> responseList = new List<ABHFL_Asset_Detail__c>();
        for(Integer i=0; i<labels.size() ; i++){
          HttpResponse response = Continuation.getResponse(labels[i]);
          ABHFL_DataServiceDetailsController.A3SSummaryData apiResponse = new ABHFL_DataServiceDetailsController.A3SSummaryData();
          if(response.getStatusCode() == 200){
            try{
                apiResponse = (ABHFL_DataServiceDetailsController.A3SSummaryData)JSON.deserialize(response.getBody(),ABHFL_DataServiceDetailsController.A3SSummaryData.class);
                String indexStr = labels[i].split('-')[1];
                Integer index = Integer.valueOf(indexStr) - 1;
                ABHFL_Asset_Detail__c detailRecord = dataServiceConverter(apiResponse,continuationWrapper.assetRecords[index],continuationWrapper.caseRecId);
                responseList.add(detailRecord); 
            }catch(Exception ex){
                system.debug(ex);
            }  
        }
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
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - chainingContinuation
    * @param labels -  List of Labels for Continuation Response Handling.
    * @param state - Variable to store stateful data.
    * @return - Object.
    * @Description - Fetch LAN Details from DataService API.
    *****************************************************************************************************************/
    @AuraEnabled(continuation=true cacheable=true)
    public static Object chainingContinuation(List<String> labels, Object state){
        DataServiceContinuationWrapper continuationWrapper = (DataServiceContinuationWrapper)state;
        List<Asset> assetList = continuationWrapper.assetRecords;
        Integer counter = continuationWrapper.counter;
        List<ABHFL_Asset_Detail__c> responseList = new List<ABHFL_Asset_Detail__c>();
        for(Integer i=0; i<labels.size() ; i++){
          HttpResponse response = Continuation.getResponse(labels[i]);
          ABHFL_DataServiceDetailsController.A3SSummaryData apiResponse = new ABHFL_DataServiceDetailsController.A3SSummaryData();
          if(response.getStatusCode() == 200){
            try{
                apiResponse = (ABHFL_DataServiceDetailsController.A3SSummaryData)JSON.deserialize(response.getBody(),ABHFL_DataServiceDetailsController.A3SSummaryData.class);
                String indexStr = labels[i].split('-')[1];
                Integer index = Integer.valueOf(indexStr) - 1;
                ABHFL_Asset_Detail__c detailRecord = dataServiceConverter(apiResponse,continuationWrapper.assetRecords[index],continuationWrapper.caseRecId);
                responseList.add(detailRecord); 
            }catch(Exception ex){
                system.debug(ex);
            }  
          } 
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
    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - processResponse
    * @param labels -  List of Labels for Continuation Response Handling.
    * @param state - Variable to store stateful data.
    * @return - Object.
    * @Description - Fetch LAN Details from DataService API.
    *****************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static Object processResponse(List<String> labels, Object state) {
      DataServiceContinuationWrapper continuationWrapper = (DataServiceContinuationWrapper)state;
      List<ABHFL_Asset_Detail__c> responseList = new List<ABHFL_Asset_Detail__c>();
      for(Integer i=0; i<labels.size() ; i++){
        HttpResponse response = Continuation.getResponse(labels[i]);
        ABHFL_DataServiceDetailsController.A3SSummaryData apiResponse = new ABHFL_DataServiceDetailsController.A3SSummaryData();
        system.debug('response' + response);
        system.debug('response.getBody()' + response.getBody());
        if(response.getStatusCode() == 200){
            try{
                apiResponse = (ABHFL_DataServiceDetailsController.A3SSummaryData)JSON.deserialize(response.getBody(),ABHFL_DataServiceDetailsController.A3SSummaryData.class);
                String indexStr = labels[i].split('-')[1];
                Integer index = Integer.valueOf(indexStr) - 1;
                ABHFL_Asset_Detail__c detailRecord = dataServiceConverter(apiResponse,continuationWrapper.assetRecords[index],continuationWrapper.caseRecId);
                responseList.add(detailRecord); 
            }catch(Exception ex){
                system.debug(ex);
            }      
        }
      }
      if(continuationWrapper != null && continuationWrapper.responseList != null && continuationWrapper.responseList.size() > 0){
        responseList.addAll(continuationWrapper.responseList);
      }
      return responseList;
    }

    /****************************************************************************************************************
    * @LOB - ABHFL
    * @Function - deleteRecords
    * @param assetDetailid -  Asset Detail Id.
    * @param userId - currentUserId.
    * @return - List<ABHFL_Asset_Detail__c>.
    * @Description - Upsert Asset Detail Record.
    *****************************************************************************************************************/
    @AuraEnabled
    public static String deleteRecordOwnerChange(Id assetDetailid,Id userId){
        try {
            ABHFL_Asset_Detail__c toBeDeletedRecord = [Select id,OwnerId from ABHFL_Asset_Detail__c where Id =: assetDetailid limit 1];
            if(toBeDeletedRecord.OwnerId != userId){
                toBeDeletedRecord.OwnerId = userId;
                if(Schema.sObjectType.ABHFL_Asset_Detail__c.isUpdateable()){
                    update toBeDeletedRecord;
                }
            }
            delete toBeDeletedRecord;
            
            return assetDetailid;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class MultipleLanWrapper{
        @AuraEnabled
        public List<AssetDetailWrapper> assetDetailRecords;
        @AuraEnabled
        public List<ColumnWrapper> columnData;
        @AuraEnabled
        public List<ColumnWrapper> additionalColumnData;
        @AuraEnabled
        public List<ColumnWrapper> childColumnData;
        @AuraEnabled
        public Boolean displayMultipleLan;
        @AuraEnabled
        public Boolean disableFieldEdit;
        @AuraEnabled
        public Boolean displayFetchAll;
        @AuraEnabled
        public Boolean displayAddRows;
        @AuraEnabled
        public Boolean displayDeleteRows;
        @AuraEnabled
        public Boolean displayFileUpload;
        @AuraEnabled
        public List<String> stagesAllowingFieldEdit;
        @AuraEnabled
        public List<String> stagesAllowingFetchAll;
        @AuraEnabled
        public List<String> stagesAllowingAddRows;
        @AuraEnabled
        public List<String> stagesAllowingFileUpload;
        @AuraEnabled
        public List<String> stagesAllowingDeleteRows;
        @AuraEnabled
        public Boolean impactLogic;

        public MultipleLanWrapper(){
            this.displayMultipleLan = false;
            this.disableFieldEdit = true;
            this.displayFetchAll = false;
            this.displayAddRows = false;
            this.displayDeleteRows = false;
            this.displayFileUpload = false;
            this.impactLogic = false;
        }
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
        @AuraEnabled
        public Boolean attachmentStatus;
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
