import { LightningElement, api } from 'lwc';

export default class Asf_RecategoriseCase extends LightningElement {
    @api recordId;
    isLoading = false; //for spinner control
}