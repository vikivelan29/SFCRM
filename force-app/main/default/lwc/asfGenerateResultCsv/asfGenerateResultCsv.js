import { LightningElement,api,wire } from 'lwc';
import downloadUploadResults from '@salesforce/apex/ASF_BulkCsvController.downloadUploadResults';
import { loadScript } from 'lightning/platformResourceLoader';
import PapaParser from '@salesforce/resourceUrl/PapaParser';
import { CloseActionScreenEvent } from "lightning/actions";

export default class AsfGenerateResultCsv extends LightningElement {
    @api recordId;
    @api reqfromLwc = false;
    downloadFailed = false;
    parserInitialized;
    csvString;

    //This component is called from ASF_BulkCSVuploadDownload and also from the quick action button on Bulk Header Object
    @wire(downloadUploadResults, { bulkHeaderId: '$recordId'})
    wiredRecord({ error, data }) {
        if (data) {
            if(Array.isArray(data) && data != undefined && data != ''){
                this.processData(data);
            }
            else{
                this.downloadFailed = true;
            }
        } else if (error) {
            console.error('Error loading record', error);
        }
    }

    //Initializes PapaParser from Static Resource
    renderedCallback() {
        if(!this.parserInitialized){
            loadScript(this, PapaParser)
                .then(() => {
                    this.parserInitialized = true;
                })
                .catch(error => console.error(error));
        }
    }

    //Unparses the Result JSON field to generate csv
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
    
    // Unparses the json object to string using papa parser
    async unparseCSV(JsonVal) {
        const csvData = await Papa.unparse(JsonVal, {
            header: true,
            quotes: true,
        });
        return csvData;
    }

    //Auto downloads the csv when the request is from quick action on header object
    downloadCsv(){
            let downloadElement = document.createElement('a');
            downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(this.csvString);
            downloadElement.target = '_blank';//'_self';
            downloadElement.download = 'BulkUploadResult' +'-' + Date.now() + '.csv';
            downloadElement.click(); 

        if(!this.reqfromLwc){
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }
}