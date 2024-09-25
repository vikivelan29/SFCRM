import { LightningElement,api,track, wire } from 'lwc';
import GetHhsActiveAge from '@salesforce/apex/ABHI_HhsActiveAgeDetails_Controller.GetHhsActiveAge';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
//import { getRecord , getFieldValue} from 'lightning/uiRecordApi';
//import CLIENT_CODE_FIELD from '@salesforce/schema/Account.Client_Code__c';
//const fields = [CLIENT_CODE_FIELD]; 
export default class Abhi_HhsActiveAgeDetails extends LightningElement {

    

    @api recordId;
    @track columns = [];
    @track data;
    customerId;
    displayTable=false;
    showRecords = false;
    @track errorMessages = '';
    @track displayError = false;
    label = {
        errorMessage: 'Error in message',
        pageSize: 5
    };

   

 //@wire(getRecord, { recordId: '$recordId', fields })
    //account;

    /*get clientCode() {
        return this.account.data ? this.account.data.fields.Client_Code__c.value : null;
    }*/


    connectedCallback(){
        this.handleShowSpinners();
        getColumns({configName:'ABHI_HHS_ActiveAgeDetails'})
        .then(result => {
    //const clientCode = getFieldValue(this.account.data, CLIENT_CODE_FIELD);

                console.log('**resultString>'+JSON.stringify(result));
                this.columns = [
                    ...result.map(col => ({
                        label: col.MasterLabel,
                        fieldName: col.Api_Name__c,
                        type: col.Data_Type__c,
                        cellAttributes: { alignment: 'left' }
                    })),
                ];
                console.log('coloumns', JSON.stringify(this.columns));
                this.GetHhsActive();
                this.handleHideSpinners();
            })
        .catch(error => {
                // todo: remove hardcoding
                //this.showNotification('Error','Error fetching data.','Error');
                this.handleHideSpinners();
            });
        
    }

    GetHhsActive() {
        //const clientCode = getFieldValue(this.account.data, CLIENT_CODE_FIELD);
        //console.log('clientCode ',clientCode);
        //this.customerId = clientCode ? clientCode : null;
        //this.customerId = this.customerId;

        console.log('GetHHsActiveAge')
        let customerId = this.recordId;
        console.log('recordId', this.recordId);
        GetHhsActiveAge({customerId: customerId})
        .then(result => {
            console.log('recordId>>', customerId);
            console.log('Result>>>>', result);
            if(result.StatusCode == 1000){
                let data = [];
                data.push(result);
                this.data= data;
                this.showRecords=true;
                this.displayTable=true;
                let statusCode = result.statusCode;
            console.log('statusCode', result.statusCode);
            console.log('this.date', JSON.stringify(this.data));
                //this.showNotification('Success', result.Message, 'success');
            }
            else{
                this.displayError = false;
                this.dispatchEvent(new CustomEvent('handleChildError',{
                    detail: {
                                    message: result.Message
                                }
                            }));
            }
        })
        .catch(error => {
            console.error('error in getdetails>>>', error);
            let errorDisplay = 'Error: ' + error.message;
            this.errorMessages = (error.body.message);
            this.displayError = true;
            //this.showNotification('Error', error.message, 'error');
            this.handleHideSpinners();
            this.dispatchEvent(new CustomEvent('handleError',{
                detail: {
                                message: error.body.message
                            }
                        }));
        });
    }

    showNotification(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }

    handleShowSpinners(){
        this.dispatchEvent(new CustomEvent('uploadstart'));
    }
    handleHideSpinners(){
        this.dispatchEvent(new CustomEvent('uploadend'));
    }




}