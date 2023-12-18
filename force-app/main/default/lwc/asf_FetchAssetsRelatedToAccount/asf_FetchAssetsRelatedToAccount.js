import { LightningElement, wire, api, track } from 'lwc';
import fetchAssets from "@salesforce/apex/Asf_FetchAssetRelatedToAccountController.fetchAssets";

import abclBusinessUnit from '@salesforce/label/c.ABCL_Business_Unit';

export default class Asf_FetchAssetsRelatedToAccount extends LightningElement {

    @api recordId;

    @track columns = [];
    @track assetRecords=[];
    @track infoObject = {};

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
        abclBusinessUnit
    };

    @wire(fetchAssets, { accountRecordId: '$recordId' })
    wiredAssets({ error, data }) {
        if (data) {
            let assets = data.assetRecords;
            this.assetRecords = data.assetRecords;
            this.populateLwcDatatableData();
            this.totalNoOfRecordsInDatatable = data.assetRecords.length;
            this.columns = data.columnNameList;
            this.accBusinessUnit = data.accBusinessUnit;
            this.setInfoObj();

            if(this.assetRecords.length > 0 && this.columns.length > 0) {
                this.fieldMappingForCase = data.fieldMappingForCase;
                this.isRenderDatatable = true;
            }

            this.paginationHelper(); // call helper menthod to update pagination logic
        } else if (error) {
            console.log('Error inside--'+error);
        }
    }

    setInfoObj() {
        let abclBusinessUnitArr = this.customLabel.abclBusinessUnit.split(",");
        if(this.totalNoOfRecordsInDatatable == 0 && (abclBusinessUnitArr.includes(this.accBusinessUnit))) {
            this.infoObject.isAsset = false;
        }
    }

    populateLwcDatatableData() {
        
        let generatedDataWithLink = this.assetRecords.map(assetRec => {
            let tempAssetRec = Object.assign({}, assetRec);
            let assetRecordLink   = '/' + assetRec.Id; 
            if(tempAssetRec.hasOwnProperty('Name')) {
                tempAssetRec.assetNameRecLink   = assetRecordLink;
                
            }
            if(tempAssetRec.hasOwnProperty('LAN__c')){
                tempAssetRec.assetLanRecLink = assetRecordLink;
            }
            return tempAssetRec;
        });

        this.assetRecords = generatedDataWithLink;
    }

    onSelectedRow(event) {

        event.preventDefault();
        let checkboxAction = event.detail.config.action;
        let selectedRows=event.detail.selectedRows;
        let currentSelectedRow = event.detail.config.value;
        let currentSelectedRec;

        if(checkboxAction == "rowSelect") {
            this.infoObject.isAsset = "true";
        }
        else if(checkboxAction == "rowDeselect") {
            this.infoObject.isAsset = "false";
        }

        if(checkboxAction === "selectAllRows") {
            this.deselectAllCheckboxes();
            return;
        }

        if(checkboxAction === "rowDeselect" || checkboxAction === "deselectAllRows") {
            this.fieldToBeStampedOnCase = {};
            return;
        }

        if(selectedRows.length == 1){
            this.setFieldMaapingOnCase(selectedRows[0]);
            return;
        }

        this.selectSingleCheckboxLogix(selectedRows, currentSelectedRow);

        let selectedRowNo = currentSelectedRow.split("-")[1];
        currentSelectedRec = this.assetRecords[selectedRowNo];

        if(currentSelectedRec){
            this.setFieldMaapingOnCase(currentSelectedRec);
        }
    }

    // Method Description - Deselect all checkbox from lightning datatable
    deselectAllCheckboxes() {
        let dataTableRecords = this.template.querySelector('lightning-datatable');
        dataTableRecords.selectedRows = [];
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
    }

    nextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.paginationHelper();
    }

    firstPage() {
        this.pageNumber = 1;
        this.paginationHelper();
    }

    lastPage() {
        this.pageNumber = this.totalPages;
        this.paginationHelper();
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
        // set records to display on current page 
        for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if (i === this.totalNoOfRecordsInDatatable) {
                break;
            }
            this.recordsToDisplay.push(this.assetRecords[i]);
        }
    }

}