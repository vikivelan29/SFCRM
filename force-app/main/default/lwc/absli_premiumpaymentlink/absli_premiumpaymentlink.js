import { LightningElement, api, track } from 'lwc';
import getTemplateBody from "@salesforce/apex/ABSLI_PremiumPaymentLinkController.getTemplateBody";
import sendCommunication from "@salesforce/apex/ABSLI_PremiumPaymentLinkController.sendCommunication";
import getAllRelatedAssets from '@salesforce/apex/ABSLI_PremiumPaymentLinkController.getAllRelatedAssets';
import getPolicyColumns from '@salesforce/apex/ABSLI_PremiumPaymentLinkController.getPolicyColumns';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { reduceErrors } from 'c/asf_ldsUtils';

export default class Absli_premiumpaymentlink extends LightningElement {
    @api recordId;
    @track showPreview = false;
    @track selectedPolicyId = '';
    @track sendToUnregistered = false;
    @track searchResults;
    @track columns;
    @track searchTerm = '';
    @track originalSearchResults;
    @track selectedRows =[];
    @track showSearchInput = true;

    totalNoOfRecordsInDatatable = 0;
    pageSize = 10; //No.of records to be displayed per page
    totalPages; //Total no.of pages
    pageNumber = 1; //Page number    
    @track recordsToDisplay = []; //Records to be displayed on the page



    displayInfo = {
        primaryField: 'LAN__c',
        additionalFields: ['Name'],
    };
    matchingInfo = {
        primaryField: { fieldPath: 'LAN__c' },
        additionalFields: [{ fieldPath: 'Name' }],
    };

    filter = {};

    async connectedCallback() {
        // Dhinesh - to load columns of policy
        await this.loadColumns();
        await this.loadRelatedAssets();
    }
    

    //Dhinesh
    loadColumns() {
        getPolicyColumns()
            .then(result => {
                if (result && result.length > 0) {
                    this.columns = result.map(column => ({
                        label: column.label,
                        fieldName: column.fieldName,
                        type: column.type
                    }));
                }
            })
            .catch(error => {
                console.error('Error loading columns:', error);
            });
    }
    

    loadRelatedAssets() {
        getAllRelatedAssets({ recordId: this.recordId })
            .then(result => {
                if (result && result.length == 1) {
                    this.totalNoOfRecordsInDatatable = result.length;
                    this.originalSearchResults = result;  
                    this.paginationHelper();
                    const selectedRecord = result[0];
                    this.selectedRows = [selectedRecord.Id]; 
                    const selectEvent = new CustomEvent('select', {
                        detail: { selectedRows: [selectedRecord] }
                    });
                    this.dispatchEvent(selectEvent);
                    this.selectedPolicyId = selectedRecord.Id;
                    this.showSearchInput = false;
                }
                 else if (result && result.length > 1){
                    this.originalSearchResults  = result;
                    //console.log('Original Search Results:', JSON.stringify(this.originalSearchResults,null,2));
                    this.totalNoOfRecordsInDatatable = result.length;
                    this.paginationHelper();
                    this.selectedRows = [];
                } else {
                    console.error('No assets found.');
                }
            })
            .catch(error => {
                console.error('Error fetching assets:', error);
            });
    }

    //Dhinesh
    handleSearchInputChange(event) {
        this.searchTerm = event.target.value.toLowerCase();
        this.filterData();
        //this.totalNoOfRecordsInDatatable = this.searchResults.length;
        //this.paginationHelper();
        
    }

    filterData() {
        if (!this.searchTerm) {
            // If search term is empty, reset to original data
            this.totalNoOfRecordsInDatatable = this.originalSearchResults .length;
            this.paginationHelper();
            return;
        }
    
        this.searchResults = this.originalSearchResults .filter(asset => asset.Policy_No__c.toLowerCase().includes(this.searchTerm));
        this.totalNoOfRecordsInDatatable = this.searchResults.length;
        this.paginationHelper();
    }
    //Dhinesh
    handleRowSelection(event) {
        
        let checkboxAction = event.detail.config.action;

        if(checkboxAction === "selectAllRows") {
            this.deselectAllCheckboxes();
            return;
        }
        if(checkboxAction === "rowDeselect") {
            this.selectedPolicyId = '';
            return;
        }
        let selectedRows=event.detail.selectedRows;
        let currentSelectedRow = event.detail.config.value;

        this.selectedPolicyId = currentSelectedRow;
        this.selectSingleCheckboxLogix(selectedRows, currentSelectedRow);
        
    }
    
    deselectAllCheckboxes() {
        let dataTableRecords = this.template.querySelector('lightning-datatable');
        if(dataTableRecords) {
            dataTableRecords.selectedRows = [];
        }
     }

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
        
        // Calculate total pages
        this.totalPages = Math.ceil(this.totalNoOfRecordsInDatatable / this.pageSize);
        //console.log('inside paginationhelper',totalPages);
        
        // Clamp the page number within the valid range
        this.pageNumber = Math.max(1, Math.min(this.pageNumber, this.totalPages));
        
        let dataToPaginate = this.searchTerm ? this.searchResults : this.originalSearchResults;
        
        // Iterate over records to display
        for (let i = (this.pageNumber - 1) * this.pageSize; i < Math.min(this.pageNumber * this.pageSize, dataToPaginate.length); i++) {
            this.recordsToDisplay.push(dataToPaginate[i]);
        }
        
    }

    deselectAllCheckboxesOnNext() {
      
        let isCurrRecExistInRecordsToDisplay = this.recordsToDisplay.filter(rec => rec.Id == this.currentSelRecord.Id);
        if(isCurrRecExistInRecordsToDisplay.length == 0) {
            this.deselectAllCheckboxes();   
        }
    }
    
    invokeCloseModal(){
        this.dispatchEvent(new CustomEvent('closepopup', {
            detail: {
                message: true
            }
        }));
    }
    
    async handlePrevSend(event){
        console.log('This method is to preview the SMS Content before sneding it to user.');
        console.log('What Id',this.recordId);
        console.log('Policy Id',this.selectedPolicyId);
        await getTemplateBody({whatId : this.recordId, policyId : this.selectedPolicyId})
        .then((result)=>{
            this.templateBody = result;
            this.showPreview = true;
        })
        .catch((error) => {
            console.log(error);
            this.showPreview = false;
        });

    }
    handleSend(event){
        this.sendCommunication(this.recordId);
    }
    @api
    sendCommunication(parentRecordId){

        console.log('Class Name --> '+parentRecordId);
        if(this.IsInputValid()){
            let unregistedPhoneNumber = null;
            if(this.refs.unregisterednumber){
                unregistedPhoneNumber = this.refs.unregisterednumber.value;
            }
            sendCommunication({accountId : parentRecordId, policyId : this.selectedPolicyId, unregisteredNumber: unregistedPhoneNumber})
            .then((result)=>{
                this.invokeCloseModal();
                this.showSuccessMessage('success', 'SMS triggered successfully.', '');
    
            })
            .catch((error)=>{
                console.log('error');
                this.showError('error', 'Unable to send SMS.', error);
                debugger;
    
            })
        }
        
    }
    handleToggle(event){
        this.sendToUnregistered = !this.sendToUnregistered;
    }
    IsInputValid(){
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.validate');
        inputFields.forEach(inputField=>{
            debugger;
            if(!inputField.checkValidity()){
                inputField.reportValidity();
                isValid = false;
            }
        });
        return isValid;
    }

    invokeCloseModal(){
        this.dispatchEvent(new CustomEvent('closepopup', {
            detail: {
                message: true
            }
        }));
    }
    showError(variant, title, error) {
        let errMsg = reduceErrors(error);
        const event = new ShowToastEvent({
            variant: variant,
            title: title,
            message: Array.isArray(errMsg) ? errMsg[0] : errMsg
        });
        this.dispatchEvent(event);
    }
    showSuccessMessage(variant, title, message) {
        const event = new ShowToastEvent({
            variant: variant,
            title: title,
            message: message
        });
        this.dispatchEvent(event);
    }
    handleBack(event){
        this.showPreview = false;
        this.selectedPolicyId = '';
        this.searchTerm = '';
        this.searchResults = [...this.originalSearchResults]; 
        this.totalNoOfRecordsInDatatable = this.searchResults.length;
        this.paginationHelper();
        this.selectedRows = [];
        this.sendToUnregistered = false;
    }

}