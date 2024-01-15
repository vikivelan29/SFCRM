import { api, LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import Case_Owner from '@salesforce/schema/Case.OwnerId';
import getCheckList from '@salesforce/apex/ASF_GetCaseRelatedDetails.getPendingChecklists';
import updateMyCheckList from '@salesforce/apex/ASF_GetCaseRelatedDetails.updateCheckList';
import updateChecklistComment from '@salesforce/apex/ASF_GetCaseRelatedDetails.updateChecklistComment';
import { refreshApex } from '@salesforce/apex';
import userId from '@salesforce/user/Id';
import { NavigationMixin } from 'lightning/navigation';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CHECKLIST_OBJECT from '@salesforce/schema/ASF_Checklist__c';
import checkListStatus from '@salesforce/schema/ASF_Checklist__c.Status__c';
import Case_Status from '@salesforce/schema/Case.Status';
import Case_Stage from '@salesforce/schema/Case.Stage__c';
const fields = [Case_Owner, Case_Status, Case_Stage];

export default class ASF_pendingCaseChecklistEdit extends NavigationMixin(LightningElement) {
    @api recordId;
    accData;
    errorData;
    value;
    event2;
    recordCheckId;
    areDetailsVisible = false;
    ownerIdCase = userId;
    checklistData;
    wiredAccountsResult;
    listRecords = [];
    hasRecord = false;
    isDisabled = true;
    @api realFormData;
    @wire(getObjectInfo, { objectApiName: CHECKLIST_OBJECT })
    checkListInfo;

    get options() {
        return [
            { label: 'Pending', value: 'Pending' },
            { label: 'Completed', value: 'Completed' },
        ];
    }
    @wire(getRecord, { recordId: '$recordId', fields })
    gAcc({ data, error }) {
        if (data) {
            const onwerId = getFieldValue(data, Case_Owner);
            const status = getFieldValue(data, Case_Stage);
            this.isClosed = status == 'Closed' ? true : false;
            this.areDetailsVisible = onwerId == this.ownerIdCase;
        }
    }
    @wire(getCheckList, { caseId: '$recordId' })
    wiredAccounts(result) {
        this.wiredAccountsResult = result;
        this.realFormData = { ... this.wiredAccountsResult.data };
        if (result.data) {
            if (result.data.length != 0) {
                this.hasRecord = true;
            }
            this.accData = result.data;
        }
        else if (result.error) {
            this.error = result.error;
            this.accounts = undefined;
        }
    }
    connectedCallback() {
        // this.event2 = setInterval(() => {
        //     refreshApex(this.wiredAccountsResult);
        // }, 1000);
    }
    disconnectedCallback() {
        clearInterval(this.event2);
    }
    handleInputChange(event) {
        if (this.areDetailsVisible == true) {
            this.textValue = event.detail.value;
            this.selectTaskID = event.target.dataset.id;
            clearTimeout(this.timeoutId); // no-op if invalid id
            this.timeoutId = setTimeout(this.doApexUpdate.bind(this), 5000); // Adjust as necessary
        }
    }
    doApexUpdate() {
        console.log('yesssworking');
        console.log("timerID", this.textValue);
        console.log("timerrerowsd", this.selectTaskID);
        updateChecklistComment({ checkId: this.selectTaskID, commentsCheck: this.textValue })
            .then(result => {
            })
            .catch(error => {
                this.error = error.message;
            });
    }
    handleChange(event) {
        this.value = event.detail.value;
        const selectedRecordId = event.target.dataset.id;
        console.log('trueOwnerId', this.areDetailsVisible);
        console.log("inputno", this.value);
        console.log("record", selectedRecordId);
        this.isDisabled = false;
        this.listRecords.push({ Id: event.target.dataset.id, [event.target.dataset.field]: event.detail.value });
        console.log("newrealform", this.listRecords);

    }
    handleSave(event) {
        
        console.log('Refresh Apex called');
        updateMyCheckList({ recordUpdate: this.listRecords }).then(() => {
            console.log('Refresh Apexsuccess called');
            refreshApex(this.wiredAccountsResult);
            const event = new ShowToastEvent({
                title: 'Success',
                message: 'Records are updated sucessfully',
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
        });
    }
 
}