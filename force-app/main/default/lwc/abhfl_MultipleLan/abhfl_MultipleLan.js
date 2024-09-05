import { LightningElement,wire,api } from 'lwc';
import getAssetRecordsandMetadata from '@salesforce/apex/ABHFL_MultipleLANController.getLanDataAndMetadata';
import fetchAssetDetailsExt from '@salesforce/apex/ABHFL_MultipleLANController.fetchAssetDetailsExt';
import upsertRecords from '@salesforce/apex/ABHFL_MultipleLANController.upsertRecords';
import fetchAll from '@salesforce/apexContinuation/ABHFL_MultipleLANController.fetchAllLANDetails';
import deleteRecordOwnerChange from '@salesforce/apex/ABHFL_MultipleLANController.deleteRecordOwnerChange';
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import Id from "@salesforce/user/Id";
import { getRecord } from "lightning/uiRecordApi";

const CASEFIELDS = ["Case.Stage__c", "Case.OwnerId"];
export default class Abhfl_MultipleLan extends LightningElement {
    @api recordId;
    searchResult; 
    totalNoOfRecordsInDatatable;
    pageSize = 5; //No.of records to be displayed per page
    totalPages; //Total no.of pages
    pageNumber = 1; //Page number    
    recordsToDisplay = []; //Records to be displayed on the page
    childColumns;
    childTableRecords = [];
    selectedRows = [];
    displayChildTable;
    disableAdd = true;
    displayMultipleLan;
    disableSave = true;
    displaySpinner = true;
    enableRowSelection = true;
    enableFetchAll = true;
    enableUpload = true;
    enableDelete = true;
    disableEditField = false;
    userId = Id;
    enableSave = true;
    stagesAllowingFieldEdit;
    stagesAllowingAddRows;
    stagesAllowingDeleteRows;
    stagesAllowingFetchAll;
    stagesAllowingFileUpload;
    amIOwner;
    sizeClass = 'multiColumnTable';
    impctLogic;

    @wire(getRecord, { recordId: "$recordId", fields: CASEFIELDS })
    case;

    connectedCallback(){
        if(this.recordId){
            getAssetRecordsandMetadata({recId : this.recordId,loggedInUserId : this.userId}).then((result) => {
                console.log(result);
                if(result && result.columnData){
                    this.impctLogic = result.impactLogic;
                    this.columns = result.columnData;
                    this.additionalcolumns=result.additionalColumnData;
                    this.childColumns = result.childColumnData;
                    this.searchResult = result.assetDetailRecords;
                    this.totalNoOfRecordsInDatatable = result.assetDetailRecords.length;
                    this.paginationHelper(); // call helper menthod to update pagination logic
                    this.displayMultipleLan = true;
                    this.childTableDisplay();
                    this.enableRowSelection = result.displayAddRows;
                    this.enableFetchAll = result.displayFetchAll;
                    this.enableDelete = result.displayDeleteRows;
                    this.enableUpload = result.displayFileUpload;
                    this.disableEditField = result.disableFieldEdit;
                    this.enableSave = !result.disableFieldEdit;
                    this.amIOwner = this.case.data.fields.OwnerId.value == this.userId ? true : false;
                    if(this.amIOwner && this.case.data.fields.Stage__c.value == 'CPU PP'){
                        this.enableSave = true;
                    }
                    this.stagesAllowingFieldEdit = result.stagesAllowingFieldEdit;
                    this.stagesAllowingAddRows = result.stagesAllowingAddRows;
                    this.stagesAllowingDeleteRows = result.stagesAllowingDeleteRows;
                    this.stagesAllowingFetchAll = result.stagesAllowingFetchAll;
                    this.stagesAllowingFileUpload = result.stagesAllowingFileUpload;
                } 
                this.displaySpinner = false;
            }).catch((error) => {
                console.log(error);
                this.displaySpinner = false;
                this.showToast({
                    title: "Error",
                    message: "Something went wrong. Please try again later.",
                    variant: "error",
                });
            })
        }
    }

    childTableDisplay(){
        for (let record in this.searchResult) {
            if(this.searchResult[record].detail.Id){
                this.childTableRecords.push(this.searchResult[record]);
            } 
        }
        if(this.childTableRecords.length > 0){
            this.displayChildTable = true;
            this.disableSave = false;
        }  
    }

    fetchAssetDetails(e){
        this.checkAccessbilityforCurrentStage();
        if(this.enableFetchAll){
            let asset;
            let detail;
            this.displaySpinner = true;
            for(let i=0; i < this.recordsToDisplay.length;i++){
                if(e.currentTarget.dataset.id == this.recordsToDisplay[i].asset.Id){
                    asset = this.recordsToDisplay[i].asset;
                    detail = this.recordsToDisplay[i].detail;
                    break;
                }
            }
            fetchAssetDetailsExt({assetRecord : asset, caseRecId : this.recordId}).then((result) => {
                console.log(result);
                this.updateSearchResult(result);
                this.displaySpinner = false;
            }).catch((error) => {
                console.log(error);
                this.displaySpinner = false;
                this.showToast({
                    title: "Error",
                    message: "We could not fetch the LAN Details. Please try again later.",
                    variant: "error",
                });
            })
        } else {
            let errMsg;
            if(this.amIOwner){
                errMsg = "You are not allowed to fetch LAN Records in the " + this.case.data.fields.Stage__c.value + " stage.";
            }else {
                errMsg = "You are not allowed to fetch LAN Records for a Case not asssigned to you.";
            }
            this.showToast({
                title: "Info",
                message: errMsg,
                variant: "info",
            });         
        }
        
    }

    updateSearchResult(result){
        for (let record in this.recordsToDisplay) {
            if(this.recordsToDisplay[record].asset.LAN__c == result.LAN__c){
                this.recordsToDisplay[record].detail = result;
                this.template.querySelectorAll("c-abhfl_fielddisplay").forEach(result=>{result.setColValue();})
                break;
            }    
        }
    }

    get bDisableFirst() {
        return this.pageNumber == 1;
    }
    get bDisableLast() {
        return this.pageNumber == this.totalPages;
    }   

    previousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.paginationHelper();
    }

    nextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.paginationHelper();
    }

    firstPage() {
        this.pageNumber = 1;
        this.paginationHelper();
    }

    lastPage() {
        this.pageNumber = this.totalPages;
        this.paginationHelper();
    }

    // JS function to handel pagination logic 
    paginationHelper() {
        this.recordsToDisplay = [];
        // calculate total pages
        this.totalPages = Math.ceil(this.totalNoOfRecordsInDatatable / this.pageSize);
        // set page number 
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }
        // set records to display on current page 
        for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if (i === this.totalNoOfRecordsInDatatable) {
                break;
            }
            this.recordsToDisplay.push(this.searchResult[i]);
        }
    }

    addRecords(e){
        this.checkAccessbilityforCurrentStage();
        if(this.enableFetchAll){
            if(this.selectedRows){
                let retrieveRecords = [];
                for(let record in this.selectedRows){
                    if(!this.selectedRows[record].detail.Id){
                        retrieveRecords.push(this.selectedRows[record].detail);
                    }
                }
                if(retrieveRecords.length){
                    this.displayChildTable = false;
                    this.displaySpinner = true;
                    upsertRecords({assetDetails : JSON.stringify(retrieveRecords), recId : this.recordId}).then((result) => {
                        console.log(result);
                        for(let record in this.selectedRows){
                            if(!this.childTableRecords.includes(this.selectedRows[record])){
                                for(let rec in result){
                                    if(result[rec].Asset__c == this.selectedRows[record].detail.Asset__c){
                                        this.selectedRows[record].detail = result[rec];
                                        break;
                                    }
                                }
                                this.childTableRecords.push(this.selectedRows[record]);
                                this.disableSave = false;
                            }
                        }
                        this.displayChildTable = true;
                        this.displaySpinner = false;
                    }).catch((error) => {
                        console.log(error);
                        this.displaySpinner = false;
                        this.showToast({
                            title: "Error",
                            message: "We could add Records. Please try again later.",
                            variant: "error",
                        });
                    })
                } else if(this.selectedRows){
                    this.displayChildTable = false;
                    for(let record in this.selectedRows){
                        if(!this.childTableRecords.includes(this.selectedRows[record])){
                            //this.childTableRecords.push(this.selectedRows[record]);
                        }
                    }
                    this.displayChildTable = true;
                }
            }
        } else {
            let errMsg;
            if(this.amIOwner){
                errMsg = "You are not allowed to add LAN Records in the " + this.case.data.fields.Stage__c.value + " stage.";
            }else {
                errMsg = "You are not allowed to add LAN Records for a Case not asssigned to you.";
            }
            this.showToast({
                title: "Info",
                message: errMsg,
                variant: "info",
            });         
        }
    }

    handleSelection(e){
        this.checkAccessbilityforCurrentStage();
        if(this.enableRowSelection){
            console.log(e);
            let row;
            for(let i=0; i < this.recordsToDisplay.length;i++){
                if(e.target.name == this.recordsToDisplay[i].asset.Id){
                    row = this.recordsToDisplay[i];
                    break;
                }
            }
            if(e.target.checked){
                this.selectedRows.push(row);
            }else{
                let index = this.selectedRows.indexOf(row)
                this.selectedRows.splice(index,1);
            }
            
            if(this.selectedRows.length){
                this.disableAdd = false;
            } else {
                this.disableAdd = true;
            }
        } else {
            let errMsg;
            if(this.amIOwner){
                errMsg = "You are not allowed to select LAN Records in the " + this.case.data.fields.Stage__c.value + " stage.";
            }else {
                errMsg = "You are not allowed to select LAN Records for a Case not asssigned to you.";
            }
            this.showToast({
                title: "Info",
                message: errMsg,
                variant: "info",
            });         
        }


    }

    removeRecord(e){
        this.checkAccessbilityforCurrentStage();
        if(this.enableDelete){
            this.displaySpinner = true;
            let deleteIndex = e.currentTarget.name;
            let deleteId = this.childTableRecords[e.currentTarget.name].detail.Id;
            deleteRecordOwnerChange({assetDetailid : this.childTableRecords[e.currentTarget.name].detail.Id,userId :this.userId})
            .then(() => {
                this.displayChildTable = false;
                this.childTableRecords.splice(deleteIndex,1);
                this.displayChildTable = true;
                for(let rec in this.selectedRows){
                    if(this.selectedRows[rec].detail.Id == deleteId){
                        this.selectedRows[rec].detail.Id = null;
                        break;
                    }
                }
                if(!this.childTableRecords.length){
                    this.disableSave = true;
                } 
                this.showToast({
                    title: "Success",
                    message: "Record deleted",
                    variant: "success",
                });
                this.displaySpinner = false;
            })
            .catch((error) => {
                this.showToast({
                    title: "Error deleting record",
                    message: error.body.message,
                    variant: "error",
                });
                this.displaySpinner = false;
            });
        } else {
            let errMsg;
            if(this.amIOwner){
                errMsg = "You are not allowed to delete LAN Records in the " + this.case.data.fields.Stage__c.value + " stage.";
            }else {
                errMsg = "You are not allowed to delete LAN Records for a Case not asssigned to you.";
            }
            this.showToast({
                title: "Info",
                message: errMsg,
                variant: "info",
            });         
        }
 
    }

    saveRecords(e){
        this.checkAccessbilityforCurrentStage();
        if(this.enableSave){
            let validityCheck = true;
            this.template.querySelectorAll("c-abhfl_fielddisplay").forEach(result=>{
                let response = result.checkValidity();
                if(!response){
                    validityCheck = false;
                }
            });               
            console.log(e);
            if(validityCheck){
                let updateRecords = [];
                for(let record in this.childTableRecords){
                    updateRecords.push(this.childTableRecords[record].detail);
                }
                this.displaySpinner = true;
                if(updateRecords.length){
                    upsertRecords({assetDetails : JSON.stringify(updateRecords), recId : this.recordId}).then((result) => {
                        console.log(result);
                        this.displaySpinner = false;
                        this.showToast({
                            title: "Success",
                            message: "Records Updated",
                            variant: "success",
                        });
                    }).catch((error) => {
                        console.log(error);
                        this.showToast({
                            title: "Error Updating Records",
                            message: error.body.message,
                            variant: "error",
                        });
                    })
                }
            } else {
                this.showToast({
                    title: "Error",
                    message: "Please enter valid values",
                    variant: "error",
                });
            }
        } else {
            let errMsg;
            if(this.amIOwner){
                errMsg = "You are not allowed to save LAN Records in the " + this.case.data.fields.Stage__c.value + " stage.";
            }else {
                errMsg = "You are not allowed to save LAN Records for a Case not asssigned to you.";
            }
            this.showToast({
                title: "Info",
                message: errMsg,
                variant: "info",
            });         
        }

    }

    updateAssetDetail(e){
        this.childTableRecords = JSON.parse(JSON.stringify(this.childTableRecords));
        for(let record in this.childTableRecords){
            if(this.childTableRecords[record].asset.Id == e.detail.assetId){
                this.childTableRecords[record].detail[e.detail.fieldName] = e.detail.value;
                break;
            }
        }
    }

    fetchAllAsset(e){
        this.checkAccessbilityforCurrentStage();
        if(this.enableFetchAll){
            let assetRecords = [];
            this.displaySpinner = true;
            for(let record in this.recordsToDisplay){
                assetRecords.push(this.recordsToDisplay[record].asset);
            }
            fetchAll({assetList : assetRecords, caseRecId : this.recordId}).then((result) => {
                console.log(result);
                for (let record in this.recordsToDisplay) {
                    for(let rec in result){
                        if(this.recordsToDisplay[record].asset.LAN__c == result[rec].LAN__c){
                            this.recordsToDisplay[record].detail = result[rec];
                            break;
                        }    
                    }
                }
                this.template.querySelectorAll("c-abhfl_fielddisplay").forEach(result=>{result.setColValue();});
                this.displaySpinner = false;
            }).catch((error) => {
                console.log(error);
                this.displaySpinner = false;
                this.showToast({
                    title: "Error",
                    message: "We could not fetch the LAN Details. Please try again later.",
                    variant: "error",
                });
            })
        }  else {
            let errMsg;
            if(this.amIOwner){
                errMsg = "You are not allowed to Fetch LAN Records in the " + this.case.data.fields.Stage__c.value + " stage.";
            }else {
                errMsg = "You are not allowed to fetch LAN Records for a Case not asssigned to you.";
            }
            this.showToast({
                title: "Info",
                message: errMsg,
                variant: "info",
            });         
        }      
    }

    showToast(e){
        this.dispatchEvent(new ShowToastEvent(e));        
    }

    checkAccessbilityforCurrentStage(e){
        let currStage = this.case.data.fields.Stage__c.value;
        this.amIOwner = this.case.data.fields.OwnerId.value == this.userId ? true : false;
        if(this.stagesAllowingFieldEdit && this.stagesAllowingFieldEdit.length > 0){
            this.enableSave = this.amIOwner?this.stagesAllowingFieldEdit.includes(currStage)?true:false:false;
            this.disableEditField = this.amIOwner?this.stagesAllowingFieldEdit.includes(currStage)?false:true:true;
            if(this.amIOwner && this.case.data.fields.Stage__c.value == 'CPU PP'){
                this.enableSave = true;
            }
            this.template.querySelectorAll("c-abhfl_fielddisplay").forEach(result=>{result.refresh(this.disableEditField);});
        }
        if(this.stagesAllowingAddRows && this.stagesAllowingAddRows.length > 0){
            this.enableRowSelection = this.amIOwner?this.stagesAllowingAddRows.includes(currStage)?true:false:false;
        }
        if(this.stagesAllowingDeleteRows && this.stagesAllowingDeleteRows.length > 0){
            this.enableDelete = this.amIOwner?this.stagesAllowingDeleteRows.includes(currStage)?true:false:false;
        }
        if(this.stagesAllowingFetchAll && this.stagesAllowingFetchAll.length > 0){
            this.enableFetchAll = this.stagesAllowingFetchAll.includes(currStage)?true:false;
        }
        if(this.stagesAllowingFileUpload && this.stagesAllowingFileUpload.length > 0){
            this.enableUpload = this.amIOwner?this.stagesAllowingFileUpload.includes(currStage)?true:false:false;
        }
    }

    get currStage() {
        return this.case.data.fields.Stage__c.value;
    }

    get currOwner() {
        return this.case.data.fields.OwnerId.value;
    }

    checkFileUploadPermissions(e){
        this.checkAccessbilityforCurrentStage();
        let errMsg;
        if(this.amIOwner){
            errMsg = "You are not allowed to Upload Files in the " + this.case.data.fields.Stage__c.value + " stage.";
        }else {
            errMsg = "You are not allowed to Upload Files for a Case not asssigned to you.";
        }
        this.showToast({
            title: "Info",
            message: errMsg,
            variant: "info",
        });      
    }

    checkEditFieldPermissions(e){
        this.checkAccessbilityforCurrentStage();
        let errMsg;
        if(this.amIOwner){
            errMsg = "You are not allowed to edit the field in the " + this.case.data.fields.Stage__c.value + " stage.";
        }else {
            errMsg = "You are not allowed to edit fields for a Case not asssigned to you.";
        }
        this.showToast({
            title: "Info",
            message: errMsg,
            variant: "info",
        });      
    }

    refresh(e){
        this.checkAccessbilityforCurrentStage();
    }

    renderedCallback(e){
        if(this.childColumns && this.childColumns.length <= 3){
            this.sizeClass = 'singleColumnTable';
        }
        if(this.template.querySelector("table[name='childTable']")){
            this.template.querySelector("table[name='childTable']").classList.add(this.sizeClass);
            
        }
        
    }
}