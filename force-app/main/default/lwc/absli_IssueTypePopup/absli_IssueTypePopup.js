import { LightningElement, api, track, wire } from 'lwc';
import getIssueType from "@salesforce/apex/ABSLI_IssueTypeController.getIssueTypeforCCC";
import updateIssueType from "@salesforce/apex/ABSLI_IssueTypeController.updateIssueType";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEventNoPageRef, registerListener } from 'c/asf_pubsub';
import {RefreshEvent } from 'lightning/refresh'

export default class Absli_IssueTypePopup extends LightningElement {
    @api recordId;
    @track options = [];
    @track selectedPicklistValue;
    @track valueEmpty = true;
    @track issueTypeNotAvailable = false;
    @wire(CurrentPageReference) pageRef;
    
    @wire(CurrentPageReference)
    getPageReference(pageRef) {
        if (pageRef && pageRef.state && pageRef.state.recordId) {
            this.recordId = pageRef.state.recordId;
        }
    }

    async connectedCallback(){
        try {
            const result = await getIssueType({ recordID: this.recordId });
            if (result.length === 0) {
                this.issueTypeNotAvailable = true; // Set to true if list is empty
                this.options = []; // Clear options if no issue types are found
            } else {
                this.issueTypeNotAvailable = false; // List is not empty
                this.options = result.map(item => ({
                    label: item,
                    value: item
                }));
            }
        } catch (error) {
            console.error('Error in retrieving issue types:', error);
        }
    }

    handleIssueTypeChange(event) {
        let val = event.target.value;
        this.selectedPicklistValue = val;
        this.valueEmpty = !this.selectedPicklistValue;
    }

    async varifyConfirmFieldPopup(event) {
        try {
            const result = await updateIssueType({ recordID: this.recordId, issueType: this.selectedPicklistValue });
    
            if (result) {
                
                let payload = { 'source': 'issueType', 'recordId': this.recordId };
                console.log('PageRef before fireEventNoPageRef:', this.pageRef);
                try {
                    fireEventNoPageRef(this.pageRef, "refreshfromIntLWC", payload);
                    console.log('Event fired successfully');
                } catch (error) {
                    console.error('Error firing event:', error);
                }
                this.dispatchEvent(new RefreshEvent());
                
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Issue type updated successfully',
                        variant: 'success'
                    })
                );
                this.closeModal();
            }
        } catch (error) {
            console.error('Error updating issue type:', error);
        }
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    cancelConfirmFieldPopup(event) {
        this.closeModal();
    }
}