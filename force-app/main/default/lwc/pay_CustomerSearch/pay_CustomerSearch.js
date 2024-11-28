import { LightningElement } from 'lwc';
import searchCustomerExternal from '@salesforce/apex/PAY_CustomerSearchController.searchCustomerExternal';
import createCustomer from '@salesforce/apex/PAY_CustomerSearchController.createCustomer';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import customCSS from '@salesforce/resourceUrl/CustomerSearchCSS';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class Asf_CustomerSearch extends NavigationMixin(LightningElement) {
    columns = [
                    { label: 'Name', fieldName: 'Name' },
                    { label: 'Client Code', fieldName: 'ClientCode'},
                    { label: 'Phone', fieldName: 'Phone'},
                    { label: 'Email', fieldName: 'Email'},
                    {
                        type: "button",fixedWidth: 155, 
                        typeAttributes: { label: 'View Customer', name: 'view_customer', variant:'Brand' },
                        cellAttributes: { alignment: 'center' },
                    }
              ];

    options = [
                { label: 'Phone', value: 'Phone' },
                { label: 'Customer ID', value: 'CustomerID' }
              ];
    data = [];
    searchterm;
    error;
    customerExistsSFDC = true;
    searchResult;
    searchOption = 'Phone';
    createCustomer = [];

    changeHandler(e){
        if(e.target.name == 'search-input'){
            this.searchterm = e.target.value;
            this.searchResult = undefined;
        } else if(e.target.name == 'searchSelector'){
            this.searchOption = e.target.value;
        }

    }

    handleRowAction(e) {
        const actionName = e.detail.action.name;
        const row = e.detail.row;
        switch (actionName) {
            case 'view_customer':
                this.navigateToCustomerRecord(row);
                break;
            case 'create_customer':
                this.createCustomerRecord(row);
                break;
            default:
        }
    }

    navigateToCustomerRecord(row){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: row.Id,
                actionName: 'view'
            }
        });
    }

    createCustomerRecord(row){
        createCustomer({customerData : row}).then((result) => {
            this.searchResult = undefined;
            this.navigateToCustomerRecord(result);
            console.log(this.searchResult);
        }).catch((error) => {
            this.error = error;
            this._title = this.error.statusText;
            this.message = this.error.body.message;
            if(this.error.body.message.includes('DUPLICATE_VALUE')){
                this.message = 'Customer Already Exists';
            }
            this.variant = 'error';
            this.showNotification();
        })
    }

    initiateExternalSearch(e){
        if(this.searchterm){
            searchCustomerExternal({searchTerm : this.searchterm, searchBasedOn : this.searchOption}).then((result) => {
                this.searchResult = result;
                if(this.searchResult.length){
                    this.columns.forEach(function (arrayItem) {
                        if(arrayItem.type && arrayItem.type == 'button'){
                            arrayItem.typeAttributes.label = 'Create Customer'; 
                            arrayItem.typeAttributes.name = 'create_customer'; 
                        }
                    });
                } else {
                    this._title = 'Info';
                    this.message = 'Customer data not found';
                    this.variant = 'info';
                    this.showNotification();
                }
            }).catch((error) => {
                this.error = error;
                this.searchResult = undefined;
                this._title = this.error.statusText;
                this.message = this.error.body.message;
                this.variant = 'error';
                this.showNotification();
            })
        }
    }

    renderedCallback(){
        Promise.all([
            loadStyle(this, customCSS + '/asf_CustomerSearch.css')
        ])
    }

    showNotification() {
        const evt = new ShowToastEvent({
          title: this._title,
          message: this.message,
          variant: this.variant,
        });
        this.dispatchEvent(evt);
      }
}