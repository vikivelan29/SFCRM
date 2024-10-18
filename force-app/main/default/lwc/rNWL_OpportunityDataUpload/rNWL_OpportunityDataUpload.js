import { LightningElement, track } from 'lwc';
import updateOpportunityRecords from '@salesforce/apex/RNWL_OpportunityDataController.updateOpportunityRecords';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import sheetjs from '@salesforce/resourceUrl/SheetJS';

let XLS = {};

export default class OpportunityDataUpload extends NavigationMixin(LightningElement) {
    @track acceptedFormats = ['.xls', '.xlsx'];

    filesUploaded = [];
    fileName;
    parsedData;
    file;
    isLoading = false;
    recordStatus;
    fileReader;
    url='/sfc/p/Bl000000pvNd/a/Bl000000dUz7/eePAzAX2mn82WNfKGX5BVj0AEoXUjaTpUAhIkhacSck';
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
        this.parsedData = ';'
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        console.log('uploadedFiles ' + uploadedFiles);
        if (uploadedFiles.length > 0) {
            this.excelToJSON(uploadedFiles[0])
            this.filesUploaded = uploadedFiles;
            this.fileName = uploadedFiles[0].name;
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
        this.recordStatus = undefined;
        console.log('this.parsedData '+this.parsedData);
        updateOpportunityRecords({ oppData: this.parsedData?.replaceAll('\\', '') })
            .then(result => {
                this.filesUploaded = '';
                this.fileName = '';
                if (result) {
                    let hasAtleastOneError = false;
                    let recordStatus = JSON.parse(result);
                    for (let each in recordStatus) {
                        if (recordStatus[each] != 'Success!') {
                            hasAtleastOneError = true;
                        }
                    }
                    if (hasAtleastOneError) {
                        this.recordStatus = recordStatus;
                        this.showMessage(this.recordStatus, 'warning');
                    } else {
                        this.recordStatus = recordStatus;
                        this.showMessage('All Opportunity rows were updated successfully!!','success');
                    }
                }
                this.isLoading = false;
            })
            .catch(error => {
                console.log(error);
                this.showMessage(error, 'error');
                this.isLoading = false;
            });
    }

    showMessage(message, variant) {
        const event = new ShowToastEvent({
            title: '',
            variant: variant,
            mode: 'dismissable',
            message: message
        });
        this.dispatchEvent(event);
    }

}