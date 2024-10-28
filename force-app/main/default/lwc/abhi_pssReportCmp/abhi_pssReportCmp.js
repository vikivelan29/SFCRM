import { LightningElement, api } from 'lwc';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import errorMessage from '@salesforce/label/c.ASF_ErrorMessage';
import pageSize from '@salesforce/label/c.ABFL_LegacyPageSize';
import commHistoryLabel from '@salesforce/label/c.ABHI_Communication_History';
import getData from'@salesforce/apex/ABHI_PSSReportController.getData';

export default class Abhi_pssReportCmp extends LightningElement {
    @api recordId;
    showRecords = false;
    isLoading = false;
    message;
    label = {
        errorMessage,
        pageSize,
        commHistoryLabel
    };
    displayError=false;
    data=[];

    connectedCallback(){
        this.message=this.label.errorMessage;
        this.isLoading = true;
        getColumns({configName:'ABHI_PSSReport'})
        .then(result => {
                this.columns = [
                    ...result.map(col => ({
                        label: col.MasterLabel,
                        fieldName: col.Api_Name__c,
                        type: col.Data_Type__c,
                        cellAttributes: { alignment: 'left' },
                        typeAttributes: col.Data_Type__c=='date-local'?{
                            day: "2-digit",
                            month: "2-digit"
                        }:''
                    })),
                ];
                this.getDetails();
            })
        .catch(error => {
                // todo: remove hardcoding
                this.isLoading=false;
                this.displayError=true;
                this.showRecords=false;
                console.error('error in Column fetch>>>', error);
            });
        
    }

    handleRefresh(){
        this.isLoading=true;
         this.getDetails();
    }

    getDetails(){
        
        getData({recordId: this.recordId})
        .then(result => {
            let returnedData=result;
            
            if(result.StatusCode==200){
                result.PolicyInfo.forEach(element => {
                    if(element.MODE_OF_COMMUNICATION == 'Email'){
                        element.Status = element.EMAIL_STATUS;
                        element.CommunicationSentOn = element.EMAIL_ID;
                    }
                    else{
                        element.Status = element.SMS_STATUS;
                        element.CommunicationSentOn = element.MOBILE_NO;
                    }
                    this.data.push(element);
                });
                this.showRecords=true;
                this.isLoading=false;
            }
            else{
                this.message = result.Message;
                this.displayError=true;
                this.isLoading=false;
            }
        })
        .catch(error => {
            console.error('Error in getData>>>', error);
            this.isLoading=false;
            this.displayError=true;
            this.showRecords=false;
        });
    }
}