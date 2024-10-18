/****************************************************************************************************************
  * Author           - Anirudh Raturi
  * Date             - 28-November-2023
  *****************************************************************************************************************/

import { LightningElement, wire, api, track } from 'lwc';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import fetchAssets from "@salesforce/apex/Asf_FetchAssetRelatedToAccountController.fetchAssets";

import BUSINESS_UNIT_FIELD from "@salesforce/schema/Account.Business_Unit__c";

import abclBusinessUnit from '@salesforce/label/c.ABCL_Business_Unit';
import autoSelectAssetBUList from '@salesforce/label/c.ASF_List_of_BUs_To_AutoSelect_Single_Asset';

const fields = [BUSINESS_UNIT_FIELD];

export default class Asf_FetchAssetsRelatedToAccount extends LightningElement {

    @api recordId;

    @track columns = [];
    @track assetRecords;
    @track infoObject = {};
    @track currentSelRecord = {};
    @track preSelectedRows = [];

    isRenderDatatable = false;
    fieldMappingForCase;
    fieldToBeStampedOnCase;
    accBusinessUnit = "";

    totalNoOfRecordsInDatatable = 0;
    pageSize = 10; //No.of records to be displayed per page
    totalPages; //Total no.of pages
    pageNumber = 1; //Page number    
    recordsToDisplay = []; //Records to be displayed on the page

    customLabel = {
        abclBusinessUnit,
        autoSelectAssetBUList
    };

    @wire(getRecord, { recordId: "$recordId", fields })
    account;

    @wire(fetchAssets, { accountRecordId: '$recordId' })
    wiredAssets({ error, data }) {
        if (data) {
            this.assetRecords = data.assetRecords;
            this.columns = data.columnNameList;
            this.populateLwcDatatableData();
            this.totalNoOfRecordsInDatatable = data.assetRecords.length;


            this.accBusinessUnit = data.accBusinessUnit;
            this.setInfoObj();

            if(this.assetRecords.length > 0 && this.columns.length > 0) {
                this.fieldMappingForCase = data.fieldMappingForCase;
                this.isRenderDatatable = true;
            }

            //PR1030924-55 Asset records should be auto-selected for manual case creation for accounts with only a single asset.
            if(this.totalNoOfRecordsInDatatable == 1 && this.customLabel.autoSelectAssetBUList.split(",").includes(getFieldValue(this.account.data, BUSINESS_UNIT_FIELD))) {
                this.preSelectedRows = [data.assetRecords[0].Id];
                this.infoObject.isAsset = "true";
                this.setFieldMaapingOnCase(data.assetRecords[0]);
            }

            this.paginationHelper(); // call helper menthod to update pagination logic
        } else if (error) {
            console.log('Error inside--'+error);
        }
    }

    setInfoObj() {
        this.infoObject.businessUnit = this.accBusinessUnit;
        let abclBusinessUnitArr = this.customLabel.abclBusinessUnit.split(",");
        if(this.totalNoOfRecordsInDatatable == 0 && (abclBusinessUnitArr.includes(this.accBusinessUnit))) {
            this.infoObject.isAsset = false;
        }
    }

    populateLwcDatatableData() {
        
        let generatedDataWithLink = this.assetRecords.map(assetRec => {
            let tempAssetRec = Object.assign({}, assetRec);
            let assetRecordLink   = `/lightning/r/ObjectName/${assetRec.LAN__c}/view`; 

            for(let columnObj of this.columns) {

                let fldName = columnObj.fieldName;

                if( columnObj.hasOwnProperty('type') && columnObj.type == "url") {
                    fldName =  columnObj.typeAttributes.label.fieldName;
                }
                tempAssetRec[fldName] = this.genericFetchNestedKeyValues(assetRec, fldName);
            }

            if(tempAssetRec.hasOwnProperty('LAN__r') && assetRec["LAN__r"].Name) {
                tempAssetRec.assetNameRecLink   = assetRecordLink;
                
            }
            if(tempAssetRec.hasOwnProperty('LAN__r') && assetRec["LAN__r"].LAN__c){
                tempAssetRec.assetLanRecLink = assetRecordLink;
            } 
            if(tempAssetRec.hasOwnProperty('LAN__r') && assetRec["LAN__r"].Policy_No__c){
                tempAssetRec.assetLanRecLink = assetRecordLink;
            } 

            return tempAssetRec;
        });

        this.assetRecords = generatedDataWithLink;
    }

    // This is a generic function used to fetch nested object key's value
    genericFetchNestedKeyValues(obj, keys) {
     
        keys = keys.split('.');
        let currentObj = obj;
    
        for (let i = 0; i < keys.length; i++) {
            const key = keys[i];
            if (currentObj.hasOwnProperty(key)) {
                currentObj = currentObj[key];
            } else {
                return undefined;
            }
        }
        // Return the value of the nested key
        return currentObj;
    }

    onSelectedRow(event) {

        event.preventDefault();
        this.infoObject.businessUnit = this.accBusinessUnit;

        let currentSelectedRec;
        let checkboxAction = event.detail.config.action;

        if(checkboxAction === "selectAllRows") {
            this.deselectAllCheckboxes();
            return;
        }
        
        if(checkboxAction == "rowSelect") {
            this.infoObject.isAsset = "true";
        }
        else if(checkboxAction == "rowDeselect") {
            this.infoObject.isAsset = "false";
        }

        if(checkboxAction === "rowDeselect" || checkboxAction === "deselectAllRows") {
            this.infoObject.isAsset = "false"; //ABSLAMC UAT-B-19 - Show CTST with folio madatory = false when user has deselected all rows
            this.fieldToBeStampedOnCase = {};
            return;
        }
        
        let selectedRows=event.detail.selectedRows;
        if(selectedRows && selectedRows.length != 0){
            let currentSelectedRow = event.detail.config.value;
            //let getRowNo = Number(currentSelectedRow.split("-")[1]);
            //let selectedRowNo = this.pageNumber == 1 ? getRowNo : ((this.pageNumber - 1) * this.pageSize) + getRowNo;
            //currentSelectedRec = this.assetRecords[selectedRowNo];
            currentSelectedRec = this.recordsToDisplay.find(record => record.Id === currentSelectedRow);
            this.currentSelRecord = currentSelectedRec;
            
            if(selectedRows.length == 1){
                this.setFieldMaapingOnCase(selectedRows[0]);
                return;
            }

            this.selectSingleCheckboxLogix(selectedRows, currentSelectedRow);

            if(currentSelectedRec){
                this.setFieldMaapingOnCase(currentSelectedRec);
            }
        }
    }

    // Method Description - Deselect all checkbox from lightning datatable
    deselectAllCheckboxes() {
       let dataTableRecords = this.template.querySelector('lightning-datatable');
       if(dataTableRecords) {
           dataTableRecords.selectedRows = [];
       }
    }

    // Method Description - Preparing Object that will contain key(Asset Field Api Name) value(Case Field Api Name) pair
    setFieldMaapingOnCase(currentSelectedRowRec) {

        let selectedRowRecord  = currentSelectedRowRec;

        let fldToMapToCaseObj = {};
        if(this.fieldMappingForCase && currentSelectedRowRec) {
            let fldsToSearch =  this.fieldMappingForCase.split(",");
            for(let fld of fldsToSearch) {
                let fldToSearch = fld.split(":")[0];
                let fldToMapToCase = fld.split(":")[1];
                fldToMapToCaseObj[fldToMapToCase] = selectedRowRecord[fldToSearch];
            }
            this.fieldToBeStampedOnCase = fldToMapToCaseObj;
        }
    }

    //  Method Description - Logic to select only one checkbox at a time
    selectSingleCheckboxLogix(selectedRows, currentSelectedRow) {
        if(selectedRows.length>1)
        {
            var el = this.template.querySelector('lightning-datatable');
             let ar = [];
             ar.push(currentSelectedRow);
             el.selectedRows = ar;
        }
    }

    get bDisableFirst() {
        return this.pageNumber == 1;
    }
    get bDisableLast() {
        return this.pageNumber == this.totalPages;
    }

    previousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.paginationHelper();
        this.deselectAllCheckboxesOnNext();
        
    }

    nextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.paginationHelper();
        this.deselectAllCheckboxesOnNext();
        
    }

    firstPage() {
        this.pageNumber = 1;
        this.paginationHelper();
        this.deselectAllCheckboxesOnNext();
        
    }

    lastPage() {
        this.pageNumber = this.totalPages;
        this.paginationHelper();
        this.deselectAllCheckboxesOnNext();
        
    }

    // JS function to handel pagination logic 
    paginationHelper() {
        this.recordsToDisplay = [];
        // calculate total pages
        this.totalPages = Math.ceil(this.totalNoOfRecordsInDatatable / this.pageSize);
        // set page number 
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }
        
        for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if (i === this.totalNoOfRecordsInDatatable) {
                break;
            }
            this.recordsToDisplay.push(this.assetRecords[i]);
        }
    }

    deselectAllCheckboxesOnNext() {
      
        let isCurrRecExistInRecordsToDisplay = this.recordsToDisplay.filter(rec => rec.Id == this.currentSelRecord.Id);
        if(isCurrRecExistInRecordsToDisplay.length == 0) {
            this.deselectAllCheckboxes();   
        }
    }

}