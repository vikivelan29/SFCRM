import { api, LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import Case_Owner from '@salesforce/schema/Case.OwnerId';
import getCheckList from '@salesforce/apex/ASF_GetCaseRelatedDetails.getPendingChecklists';
import updateMyCheckList from '@salesforce/apex/ASF_GetCaseRelatedDetails.updateCheckList';
import { refreshApex } from '@salesforce/apex';
import userId from '@salesforce/user/Id';
import { NavigationMixin } from 'lightning/navigation';
import Case_Status from '@salesforce/schema/Case.Status';
import Case_Stage from '@salesforce/schema/Case.Stage__c';
import { reduceErrors } from 'c/asf_ldsUtils';
const fields = [Case_Owner, Case_Status, Case_Stage];


import { registerRefreshContainer, unregisterRefreshContainer, REFRESH_COMPLETE, REFRESH_COMPLETE_WITH_ERRORS, REFRESH_ERROR } from 'lightning/refresh'

export default class ASF_pendingCaseChecklistEdit extends NavigationMixin(LightningElement) {
    @api recordId;
    accData;
    areDetailsVisible = false;
    ownerIdCase = userId;
    wiredAccountsResult;
    listRecords = {};
    hasRecord = false;
    isDisabled = true;
    get isAnyStageMatchChecklistPresent(){
        let output = false;
        if(this.accData){
            let matches = this.accData.find(item=>{
                return item.Stage_Matched__c == true;
            });
            if(matches){
                output = true;
            }
        }
        return output;
    }
    @api realFormData;

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

        this.refreshContainerID = registerRefreshContainer(this.template.host, this.refreshContainer.bind(this));
    }
    disconnectedCallback() {
        clearInterval(this.event2);
        unregisterRefreshContainer(this.refreshContainerID);
    }
    
    handleChange(event) {
        let value = event.detail.value;
        let selectedRecordId = event.target.dataset.id;
        let fieldAPI = event.target.dataset.field;
        this.isDisabled = false;
        if(Object.hasOwn(this.listRecords, selectedRecordId)){
            let checklist = this.listRecords[selectedRecordId];
            checklist[fieldAPI] = value;
            this.listRecords[selectedRecordId] = checklist;
        }else{
            let checklist = {};
            checklist['Id'] = selectedRecordId;
            checklist[fieldAPI] = value;
            this.listRecords[selectedRecordId] = checklist;
        }

    }
    handleSave(event) {
        
        console.log('Refresh Apex called');
        updateMyCheckList({ updateChecklistRecords: this.listRecords }).then(result => {
            console.log('Refresh Apexsuccess called');
            refreshApex(this.wiredAccountsResult);
            const event = new ShowToastEvent({
                title: 'Success',
                message: 'Records are updated sucessfully',
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
        })
        .catch(error => {
            console.log('what is therror' + JSON.stringify(error));
            this.showError('error', 'Error occured', error);

            
        })
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

    refreshContainer(refreshPromise) {
        if (refreshPromise) {
            return refreshPromise
                .then((status) => {
                    if (status === REFRESH_COMPLETE) {
                        refreshApex(this.wiredAccountsResult);
                    } else if (status === REFRESH_COMPLETE_WITH_ERRORS) {
                        console.warn("Done, with issues refreshing some components");
                    } else if (status === REFRESH_ERROR) {
                        console.error("Major error with refresh.");
                    }
                })
                .catch((error) => {
                    console.log(error);
                });
        }
    }

    //Old methods
    /*
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
    */
}