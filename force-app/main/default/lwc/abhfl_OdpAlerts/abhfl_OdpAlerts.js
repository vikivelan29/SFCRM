import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import getOdpAlerts from '@salesforce/apex/ABHFL_ODPAlerts.getOdpAlerts';
import getConstants from '@salesforce/apex/ABHFL_Constants.getAllConstants';
import getConstantsABFL from '@salesforce/apex/ABFL_Constants.getAllConstants'; //new code for ABFL
import businessUnitType from '@salesforce/schema/User.Business_Unit__c';
const ACCOUNTFIELDS = ["Account.Business_Unit__c"];
export default class Abhfl_OdpAlerts extends LightningElement {
    @api recordId ;
    showSpinner = false;
    showErrorMessage = false;
    isAbhflUser = false;
    isAbflUser = false; //New
    userType;
    responseMessage;
    account;

    @wire(getRecord, { recordId: "$recordId", fields: ACCOUNTFIELDS}) 
    accountInfo({error, data}) {
        if (data) {
            this.odpAlerts();
            this.account = data;
        } else if (error) {
            this.handleError(error);
        }
    }

    odpAlerts(){
        this.showSpinner = true;
        this.showErrorMessage = false;
        //let isABFL = this.account.fields.BusinessUnit__c.value == 'ABFL' ? true : false;
        getOdpAlerts({'AccountId':this.recordId, isABFL: false}) //new
        .then(result => {
            if(result && result.length > 0){
                this.responseMessage = result;
                this.showErrorMessage = false;
            }
            this.showSpinner = false;
        })
        .catch(error => {
            this.showSpinner = false;
            this.handleError(error);
            console.log('error==>',JSON.stringify(error));
        });
    }

    handleError(error){
        this.responseMessage = error;
        this.showErrorMessage = true;
    }
}