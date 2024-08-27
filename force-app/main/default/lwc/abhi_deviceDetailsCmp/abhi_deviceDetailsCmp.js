import { LightningElement, api, wire } from 'lwc';
import getDetails from '@salesforce/apex/ABHI_DeviceDetailsController.getDeviceDetails';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import recDevices from '@salesforce/label/c.ABHI_RecommendedDevice';
import otherDevices from '@salesforce/label/c.ABHI_OtherDevice';
import deviceDetail from '@salesforce/label/c.ABHI_DeviceDetails';
import pageSize from '@salesforce/label/c.ABFL_LegacyPageSize';
import { getRecord } from 'lightning/uiRecordApi';

export default class Abhi_deviceDetailsCmp extends LightningElement {
    @api recordId;
    showOtherRecords=false;
    showRecommendedRecords=false;
    displayMessage='';
    label = {
        pageSize,
        recDevices,
        otherDevices,
        deviceDetail
    };
    displayError=false;
    accountRecord;
    isLoading = false;
    fields = ['ACCOUNT.Client_Code__c'];

    @wire(getRecord, { recordId: '$recordId', fields: '$fields'})
    wiredRecord({ error, data }) {
        if (error) {
            console.error('Error getting RecordData', error);    
        } else if (data) {
          this.accountRecord = data;
        }
      }

    connectedCallback(){
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
                console.error('Error in getColumns>>>', JSON.stringify(error));
            });
        
    }

    getData(){
        let requestData = {
            MemberID: this.accountRecord.fields.Client_Code__c.value,
            OS: 'android',
            PolicyStartDate: '2000-12-09',
            WellnessID: ''
        };
        
        getDetails({customerId: this.recordId, requestPayload: JSON.stringify(requestData)})
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
            this.displayMessage=error.body.message;
            this.isLoading=false;
            this.displayError=true;
            this.showRecommendedRecords=false;
            this.showOtherRecords=false;
            console.error('error in getdetails>>>', error);
        });
    }

    handleRefresh(){
        this.isLoading=true;
        // this.showOtherRecords=false;
        // this.showRecommendedRecords=false;
        this.getData();
    }
}