import { LightningElement, wire, api, track } from 'lwc';
import fetchAssets from "@salesforce/apex/Asf_FetchAssetRelatedToAccountController.fetchAssets";

export default class Asf_FetchAssetsRelatedToAccount extends LightningElement {

    @api recordId;

    @track columns = [];
    @track assetRecords;

    isRenderDatatable = false;
    fieldMappingForCase;
    fieldToBeStampedOnCase;
    totalNoOfRecordsInDatatable;

    @wire(fetchAssets, { accountRecordId: '$recordId' })
    wiredAssets({ error, data }) {
        if (data) {
            this.assetRecords = data.assetRecords;
            this.populateLwcDatatableData();
            this.totalNoOfRecordsInDatatable = data.assetRecords.length;
            this.columns = data.columnNameList;
            if(this.assetRecords.length > 0 && this.columns.length > 0) {
                this.fieldMappingForCase = data.fieldMappingForCase;
                this.isRenderDatatable = true;
            }
        } else if (error) {
            console.log('Error inside--'+error);
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
        let selectRowRec   = event.detail.selectedRows;
        let currentSelectedRow = event.detail.config.value;
        let currentSelectedRec;

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

}