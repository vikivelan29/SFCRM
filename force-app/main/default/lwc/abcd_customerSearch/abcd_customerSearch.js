import { LightningElement } from 'lwc';
import searchCustomerExternal from '@salesforce/apex/ABCD_CustomerInfoController.searchCustomerExternal';
import createCustomer from '@salesforce/apex/ABCD_CustomerInfoController.createCustomer';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import customCSS from '@salesforce/resourceUrl/CustomerSearchCSS';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { reduceErrors } from 'c/asf_ldsUtils';

export default class Abcd_customerSearch extends NavigationMixin(LightningElement) 
{
    columns = [
            { label: 'Name', fieldName: 'customerName' },
            { label: 'Client Code', fieldName: 'customerId'},
            { label: 'Phone', fieldName: 'mobileNumber'},
            { label: 'Email', fieldName: 'emailId'},
            { label: 'Age', fieldName: 'age'},
            { label: 'Date of Birth', fieldName: 'dob'},
            { label: 'PAN', fieldName: 'pan'},
            {
                type: "button",fixedWidth: 155, 
                typeAttributes: { label: 'View Customer', name: 'view_customer', variant:'Brand' },
                cellAttributes: { alignment: 'center' },
            }
    ];

    options = [
        { label: 'Phone', value: 'Phone' },
        { label: 'Email', value: 'Email' },
        { label: 'Customer ID', value: 'CustomerID' }
    ];
    searchterm;
    error;
    searchResult;
    searchOption = 'Phone';

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
        console.log('account details:'+JSON.stringify(row));
        createCustomer({customerData : row}).then((result) => {
            this.searchResult = undefined;
            this.navigateToCustomerRecord(result);
            console.log(this.searchResult);
        }).catch((error) => {
            console.log('Error:'+JSON.stringify(error));
            this.error = error;
            this._title = this.error.statusText;
            if(JSON.stringify(this.error.body).includes('DUPLICATE_VALUE')){
                this.message = 'Customer Already Exists';
            }else{
                this.message = reduceErrors(this.error);
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