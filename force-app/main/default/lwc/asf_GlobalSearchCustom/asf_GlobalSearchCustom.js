import { LightningElement, api, track } from 'lwc';
import getCustomerProspectData from '@salesforce/apex/ASF_CustomerAndProspectSearch.getRecords';



export default class Asf_GlobalSearchCustom extends LightningElement {
    @api recordId;
    @track data;
    @track accountRecords;
    @track contactRecords;
    @track leadRecords;
    typingTimer;
    doneTypingInterval = 300;
    @track showWelcomeMat = true;
    @track headerString = 'Customer and Prospect Search is here.!';
    @track bAtleastOneRecord = false;
    @track showModal = false;


    cols_Customer = [
        { label: 'Name', fieldName: 'redirectLink', type: 'url', typeAttributes: { label: { fieldName: 'Name' }}},
        { label: 'Business Unit', fieldName: 'Business_Unit__c', type: 'text' },
        { label: 'Client Code', fieldName: 'Client_Code__c', type: 'text' }
    ];
    cols_Contact = [
        { label: 'Name', fieldName: 'redirectLink', type: 'url', typeAttributes: { label: { fieldName: 'Name' }}},
        { label: 'Email', fieldName: 'Email', type: 'text' }
    ];
    cols_Lead = [
        { label: 'Name', fieldName: 'redirectLink', type: 'url', typeAttributes: { label: { fieldName: 'Name' }}},
        { label: 'Name', fieldName: 'Name', type: 'text' }
    ]

    async handleInputChange(event) {
        console.log(event.target.value);
        let searchString = event.target.value;
        if (searchString != null && searchString != '') {
            // Only when something valid is entered.
            clearTimeout(this.typingTimer);
            this.typingTimer = setTimeout(() => {
                if (searchString.length >= 3) {
                    this.SearchCustomerProspectHandler(searchString);
                }
            }, this.doneTypingInterval);


        }
        else{
            this.showWelcomeMat = true;
        }

    }

    async SearchCustomerProspectHandler(searchString) {
        this.bAtleastOneRecord = false;
        this.showWelcomeMat = true;
        getCustomerProspectData({ searchString: searchString })
            .then(result => {
                console.log(result);
                if(result != null && result != undefined){
                    this.showWelcomeMat = false;
                }
                this.data = result;
                for (var a = 0; a < result.length; a++) {
                    if (result[a].objectName == 'Account') {
                        this.data[a].cols = this.cols_Customer;
                    }
                    else if (result[a].objectName == 'Contact') {
                        this.data[a].cols = this.cols_Contact;
                    }
                    else if (result[a].objectName == 'Lead') {
                        this.data[a].cols = this.cols_Lead;
                    }
                    
                    this.data[a].objRecords.forEach(res => {
                        res.redirectLink = '/' + res.Id;
                        this.bAtleastOneRecord = true;
                    });
                }
                
            })
            .catch(error => {
                console.log(error);
            })
    }
    handleCaseWithProspect(event){
        this.showModal=true;
    }
}