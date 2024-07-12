import { LightningElement, api, track, wire } from 'lwc';
import managerAccess from '@salesforce/apex/ASF_OwnerShipChange.checkManagerAccess';
import changeOwnerToOtherUser from '@salesforce/apex/ASF_OwnerShipChange.changeOwnerToOtherUser';
import { CloseActionScreenEvent } from "lightning/actions";

import { getRecord, getFieldValue, updateRecord, getRecordNotifyChange } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";


const FIELDS = [
    "Case.Id",
    "Case.OwnerId",
    "Case.Stage__c",
    "Case.OwnerUser__c",
    "Case.pending_clarification__c"
];

export default class Asf_OwnershipChange extends LightningElement {

    @track ownerManager = false;
    @api recordId;
    record;


    @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
    wiredRecord({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.record = data;
            managerAccess({ caseRecordId: this.recordId })
                .then(result => {
                    this.ownerManager = result;
                })
                .catch(error => {
                    console.log(error);
                });
            console.log("data" + JSON.stringify(data));
        }
    }

    handleSuccess() {
        if (this.recordId !== null) {
            this.dispatchEvent(new ShowToastEvent({
                title: "SUCCESS!",
                message: "Owner Changed.",
                variant: "success",
            }),
            );
        }
    }

    handleError(event) {
        const evt = new ShowToastEvent({
            title: 'Error!',
            message: event.detail.detail,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    onSubmitHandler(event) {
        event.preventDefault();
        const fields = event.detail.fields;

        const ownerid = event.detail.fields['OwnerUser__c'];
        event.detail.fields['OwnerId'] = ownerid;
        event.detail.fields['Id'] = this.recordId;
        changeOwnerToOtherUser({ caseRecordId: this.recordId, newOwnerId: ownerid })
            .then(result => {
                this.dispatchEvent(new ShowToastEvent({
                    title: "SUCCESS!",
                    message: "Owner Changed.",
                    variant: "success",
                }),);
                this.dispatchEvent(new CloseActionScreenEvent())
                eval("$A.get('e.force:refreshView').fire();")

            })
            .catch(error => {
                const evt = new ShowToastEvent({
                    title: 'Error!',
                    message: error,
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);
            });

    }




}