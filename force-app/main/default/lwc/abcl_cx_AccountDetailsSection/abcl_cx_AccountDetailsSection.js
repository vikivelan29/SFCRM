import { LightningElement,api,track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getFieldSetFields from '@salesforce/apex/ABCL_cx360Controller.getFieldSetFieldsAndValues';
import { NavigationMixin} from 'lightning/navigation';
const ACCOUNT_FIELDS = ['Account.Business_Unit__c','Account.Name','Account.Salutation'];

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

    // Wire to fetch Business Unit from Account record
    @wire(getRecord, { recordId: '$recordId', fields: ACCOUNT_FIELDS })
    wiredAccount({ data, error }) {
        if (data) {
            // Fetch Business Unit value
            this.businessUnit = data.fields.Business_Unit__c.value;
            this.title= data.fields.Salutation.value
            this.name = data.fields.Name.value;
            this.name= this.name.length > 30 ? this.name.substring(0, 27) + "..." : this.name;
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
            case 'ABFL':
                fieldSetName = 'ABFL_CX360_Fields';
                break;
            default:
                fieldSetName = 'ABFL_CX360_Fields';
        }
        // Call Apex method to get field set fields
        getFieldSetFields({ objectName, fieldSetName, recordId: this.recordId })
            .then((fields) => {
                this.fields = fields; // Populate the fields array
                /**this.fields = fields.map(row => {
                    // Add 'clickable' column based on condition
                    return {
                        ...row,
                        clickable: row.label === 'Client Code' // true if label is 'xyz', otherwise false
                    };
                });**/
                console.log('Fields retrieved from field set:', fields);
            })
            .catch((error) => {
                console.error('Error fetching field set fields:', error);
                this.error = error;
            });
    }
    
    
    
    navigateToAccDetails(){
        console.log('Navigation Started');
    this.invokeWorkspaceAPI('getFocusedTabInfo').then(focusedTab => {
        var strtabId;
        if(focusedTab.tabId){strtabId=focusedTab.tabId}
        if(focusedTab.parentTabId){strtabId=focusedTab.parentTabId}
        this.invokeWorkspaceAPI('openSubtab', {
            parentTabId: strtabId,
            pageReference: {
            type: "standard__component",
            attributes: {
                componentName: "c__abcl_CommonTabNavigationPage",
            },
            state: {
                c__accountId: this.recordId,
                c__showAccountDetails: true
            }
            },
            focus: true
        }).then(response => {
            this.invokeWorkspaceAPI('setTabLabel', {
            tabId: response,
            label: 'Account Details'
            }),
            this.invokeWorkspaceAPI('setTabIcon', {
                tabId: response,
                icon: "utility:snippet",
                iconAlt: "apex_plugin"
            })
        });
        });
        console.log('Navigation End');
    }
    
    invokeWorkspaceAPI(methodName, methodArgs) {
        return new Promise((resolve, reject) => {
        const apiEvent = new CustomEvent("internalapievent", {
            bubbles: true,
            composed: true,
            cancelable: false,
 
            detail: {
            category: "workspaceAPI",
            methodName: methodName,
            methodArgs: methodArgs,
            callback: (err, response) => {
                if (err) {
                return reject(err);
                } else {
                return resolve(response);
                }
            }
            }
        });
        window.dispatchEvent(apiEvent);
        });
    }
}