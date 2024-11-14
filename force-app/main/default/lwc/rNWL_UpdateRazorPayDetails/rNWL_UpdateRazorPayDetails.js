import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import LINK_FIELD from "@salesforce/schema/Opportunity.Razor_Pay_Link__c";
import AMOUNT_FIELD from "@salesforce/schema/Opportunity.Razor_Pay_Amount__c";
import updateOppRecord from '@salesforce/apex/RNWL_RelatedListHelper.updateOpportunityFields';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class RNWL_UpdateRazorPayDetails extends LightningElement {
    @api recordId;
    razorPayAmount;
    razorPayLink;

    @wire(getRecord, { recordId: "$recordId", fields: [LINK_FIELD, AMOUNT_FIELD] })
    wiredRecord({ error, data }) {
        if (error) {
            let message = "Unknown error";
            if (Array.isArray(error.body)) {
                message = error.body.map((e) => e.message).join(", ");
            } else if (typeof error.body.message === "string") {
                message = error.body.message;
            }
            this.dispatchEvent(this.showToast('error', message, 'Error loading Opportunity!', 'dismissable'));
        } else if (data) {
            let oppRec = data;
            this.razorPayLink = oppRec.fields.Razor_Pay_Link__c.value;
            this.razorPayAmount = oppRec.fields.Razor_Pay_Amount__c.value;
        }
    }

    handleChange(event) {
        if (event.target.name === 'razorPayAmount') {
            this.razorPayAmount = event.detail.value;
        } else {
            this.razorPayLink = event.detail.value;
        }
    }

    //Common method to show toast
    showToast(variant, message, title, mode) {
        return new ShowToastEvent({
            "title": title,
            "message": message,
            "variant": variant,
            "mode": mode
        });
    }

    updateOppRecord() {
        updateOppRecord({ recordId : this.recordId, linkVal : this.razorPayLink, amountVal : this.razorPayAmount })
        .then(result => {
            this.dispatchEvent(new CloseActionScreenEvent());
            this.dispatchEvent(this.showToast('success', 'Updated Razor Pay details successfully', 'Success!', 'dismissable'));
            notifyRecordUpdateAvailable([{recordId: this.recordId}]);
        })
        .catch(error=>{
            this.error = error;
            let errMsg = '';                    
            if (error && error.body && error.body.message) {
                errMsg = error.body.message;
            }                  
            this.dispatchEvent(this.showToast('error', errMsg, 'Error!', 'dismissable'));
        })
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}