import { LightningElement,api,wire } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import STAGE_FIELD from '@salesforce/schema/Case.Stage__c';
import STATUS_FIELD from '@salesforce/schema/Case.Status';
import ID_FIELD from '@salesforce/schema/Case.Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {CurrentPageReference} from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import No_DML_Access from '@salesforce/label/c.ASF_No_DML_Access';


export default class Asf_PendingWithCustomer extends LightningElement {

    @api recordId;
    @api isLoaded = false;

        @wire(CurrentPageReference)
        getStateParameters(currentPageReference) {
            if (currentPageReference) {
                this.recordId = currentPageReference.state.recordId;
                const fields = {};
                if(this.recordId!=null){
                    console.log('this.recordId'+this.recordId);
                    fields[ID_FIELD.fieldApiName] = this.recordId;
                    fields[STAGE_FIELD.fieldApiName] = 'Pending with Customer';
                    fields[STATUS_FIELD.fieldApiName] = 'Waiting for Customer';
                    const recordInput = {
                        fields: fields
                      };
                    updateRecord(recordInput)
                    .then(() => {
                        this.showToast('Success!!', 'Service Request updated successfully!!', 'success', 'dismissable');
                        // Display fresh data in the form
                        console.log('sucesss');
                        this.dispatchEvent(new CloseActionScreenEvent());
                        this.isLoaded = true;
                        //return refreshApex(this.account);

                    })
                    .catch(error => {
                        this.showToast('Error!!', No_DML_Access, 'Error', 'dismissable');
                        // Display fresh data in the form
                        this.dispatchEvent(new CloseActionScreenEvent());
                        this.isLoaded = true;
                        //return refreshApex(this.account);
                    });
                }
            }
        }
    
    showToast(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
}