/****************************************************************************************************************
  * Author           - Anirudh Raturi
  * Date             - 28-November-2023
*****************************************************************************************************************/

@SuppressWarnings('PMD')
public with sharing class Asf_FetchAssetRelatedToAccountController {
    
    /****************************************************** 
    * Description      - Getting asset records on the basis of Account LOB and to the related account.
    * return params    - Asf_FetchAssetRelatedToAccountControllerWrapper object
    ********************************************************
    */
    @AuraEnabled(cacheable=true)
    public static Asf_FetchAssetRelatedToAccountControllerWrapper fetchAssets(String accountRecordId) {

        String accLOB = '';
        Set<String> assetIdSet = new Set<String>();
        Asf_FetchAssetRelatedToAccountControllerWrapper findAssetObj                 = new Asf_FetchAssetRelatedToAccountControllerWrapper();
        Asf_FetchAssetRelatedToAccountControllerWrapper  fieldApiNameOnBasisOfLOBObj = new Asf_FetchAssetRelatedToAccountControllerWrapper();

        List<Account> accList = [SELECT Line_of_Business__c FROM Account WHERE id =:accountRecordId];
        accLOB                = accList[0].Line_of_Business__c;

        fieldApiNameOnBasisOfLOBObj  = fetchFieldApiNameOnBasisOfLOB(accLOB);
        List<String> fieldApiNamList = fieldApiNameOnBasisOfLOBObj.fieldApiNameLst;
        List<ColumnName> colmnNameList   = fieldApiNameOnBasisOfLOBObj.columnNameList;
        String fieldMapping = fieldApiNameOnBasisOfLOBObj.fieldMappingForCase;
        String allFieldApiNameString = String.join(fieldApiNamList,',');
        String escapeSingleQuotes = String.escapeSingleQuotes(allFieldApiNameString);

        System.debug('***escapeSingleQuotes:'+escapeSingleQuotes);
        String dynamicQuery = '';
        List<Sobject> assetRecLst = new List<SObject>();
        if(!ASF_Constants.BUSpecificLANKey.contains(accLOB)){
            dynamicQuery     = 'SELECT ' + escapeSingleQuotes + ' FROM LAN_Mapping__c WHERE Customer__c =:accountRecordId AND Lan__c != null';
            System.debug('***dynamicQuery:'+dynamicQuery);
            assetRecLst = Database.query(dynamicQuery);
        }

        findAssetObj.columnNameList = colmnNameList;
        if(!ASF_Constants.BUSpecificLANKey.contains(accLOB)){
            findAssetObj.assetRecords   = (List<LAN_Mapping__c>) assetRecLst;
        }
        else{
            findAssetObj.assetRecords   = new List<LAN_Mapping__c>();
        }
        
        findAssetObj.fieldMappingForCase = fieldMapping;
        findAssetObj.accBusinessUnit = accLOB;
        return findAssetObj;

    }

    /****************************************************** 
    * Description      - Getting field Api Name list, column Name List and field Mapping for Case on the basis of Account LOB.
    * return params    - Asf_FetchAssetRelatedToAccountControllerWrapper object
    ********************************************************
    */
    public static Asf_FetchAssetRelatedToAccountControllerWrapper fetchFieldApiNameOnBasisOfLOB(String accLOB) {
        
        List<String> fieldApiNameList                       = new List<String>();
        Asf_FetchAssetRelatedToAccountControllerWrapper obj = new Asf_FetchAssetRelatedToAccountControllerWrapper();
        List<ColumnName> colNameLst                         = new List<ColumnName>();

        List<ASF_Asset_Metadata__mdt> assetMetaList   = [SELECT Fields_to_Fetch__c,Field_Mapping__c FROM ASF_Asset_Metadata__mdt WHERE Line_Of_Business__c =:accLOB];

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
                    if(fieldApiName == 'LAN__r.Name') {
                        colNameObj.fieldName = 'assetNameRecLink';
                    }
                    else if(fieldApiName == 'LAN__r.LAN__c') {
                        colNameObj.fieldName = 'assetLanRecLink';
                        toolTp.fieldName = fieldApiName;
                        typeAttrbtObj.tooltip = toolTp;

                    }
                    else if(fieldApiName == 'LAN__r.Policy_No__c') {
                        colNameObj.fieldName = 'assetLanRecLink';
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

        return obj;
    }

    public class Asf_FetchAssetRelatedToAccountControllerWrapper {
        @AuraEnabled public List<ColumnName> columnNameList;
        @AuraEnabled public List<LAN_Mapping__c> assetRecords;
        @AuraEnabled public List<String> fieldApiNameLst;
        @AuraEnabled public String fieldMappingForCase;
        @AuraEnabled public String accBusinessUnit;
    }

    public class ColumnName {
        @AuraEnabled public String label;
        @AuraEnabled public String fieldName;
        @AuraEnabled public String type;
        @AuraEnabled public TypeAttributes typeAttributes;
        @AuraEnabled public CellAttributes cellAttributes;
    }

    public class TypeAttributes {
        @AuraEnabled public String day;
        @AuraEnabled public String month;
        @AuraEnabled public String year;
        @AuraEnabled public String currencyCode;
        @AuraEnabled public String target;
        @AuraEnabled public TypeAttributesLabel label;
        @AuraEnabled public ToolTip tooltip;
    }

    public class CellAttributes {
        @AuraEnabled public String alignment;
    }

    public class TypeAttributesLabel {
        @AuraEnabled public String fieldName;
    }

    public class ToolTip {
        @AuraEnabled public String fieldName;
    }
}