import { LightningElement,api,wire } from 'lwc';
import downloadUploadResults from '@salesforce/apex/ASF_BulkCsvController.downloadUploadResults';
import { loadScript } from 'lightning/platformResourceLoader';
import PapaParser from '@salesforce/resourceUrl/PapaParser';
import { CloseActionScreenEvent } from "lightning/actions";

export default class AsfGenerateResultCsv extends LightningElement {
    @api recordId;
    @api reqfromLwc = false;
    downloadSuccess = false;
    parserInitialized;
    csvString;

    @wire(downloadUploadResults, { bulkHeaderId: '$recordId'})
    wiredRecord({ error, data }) {
        if (data) {
            if(Array.isArray(data)){
                this.processData(data);
            }
        } else if (error) {
            console.error('Error loading record', error);
        }
    }

    renderedCallback() {
        if(!this.parserInitialized){
            loadScript(this, PapaParser)
                .then(() => {
                    this.parserInitialized = true;
                })
                .catch(error => console.error(error));
        }
    }
    async processData(data){
        let resultList = [];
        data.forEach(item => {
            let jsonData = JSON.parse(item.Result_JSON_Data__c);
            resultList.push(jsonData);
        });
        this.csvString = await this.unparseCSV(resultList);
        if(!this.reqfromLwc){
            this.downloadCsv();
        }
    }

    async unparseCSV(JsonVal) {
        const csvData = await Papa.unparse(JsonVal, {
            header: true,
            quotes: true,
        });
        return csvData;
    }

    downloadCsv(){
        this.downloadSuccess = true;
            let downloadElement = document.createElement('a');
            downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(this.csvString);
            downloadElement.target = '_blank';//'_self';
            downloadElement.download = 'BulkUploadResult' +'-' + Date.now() + '.csv';
            downloadElement.click(); 

        if(!this.reqfromLwc){
            this.dispatchEvent(new CloseActionScreenEvent());
        }else{
           /* const downloadCompleteEvent = new CustomEvent('downloadcomplete', {
                detail: { value: csvString }
            });
            this.dispatchEvent(downloadCompleteEvent); */
        }
    }
}