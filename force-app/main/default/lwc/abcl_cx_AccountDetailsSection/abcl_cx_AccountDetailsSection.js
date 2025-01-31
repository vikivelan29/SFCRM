import { LightningElement,api,track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getAccountInfoFields from '@salesforce/apex/ABCL_cx360Controller.getAccountInfoFields';
import { NavigationMixin} from 'lightning/navigation';
import getHNIField from '@salesforce/apex/ABCL_cx360Controller.getHNIorHWCField';
const ACCOUNT_FIELDS = ['Account.Business_Unit__c','Account.Name','Account.Salutation','Account.HNI_Customer__c'];

export default class Abcl_cx_AccountDetailsSection extends NavigationMixin(LightningElement) {

    objectInfo;
    fieldNames = [];
    @api recordId;
    name;
    accountNumber;
    gender;
    phone;
    pan;
    dob;
    reKycDueDate;
    email;
    nachStatus;
    preferredLanguage;
    state;
    error;
    email
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
        const objectName = 'Account';
        let fieldSetName;

        // Determine the field set name based on the Business Unit
        switch (this.businessUnit) {
            case 'ABHFL':
                fieldSetName = 'ABHFL_CX360_Fields';
                break;
            case 'ABML':
                fieldSetName = 'ABML_CX360_Fields';
                break;
            default:
                fieldSetName = 'ABHFL_CX360_Fields';
        }
        // Call Apex method to get field set fields
        getAccountInfoFields({recordId: this.recordId, businessUnit: this.businessUnit, tileName:'Account Info'})
            .then((fields) => {
                this.fields = fields; // Populate the fields array
                /**this.fields = fields.map(row => {
                    // Add 'clickable' column based on condition
                    return {
                        ...row,
                        clickable: row.label === 'Client Code' // true if label is 'xyz', otherwise false
                    };
                });**/
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