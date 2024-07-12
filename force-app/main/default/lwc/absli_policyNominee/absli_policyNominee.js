import { LightningElement, api, track, wire } from 'lwc';
import generateData from './dummydata';
import fetchNomineeDetails from '@salesforce/apex/ABSLI_NomineeDetailController.getNomineeFromCore';

const columns = [
    { label: 'Nominee Name', fieldName: 'name' },
    { label: 'Nominee Share %', fieldName: 'allocation' },
    { label: 'Appointee', fieldName: 'appointee'},
    { label: 'DOB of Nominee', fieldName: 'nomineeDob', type: 'date' },
    { label: 'Relationship', fieldName: 'relationship' }    
];

export default class Absli_policyNominee extends LightningElement {
    @api recordId;

    @track data = [];
    @track columns = columns;
    @track processApexReturnValue;
    @track errorMessage = '';
    @track showErrorMsg = false;
    @track loaded = false;

    connectedCallback() {
        //this.data = generateData({ amountOfRecords: 25 });
    }

    
    @wire(fetchNomineeDetails, {
        "policyId": "$recordId"
    })
    async processResult(result) {
        this.processApexReturnValue = result.data;
        debugger;
        if(this.processApexReturnValue.bSuccess == true){
            this.data = this.processApexReturnValue.nominees;
            this.loaded = true; 
            debugger;
        }
        else{
            this.data = [];
            debugger;
            this.errorMessage = this.processApexReturnValue.errorMessage;
            this.showErrorMsg = true;
            this.loaded = true;
        }
        console.log(this.processApexReturnValue);
    }
    


    
}