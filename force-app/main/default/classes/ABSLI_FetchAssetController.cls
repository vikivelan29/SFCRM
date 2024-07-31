/**
 * @description       : ABSLI Fetch Asset LWC Controller
 * @author            : dhinesh.t@salesforce.com
 * @group             : 
 * @last modified on  : 06-03-2024
 * @last modified by  : dhinesh.t@salesforce.com
 * Modifications Log
 * Ver   Date         Author                       Modification
 * 1.0   06-03-2024   dhinesh.t@salesforce.com   Initial Version
**/
public with sharing class ABSLI_FetchAssetController {
	 
     /****************************************************************************************************************
     * @LOB - ABSLI
     * @Function - fetchAssets  - fetch assets related to the account.
     * @param accountRecordId - Account Id
     * @return Asf_FetchAssetRelatedToAccountControllerWrapper - Wrapper
     * @description - Method to get the assets related to the account.
     *****************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static Asf_FetchAssetRelatedToAccountControllerWrapper fetchAssets(String accountRecordId) {

        String accLOB = '';
        Set<String> assetIdSet = new Set<String>();
        Asf_FetchAssetRelatedToAccountControllerWrapper findAssetObj                 = new Asf_FetchAssetRelatedToAccountControllerWrapper();
        Asf_FetchAssetRelatedToAccountControllerWrapper  fieldApiNameOnBasisOfLOBObj = new Asf_FetchAssetRelatedToAccountControllerWrapper();

        List<Account> accList = [SELECT Line_of_Business__c FROM Account WHERE id =:accountRecordId WITH SECURITY_ENFORCED];
        accLOB                = accList[0].Line_of_Business__c;

        fieldApiNameOnBasisOfLOBObj  = fetchFieldApiNameOnBasisOfLOB(accLOB);
        List<String> fieldApiNamList = fieldApiNameOnBasisOfLOBObj.fieldApiNameLst;
        List<ColumnName> colmnNameList   = fieldApiNameOnBasisOfLOBObj.columnNameList;
        String fieldMapping = fieldApiNameOnBasisOfLOBObj.fieldMappingForCase;
        String allFieldApiNameString = String.join(fieldApiNamList,',');
        String escapeSingleQuotes = String.escapeSingleQuotes(allFieldApiNameString);

        String dynamicQuery     = 'SELECT ' + escapeSingleQuotes + ' FROM Asset WHERE Account.Id =:accountRecordId OR Interested_Party__c =:accountRecordId';
        System.debug(LoggingLevel.INFO,'***dynamicQuery:'+dynamicQuery);
        List<Sobject> assetRecLst = Database.query(dynamicQuery);
        System.debug(LoggingLevel.INFO,'***dynamicQueryResult:'+assetRecLst);

        findAssetObj.columnNameList = colmnNameList;
        findAssetObj.assetRecords   = (List<Asset>) assetRecLst;
        findAssetObj.fieldMappingForCase = fieldMapping;
        findAssetObj.accBusinessUnit = accLOB;
        return findAssetObj;

    }

    /****************************************************************************************************************
     * @LOB - ABSLI
     * @Function - fetchFieldApiNameOnBasisOfLOB  - fetch field API name based on LOB
     * @param accLOB - Account's LOB
     * @return Asf_FetchAssetRelatedToAccountControllerWrapper - Wrapper
     * @description - Method to populate the wrapper with columns and their properties.
     *****************************************************************************************************************/
    public static Asf_FetchAssetRelatedToAccountControllerWrapper fetchFieldApiNameOnBasisOfLOB(String accLOB) {
        
        List<String> fieldApiNameList                       = new List<String>();
        Asf_FetchAssetRelatedToAccountControllerWrapper obj = new Asf_FetchAssetRelatedToAccountControllerWrapper();
        List<ColumnName> colNameLst                         = new List<ColumnName>();

        List<ASF_Asset_Metadata__mdt> assetMetaList   = [SELECT Fields_to_Fetch__c,Field_Mapping__c FROM ASF_Asset_Metadata__mdt WHERE Line_Of_Business__c =:accLOB WITH SECURITY_ENFORCED];

        for(ASF_Asset_Metadata__mdt assetMetaRec : assetMetaList) {

            List<String> fieldToFetch  = assetMetaRec.Fields_to_Fetch__c.split(',');
            for(String fld : fieldToFetch) {

                ColumnName colNameObj = new ColumnName();
                TypeAttributes typeAttrbtObj = new TypeAttributes();
                CellAttributes cellAttrbtObj = new CellAttributes();
                TypeAttributesLabel typeAttrLabelObj = new TypeAttributesLabel();
                ToolTip toolTp = new ToolTip();

                String fldLabel = fld.split(':')[0];
                String fieldApiName = fld.split(':')[1];
                String fieldType = fld.split(':').size() > 2 ? fld.split(':')[2] : '';
                colNameObj.label = fldLabel;
                colNameObj.fieldName = fieldApiName;
                
                if(String.isNotBlank(fieldType)) {
                    colNameObj.type = fieldType;
                }

                cellAttrbtObj.alignment = 'left';

                if(fieldType == 'date') {
                    typeAttrbtObj.day   = 'numeric';
                    typeAttrbtObj.month = 'numeric';
                    typeAttrbtObj.year  = 'numeric';
                }
                else if(fieldType == 'url') {
                    if(fieldApiName == 'Name') {
                        colNameObj.fieldName = 'assetNameRecLink';
                    }
                    else if(fieldApiName == 'LAN__c') {
                        colNameObj.fieldName = 'assetLanRecLink';
                        toolTp.fieldName = fieldApiName;
                        typeAttrbtObj.tooltip = toolTp;

                    }
                    else if(fieldApiName == 'Policy_No__c') {
                        colNameObj.fieldName = 'assetLanRecLink';
                        toolTp.fieldName = fieldApiName;
                        typeAttrbtObj.tooltip = toolTp;

                    }
                    else if(fieldApiName == 'Advisor__r.Name') {
                        colNameObj.fieldName = 'advisorNameRecLink';
                        toolTp.fieldName = fieldApiName;
                        typeAttrbtObj.tooltip = toolTp;

                    }
                    typeAttrLabelObj.fieldName = fieldApiName;
                    typeAttrbtObj.label  = typeAttrLabelObj;
                    typeAttrbtObj.target = '_self';
                }

                colNameObj.typeAttributes = typeAttrbtObj;
                colNameObj.cellAttributes = cellAttrbtObj;
                colNameLst.add(colNameObj);
                fieldApiNameList.add(fieldApiName);
            }
        }
        
        obj.fieldApiNameLst = fieldApiNameList;
        obj.columnNameList  = colNameLst;
        obj.fieldMappingForCase = assetMetaList[0].Field_Mapping__c;
        //system.debug(obj);
        return obj;
    }

     /****************************************************************************************************************
     * @LOB - ABSLI
     * @description - Asf_FetchAssetRelatedToAccountControllerWrapper wrapper
     *****************************************************************************************************************/
    public class Asf_FetchAssetRelatedToAccountControllerWrapper {
        @AuraEnabled public List<ColumnName> columnNameList;
        @AuraEnabled public List<Asset> assetRecords;
        @AuraEnabled public List<String> fieldApiNameLst;
        @AuraEnabled public String fieldMappingForCase;
        @AuraEnabled public String accBusinessUnit;
    }
     /****************************************************************************************************************
     * @LOB - ABSLI
     * @description - ColumnName wrapper
     *****************************************************************************************************************/
    public class ColumnName {
        @AuraEnabled public String label;
        @AuraEnabled public String fieldName;
        @AuraEnabled public String type;
        @AuraEnabled public TypeAttributes typeAttributes;
        @AuraEnabled public CellAttributes cellAttributes;
    }
    /****************************************************************************************************************
     * @LOB - ABSLI
     * @description - TypeAttributes wrapper
     *****************************************************************************************************************/
    public class TypeAttributes {
        @AuraEnabled public String day;
        @AuraEnabled public String month;
        @AuraEnabled public String year;
        @AuraEnabled public String currencyCode;
        @AuraEnabled public String target;
        @AuraEnabled public TypeAttributesLabel label;
        @AuraEnabled public ToolTip tooltip;
    }
    /****************************************************************************************************************
     * @LOB - ABSLI
     * @description - CellAttributes wrapper
     *****************************************************************************************************************/
    public class CellAttributes {
        @AuraEnabled public String alignment;
    }
    /****************************************************************************************************************
     * @LOB - ABSLI
     * @description - TypeAttributesLabel wrapper
     *****************************************************************************************************************/
    public class TypeAttributesLabel {
        @AuraEnabled public String fieldName;
    }
    /****************************************************************************************************************
     * @LOB - ABSLI
     * @description - ToolTip wrapper
     *****************************************************************************************************************/
    public class ToolTip {
        @AuraEnabled public String fieldName;
    }
}