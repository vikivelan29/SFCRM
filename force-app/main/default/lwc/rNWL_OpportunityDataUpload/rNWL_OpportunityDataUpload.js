import { LightningElement, track } from 'lwc';
import updateOpportunityRecords from '@salesforce/apex/RNWL_OpportunityDataController.updateOpportunityRecords';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import sheetjs from '@salesforce/resourceUrl/SheetJS';
import template from '@salesforce/resourceUrl/RNWL_BulkUploadTemplate';
let XLS = {};
const columns = [
    { label: 'Renewal Request Name', fieldName: 'oppId', type: 'url',typeAttributes: {label: { fieldName: 'oppName' }, target: '_blank'},
            sortable: true},
    { label: 'Policy Number', fieldName: 'policyNumber'},
    { label: 'Status', fieldName: 'status' },
    { label: 'Error Message', fieldName: 'response'}
];

export default class OpportunityDataUpload extends NavigationMixin(LightningElement) {
    @track acceptedFormats = ['.xls', '.xlsx'];
    label ={
    template
    };
    filesUploaded = [];
    fileName;
    parsedData;
    file;
    isLoading = false;
    recordStatus = false;
    fileReader;
    @track errorRecords = {}
    data = [];
    columns = columns;
    
    columnHeader = ['Policy Number', 'Final Eligibility', 'Propensity to Pay', 'Renewal Calling Flag', 'Calling Source', 'Upsell SI 1', 'Upsell SI 2', 'Upsell SI 3', 'Upsell SI 4', 'Upsell SI 5', 'Max Upsell', 'Bucket', 'Error Message']
    MAX_FILE_SIZE = 1500000;

    async connectedCallback() {
        Promise.all([
            loadScript(this, sheetjs)
        ]).then(() => {
            XLS = XLSX
        })

    }

    handleReset(){
        this.fileName = '';
        this.parsedData = '';
        this.recordStatus = false;
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        console.log('uploadedFiles ' + uploadedFiles);
        if (uploadedFiles.length > 0) {
            this.excelToJSON(uploadedFiles[0])
            this.filesUploaded = uploadedFiles;
            this.fileName = 'Selected file: ' + uploadedFiles[0].name;
        }
    }

    excelToJSON(file) {
        console.log('file ' + file);
        var reader = new FileReader();
        reader.onload = event => {
            var data = event.target.result;
            console.log('data ' + data);
            var workbook=XLS.read(data, {
                type: 'binary'
            });
            console.log('workbook json' + JSON.stringify(workbook));
            var XL_row_object = XLS.utils.sheet_to_row_object_array(workbook.Sheets["Sheet1"]);
            console.log('XL_row_object ' + XL_row_object);
            this.parsedData = JSON.stringify(XL_row_object);
            console.log('parsedData ' + this.parsedData);
        };
        reader.onerror = function (ex) {
            this.error = ex;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error while reading the file',
                    message: ex.message,
                    variant: 'error',
                }),
            );
        };
        reader.readAsBinaryString(file);
    }

    handleSave() {
        if (this.parsedData) {
            this.uploadHelper();
        } else {
            this.fileName = 'Please select an excel file to upload!!';
        }
    }

    uploadHelper() {
        this.file = this.filesUploaded[0];
        if (this.file.size > this.MAX_FILE_SIZE) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'File size is too long',
                    message: 'File size is too long. Please upload another file to proceed',
                    variant: 'error',
                    mode: 'sticky'
                }),
            );
            return;
        }
        this.isLoading = true;
        this.saveToFile();
    }

    saveToFile() {
       // this.recordStatus = undefined;
        console.log('this.parsedData '+this.parsedData);
        updateOpportunityRecords({ oppData: this.parsedData?.replaceAll('\\', '') })
        .then(result => {
            this.filesUploaded = '';
            this.fileName = '';
            if (result) {
                let hasAtleastOneError = false; 
                // let recordStatus = JSON.stringify(result);
                    //console.log('recordStatus '+recordStatus);
                    this.errorRecords = result;
                    this.data = result;
                for (let i=0;i<result.length; i++) {
                    console.log('result[i] '+JSON.stringify(result[i]));
                    if (result[i].status != 'Success') {
                        
                        hasAtleastOneError = true;
                        this.recordStatus = true;
                        
                    }
                    
                }
                if (hasAtleastOneError) {
                    //this.recordStatus = recordStatus;
                    console.log('errorRecords '+this.errorRecords);
                    let doc = '<table>';
                    
                    // Add all the Table Headers
                    doc += '<tr>';
                    this.columnHeader.forEach(element => {            
                    doc += '<th>'+ element +'</th>'           
                    });
                    doc += '</tr>';
                    this.errorRecords.forEach(record => {
                    if(record.status =='Error'){
                        console.log('record '+record.status);
                    doc += '<tr>';
                    doc += '<th>'+record.policyNumber+'</th>'; 
                    doc += '<th>'+record.finalEligibilityFlag+'</th>'; 
                    doc += '<th>'+record.propensityToPay+'</th>'; 
                    doc += '<th>'+record.renewalCallingFlag+'</th>';
                    doc += '<th>'+record.callingSource+'</th>';
                    doc += '<th>'+record.upsellSI1+'</th>';
                    doc += '<th>'+record.upsellSI2+'</th>';
                    doc += '<th>'+record.upsellSI3+'</th>';
                    doc += '<th>'+record.upsellSI4+'</th>';
                    doc += '<th>'+record.upsellSI5+'</th>';
                    doc += '<th>'+record.maxUpsell+'</th>';
                    doc += '<th>'+record.bucket+'</th>';
                    doc += '<th>'+record.response+'</th>'; 
                    doc += '</tr>';
                    }
                });
                    doc += '</table>';
                    var element = 'data:application/vnd.ms-excel,' + encodeURIComponent(doc);
                    let downloadElement = document.createElement('a');
                    downloadElement.href = element;
                    downloadElement.target = '_self';
                    downloadElement.download = 'OpportunityUploadErrorFile.xls'; 
                    document.body.appendChild(downloadElement);
                    downloadElement.click();

                    this.showMessage('Opportunity rows were updated partially!', 'warning', 'Warning!');
                } else {
                    this.recordStatus = true;
                    this.showMessage('All Opportunity rows were updated successfully!!', 'success', 'Success!');
                }
            }
            this.isLoading = false;
        })
        .catch(error => {
            console.log(error);
            let message = error.body.message;
            if (message.includes('Duplicate')) {
                message = 'Your file has duplicates. Please remove duplicates and reupload it';
            }
            this.showMessage(message, 'error', 'Error!');
            this.isLoading = false;
        });
    }

    showMessage(message, variant, title) {
        const event = new ShowToastEvent({
            title: title,
            variant: variant,
            mode: 'dismissable',
            message: message
        });
        this.dispatchEvent(event);
    }

}