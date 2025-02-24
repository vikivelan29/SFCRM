import { LightningElement, api, track, wire} from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import CLIENT_CODE from '@salesforce/schema/Account.Client_Code__c';
import MOBILE_NUMBER from '@salesforce/schema/Account.PersonMobilePhone';  
import EMAIL_ID from '@salesforce/schema/Account.PersonEmail';  

export default class AbcdDigiGoldDetails extends LightningElement {
    @api dgdetails;
    @track showPopup = false;
    @api accountRecordId;;
    @track clientCode;
    @track mobileNumber;
    @track emailID; 

    @wire(getRecord, { recordId: '$accountRecordId', fields: [CLIENT_CODE,MOBILE_NUMBER,EMAIL_ID] })
    wiredRecord({ data, error }) {
        if (this.isRecordIdAvailable && data) {
            console.log('Record Data:', JSON.stringify(data));
            this.clientCode = getFieldValue(data, CLIENT_CODE);
            this.mobileNumber = getFieldValue(data, MOBILE_NUMBER);
            this.emailID = getFieldValue(data, EMAIL_ID);
            console.log('Extracted Client Code:', this.clientCode);
        } else if (error) {
            console.error('Error fetching record:', JSON.stringify(error));
        }
    }

    get isRecordIdAvailable() {
        return this.accountRecordId !== undefined && this.accountRecordId !== null;
    }

    connectedCallback() {
        console.log('Record ID in Parent:', this.accountRecordId);
    }
    
    openTransactionPopUp(event){
        this.showPopup = true;
    }

    closePopup() {
        this.showPopup = false;
    }

}