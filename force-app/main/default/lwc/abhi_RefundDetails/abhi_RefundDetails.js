import { LightningElement,track,api,wire } from 'lwc';
import GetRefunds from '@salesforce/apex/ABHI_RefundDetails.GetRefunds';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import { getRecord } from 'lightning/uiRecordApi';

export default class Abhi_RefundDetails extends LightningElement {

    @api recordId;
    @track isLoading = false;
    @track errorMessages = '';
    @track displayError = false;
    @track showData;
    showRecords = false;
    //@track data = [];

    label = {
        errorMessage: 'Error in message',
        pageSize: 5
    };

    @wire(getRecord, { recordId: '$recordId'})
    record;


    connectedCallback(){
        getColumns({configName:'ABHI_RefundDetailsView'})
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
            this.GetRefund();
    
        })
    .catch(error => {
            
            this.isLoading=false;
            this.displayError=true;
            this.showRecords=false;
            console.error('error in Column fetch>>>', error);
        });
    }

    GetRefund(){
        this.isLoading = true;
        GetRefunds({assetId: this.recordId})
        .then(result => {
            this.result=result;
            console.log('Response Data:', JSON.stringify(result));
            //const responseObj = result.ResponseObj[0] || {};
            const responseObj = result.ResponseObj || {};
            console.log('response obj',JSON.stringify(responseObj));
            const StatusCode = responseObj.Code;
            const RespMessage = responseObj.Message;
            this.ApiFailure = RespMessage;
            if(StatusCode === 1){
                const receiptObj = result.ReceiptObj || [];
            if (receiptObj.length === 0 || receiptObj[0].RefundDetails.length === 0) {
                    // Response is either null, or an empty array
                    this.errorMessages = 'No data found';
                    this.isLoading = false;
                    this.displayError = true;
                    this.showRecords = false;
                }else{
                    // Response is a non-empty
                    this.displayError=false;
                    this.data = receiptObj.flatMap(receipt => receipt.RefundDetails);
                    this.errorMessages = '';
                    this.showRecords=true;
                    this.isLoading = false;
                }   
            }
            else if(StatusCode == 1001){
                this.errorMessages = RespMessage;  //this.errorMessages = result.Message
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
        this.GetRefund();
    }




}