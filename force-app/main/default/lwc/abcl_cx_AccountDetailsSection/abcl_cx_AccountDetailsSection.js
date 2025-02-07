import { LightningElement,api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getAccountInfoFields from '@salesforce/apex/ABCL_cx360Controller.getAccountInfoFields';
import { NavigationMixin} from 'lightning/navigation';
import getHNIField from '@salesforce/apex/ABCL_cx360Controller.getHNIorHWCField';
const ACCOUNT_FIELDS = ['Account.Business_Unit__c','Account.Name','Account.Salutation'];

export default class Abcl_cx_AccountDetailsSection extends NavigationMixin(LightningElement) {

    objectInfo;
    @api recordId;
    name;
    fields = []; // List of field API names from the field set
    accountData = {}; // Stores queried account field values
    businessUnit; // Business unit value fetched from the Account record
    error; // Error messages for debugging
    title;
    showHNI= false;
    // Wire to fetch Business Unit from Account record
    @wire(getRecord, { recordId: '$recordId', fields: ACCOUNT_FIELDS })
    wiredAccount({ data, error }) {
        if (data) {
            // Fetch Business Unit value
            this.businessUnit = data.fields.Business_Unit__c.value;
            this.title= data.fields.Salutation.value
            this.name = data.fields.Name.value;
            this.name= this.name.length > 23 ? this.name.substring(0, 20) + "..." : this.name;
            this.getHNIField();
            // Fetch the fields from the appropriate field set
            this.fetchFieldSet();
        } else if (error) {
            console.error('Error fetching account record:', error);
            this.error = error;
        }
    }

    // Fetch fields from the appropriate field set based on Business Unit
    fetchFieldSet() {
        // Call Apex method to get field set fields
        getAccountInfoFields({recordId: this.recordId, businessUnit: this.businessUnit, tileName:'Account Info'})
            .then((fields) => {
                this.fields = fields; // Populate the fields array
            })
            .catch((error) => {
                console.error('Error fetching field set fields:', error);
                this.error = error;
            });
    }
    getHNIField(){
        getHNIField({recordId: this.recordId, businessUnit:this.businessUnit,scenario:'HNI' })
        .then(result => {
            this.showHNI = result;    
        })
        .catch(error => {
            console.error('HNI error ', error);
        });
    }
    
}