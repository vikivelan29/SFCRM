import { LightningElement, api, wire } from 'lwc';
import getDetails from '@salesforce/apex/ABHI_DeviceDetailsController.getDeviceDetails';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import recDevices from '@salesforce/label/c.ABHI_RecommendedDevice';
import otherDevices from '@salesforce/label/c.ABHI_OtherDevice';
import deviceDetail from '@salesforce/label/c.ABHI_Devices';
import pageSize from '@salesforce/label/c.ABFL_LegacyPageSize';
import errorMessage from '@salesforce/label/c.ASF_ErrorMessage';

export default class Abhi_deviceDetailsCmp extends LightningElement {
    @api recordId;
    showOtherRecords=false;
    showRecommendedRecords=false;
    displayMessage='';
    label = {
        errorMessage,
        pageSize,
        recDevices,
        otherDevices,
        deviceDetail
    };
    displayError=false;
    accountRecord;
    isLoading = false;

    connectedCallback(){
        this.displayMessage = this.label.errorMessage;
        this.isLoading=true;
        getColumns({configName:'ABHI_DeviceDetails'})
        .then(result => {
                this.columns = [
                    ...result.map(col => ({
                        label: col.MasterLabel,
                        fieldName: col.Api_Name__c,
                        type: col.Data_Type__c,
                        cellAttributes: { alignment: 'left' }
                    })),
                ];
                this.getData();
            })
        .catch(error => {
                // todo: remove hardcoding
                this.isLoading=false;
                this.displayError=true;
                this.showRecommendedRecords=false;
                this.showOtherRecords=false;
                console.error('Error in getColumns>>>', JSON.stringify(error));
            });
        
    }

    getData(){
        
        getDetails({customerId: this.recordId})
        .then(result => {
            let returnedData=result;
            if(result.statusCode==1000){
                this.isLoading=false;
                this.displayError=false;
                if(result.devices && result.devices.Recommended){
                    returnedData.devices.Recommended.forEach(element => {
                        element.synced=element.synced==0?false:true;
                    });
                    this.recommendedData = returnedData.devices.Recommended;
                    this.showRecommendedRecords=true;
                }
                if(result.devices && result.devices.Others){
                    returnedData.devices.Others.forEach(element => {
                        element.synced=element.synced==0?false:true;
                    });
                    this.otherData = returnedData.devices.Others;
                    this.showOtherRecords=true;
                }
            }
            else{
                this.displayMessage=result.Message;
                this.isLoading=false;
                this.displayError=true;
                this.showRecommendedRecords=false;
                this.showOtherRecords=false;
            }
        })
        .catch(error => {
            this.isLoading=false;
            this.displayError=true;
            this.showRecommendedRecords=false;
            this.showOtherRecords=false;
            console.error('error in getdetails>>>', error);
        });
    }

    handleRefresh(){
        this.isLoading=true;
        this.getData();
    }
}