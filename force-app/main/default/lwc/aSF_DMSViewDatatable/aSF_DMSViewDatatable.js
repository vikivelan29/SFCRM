import { LightningElement, wire, api, track } from 'lwc';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import syncDMSFilesManually from '@salesforce/apex/ABFL_DMSSync_Orchestrator.syncDMSFilesManually';
import executeQuery from '@salesforce/apex/Asf_DmsViewDataTableController.executeQuery';
import DMS_URL from '@salesforce/label/c.DMS_URL';
import generateLinkParams from '@salesforce/apex/Asf_DmsViewDataTableController.generateLinkParams';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import noFileAvailableLabel from '@salesforce/label/c.No_DMS_File';
import DMS_File_Name from '@salesforce/label/c.DMS_File_Name';
import Manual_Synching from '@salesforce/label/c.Manual_Synching';
import Synched_Already from '@salesforce/label/c.Synched_Already';
import Sync_Canceled from '@salesforce/label/c.Sync_Canceled';
import Synching_initiated from '@salesforce/label/c.Synching_initiated';
import Sync_Manually from '@salesforce/label/c.Sync_Manually';
import pageSize from '@salesforce/label/c.ABFL_DMSPageSize';
import manualSyncThreshold from '@salesforce/label/c.ABFL_Manual_Sync_Threshold';
import ABSLI_BU from '@salesforce/label/c.ABSLI_BU';
import { getColumnsStatic } from './asf_DMSColumn';
import { getRecord } from "lightning/uiRecordApi";

const CASEFIELDS = ["Case.Business_Unit__c"];

export default class ASF_DMSViewDatatable extends NavigationMixin(LightningElement) {
    isLoading=false;
    @api recordId;
    @track tableData = [];
    @track columns = [];
    @track isRecordPresent = false;
    // baseUrl;
    @api showChecklistColumn = false; 
    currentlySelectedData=[];
    @track dmsList = []; 
    noFileAvailableLabel = noFileAvailableLabel;
    isDisabled = true;
    @track currentPage = 1;
    @track totalRecords = 0;
    businessUnit;
    label = {
        pageSize
    };
    processApexReturnValue;

    /**Table Attributes */
    totalNoOfRecordsInDatatable = 0;
    totalPages; //Total no.of pages
    pageNumber = 1; //Page number

    // @api recordPerPage;
    recordsToDisplay;
    isPreviousDisabled ;
    isNextDisabled;

    @wire(getRecord, { recordId: "$recordId", fields: CASEFIELDS })
    async processResult(caseResult) {
        this.processApexReturnValue = caseResult;

        if (caseResult.data) {
            this.retrieveData();
            this.isPreviousDisabled = true;
        }
    }

    connectedCallback() {
    }
    retrieveData() {
        this.isLoading=true;
        this.retrieveColumns()
            .then(() => this.retrieveDataTable())
            .catch(error => {
                // todo: remove hardcoding
                console.error('Error column records:',JSON.stringify(error));
                this.showToast('Error','Error fetching data.','Error');
            });
    }
    retrieveColumns() {
        return new Promise((resolve, reject) => {
            getColumns({configName:'Asf_DMS_File_Datatable'})
                .then(result => {
                    this.columns = getColumnsStatic(result,this.processApexReturnValue.data.fields.Business_Unit__c.value);
                    /*
                    this.columns = [
                        {
                            label: DMS_File_Name,
                            fieldName: 'accLink',
                            type: 'url',
                            fixedWidth: 260,
                            typeAttributes: { label: { fieldName: 'File_Name__c' }, target: '_self' }
                        },
                        {
                            fieldName: 'Error_Description__c',
                            label: 'Status',
                            type: 'url',
                            typeAttributes: { label: { fieldName: 'dynamicIconText' }, target: '_self' },
                            cellAttributes: { iconName: { fieldName: 'dynamicIcon' }, iconAlternativeText: {fieldName: 'dynamicIconText' } }
                        }
                        ,
                        ...result.map(col => ({
                            label: col.MasterLabel,
                            fieldName: col.Api_Name__c,
                            type: col.Data_Type__c,
                            cellAttributes: { alignment: 'left' }
                        })),
                        {
                            label: 'Actions',
                            type: 'button',
                            typeAttributes: {
                                label: 'View Link',
                                name: 'viewLink',
                                variant: 'base',
                                disabled: { fieldName: 'showButtons' }
                            }
                        },
                        {
                            label: Manual_Synching,
                            type: 'button',
                            typeAttributes: {
                                label: { fieldName: 'actionText' },
                                name: 'manualSync',
                                variant: 'base',
                                disabled: { fieldName: 'showButtonsSynch' }
                            }
                        }
                    ];*/
                    resolve();
                })
                .catch(error => reject(error));
        });
    }

    // JS function to handel pagination logic 
    paginationHelper() {
        this.recordsToDisplay = [];
        // calculate total pages
        this.totalPages = Math.ceil(this.totalNoOfRecordsInDatatable / this.label.pageSize);
        // set page number 
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }

        for (let i = (this.pageNumber - 1) * this.label.pageSize; i < this.pageNumber * this.label.pageSize; i++) {
            if (i === this.totalNoOfRecordsInDatatable) {
                break;
            }
            this.recordsToDisplay.push(this.tableData[i]);
        }
        // this.selectedRows = [];
    }
    
    retrieveDataTable() {
        executeQuery({ caseId: this.recordId})
            .then(result => {
                // Check if result exists and has data
                if (result) {
                    const currentDateTime = new Date();
                    // Process each record and add additional properties
                    this.tableData = result.map(res => {
                        let processedRes = { ...res }; // Create a copy of the record
                        processedRes.accLink = '/' + res.Id;
                        if (res.DocumentID__c == null || res.DocumentID__c == '0') {
                            processedRes.showButtons = true;
                        }
                        // If retry attempt is < 2, then consider Next_Retry__c else consider lastmodifieddate
                        let nextRetryDateTime;
                        if(res.Next_Retry__c < 2){
                            nextRetryDateTime= new Date(res.Next_Retry__c);
                        }else{
                            nextRetryDateTime= new Date(new Date(res.LastModifiedDate).getTime() + manualSyncThreshold*60000);
                        }
                         
                        processedRes.showButtonsSynch = res.Status__c === 'Success' || res.Status__c === 'Canceled' || (res.Status__c === 'Pending' && currentDateTime < nextRetryDateTime) || res.Retry_Attempt__c < 2;
                        processedRes.actionText = res.Status__c === 'Success' ? Synched_Already : (res.Status__c === 'Canceled' ? Sync_Canceled : (res.Status__c === 'Pending' && currentDateTime < nextRetryDateTime ? Synching_initiated : (res.Status__c === 'Failure' && res.Retry_Attempt__c < 2 ? 'Autosync process' : Sync_Manually)));
                        processedRes.dynamicIcon = res.Status__c === 'Success' ? 'utility:warranty_term' : (res.Status__c === 'Canceled' ? 'utility:cancel_file_request' : (res.Status__c === 'Pending' ? 'utility:real_time' : 'utility:error'));
                        processedRes.dynamicIconText = res.Status__c;
                        processedRes.Error_Description__c = res.Error_Description__c?res.Error_Description__c:'Sync Initiated!';
                        return processedRes;
                    });
                    
                    this.totalNoOfRecordsInDatatable = this.tableData?.length;
                    // Set total records
                    console.log('this.totalRecords ', this.totalNoOfRecordsInDatatable);  
                    this.paginationHelper();
                    // Update visibility flags
                    this.isRecordPresent = this.totalNoOfRecordsInDatatable!=0;
                    this.isLoading = false;
                } else {
                    // Handle case where result or result.data is empty
                    console.error('Error fetching records: Result or Result data is empty');
                    this.showToast('Error', 'Error fetching records.', 'Error');
                }
            })
            .catch(error => {
                console.error('Error fetching records:', error);
                this.showToast('Error', 'Error fetching records.', 'Error');
            });
        }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        console.log('Row Object:', JSON.stringify(row));
        if (action.name === 'viewLink') {
            if (row.DocumentID__c == null || row.DocumentID__c == undefined) {
                this.showToast('Error','Document Id is null','Error');
            } else {
                //Currently ABSLI DMS Integration is not having any Redirect URL. In Future when this URL is provided please write your code down here.
                if(row.Business_Unit__c != ABSLI_BU){
                    generateLinkParams({ documentId: row.DocumentID__c })
                    .then(result => {
                        console.log('generateLinkParams:', result);
                        // this.baseUrl = DMS_URL;
                        let res = JSON.parse(result);
                        if(res?.encyptedDocId != null && res?.userDbId != null){
                        const dynamicUrl = `${DMS_URL}&Userdbid=${res.userDbId}&DocumentId=${res.encyptedDocId}`;
                        console.log('dynamicUrl:', dynamicUrl);
                        this[NavigationMixin.Navigate]({
                            type: 'standard__webPage',
                            attributes: {
                                url: dynamicUrl
                            }
                        });
                    } else {
                        this.showToast('Error', 'Something went wrong! There is some error in viewing the document. Please contact System Admin.', 'Error');
                    }
                    })
                    .catch(error => {
                       // console.error('Error:', error);
                        this.showToast('Error','Error fetching necessary document view attributes.','Error');
                    });
                }
            }
        } else if (action.name === 'manualSync') {
            console.log('manualSync ');
            syncDMSFilesManually({ lDmsIds: row.Id })
                .then(result => {
                    console.log('***result:'+JSON.stringify(result));
                    if(result.isSuccess === true) {
                        this.showToast('Success','The synchronization process has been successfully initiated.','Success');
                    this.retrieveData();
                    } else {
                        if(result?.errorMsg) {
                            this.showToast('Error',result.errorMsg,'Error');
                        }else {
                            console.log('Error:'+JSON.stringify(result));
                            this.showToast('Error','Error syncing DMS files.','Error');
                        }
                    }
                })
                .catch(error => {
                    console.log('Error:', error);
                    if(error?.body?.message) {
                        this.showToast('Warning',error.body.message,'warning');
                    }else{
                        this.showToast('Error','Error syncing DMS files.','Error');
                    }
                    this.retrieveData();
                });
        }
    }

    refreshTable(){
        this.retrieveData();
    }
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    selectedRows=[];
    evaluateRows(event){
        // get only pending rows
        this.selectedRows = event.detail.selectedRows.map(row => {
            let rtnId;
            if(row.Status__c == 'Pending' ||row.Status__c == 'Failure' ){
                rtnId = row.Id;
            }
            return rtnId;
        });
        // clean the list
        this.selectedRows = this.selectedRows.filter(function (el) {
            return el != null;
        });
        if(this.selectedRows.length==0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'No eligible records selected !', 
                    variant: 'error'
                })
            );
        }else{
            if(this.selectedRows.length!=0 && event.detail.selectedRows.length!=this.selectedRows.length){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Info',
                        message: 'Only eligible DMS records with pending status are selected.', 
                        variant: 'info'
                    })
                );
            }
            this.isDisabled = false;
        }

        console.log('selectedRows 2>', JSON.stringify(this.selectedRows));
    
        // Filter out the row that is not allowed for row selection
        event.detail.selectedRows = event.detail.selectedRows.filter(row => row.Status__c == 'Pending');
    }
    /**
     * * 1. On Select all rows, deselect the rows which are not pending. 
     * * * a. If there is no pending record, show toast error otherwise info error.
     * 
     */
    handleRowSelects(event) {
        const action = event.detail.config.action;
        switch (action) {
            case 'selectAllRows':
                this.evaluateRows(event);
                break;
            case 'deselectAllRows':
                // If all rows are deselected, clear the selectedIds list
                this.selectedRows = [];
                console.log('alldechecked ',this.selectedIds);
                break;
            case 'rowSelect':
                this.evaluateRows(event);
                break;
            case 'rowDeselect':
                // remove unselected from selectedRows
                console.log('selectedRows 4>'+JSON.stringify(this.selectedRows));
                let currentRows = event.detail.selectedRows;
                if (this.selectedRows.length > 0) {
                    let selectedIds = currentRows.map(row => row.Id);
                    // let unselectedRows = this.selectedRows.filter(row => !selectedIds.includes(row.Id));
                    // console.log(unselectedRows);
                    this.selectedRows = selectedIds;
                    this.isDisabled = selectedIds.length==0;
                }
                console.log('selectedRows 7>'+JSON.stringify(this.selectedRows));
                break;
            default:
                break;
        }
}

syncDMSRecords() {
    // get selected records from this.selectedRows

    /*this.selectedRows.forEach(dmsRec=>{
        this.dmsList.add(dmsRec.Id);
    });*/
    console.log('this.dmsList ',this.selectedRows);

    syncDMSFilesManually({ lDmsIds: this.selectedRows })
        .then(result => {
            // Perform any actions after the Apex method call, if needed
            console.log('***result:'+JSON.stringify(result));
            if(result.isSuccess === true) {
                this.showToast('Success','The synchronization process has been successfully initiated.','Success');
            this.retrieveData();
            } else {
                if(result?.errorMsg) {
                    this.showToast('Error',result.errorMsg,'Error');
                }else {
                    this.showToast('Error','Error syncing DMS files.','Error');
                }
            }           
             this.dmsList = [];
        })
        .catch(error => {
            if(error?.body?.message){
                this.showToast('Info',error?.body?.message,'info');
            }else{
                this.showToast('Error','Error calling Apex method:','error');
            }
        });
}  
   /* handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        const selectedIds = new Set(selectedRows.map(row => row.Id)); 
        this.dmsList = this.dmsList.filter(id => selectedIds.has(id));
        selectedRows.forEach(row => {
            if (!this.dmsList.includes(row.Id)) {
                this.dmsList.push(row.Id);
            }
        });    
    } */
    handleRowSelection(event) {
        const currentDateTime = new Date();
        const selectedRows = event.detail.selectedRows;
        const selectedIds = new Set(selectedRows.map(row => row.Id)); 
        let hasInvalidRecord = false; // Flag to track if any invalid record is selected
        selectedRows.forEach(row => {
            const nextRetryDateTime = new Date(row.Next_Retry__c);
            if (row.Status__c === 'Canceled' || row.Status__c === 'Success'|| (row.Status__c === 'Pending' && currentDateTime < nextRetryDateTime ) ) {
                this.showToast('Error','Some or selected DMS record is invalid','Error');
                hasInvalidRecord = true;
            } else {
                if (!this.dmsList.includes(row.Id)) {
                    this.dmsList.push(row.Id);
                }
            }
        });   
        this.isDisabled = hasInvalidRecord || this.dmsList.length === 0;
 
    }
    // handlePrevious() {
    //     if (this.currentPage > 1) {
    //         this.currentPage--;
    //         this.retrieveDataTable();
    //     }
    //     this.updatePaginationButtons();
    // }

    // handleNext() {
    //     const maxPage = Math.ceil(this.totalRecords / this.recordPerPage);
    //     if (this.currentPage < maxPage) {
    //         this.isPreviousDisabled = false;
    //         this.currentPage++;
    //         this.retrieveDataTable();
    //     }
    //     this.updatePaginationButtons();
    // }
    // updatePaginationButtons() {
    //     const maxPage = Math.ceil(this.totalRecords / this.recordPerPage);
    //     this.isPreviousDisabled = this.currentPage <= 1;
    //     this.isNextDisabled = this.currentPage >= maxPage;
    // }    

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
}