import { api, LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getPendingTasks from '@salesforce/apex/ASF_GetCaseRelatedDetails.getPendingTasks';
import updateTaskObj from '@salesforce/apex/ASF_GetCaseRelatedDetails.updateTask';
import updateTaskComments from '@salesforce/apex/ASF_GetCaseRelatedDetails.updateTaskRecordsComment';

// check ownership of task
import getOwnerTaskOwnerShip from '@salesforce/apex/ASF_UserQueueDetails.getUserQueueDetails';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import userId from '@salesforce/user/Id';

export default class ASF_pendingCaseTaskEdit extends NavigationMixin(LightningElement) {
    @api recordId;
    accData;
    errorData;
    value;
    event2;
    recordCheckId;
    wiredAccountsResult;
    hasRecord = false;
    listRecords = [];
    isCompleted = false;
    loggedInUser = userId;
    isDisabled = true;
    isManual = false;
    autoIcon = false;

    /*@wire(getObjectInfo, { objectApiName: TASK_OBJECT })
       taskInfo;
    
       @wire(getPicklistValues,
           {
               recordTypeId: '$taskInfo.data.defaultRecordTypeId',
               fieldApiName: taskStatus
           }
       )
       options; */

    get options() {
        return [
            { label: 'Open', value: 'Open' },
            { label: 'Completed', value: 'Completed' },


        ];
    }
    @wire(getPendingTasks, { caseId: '$recordId' })
    wiredAccounts(result) {
        this.wiredAccountsResult = result;
        if (result.data) {
            if (result.data) {
                this.getOwnerTaskOwnerShip();
            }
            if (result.data.length != 0) {
                this.hasRecord = true;
            }
            this.accData = result.data;
            console.log("taskks" + result.data);
            for (let j = 0; j < this.accData.length; j++) {
                if (this.accData[j].OwnerId != this.loggedInUser) {
                    this.isCompleted = true;
                    break;
                }
            }
        }
        else if (result.error) {
            this.error = result.error;
            this.accounts = undefined;
        }
    }
    connectedCallback() {
        this.event2 = setInterval(() => {
            refreshApex(this.wiredAccountsResult);
        }, 5000);
    }

    disconnectedCallback() {
        clearInterval(this.event2);
    }

    handleChange(event) {
        this.value = event.detail.value;
        const selectedRecordId = event.target.dataset.id;
        this.isDisabled = false;
        console.log("inputno", this.value);
        console.log("record", selectedRecordId);
        this.listRecords.push({ Id: event.target.dataset.id, [event.target.dataset.field]: event.detail.value })
        console.log("newrealform", this.listRecords);


    }
    handleInputChange(event) {
        this.textValue = event.detail.value;
        console.log("inputno", this.textValue);
        const selectId = event.target.dataset.id;
        this.isDisabled = false;
        console.log("record", selectId);
        this.selectTaskID = event.target.dataset.id;
        clearTimeout(this.timeoutId); // no-op if invalid id
        this.timeoutId = setTimeout(this.doApexUpdate.bind(this), 6000); // Adjust as necessary
    }
    doApexUpdate() {
        console.log('yesssworking');
        console.log("timerID", this.textValue);
        console.log("timerrerowsd", this.selectTaskID);

        updateTaskComments({ taskId: this.selectTaskID, comments: this.textValue })
            .then(result => {

                const event = new ShowToastEvent({
                    title: 'Success',
                    message: 'Records are updated sucessfully',
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);

            })
            .catch(error => {
                this.error = error.message;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error updating record",
                        message: error.body.pageErrors[0].message,
                        variant: "error"
                    })
                );
            });
    }
    handleSave() {
        console.log('Refresh ApexTASK called');
        updateTaskObj({ recordUpdate: this.listRecords }).then(() => {
            console.log('Refresh Apexsuccess called');
            refreshApex(this.wiredAccountsResult);

            const event = new ShowToastEvent({
                title: 'Success',
                message: 'Records are updated sucessfully',
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
        }).catch(error => {
            this.error = error.message;

            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error updating record",
                    message: error.body.pageErrors[0].message,
                    variant: "error"
                })
            );
        });



    }
    updateRecordView() {
        setTimeout(() => {
            eval("$A.get('e.force:refreshView').fire();");
        }, 1000);
    }
    handleClick(event) {
        this.selectTaskID = event.target.dataset.id;
        console.log("clicked", this.selectTaskID);
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: this.selectTaskID,
                actionName: 'view',
            },
        }).then(url => {
            //2. Assign it to the prop
            this.recordPageUrl = url;
        });
    }
    getOwnerTaskOwnerShip() {

        getOwnerTaskOwnerShip({ userId: this.loggedInUser, caseId: this.recordId })
            .then(result => {
                this.isCompleted = result == true ? false : true;
            })
            .catch(error => {
                this.error = error.message;
            });
    }

}