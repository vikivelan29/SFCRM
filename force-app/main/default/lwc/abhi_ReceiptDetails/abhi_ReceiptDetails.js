import { LightningElement,track,api,wire } from 'lwc';
import GetReceiptDetails from '@salesforce/apex/ABHI_ReceiptDetails.GetReceiptDetails';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import { getRecord } from 'lightning/uiRecordApi';

export default class Abhi_ReceiptDetails extends LightningElement {

    @api recordId;
    @track isLoading = false;
    @track errorMessages = '';
    @track displayError = false;
    @track showData;
    showRecords = false;
    @track data = [];

    label = {
        errorMessage: 'Error in message',
        pageSize: 5
    };

    @wire(getRecord, { recordId: '$recordId'})
    record;

    connectedCallback(){
        getColumns({configName:'ABHI_ReceiptDetailsView'})
        .then(result => {
            console.log('result columns--'+JSON.stringify(result));
            this.columns = [
                ...result.map(col => ({
                    label: col.MasterLabel,
                    fieldName: col.Api_Name__c,
                    type: col.Data_Type__c,
                    cellAttributes: { alignment: 'left' },
                })),
            ]; 
            this.GetReceipts();
    
        })
    .catch(error => {
            
            this.isLoading=false;
            this.displayError=true;
            this.showRecords=false;
            console.error('error in Column fetch>>>', error);
        });
    }

    GetReceipts(){
        this.isLoading = true;
        GetReceiptDetails({assetId: this.recordId})
        .then(result => {
            this.result=result;
            console.log('Response Data:', JSON.stringify(result));
            const responseObj = result.ResponseObj[0] || {};
            const StatusCode = responseObj.Code;
            const RespMessage = responseObj.Message;
            console.log('status code', StatusCode);
            console.log('ResponseObj Message', RespMessage);
            this.ApiFailure = RespMessage;    //this.ApiFailure = result.Message;
            if(StatusCode === 1){
                //const Response = result.Response || [];
            if (result.Response === null || !Array.isArray(result.Response) || result.Response.length === 0) {
                    // Response is either null, or an empty array
                    this.errorMessages = 'No data found';
                    this.isLoading = false;
                    this.displayError = true;
                    this.showRecords = false;
                }else{
                    // Response is a non-empty
                    this.displayError=false;
                    this.data = result.Response;
                    this.errorMessages = '';
                    this.showRecords=true;
                    this.isLoading = false;
                }   
            }
            else if(StatusCode == 501){
                this.errorMessages = 'No response received from server';  //this.errorMessages = result.Message
                this.isLoading=false;
                this.displayError=true;
                this.showRecords=false;
            }
            else{
                this.errorMessages = RespMessage;   ////this.errorMessages = result.Message
                this.isLoading=false;
                this.displayError=true;
                this.showRecords=false;
            }
        
        })
        .catch(error => {
            this.isLoading=false;
            this.displayError=true;
            this.showRecords=false;
            if (error.body!= null) {
                this.errorMessages = error.body.message;
            } else if(this.ApiFailure){
                this.errorMessages = this.ApiFailure;
            }
            else{
                this.errorMessages = 'An unknown error occured, please contact your system admin'
            }
            console.error('error in getdetails>>>', error);
        });

    }
    handleRefresh(){
        this.isLoading=true;
        this.showData=false;
        this.GetReceipts();
        
    }

    // handleShowSpinners(){
    //     this.dispatchEvent(new CustomEvent('uploadstart'));
    // }
    // handleHideSpinners(){
    //     this.dispatchEvent(new CustomEvent('uploadend'));
    // }

}