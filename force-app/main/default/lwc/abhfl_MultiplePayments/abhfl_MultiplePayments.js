import { LightningElement, api, wire, track } from 'lwc';
import STAGE_FIELD from '@salesforce/schema/Case.Stage__c';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getPaymentsForCase from '@salesforce/apex/ABHFL_MultiplePaymentsController.getPaymentsForCase';
import deletePaymentRecord from '@salesforce/apex/ABHFL_MultiplePaymentsController.deletePaymentRecord';
import savePayments from '@salesforce/apex/ABHFL_MultiplePaymentsController.savePayments';
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";


export default class Abhfl_MultiplePayments extends LightningElement {
    // Case Record Id
    @api recordId;
    @track payments = [];
    error;
    //@track isEditable = true;

    isPaymentIdEditable;
    isPaymentAmountEditable;
    isPaymentModeEditable;
    isDateEditable;
    isRealizationEditable;
    serverPayments; // Property used to refresh apex

    // Wire the Case Record, and Find Stage
    @wire(getRecord, { recordId: '$recordId', fields: [STAGE_FIELD] })
    wiredRecord({ error, data }) {
        if (error) {
        }
        else if(data){
            let stage = getFieldValue(data, STAGE_FIELD);
            this.setupFieldPermissions(stage);
        }
    }

    @wire(getPaymentsForCase, {caseId:'$recordId'})
    getPaymentsWire(paymentRecords) {
        this.serverPayments = paymentRecords;
        if(paymentRecords.data && paymentRecords.data.length > 0){
           let records = JSON.parse(JSON.stringify(paymentRecords.data));
           console.log(records)
            for(let i = 0; i < records.length; i++) {
                //if(this.record[i].Id)
                console.log(records[i].Id);
                records[i].key = `${records[i].Id}`;
            }
            this.payments = records;
        }
    }

    handleDataChange(event){
        let element = this.payments.find(ele  => ele.key === event.target.dataset.id);
        let fieldName = event.target.dataset.fieldname;
        element[fieldName] = event.target.value;
        this.payments = [...this.payments];
    }

    /*
    handlePaymentIdChange(event) {
        let element = this.payments.find(ele  => ele.Id === event.target.dataset.id);
        element.Payment_Identifier__c = event.target.value;
        this.payments = [...this.payments];
        console.log(JSON.stringify(this.payments));
    }
    handlePaymentIdChange(event) {
        let element = this.payments.find(ele  => ele.Id === event.target.dataset.id);
        element.Amount__c = event.target.value;
        this.payments = [...this.payments];
        console.log(JSON.stringify(this.payments));
    }

    handleDateChange(event){
        let element = this.payments.find(ele  => ele.Id === event.target.dataset.id);
        element.Date__c = event.target.value;
        this.payments = [...this.payments];
        console.log(JSON.stringify(this.payments));
    }
    */

    handlePicklistChange(event) {
        let eventData = event.detail;
        let pickValue = event.detail.selectedValue;
        let uniqueKey = event.detail.key;
        console.log(pickValue);
        console.log(uniqueKey);
        console.log(event.detail.fieldApiName);
        console.log(JSON.stringify(eventData));

        let element = this.payments.find(ele  => ele.key === uniqueKey);
        element[event.detail.fieldApiName] = pickValue;
        this.payments = [...this.payments];
    }

    add() {
        console.log(JSON.stringify(this.payments));
        let newList = this.payments;
        newList.push({
            Payment_Identifier__c : "", 
            key : Math.random().toString(36).substring(2, 15),
            isDeleteAllowed: true});
        this.payments = newList;
        console.log(JSON.stringify(this.payments));
    }

    remove(event) {
        const recId = event.currentTarget.dataset.id;
    
        // Find the index of the element to be removed
        const indexToRemove = this.payments.findIndex(item => item.key === recId);
    
        if (indexToRemove !== -1) {
            // Remove the element from the array
            this.payments.splice(indexToRemove, 1);
            this.error = undefined;
    
            // Call the Apex method to delete the payment record by its Id
            deletePaymentRecord({ paymentId: recId })
                .then((response ) => {
                    // Success message after successful deletion
                    console.error('deleted payment record:', response );
                    this.showToast('Success', 'Payment deleted successfully', 'success');
                })
                .catch(error => {
                    // Handle error during record deletion
                    console.error('Error deleting payment record:', error);
                    this.showToast('Error', 'Error deleting payment record', 'error');
                });
        }
    }

    handleSave() {
        console.log(JSON.stringify(this.payments));
        // Check UI Level Validations here
        let allRecords = [];
        this.payments.forEach((payment) =>{
            const record = {
                sobjectType: "ABHFL_Payment__c",
                Payment_Identifier__c:payment.Payment_Identifier__c,
                Amount__c:payment.Amount__c,
                Mode_of_Payment__c:payment.Mode_of_Payment__c,
                Date__c:payment.Date__c,
                Id:payment.Id,
                Realization_Status__c:payment.Realization_Status__c,
                Case__c:this.recordId
            };
            console.log(this.record);
            allRecords.push(record);
        })
        if(allRecords.length > 0){
            savePayments({caseId:this.recordId, payments:allRecords})
            .then((result) =>{
                refreshApex(this.serverPayments);
                // TODO Complete Checklist Here ?
                this.showToast("Success", "Payments updated successfully", "success");
            })
            .catch((error) =>{
                console.log(error);
                let errorMessage = error?.body?.message.split(',')[1].split(':')[0];
                this.showToast("Error", errorMessage, 'error');
            })
        }
    }

   

    handleCancel() {
       
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    setupFieldPermissions(stageName){
        this.isSaveAllowed = false;
        this.isPaymentIdEditable = false;
        this.isPaymentAmountEditable = false;
        this.isPaymentModeEditable = false;
        this.isDateEditable = false;
        this.isRealizationEditable = false;
        this.isDeleteAllowed = false;
        switch(stageName) {
            case 'Open':
                this.isPaymentIdEditable = true;
                this.isPaymentAmountEditable = true;
                this.isPaymentModeEditable = true;
                this.isDateEditable = true;
                this.isSaveAllowed = true;
                this.isDeleteAllowed = true;
                break;
            case 'CPU Banking':
                this.isRealizationEditable = true;
                this.isSaveAllowed = true;
                break;
            case 'Pending CPU Banking':
                this.isRealizationEditable = true;
                this.isSaveAllowed = true;
                break;
            default:
                break;
          }
        console.log('Setup Field Permissions' + this.isRealizationEditable);

        }

}