import { LightningElement, api, track, wire } from 'lwc';
import generateLink from "@salesforce/apex/ABSLI_QuickKillController.generateLink";
import generateBitlyLink from "@salesforce/apex/ABSLI_QuickKillController.generateBitlyLink";
import sendCommunication from "@salesforce/apex/ABSLI_QuickKillController.sendCommunication";
import getAllRelatedAssets from '@salesforce/apex/ABSLI_QuickKillController.getAllRelatedAssets';
import getPolicyColumns from '@salesforce/apex/ABSLI_QuickKillController.getPolicyColumns';
import deleteDraftLogs from '@salesforce/apex/ABSLI_QuickKillController.deleteDraftLogs';
import getCustomerPhoneNumber from '@salesforce/apex/ABSLI_QuickKillController.getCustomerPhoneNumber';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { reduceErrors } from 'c/asf_ldsUtils';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";



import MOBILE_FIELD from "@salesforce/schema/Account.PersonMobilePhone";


const fields = [MOBILE_FIELD];



export default class Absli_quickkill extends LightningElement {
    @api recordId;
    @track selectedPolicyId = '';
    @track selectedFuncValue = '';
    @track templateBody = '';
    @track showPreview = false;
    @track showPolicy = false;
    @track showQuickServices = false;
    @track cLogId = '';
    @track sendToUnregistered = false;
    @track showLoading = false;
    @track controlGenerateLink = false;
	@track searchResults;
    @track columns;
    @track searchTerm = '';
    @track originalSearchResults;
    @track selectedRows =[];
    @track showSearchInput = true;
    @track showGenerateLink = false;
    @track bErrored = false;
    @track noMobileNum = false;
    @track loaded = false;
    @track accountRecord;
	
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


    @wire(getCustomerPhoneNumber, { recordId: "$recordId"})
    async wiredRecord({ error, data }) {
        if (error) {
          console.log(JSON.stringify(error));
        } else if (data) {
            debugger;
            //this.accountRecord = data;

            let mobVal = data;//this.accountRecord.fields.PersonMobilePhone.value;
            if(mobVal != null && mobVal != ""){
                await this.loadColumns();
                await this.loadRelatedAssets();
                this.noMobileNum = false;
                this.loaded = true;
            }
            else{
                this.noMobileNum = true;
                this.loaded = true;
            }
        }
      }
    
    
    
    get showPolicyTable(){
        return !(!this.noMobileNum && this.loaded && !this.showPolicy);
    }

    async connectedCallback() {
        // Dhinesh - to load columns of policy
        //this.loadColumns();
        //this.loadRelatedAssets();
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
	async handleQuickLink(event){
        console.log('This method is to preview the SMS Content before sneding it to user.');
        console.log('What Id',this.recordId);
        console.log('Policy Id',this.selectedPolicyId);
        if (this.selectedPolicyId) {
            this.showPolicy = true;
            this.showQuickServices = true;
        }
    }

    get options() {
        return [
            { label: 'Address Update', value: 'ADDRU' },
            { label: 'Apply for Loan', value: 'LA' },
            { label: 'Bank Details update', value: 'BAU' },
            { label: 'Download Document', value: 'TCD' },
            { label: 'Email ID Update', value: 'EU' },
            { label: 'e-NACH STP', value: 'ENACH' },
            { label: 'FATCA update', value: 'FD' },
            { label: 'Fund Switch/Premium Redirection', value: 'FS' },
            { label: 'Loan Repayment', value: 'LR' },
            { label: 'Mobile Number Update', value: 'CNU' },
            { label: 'Mode Change', value: 'MC' },
            { label: 'Nominee Update', value: 'NU' },
            { label: 'Open EIA', value: 'EI' },
            { label: 'Pan details update', value: 'PU' },
            { label: 'Pay Premium', value: 'PP' },
            { label: 'Purpose of Insurance', value: 'POI' },
            { label: 'Reinstate Policy', value: 'RI' },
            { label: 'Surrender Retention by Branch', value: 'RPJ' },
            { label: 'Survival Certificate', value: 'SC' }

        ];
    }
    handleFuncSelection(event){
        this.selectedFuncValue = event.detail.value;
        if(this.selectedFuncValue){
            this.showGenerateLink = true;
        }
        
         
    }
    handleGenerateLinkPrev(event){
        console.log(this.selectedFuncValue);
        this.showLoading = true;
        this.controlGenerateLink = true;
        this.showQuickServices = false;
        this.showGenerateLink = false;
        generateLink({functionName: this.selectedFuncValue, accountId : this.recordId, policyId : this.selectedPolicyId})
        .then((result)=>{
            console.log('result --> '+result);
            this.cLogId = result;
            this.invokeBitlyIntegration(result,this.selectedFuncValue);
        })
        .catch((error)=>{
            this.showLoading = false;
            this.controlGenerateLink = false;
        })
    }
    async invokeCloseModal(){
        if(this.cLogId != null && this.cLogId != undefined && this.cLogId != ''){
            await deleteDraftLogs({commLogId : this.cLogId})
            .then((result)=>{
                if(result == true){
                    console.log('Deleted Draft Communication Log.');
                }
                else{
                    this.showError('error', 'Something went Wrong ! Please contact system administrator.');
                }
            })
            .catch((error)=>{
                this.showError('error', 'Something went Wrong ! ');
            })
        }
        this.dispatchEvent(new CustomEvent('closepopup', {
            detail: {
                message: true
            }
        }));
    }
    async invokeBitlyIntegration(commLogId,functionCode){
        debugger;
        await generateBitlyLink({cLogId : commLogId, funcCode : functionCode})
        .then((result)=>{
            this.templateBody = result;
            this.showPreview = true;
            this.showLoading = false;
            this.bErrored = false;
        })
        .catch((error)=>{
            let errMsg = reduceErrors(error);
            this.templateBody = errMsg;
            this.showPreview = true;
            this.showLoading = false;
            this.bErrored = true;
        })
    }
    get showSendButton(){
        return this.showPreview && !this.bErrored;
    }
    handleSend(event){
        this.sendCommunication(this.recordId);
    }
    @api
    sendCommunication(parentRecordId){

        console.log('Class Name --> '+parentRecordId);
        if(this.IsInputValid()){
            debugger;
            let unregistedPhoneNumber = null;
            /* DONT NEED BELOW CODE AS UNREGISTERED PHONE NUMBER REQUIREMENT IS NOT FOR QUICK LINK.
            if(this.refs.unregisterednumber){
                unregistedPhoneNumber = this.refs.unregisterednumber.value;
            }
            */
            sendCommunication({cLogId : this.cLogId, smsTxt : this.templateBody, unregisteredNumber: unregistedPhoneNumber})
            .then((result)=>{
                this.dispatchEvent(new CustomEvent('closepopup', {
                    detail: {
                        message: true
                    }
                }));
                this.showSuccessMessage('success', 'SMS & Email triggered successfully.', '');
    
            })
            .catch((error)=>{
                console.log('error');
                this.showError('error', 'Unable to send SMS & Email.', error);
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
}