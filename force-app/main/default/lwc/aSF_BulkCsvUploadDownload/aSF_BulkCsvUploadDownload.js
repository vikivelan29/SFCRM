import { LightningElement, api, track, wire } from 'lwc';
import getMetadataDetails from '@salesforce/apex/ASF_BulkCsvController.getMetadataDetails';
import generateCSVFile from '@salesforce/apex/ASF_BulkCsvController.generateCSVFileWithData';
import generateCtstFile from '@salesforce/apex/ASF_BulkCsvController.generateCSVFileWithCtst';
import getCSVTemplate from '@salesforce/apex/ASF_BulkCsvController.getCSVTemplate';
import insertHeaderRowWithLineItems from '@salesforce/apex/ASF_BulkUploadUtilityController.insertHeaderRowWithLineItems';
import insertLineItemsChunk from '@salesforce/apex/ASF_BulkUploadUtilityController.insertLineItemsChunk';
import startProcessingChunks from '@salesforce/apex/ASF_BulkUploadUtilityController.startProcessingChunks';

import { loadScript } from 'lightning/platformResourceLoader';
import PapaParser from '@salesforce/resourceUrl/PapaParser';
import ASF_BulkUploadBUValidation from '@salesforce/resourceUrl/ASF_BulkUploadBUValidation';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { reduceErrors } from 'c/asf_ldsUtils';
import CHUNK_SIZE from '@salesforce/label/c.ASF_Bulk_Chunk_Size';
import DOWNLOAD_LIMIT_MESSAGE from '@salesforce/label/c.ASF_BulkDownloadLimit_Msg';

export default class ASF_BulkCsvUploadDownload extends LightningElement {
    @api strURL = '';
    @api strButtonName = '';
    @api selectedCases= '';
    cmpTitle = 'Welcome to the Bulk Data Uploader';
    @track UploadFile = 'Upload CSV';
    @track strDownloadTemplate = 'Download Template';
    strActionLabel = 'Please choose the action you wish to perform on the CSV.';
    strSelectionPlaceholder = '--Please choose an Operation--';
    strAdminError = 'An unexpected error occured please connect with the system admininistrator.';
    strConfigError = 'Error -: There is an error in the Custom Metadata Configuration. Please connect with the System Administrator.';
    strCSVGeneration = 'Please wait. The CSV generation is in progress...';
    listViewId = 'Recent';
    strNoAccessError = 'You do not have access to perform Bulk Operation';
    strDownloadCtst = 'Download CTST';
    MAX_CHUNK_SIZE = CHUNK_SIZE;
    downloadLimitMsg = DOWNLOAD_LIMIT_MESSAGE;

    helpMessage = false;
    @track showLoadingSpinner = true;
    boolShowDownloadButton = false;
    boolShowUploadButton = false;
    boolDisplayLoadingText = false;
    foundFileWithNotAllowedExtn = false;
    boolShowFileUploadButton = false;
    boolDisableDownload = false;
    boolShowUploadProgress = false;
    uploadValidationSuccess = true;
    boolCSVCheck = false;
    boolDisplayProgressbar = false;
    boolDisableUploadButton = true;
    parserInitialized = false;
    showDownloadResult = false;
    isTrue = true;
    hasPermission = false;
    hasLoaded = false;
    disableUploadBtn = true;

    @track uploadId;
    @track fileName = '';
    operationRecordTypeValue = '';
    strErrorMessage = '';
    strSuccessMessage = '';
    strCSVFileError = '';
    businessUnitValue = '';
    filesUploaded = [];
    file;
    fileContents;
    fileReader;
    optionActions= [];
    dataCSV;
    strBackURL;
    allConfigMetaList;
    selectedConfigRec;
    processedCsvData;
    rowCount = 0;
    chunkedLineItems;
    allLineItems;
    currentChunkIndex = 0;
    boolShowCTST = false;
   
    //Disable Upload Button
    get noOperationTypeValue(){
        if(!this.operationRecordTypeValue ){
            return true;
        }
        return false;
    }

    //Fetches the access and operation details based on the logged In user's business Unit
    @wire(getMetadataDetails)
    wiredMetaResult({ error, data }) {
        if (data) {
            let objErrorPicklist = {'label':'No Relevant Values Found', 'value':'No Relevant Values Found'};
            if(data && data != null){
                let allMetadata = data;
                allMetadata.map(item => {
                    const option = {
                        label: item.Display_Label__c,
                        value: item.Template_Name__c
                    };
                    this.optionActions = [ ...this.optionActions, option ];
                    if(!this.operationRecordTypeValue){
                        this.operationRecordTypeValue = item.Template_Name__c;
                    }
                    if(!this.hasPermission){
                        this.hasPermission = true;
                    }
                });
                this.allConfigMetaList = allMetadata;
                if(this.hasPermission){
                    this.findAndSetSelectedConfig();
                }
                this.hasLoaded = true;
            }

            else{
                this.optionActions = [ ...this.optionActions, objErrorPicklist ];
            }

        } else if (error) {
            console.log('error'+JSON.stringify(error));
            this.displayErrorMessage(error, '');
        }
    }

    /*Loads the BU specific validation file from Static Resource and show/hide the components based on
    current user request */
    connectedCallback(){

        if(this.strButtonName== 'DownloadCSVButton'){
            this.boolShowDownloadButton = true;
        }
        if(this.strButtonName== 'UploadCSVButton'){
            this.boolShowUploadButton = true;
            this.boolShowFileUploadButton = true;
        }
        this.listViewId = this.strURL.split('filterName%3D')[1].split('&')[0];
        this.loadValidationFile();
        this.showLoadingSpinner = false;
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

    //Initializes the BU Specific validation from Static Resource
    async loadValidationFile() {
        await loadScript(this, ASF_BulkUploadBUValidation)
        .then(() => {
        })
        .catch(error => {
            this.displayErrorMessage(error, '');
        });
    }

    //This method executes when user selects an operation to perform
    onChangeOperationRecordTypeChange(event){
        this.operationRecordTypeValue = event.target.value;
        this.findAndSetSelectedConfig();
    }
    findAndSetSelectedConfig(){
        this.allConfigMetaList.forEach((element) => {
            if(element.Template_Name__c == this.operationRecordTypeValue){
                this.selectedConfigRec = element;
                this.disableUploadBtn = false;
            }
        });
        this.boolShowCTST = this.selectedConfigRec.CTST_Query_Fields__c != undefined && this.selectedConfigRec.CTST_Query_Fields__c != null? true : false;
    }
    //Method to Download CTST CSV records
    downloadCtst(){
        this.boolDisplayLoadingText = true;
        this.strErrorMessage = '';

        generateCtstFile({strConfigName: this.selectedConfigRec.DeveloperName})
        .then(result => {
            this.boolDisplayLoadingText = false;
                this.dataCSV = result;
                this.showLoadingSpinner = true;
                if(Array.isArray(this.dataCSV)){
                    this.downloadCSVFile('CTST Data');
                    }
                else {
                    this.showLoadingSpinner = false;
                    this.getCSVClick(result,'CTST Data');
                }
        })
        .catch(error => { 
            this.boolDisplayLoadingText = false;
            this.displayErrorMessage(error, '');
        });
    }

    //Method to Download CSV template along with records
    downloadTemplate() {
        this.boolDisplayLoadingText = true;
        this.strErrorMessage = '';

        generateCSVFile({ strConfigName: this.selectedConfigRec.DeveloperName, 
                            strURL:this.strURL,
                            strSelectedRecords : this.selectedCases,
                            listViewId : this.listViewId })
            .then(result => {
                this.boolDisplayLoadingText = false;
                this.dataCSV = result;
                this.showLoadingSpinner = true;
                if(Array.isArray(this.dataCSV )){
                    this.downloadCSVFile('');
                    }
                else {
                    this.showLoadingSpinner = false;
                    this.getCSVClick(result,this.operationRecordTypeValue +'-' + Date.now() );
                }
            })
            .catch(error => {
                this.boolDisplayLoadingText = false;
                this.displayErrorMessage(error, '');
        });
    }
    //This method validates the dataCSV and creates the csv file to download
    async downloadCSVFile(fileName) {   
        let csvString = '';

        this.dataCSV = this.dataCSV.map(obj => {
            if (obj.hasOwnProperty('Id')) {
                delete obj['Id'];
            }
            return obj;
        });
        csvString = await Papa.unparse(this.dataCSV, {
            header: true,
            quotes: true,
            escapeChar: '"'
        });
        /*Hack - to display leading 0s of case number in the CSV file. TODO: Think of something better, for better sleep! 
        quotes: true,*/
        // if(this.operationRecordTypeValue.includes('Close')){
        //     csvString = csvString.replaceAll('\n', '\n=');
        // } 
        this.showLoadingSpinner = false;
        let csvName = fileName != '' ? fileName : this.operationRecordTypeValue +'-' + Date.now();
        this.getCSVClick(csvString, csvName);
    }

    //This method downloads CSV
    getCSVClick(objData,strCSVFileName){
        let downloadElement = document.createElement('a');
        downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURIComponent(objData);
        downloadElement.target = '_blank';//'_self';
        downloadElement.download = strCSVFileName + '.csv';
        downloadElement.click(); 

    }
    //This method parses the CSV to Object using papa parser
    parseCsv(file){
        return new Promise((resolve, reject) => {
            Papa.parse(file, {
                header: true,
                complete: (result) => {
                    if (result && result.data) {
                        resolve(result.data);
                    } 
                },
                error: (error) => {
                    this.displayErrorMessage(error, '');
                    reject(error);
                }
            });
        });
    }
    //Method that executes on Upload of CSV and parses the CSV to object
    async handleFilesChange(event) {
        this.foundFileWithNotAllowedExtn = false;
        if(event.target.files.length > 0) {
            this.filesUploaded = event.target.files[0];
            this.fileName = event.target.files[0].name; 
            let strFileExt = this.fileName.substring(this.fileName.lastIndexOf('.')+1, this.fileName.length) || this.fileName;
            let arrFileExtn = this.fileName.slice(-4);
            if(arrFileExtn.toLowerCase() != '.csv'){
                this.boolCSVCheck = false;
                this.foundFileWithNotAllowedExtn = true;
                this.strCSVFileError = 'Invalid file extension or file format.';
            }

            if(!this.foundFileWithNotAllowedExtn){
                if(strFileExt!= null && strFileExt.toLowerCase()=='csv'){
                    this.boolCSVCheck = true;
                    this.strCSVFileError = '';
                    let parsedData = await this.parseCsv(event.target.files[0]);
                    console.log('parsedData', JSON.stringify(parsedData));
                    this.processedCsvData = parsedData.filter(obj => {
                        const hasNonBlankValue = Object.values(obj).some(value => value.trim() !== '');
                        return hasNonBlankValue && Object.keys(obj)[0] !== '' && Object.keys(obj).length > 0;
                    });
                    console.log('parsed data--'+this.processedCsvData.length +'--'+JSON.stringify(this.processedCsvData));
                    this.rowCount = this.processedCsvData.length;
                }
                else{
                    this.boolCSVCheck = false;
                    this.strCSVFileError = 'This is not a valid CSV File. Please upload a file with valid .csv extension.';
                }
            }
        }
    }

    //this method fetches the Template header without data
    getTemplateData(){
        this.strErrorMessage = '';
        getCSVTemplate({strConfigName: this.selectedConfigRec.DeveloperName})
        .then(result => {
            this.getCSVClick(result, this.operationRecordTypeValue +'- Template');
        })
        .catch(error => { });
    }

     //This method handles logic of 'Go Back' Button
     handleListViewNavigation() {
        const baseURL = window.location.origin;
        const listViewUrl = `${baseURL}/lightning/o/Case/list?filterName=${this.listViewId}`;
        window.open(listViewUrl,"_self");
    }

    //This method Opens Help Modal
    openHelp(){
        this.helpMessage = true;
    }
    
    //This method Closes Help Modal
    closeHelp(){
        this.helpMessage = false;
    }

    //This method validates the uploaded CSV on click of upload button
    validateUploadFile(){
        if(this.filesUploaded.length <= 0){
            this.strErrorMessage = 'Please select a valid .CSV file to upload';
            this.uploadValidationSuccess = false;
            return;
        }
        if(this.operationRecordTypeValue == ''){
            this.strErrorMessage = 'Please select the operation type';
            this.uploadValidationSuccess = false;
            return;
        }
        if(this.rowCount > 50000){
            this.strErrorMessage = 'Max record limit exceeded. Max record limit is 50000';
            this.uploadValidationSuccess = false;
            return;
        }
        this.file = this.filesUploaded;
        if (this.file.size > this.selectedConfigRec.Max_File_Size__c) {
            this.strErrorMessage = 'Max file size exceeded. Max file size is 20.0 MB';
            this.uploadValidationSuccess = false;
            return;
        } 
        if (!this.processedCsvData || this.processedCsvData.length === 0){
            this.strErrorMessage = 'The selected file is Empty';
            this.uploadValidationSuccess = false;
            return;
        }
        const inputData = {
            csvData: this.processedCsvData,
            processName: this.operationRecordTypeValue,
            configData: this.selectedConfigRec
        };
        let buValResult = window.validateFile(inputData);
        if(buValResult != 'Success'){
            this.strErrorMessage = buValResult;
            this.uploadValidationSuccess = false;
            return;
        }
    }
    /*This method performs CSV upload operation. When the data is more than the MAX CHUNK size (e.g., 1000),
     The records are chunked as per MAX CHUNK size and then sent to the apex class for further processing 
    */
    handleSave() {
        this.showLoadingSpinner = true;
        this.disableUploadBtn = true;
        this.boolShowFileUploadButton = false;
        this.boolCSVCheck= false;
        this.boolShowUploadButton = false;
        this.uploadValidationSuccess = true;
        this.validateUploadFile();
        this.showLoadingSpinner = false;
        
        if(this.uploadValidationSuccess){
            this.strErrorMessage = '';
            this.boolShowUploadProgress = true;
            this.disableUploadBtn = false;
            this.allLineItems = this.processedCsvData.map(item => {
                return {
                    JSON_Data__c: JSON.stringify(item)
                };
            });
            if(this.rowCount <= this.MAX_CHUNK_SIZE){
                this.insertFirstChunk(this.allLineItems);
            }
            else if(this.rowCount > this.MAX_CHUNK_SIZE){
                this.chunkedLineItems = this.chunkArray(this.allLineItems, parseInt(this.MAX_CHUNK_SIZE));
                //First Chunk
                if (this.currentChunkIndex === 0) {
                    this.insertFirstChunk(this.chunkedLineItems[0]);
                }
            }
        }else{
            this.showToastMessage('Error!', this.strErrorMessage, 'error');
            this.boolShowFileUploadButton = true;
            this.disableUploadBtn = false;
            this.boolCSVCheck= true;
            this.boolShowUploadButton = true;
        }
    }
    
    //Insert middle chunks to database
    async insertMiddleChunk(lineItems){
        await insertLineItemsChunk({lineItems: lineItems})
        .then(result => {
          console.log('middle chunk success');
        })
        .catch(error => {
            this.displayErrorMessage(error, 'InsertChunk');
        });
    }

    //Starts the processing of upload once all the records are inserted to the database.
    startProcessingChunks(){
        console.log('start process');
        startProcessingChunks({headRowId: this.uploadId, totalRowCount: this.rowCount, templateName: this.operationRecordTypeValue})
        .then(result => {
            this.showLoadingSpinner = false;
            this.boolShowUploadProgress = false;
            if(result.isSuccess){
                this.boolDisplayProgressbar = true;
                if(result.successMessageIfAny && result.successMessageIfAny != ''){
                    this.strSuccessMessage = result.successMessageIfAny;
                }
            }else{
                this.strErrorMessage = result.errorMessage;
            }   
        })
        .catch(error => {
            this.displayErrorMessage(error, 'InsertChunk');
        });
    }

    //Inserts the first chunk. This method is also used when the total uploaded records are less than MAC CHUNK size.
    insertFirstChunk(lineItems) {
        insertHeaderRowWithLineItems({ lineItems: lineItems, totalRowCount: this.rowCount, templateName: this.operationRecordTypeValue})
        .then(async result => {

            if(result && result.isSuccess){
                console.log('first chunk successs');
                this.uploadId = result.headRowId;
                this.fileName = this.fileName + ' - Uploaded Successfully';

                if(this.chunkedLineItems && this.chunkedLineItems.length >0){
                    for (let i = 1; i < this.chunkedLineItems.length; i++) {
                        this.currentChunkIndex = i;
                        //Middle Chunk
                        if(this.uploadId){
                            this.chunkedLineItems[i].forEach(obj => {
                                obj.Bulk_Upload_Header__c = this.uploadId;
                            });
                            await this.insertMiddleChunk(this.chunkedLineItems[i]);
                        }
                    }
                }
                if(this.strErrorMessage === ''){
                    this.startProcessingChunks();
                }
            }
            else if(!result.isSuccess){
                this.strErrorMessage = result.errorMessage;
                this.boolShowFileUploadButton = true;
                this.boolCSVCheck= true;
                this.boolShowUploadButton = true;
                this.boolShowUploadProgress = false;
                this.showLoadingSpinner = false;
            }
        })
        .catch(error => {
            this.boolShowFileUploadButton = true;
            this.boolCSVCheck= true;
            this.boolShowUploadButton = true;
            this.strErrorMessage = this.strAdminError;
            this.displayErrorMessage(error, 'InsertChunk');

        }); 
    }

    //utility method to show a readable exception message
    displayErrorMessage(error, reqFrom){
        let errMsg = reduceErrors(error);
        this.strErrorMessage = Array.isArray(errMsg) ? errMsg[0] : errMsg;
        if(reqFrom == 'InsertChunk'){
            this.showLoadingSpinner = false;
            this.boolShowUploadProgress = false;
        }
    }
    //Shows the Downlaod Result Button once the Upload is complete
    handleUploadComplete(event){
        if(event.detail.value === 100){
            this.strSuccessMessage = '';
            this.showDownloadResult = true;
        }
    }

    //Chunks the uploaded csv data if the count is more than MAX CHUNK size
    chunkArray(array, size) {
        // Function to split an array into chunks of the given size
        const chunkedArray = [];
        for (let i = 0; i < array.length; i += size) {
            chunkedArray.push(array.slice(i, i + size));
        }
        return chunkedArray;
    }

    //Utility method to Display Toast Message
    showToastMessage(title, message, variant){
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}