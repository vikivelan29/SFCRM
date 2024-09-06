import { LightningElement, api, wire, track } from 'lwc';
import fetchAssets from '@salesforce/apex/Asf_FetchAssetRelatedToAccountController.fetchAssets'
import LightningModal from 'lightning/modal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class Abhi_clickPSSCommCmp extends LightningElement {
    @api recordId;
    @api objectApiName;
    message = '';
    recordsToDisplay=[];
    showTable=true;
    showRecords=false;
    isLoading=false;
    selectedRow;
    
    @track columns = [];
    @track assetRecords;
    
    @track currentSelRecord = {};
    
    totalNoOfRecordsInDatatable = 0;
    pageSize = 10; //No.of records to be displayed per page
    totalPages; //Total no.of pages
    pageNumber = 1; 
    showForm =false;
    
    displayMessage='';
    displayError = false;
    

    connectedCallback(){
        this.isLoading=true;
    }

    @wire(fetchAssets, { accountRecordId: '$recordId' })
    wiredAssets({ error, data }) {
        if (data) {
            console.log('Data>>>', data);
            this.assetRecords = data.assetRecords;
            this.columns = data.columnNameList;
            this.populateLwcDatatableData();
            this.totalNoOfRecordsInDatatable = data.assetRecords.length;
            if(this.assetRecords.length > 0 && this.columns.length > 0) {
                this.showRecords = true;
                this.isLoading = false;
            }
            this.paginationHelper(); // call helper method to update pagination logic
        } else if (error) {
            console.log('Error inside--'+error);
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
        try {
            event.preventDefault();
            let currentSelectedRec;
            let checkboxAction = event.detail.config.action;
            console.log('checkBoxAction>>>', checkboxAction);
            if(checkboxAction === "selectAllRows") {
                this.deselectAllCheckboxes();
                return;
            }
            if(checkboxAction == "rowDeselect"){
                this.currentSelRecord = {};
                return;
            }
            let selectedRows=event.detail.selectedRows;
            let currentSelectedRow = event.detail.config.value;
            this.selectedRow = currentSelectedRow;
            
            let getRowNo = Number(currentSelectedRow.split("-")[1]);
            let selectedRowNo = this.pageNumber == 1 ? getRowNo : ((this.pageNumber - 1) * this.pageSize) + getRowNo;
            currentSelectedRec = this.assetRecords[selectedRowNo];
            this.currentSelRecord = currentSelectedRec;
            console.log('selectedRecord>>>', JSON.stringify(this.currentSelRecord));
            this.selectSingleCheckboxLogix(selectedRows, currentSelectedRow);
        } catch (error) {
            console.error('Error in selection>>>', JSON.stringify(error));
            
        }
    }

    //  Method Description - Logic to select only one checkbox at a time
    selectSingleCheckboxLogix(selectedRows, currentSelectedRow) {
        console.log('selectedRowsLength>>>', selectedRows.length);
        console.log('currentSelectedRow>>>', currentSelectedRow);
        
        if(selectedRows.length>1)
        {
            var el = this.template.querySelector('lightning-datatable');
            console.log('el>>>', el);
             let ar = [];
             ar.push(currentSelectedRow);
             el.selectedRows = ar;
        }
    }

    handleClick(event){
        let buttonLabel = event.target.label;
        console.log('buttonLabel>>>', buttonLabel);
        if(buttonLabel === 'Next'){
            console.log('Current Record>>>', JSON.stringify(this.currentSelRecord));
            console.log('Current Record Values>>>', Object.values(this.currentSelRecord).length);
            
            if(Object.values(this.currentSelRecord).length == 0){
                this.showToast('Error', 'Please select a record', 'error');
            }
            else{
                this.showTable=false;
                this.showForm=true;
                } 
            
        }
        
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissible'
        });
        this.dispatchEvent(event);
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
        console.log('RecordsTOdisplay>>', this.recordsToDisplay);
        
    }

    deselectAllCheckboxesOnNext() {
      try {
        let isCurrRecExistInRecordsToDisplay = this.recordsToDisplay.filter(rec => rec.Id == this.currentSelRecord.Id);
        if(isCurrRecExistInRecordsToDisplay.length == 0) {
            this.deselectAllCheckboxes();   
        }
      } catch (error) {
        console.error('Error in deselect>>>', error);
        
      }
        
    }

     // Method Description - Deselect all checkbox from lightning datatable
     deselectAllCheckboxes() {
        let dataTableRecords = this.template.querySelector('lightning-datatable');
        if(dataTableRecords) {
            dataTableRecords.selectedRows = [];
        }
     }

     
}