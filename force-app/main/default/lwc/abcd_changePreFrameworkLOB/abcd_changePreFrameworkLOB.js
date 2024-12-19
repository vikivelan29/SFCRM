import { LightningElement, api, wire, track } from 'lwc';
import getPriorityEmails from '@salesforce/apex/ASF_SendPreFrameworkCaseToLOB.getPriorityEmailList';
import updateCase from '@salesforce/apex/ASF_SendPreFrameworkCaseToLOB.updateCase';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';



const columns = [
    { label: 'Business Unit', fieldName: 'Business_Unit__c' },
    { label: 'Email Address', fieldName: 'Email2CaseAddress__c'},
    { label: 'Default Queue Name', fieldName: 'Default_Queue_Dev_Name__c'}
];

export default class Abcd_changePreFrameworkLOB extends LightningElement {
    data = [];
    columns = columns;
    selectedRecord = undefined;
    @api recordId;
    @track filteredData = [];

    @wire(getPriorityEmails, {})
    wiredEmails({
        error,
        data
    }) {
        if (data) {
            this.data = data;
            this.filteredData = [...this.data];            

        } else if (error) {
            this.error = error;
            console.log('error--'+JSON.stringify(error));
        }
    }

    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    handleSearchInputChange(event) {
        this.searchTerm = event.target.value.toLowerCase(); // Get the search term
        if (this.searchTerm) {
            // Filter data based on the search term
            this.filteredData = this.data.filter(
                (priorityEmail) =>
                    (priorityEmail.Email2CaseAddress__c && priorityEmail.Email2CaseAddress__c.toLowerCase().includes(this.searchTerm)) ||
                    (priorityEmail.Business_Unit__c && priorityEmail.Business_Unit__c.toLowerCase().includes(this.searchTerm)) ||
                    (priorityEmail.Default_Queue_Dev_Name__c && priorityEmail.Default_Queue_Dev_Name__c.toLowerCase().includes(this.searchTerm))
            );
        } else {
            // Reset to original data if search term is cleared
            this.filteredData = [...this.data];
        }
    }
    getSelectedName(event) {
        const selectedRows = event.detail.selectedRows[0];
        console.log(selectedRows);
        this.selectedRecord = selectedRows;
    }
    handleForwardCase(event){

        let selectedEmailRecId = this.selectedRecord.Id;
        updateCase({
            recId: this.recordId,
            priorityCMId: selectedEmailRecId
        })
            .then(result => {
                const event = new ShowToastEvent({
                    title: 'Success',
                    message: 'Case updated',
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
                this.dispatchEvent(new CloseActionScreenEvent());

                getRecordNotifyChange([{ recordId: this.recordId }]);

                setTimeout(() => {
                    eval("$A.get('e.force:refreshView').fire();");
                }, 1000);
            })
            .catch(error => {
                    const event = new ShowToastEvent({
                        title: 'Error',
                        message: this.noUpdate,
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(event);
            });
    }

}