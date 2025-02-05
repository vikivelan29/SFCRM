import { LightningElement,api } from 'lwc';
import noFileAvailableLabel from '@salesforce/label/c.No_DMS_File';
import executeQuery from '@salesforce/apex/ABHI_UploadIGMSComplaintsIntegration.executeQuery';
import DMS_File_Name from '@salesforce/label/c.DMS_File_Name';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import pageSize from '@salesforce/label/c.ABFL_DMSPageSize';
import Manual_Synching from '@salesforce/label/c.Manual_Synching';
import uploadAttachment from '@salesforce/apex/ABHI_UploadIGMSComplaintsIntegration.uploadAttachment';

const columns = [
            {
                label: DMS_File_Name,
                fieldName: 'contentURL',
                type: 'url',
                typeAttributes: { label: { fieldName: 'fileName' }, target: '_blank' }
            },
            {
                label: 'Status',
                fieldName: 'status',
                type: 'test'
            },
            {
                label: Manual_Synching,
                type: 'button',
                typeAttributes: {
                    label: { fieldName: 'uploadFileLabel' },
                    name: 'manualSync',
                    variant: 'base',
                    disabled: { fieldName: 'allowUpload' }
                }
            }
          ];
export default class Absli_igmsuploadattachment extends LightningElement {
    isRecordPresent = false;
    noFileAvailableLabel = noFileAvailableLabel;
    isPreviousDisabled =false;
    recordsToDisplay = [];
    @api recordId;
    isRecordPresent = false;
    columns = columns;
    label = {
        pageSize
    };
    pageNumber = 1;
    relatedListTitle = 'IGMS Documents(TO IRDAI)';
    relatedListTitleWithCount;
    totalNoOfRecordsInDatatable = 0;
    clickedRecords = [];

    connectedCallback() {
        this.retrieveDataTable();
        this.isPreviousDisabled = true;
    }

    retrieveDataTable() {
        executeQuery({ caseId: this.recordId,clickedIds:this.clickedRecords})
            .then(result => {
                // Check if result exists and has data
                if (result) {
                    this.tableData = result;
                    for(let i=0;i<this.tableData.length;i++) {
                        this.tableData[i].contentURL = '/'+this.tableData[i].contentDocumentId;
                    }
                    this.totalNoOfRecordsInDatatable = this.tableData?.length;
                    // Set total records
                    //console.log('this.totalRecords ', this.totalNoOfRecordsInDatatable);  
                    this.paginationHelper();
                    // Update visibility flags
                    this.isRecordPresent = this.totalNoOfRecordsInDatatable!=0;
                    this.isLoading = false;
                    this.relatedListTitleWithCount = this.relatedListTitle + ' (' + this.totalNoOfRecordsInDatatable + ')';
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

    refreshTable(){
        this.retrieveDataTable();
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }


    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        console.log('Row Object:', JSON.stringify(row));
        if (action.name === 'manualSync') {
            console.log('manualSync ');
            uploadAttachment({ recId: this.recordId, rowWrapper : JSON.stringify(row) })
                .then(result => {
                    console.log('***result:'+JSON.stringify(result));
                    if(result.isSuccess === true) {
                        this.showToast('Success','The synchronization process has been successfully initiated.','Success');
                        this.clickedRecords.push(result.contentDocumentId);
                        this.retrieveDataTable();
                    } else {
                        if(result?.errorMsg) {
                            this.showToast('Error',result.errorMsg,'Error');
                        }else {
                            console.log('Error:'+JSON.stringify(result));
                            this.showToast('Error','Error syncing to IGMS.','Error');
                        }
                    }
                })
                .catch(error => {
                    console.log('Error:', error);
                    if(error?.body?.message) {
                        this.showToast('Warning',error.body.message,'warning');
                    }else{
                        this.showToast('Error','Error syncing to IGMS.','Error');
                    }
                    this.retrieveDataTable();
                });
        }
    }

}