/* eslint-disable no-await-in-loop */
/* eslint-disable no-empty-function */
/* eslint-disable no-alert */
/* eslint-disable handle-callback-err */
/* eslint-disable no-unused-vars */
/* eslint-disable eqeqeq */
/* eslint-disable no-empty */
import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import REOPENREASON_FIELD from "@salesforce/schema/Case.Reopen_Reason__c";
import REOPENED_FIELD from "@salesforce/schema/Case.Reopened__c";
import REOPENED_DATETIME_FIELD from "@salesforce/schema/Case.Reopened_DateTime__c";
import ID_FIELD from "@salesforce/schema/Case.Id";
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from "lightning/navigation";
import { reduceErrors } from 'c/asf_ldsUtils';
import { fireEventNoPageRef, registerListener } from 'c/asf_pubsub';

export default class Asf_ReopenCase extends NavigationMixin(LightningElement) {

    @api recordId;
    reopenReason = REOPENREASON_FIELD;
    isLoading = false; //for spinner control

    @wire(CurrentPageReference) pageRef;


    /* Component functions */
    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSubmit(event) {
        this.isLoading = true;
        event.preventDefault();       // stop the form from submitting
        let fields = {};
        fields[REOPENED_FIELD.fieldApiName] = true;
        fields[REOPENED_DATETIME_FIELD.fieldApiName] = new Date().toISOString();
        fields[REOPENREASON_FIELD.fieldApiName] = event.detail.fields[REOPENREASON_FIELD.fieldApiName];
        fields[ID_FIELD.fieldApiName] = this.recordId;
        console.log(fields);
        const recordInput = { fields };
        console.log(recordInput);
        updateRecord(recordInput)
        .then(result => {
            const successevent = new ShowToastEvent({
                variant: 'success',
                title: 'Case Reopened Successfully',
                message: 'Case is successfully reopened!'
            });
            // this[NavigationMixin.Navigate]({
            //     type: "standard__recordPage",
            //     attributes: {
            //         objectApiName: "Case",
            //         actionName: "view",
            //         recordId: this.recordId
            //     }
            // });
            console.log('Firing pubsub from Reopen!!!!!!');
            // let payload = {'source':'reopencase', 'recordId':this.recordId};
            // fireEventNoPageRef(this.pageRef, "refreshpagepubsub", payload);
            setTimeout(()=>{
                console.log('refreshing view');
                eval("$A.get('e.force:refreshView').fire();");
            }, 500);
            this.closeAction();

        })
        .catch(error => {
            let errMsg = reduceErrors(error);
            const event = new ShowToastEvent({
                variant: 'error',
                title: 'Oops! Error reopening the case',
                message: Array.isArray(errMsg) ? errMsg[0] : errMsg
            });
            this.dispatchEvent(event);
            this.isLoading = false;
            this.closeAction();
        })
        
    }

    

}