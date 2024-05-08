import { LightningElement, wire, api, track } from 'lwc';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import syncDMSFilesManually from '@salesforce/apex/ABFL_DMSSync_Orchestrator.syncDMSFilesManually';
import executeQuery from '@salesforce/apex/Asf_DmsViewDataTableController.executeQuery';
import DMS_URL from '@salesforce/label/c.DMS_URL';
import getUserBDid from '@salesforce/apex/Asf_DmsViewDataTableController.getUserBDid';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import noFileAvailableLabel from '@salesforce/label/c.No_DMS_File';
import DMS_File_Name from '@salesforce/label/c.DMS_File_Name';
import Manual_Synching from '@salesforce/label/c.Manual_Synching';
import Synched_Already from '@salesforce/label/c.Synched_Already';
import Sync_Canceled from '@salesforce/label/c.Sync_Canceled';
import Synching_initiated from '@salesforce/label/c.Synching_initiated';
import Sync_Manually from '@salesforce/label/c.Sync_Manually';



export default class ASF_DMSViewDatatable extends NavigationMixin(LightningElement) {
    isLoading=true;
    @api recordId;
    @track data = [];
    @track columns = [];
    @track isRecordPresent = false;
    baseUrl;
    @api showChecklistColumn = false; 
    currentlySelectedData=[];
    @track dmsList = []; 
    noFileAvailableLabel = noFileAvailableLabel;
    isDisabled = true;
    @track currentPage = 1;
    @track totalRecords = 0;
    @api recordPerPage;
    isPreviousDisabled ;
    isNextDisabled;
    connectedCallback() {
        this.retrieveData();
        this.isPreviousDisabled = true;
    }
    retrieveData() {
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
                    this.columns = [
                        {
                            label: DMS_File_Name,
                            fieldName: 'accLink',
                            type: 'url',
                            typeAttributes: { label: { fieldName: 'Name' }, target: '_self' }
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
                        },
                        {
                            fieldName: '',
                            label: '',
                            fixedWidth: 40,
                            cellAttributes: { iconName: { fieldName: 'dynamicIcon' } }
                        }
                    ];
                    resolve();
                })
                .catch(error => reject(error));
        });
    }

    retrieveDataTable() {
        executeQuery({ caseId: this.recordId, pageNumber: this.currentPage, pageSize: this.recordPerPage })
            .then(result => {
                // Check if result exists and has data
                if (result && result.data) {
                    // Set total records
                    this.totalRecords = result.totalRecords;
                    console.log('this.totalRecords ', this.totalRecords);  
                    if(this.totalRecords<=this.recordPerPage){
                        this.isNextDisabled = true;
                    }
                    const currentDateTime = new Date();
                    // Process each record and add additional properties
                    this.data = result.data.map(res => {
                        let processedRes = { ...res }; // Create a copy of the record
                        processedRes.accLink = '/' + res.Id;
                        if (res.DocumentID__c == null) {
                            processedRes.showButtons = true;
                        }
                        const nextRetryDateTime = new Date(res.Next_Retry__c);
                        processedRes.showButtonsSynch = res.Status__c === 'Success' || res.Status__c === 'Canceled' || currentDateTime < nextRetryDateTime;
                        processedRes.actionText = res.Status__c === 'Success' ? Synched_Already : (res.Status__c === 'Canceled' ? Sync_Canceled : (currentDateTime < nextRetryDateTime ? Synching_initiated : Sync_Manually));
                        processedRes.dynamicIcon = res.Status__c === 'Success' ? 'utility:warranty_term' : (res.Status__c === 'Canceled' ? 'utility:cancel_file_request' : (res.Status__c === 'Pending' ? 'utility:real_time' : 'utility:error'));
                        return processedRes;
                    });
                    
                    // Update visibility flags
                    this.isRecordPresent = this.data.length > 0;
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
                getUserBDid({ userBDid: 'UserBDid' })
                    .then(result => {
                        console.log('UserBDid:', result);
                        this.baseUrl = DMS_URL;
                        const userdbid = result;
                        const documentId = row.DocumentID__c;
                        const dynamicUrl = `${this.baseUrl}&Userdbid=${userdbid}&DocumentId=${documentId}`;
                        console.log('dynamicUrl:', dynamicUrl);
                        if (userdbid != null || userdbid != undefined) {
                            this[NavigationMixin.Navigate]({
                                type: 'standard__webPage',
                                attributes: {
                                    url: dynamicUrl
                                }
                            });
                        }
                    })
                    .catch(error => {
                       // console.error('Error:', error);
                        this.showToast('Error','Error fetching user B Did.','Error');
                    });
            }
        } else if (action.name === 'manualSync') {
            console.log('manualSync ');
            syncDMSFilesManually({ dmsFileRecordId: row.Id })
                .then(result => {
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
                })
                .catch(error => {
                   // console.error('Error:', error);
                    this.showToast('Error','Error syncing DMS files.','Error');
                });
        }
    }
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    evaluateRows(event){
        // get only pending rows
        this.selectedRows = event.detail.selectedRows.map(row => {
            let rtnId;
            if(row.Status__c == 'Pending'){
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
    selectedRows;
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
    this.selectedRows.forEach(dmsRec=>{
        this.dmsList.add(dmsRec.Id);
    });
    console.log(this.dmsList);

    syncDMSFilesManually({ lDmsIds: this.dmsList })
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
            console.error('Error calling Apex method:', error);
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
    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.retrieveDataTable();
        }
        this.updatePaginationButtons();
    }

    handleNext() {
        const maxPage = Math.ceil(this.totalRecords / this.recordPerPage);
        if (this.currentPage < maxPage) {
            this.isPreviousDisabled = false;
            this.currentPage++;
            this.retrieveDataTable();
        }
        this.updatePaginationButtons();
    }
    updatePaginationButtons() {
        const maxPage = Math.ceil(this.totalRecords / this.recordPerPage);
        this.isPreviousDisabled = this.currentPage <= 1;
        this.isNextDisabled = this.currentPage >= maxPage;
    }    
}