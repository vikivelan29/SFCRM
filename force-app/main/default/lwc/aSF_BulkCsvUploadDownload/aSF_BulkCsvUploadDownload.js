import { LightningElement, api, track, wire } from 'lwc';
import getMetadataDetails from '@salesforce/apex/ASF_BulkCsvController.getMetadataDetails';
import generateCSVFile from '@salesforce/apex/ASF_BulkCsvController.generateCSVFileWithData';
import getCSVTemplate from '@salesforce/apex/ASF_BulkCsvController.getCSVTemplate';
import insertHeaderRowWithLineItems from '@salesforce/apex/ASF_BulkUploadUtilityController.insertHeaderRowWithLineItems';
import insertLineItemsChunk from '@salesforce/apex/ASF_BulkUploadUtilityController.insertLineItemsChunk';
import insertLastLineItemsChunk from '@salesforce/apex/ASF_BulkUploadUtilityController.insertLastLineItemsChunk';
import startProcessingChunks from '@salesforce/apex/ASF_BulkUploadUtilityController.startProcessingChunks';

import { loadScript } from 'lightning/platformResourceLoader';
import PapaParser from '@salesforce/resourceUrl/PapaParser';
import ASF_BulkUploadBUValidation from '@salesforce/resourceUrl/ASF_BulkUploadBUValidation';
import { validateFile } from "./bulkUploadBUValidationUtil";

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

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
    MAX_CHUNK_SIZE = 9000;

    helpMessage = false;
    @track showLoadingSpinner = false;
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

    @track uploadId;
    @track fileName = '';
    operationRecordTypeValue = '';
    strErrorMessage = '';
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

   
    /**Description - Disable Upload Button*/
    get noOperationTypeValue(){
        if(!this.operationRecordTypeValue ){
            return true;
        }
        return false;
    }

    @wire(getMetadataDetails)
    wiredMetaResult({ error, data }) {
        if (data) {
            console.log('inside on load meta method--'+JSON.stringify(data));

            let objErrorPicklist = {'label':'No Relevant Values Found', 'value':'No Relevant Values Found'};
            if(data && data != null){
                data.allMetadata.map(item => {
                    const option = {
                        label: item.Display_Label__c,
                        value: item.Template_Name__c
                    };
                    this.optionActions = [ ...this.optionActions, option ];
                });
                this.allConfigMetaList = data.allMetadata;
                this.hasPermission = data.hasCustomPermission;
                this.hasLoaded = true;
            }

            else{
                this.optionActions = [ ...this.optionActions, objErrorPicklist ];
            }

        } else if (error) {
            console.error('Error retrieving metadata:', error);
        }
    }

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

    async loadValidationFile() {
        try {
            await loadScript(this, ASF_BulkUploadBUValidation);
        } catch (error) {
            console.error('Error loading Validation file:', error);
        }
    }

    onChangeOperationRecordTypeChange(event){
        this.operationRecordTypeValue = event.target.value;
        this.allConfigMetaList.forEach((element) => {
            if(element.Template_Name__c == this.operationRecordTypeValue){
                this.selectedConfigRec = element;
            }
        });
        console.log('selected config--'+JSON.stringify(this.selectedConfigRec));
    }

    /**Description - Method to Download Record CSV*/
    downloadTemplate() {
        this.boolDisplayLoadingText = true;
        generateCSVFile({ strConfigName: this.selectedConfigRec.DeveloperName, 
                            strURL:this.strURL,
                            strSelectedRecords : this.selectedCases,
                            listViewId : this.listViewId })
            .then(result => {
                this.boolDisplayLoadingText = false;
                this.dataCSV = result;
                this.showLoadingSpinner = true;
                if(Array.isArray(this.dataCSV )){
                    this.downloadCSVFile();
                    }
                else {
                    this.showLoadingSpinner = false;
                    this.getCSVClick(result,this.operationRecordTypeValue +'-' + Date.now() );
                }
            })
            .catch(error => {
                this.boolDisplayLoadingText = false;
                console.log('error--'+JSON.stringify(error));
                this.strErrorMessage = this.strAdminError + ' Following technical Error occured.  ' ;
        });
    }
    /**Description - this method validates the dataCSV and creates the csv file to download**/
    async downloadCSVFile() {   
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
        //Hack - to display leading 0s of case number in the CSV file. TODO: Think of something better, for better sleep!
        if(this.operationRecordTypeValue.includes('Close')){
            csvString = csvString.replaceAll('\n', '\n=');
        }
        this.showLoadingSpinner = false;
        this.getCSVClick(csvString,this.operationRecordTypeValue +'-' + Date.now() );
    }

    /**Description - this method downloads CSV**/
    getCSVClick(objData,strCSVFileName){
        let downloadElement = document.createElement('a');
        downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(objData);
        downloadElement.target = '_blank';//'_self';
        downloadElement.download = strCSVFileName + '.csv';
        downloadElement.click(); 

    }
    /*handleDownloadresult(event){
        const csvString = event.detail.value;
        console.log('csv--'+csvString);
        const fileName = 'BulkUploadResult' +'-' + Date.now();
        this.getCSVClick(csvString, fileName);
    } */
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
                    console.error(error);
                    reject(error);
                }
            });
        });
    }
    /**Description - Method that works on Upload of CSV*/
    async handleFilesChange(event) {
        this.foundFileWithNotAllowedExtn = false;
        if(event.target.files.length > 0) {
            this.filesUploaded = event.target.files[0];
            this.fileName = event.target.files[0].name; 
            let strFileExt = this.fileName.substring(this.fileName.lastIndexOf('.')+1, this.fileName.length) || this.fileName;

            let arrFileExtn = this.fileName.split('.');
            for(var i=0;i<arrFileExtn.length;i++){
                let tempExtn = arrFileExtn[i];
                if(tempExtn != null && tempExtn != undefined){
                    tempExtn = tempExtn.toUpperCase();
                    if(tempExtn!='CSV' && i != 0){
                        this.boolCSVCheck = false;
                        this.foundFileWithNotAllowedExtn = true;
                        this.strCSVFileError = 'You are trying to upload file with multiple extension. Please select file with only one and .csv extension.';
                        break;
                    }
                }     
            }

            if(!this.foundFileWithNotAllowedExtn){
                if(strFileExt!= null && strFileExt.toLowerCase()=='csv'){
                    this.boolCSVCheck = true;
                    this.strCSVFileError = '';
                    let parsedData = await this.parseCsv(event.target.files[0]);
                    //this.processedCsvData = parsedData;
                    this.processedCsvData = parsedData.filter(obj => {
                        return Object.keys(obj)[0] !== '' && Object.keys(obj).length > 1;
                    });
                    console.log('parsed data--'+JSON.stringify(this.processedCsvData))
                    this.rowCount = this.processedCsvData.length;
                }
                else{
                    this.boolCSVCheck = false;
                    this.strCSVFileError = 'This is not a valid CSV File. Please upload a file with valid .csv extension.';
                }
            }
        }
    }

    /**Description - this method fetchs Tempplate**/
    getTemplateData(){
        getCSVTemplate({strConfigName: this.selectedConfigRec.DeveloperName})
        .then(result => {
            this.getCSVClick(result, this.operationRecordTypeValue +'- Template');
        })
        .catch(error => { });
    }

     /**Description - this method handles logic of 'Go Back' Button**/
     handleListViewNavigation() {
        const baseURL = window.location.origin;
        const listViewUrl = `${baseURL}/lightning/o/Case/list?filterName=${this.listViewId}`;
        //window.location.assign(listViewUrl,"_self");
        window.open(listViewUrl,"_self");
        //history.back();
    }

    /**Description - this method Opens Help Modal**/
    openHelp(){
        this.helpMessage = true;
    }
    
    /**Description - this method Closes Help Modal**/

    closeHelp(){
        this.helpMessage = false;
    }

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
        let buValResult = validateFile(inputData);
        console.log('val result--'+buValResult);
        if(buValResult != 'Success'){
            this.strErrorMessage = buValResult;
            this.uploadValidationSuccess = false;
            return;
        }
    }
     /**Description - this method uploads the CSV **/
    handleSave() {
        this.showLoadingSpinner = true;
        this.boolShowFileUploadButton = false;
        this.boolCSVCheck= false;
        this.boolShowUploadButton = false;
        this.uploadValidationSuccess = true;
        this.validateUploadFile();
        this.showLoadingSpinner = false;
        
        if(this.uploadValidationSuccess){
            this.strErrorMessage = '';
            this.boolShowUploadProgress = true;
            this.allLineItems = this.processedCsvData.map(item => {
                return {
                    JSON_Data__c: JSON.stringify(item)
                };
            });
            if(this.rowCount <= this.MAX_CHUNK_SIZE){
                this.insertFirstChunk(this.allLineItems);
            }
            else if(this.rowCount > this.MAX_CHUNK_SIZE){
                this.chunkedLineItems = this.chunkArray(this.allLineItems, this.MAX_CHUNK_SIZE);
                
                //First Chunk
                if (this.currentChunkIndex === 0) {
                    this.insertFirstChunk(this.chunkedLineItems[0]);
                }
            }
        }else{
            this.showToastMessage('Error!', this.strErrorMessage, 'error');
            this.boolShowFileUploadButton = true;
            this.boolCSVCheck= true;
            this.boolShowUploadButton = true;
        }
    }
    
    async insertMiddleChunk(lineItems){
        await insertLineItemsChunk({lineItems: lineItems})
        .then(result => {
            console.log('middle chunk result');
        })
        .catch(error => {
            console.error(error);
        });
    }

    async insertLastChunk(lineItems){
        await insertLastLineItemsChunk({lineItems: lineItems, headRowId: this.uploadId})
        .then(result => {
            console.log('last chunk result');
            this.startProcessingChunks();
            this.boolShowUploadProgress = false;
            this.showLoadingSpinner = false;
            this.boolDisplayProgressbar = true;
        })
        .catch(error => {
            console.error(error);
        });
    }

    startProcessingChunks(){
        startProcessingChunks({headRowId: this.uploadId, totalRowCount: this.rowCount, templateName: this.operationRecordTypeValue})
        .then(result => {
            console.log('processing chunk result--'+JSON.stringify(result));
            this.boolShowUploadProgress = false;
            this.showLoadingSpinner = false;
            this.boolDisplayProgressbar = true;
        })
        .catch(error => {
            console.error(error);
        });
    }

    /**Description - this method Process the CSV Uploaded**/
    insertFirstChunk(lineItems) {
        insertHeaderRowWithLineItems({ lineItems: lineItems, totalRowCount: this.rowCount, templateName: this.operationRecordTypeValue})
        .then(result => {

            if(result && result.isSuccess){
                this.uploadId = result.headRowId;
                this.fileName = this.fileName + ' - Uploaded Successfully';

                if(this.chunkedLineItems && this.chunkedLineItems.length >0){
                    for (let i = 1; i < this.chunkedLineItems.length; i++) {
                        this.currentChunkIndex = i;
                        // Last Chunk
                        if(this.currentChunkIndex === this.chunkedLineItems.length - 1){
                            if(this.uploadId){
                                this.chunkedLineItems[i].forEach(obj => {
                                    obj.Bulk_Upload_Header__c = this.uploadId;
                                });
                                this.insertLastChunk(this.chunkedLineItems[i]);
                            }
                        }
                        //Middle Chunk
                        else {
                            if(this.uploadId){
                                this.chunkedLineItems[i].forEach(obj => {
                                    obj.Bulk_Upload_Header__c = this.uploadId;
                                });
                                this.insertMiddleChunk(this.chunkedLineItems[i]);
                            }
                        }
                    }
                } else{
                    this.startProcessingChunks();
                }
            }
            else if(!result.isSuccess){
                this.strErrorMessage = result.errorMessage;
                this.showToastMessage('Error!', result.errorMessage, 'error');
                this.boolShowFileUploadButton = true;
                this.boolCSVCheck= true;
                this.boolShowUploadButton = true;
                this.boolShowUploadProgress = false;
                this.showLoadingSpinner = false;
            }
        })
        .catch(error => {
            this.showLoadingSpinner = false;
            this.boolShowUploadProgress =false;
            this.boolShowFileUploadButton = true;
            this.boolCSVCheck= true;
            this.boolShowUploadButton = true;
            this.strErrorMessage = this.strAdminError;
            this.showToastMessage('Error while uploading File', error.body.message, 'error');
            console.log(error.body);
        }); 
    }

    handleUploadComplete(event){
        if(event.detail.value === 100){
            this.showDownloadResult = true;
        }
    }

    chunkArray(array, size) {
        // Function to split an array into chunks of the given size
        const chunkedArray = [];
        for (let i = 0; i < array.length; i += size) {
            chunkedArray.push(array.slice(i, i + size));
        }
        return chunkedArray;
    }

    showToastMessage(title, message, variant){
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}