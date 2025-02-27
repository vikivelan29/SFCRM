import { LightningElement, wire, api, track} from 'lwc';
import fetchAssets from "@salesforce/apex/Asf_FetchAssetRelatedToAccountController.fetchAssets";
import abclBusinessUnit from '@salesforce/label/c.ABCL_Business_Unit';

export default class Abcl_cx_relationValueTabs extends LightningElement {
    @track activeTabValue = 'LAN'; // Default active tab
    @track insuranceData = [];

    insuranceColumns = [
        { label: 'Policy Number', fieldName: 'policyNumber' },
        { label: 'LAN Mapped', fieldName: 'lanMapped' },
        { label: 'Insured Name', fieldName: 'insuredName' },
        { label: 'Insurance Amount', fieldName: 'insuranceAmount' },
        { label: 'Insurance Provider', fieldName: 'insuranceProvider' },
        { label: 'Policy Start Date', fieldName: 'policyStartDate' },
        { label: 'Policy End Date', fieldName: 'policyEndDate' },
    ];
    @api recordId;
    @track columns = [];
    @track assetRecords;
    @track infoObject = {};
    @track currentSelRecord = {};
    
    isRenderDatatable = false;
    fieldMappingForCase;
    fieldToBeStampedOnCase;
    accBusinessUnit = "";

    totalNoOfRecordsInDatatable = 0;
    pageSize = 10; //No.of records to be displayed per page
    totalPages; //Total no.of pages
    pageNumber = 1; //Page number    
    recordsToDisplay = []; //Records to be displayed on the page

    ShowInsuranceData = true;   // added by Yogesh for ABFL C360 related changes

    customLabel = {
        abclBusinessUnit
    };

    handleTabChange(event) {
        this.activeTabValue = event.target.value;
    }
    
    @wire(fetchAssets, { accountRecordId: '$recordId' })
    wiredAssets({ error, data }) {
        if (data) {
            this.assetRecords = data.assetRecords;
            this.columns = data.columnNameList;
            this.populateLwcDatatableData();
            this.totalNoOfRecordsInDatatable = data.assetRecords.length;
            this.accBusinessUnit = data.accBusinessUnit;
       // Added below condition by Yogesh for ABFL C360 related changes
            if(this.accBusinessUnit == 'ABFL' || this.accBusinessUnit == 'Wealth'){
            this.ShowInsuranceData = false;
        }
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
            let assetRecordLink   = `/lightning/r/ObjectName/${assetRec.Id}/view`;
            let advisorRecordLink   = `/lightning/r/ObjectName/${assetRec.Advisor__c}/view`;  

            for(let columnObj of this.columns) {

                let fldName = columnObj.fieldName;

                if( columnObj.hasOwnProperty('type') && columnObj.type == "url") {
                    fldName =  columnObj.typeAttributes.label.fieldName;
                }
                tempAssetRec[fldName] = this.genericFetchNestedKeyValues(assetRec, fldName);
            }

            if(tempAssetRec.hasOwnProperty('LAN__c')) {
                tempAssetRec.assetLanRecLink = assetRecordLink;
            }
            if(tempAssetRec.hasOwnProperty('Policy_No__c')) {
                tempAssetRec.assetLanRecLink = assetRecordLink;
                console.log("Here in Policy_No__c", JSON.stringify(tempAssetRec, null, 2));
            }

            if(tempAssetRec.hasOwnProperty('LAN__r') && assetRec["LAN__r"].Name) {
                tempAssetRec.assetNameRecLink   = assetRecordLink;
                
            }
            if(tempAssetRec.hasOwnProperty('LAN__r') && assetRec["LAN__r"].LAN__c){
                tempAssetRec.assetLanRecLink = assetRecordLink;
            }
            if(tempAssetRec.hasOwnProperty('Advisor__r') && assetRec["Advisor__r"].Name){
                tempAssetRec.advisorNameRecLink= advisorRecordLink;
                console.log("Here in Advisor__c", JSON.stringify(tempAssetRec, null, 2));
            }  

            return tempAssetRec;
        });

        this.assetRecords = generatedDataWithLink;
        console.log("Inside populatelwc", JSON.stringify(this.assetRecords, null, 2));
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
            this.fieldToBeStampedOnCase = {};
            return;
        }
        
        let selectedRows=event.detail.selectedRows;
        let currentSelectedRow = event.detail.config.value;
        
        let getRowNo = Number(currentSelectedRow.split("-")[1]);
        let selectedRowNo = this.pageNumber == 1 ? getRowNo : ((this.pageNumber - 1) * this.pageSize) + getRowNo;
        currentSelectedRec = this.assetRecords[selectedRowNo];
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
