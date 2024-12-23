import { LightningElement, api, track } from 'lwc';
import GetHhsActiveAge from '@salesforce/apex/ABHI_HhsActiveAgeDetails_Controller.GetHhsActiveAge';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class Abhi_ActiveAge extends LightningElement {

    @api recordId;
    @track columns = [];
    @track data;
    displayTable=false;
    showRecords = false;
    label = {
        errorMessage: 'Error in message',
        pageSize: 5
    };


    connectedCallback(){
        this.handleShowSpinners();
        getColumns({configName:'ABHI_ActiveAgeDetails'})
        .then(result => {
                console.log('**rec2>'+JSON.stringify(result));
                console.log('result1', result);
                console.log('customerId>>');
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
                console.log('GetHhsActiveAge>>', this.GetHhsActive);
            })
        .catch(error => {
                // todo: remove hardcoding
                //this.showNotification('Error','Error fetching data.','Error');
                this.handleHideSpinners();
            });
        
    }

    GetHhsActive() {
        // const clientCode = this.clientCode;
         //if (!clientCode) {
             //this.showNotification('Error', 'Client Code is not available.', 'error');
             //return;
         //}
         console.log('GetHHsActiveAge')
         let customerId = this.recordId;
         GetHhsActiveAge({customerId: customerId})
         .then(result => {
             console.log('recordId>>', customerId);
             console.log('Result>>>>', result);
             if(result.StatusCode == 1000){

                 let data = [];
                 data.push(result.activeAge);
                 this.data= data;
                 
                 this.showRecords=true;
                 this.displayTable=true;
                 let StatusCode = result.StatusCode;
             console.log('statusCode', result.StatusCode);
             console.log('this.date', JSON.stringify(this.data));
                 //this.showNotification('Success', result.Message, 'success');
             }
             else{
                 //this.showNotification('Error', result.Message, 'error');
             }
         })
         .catch(error => {
             console.error('error in getdetails>>>', error);
             //this.showNotification('Error', error.message, 'error');
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