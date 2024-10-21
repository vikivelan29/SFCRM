import { LightningElement, wire, api, track } from 'lwc';

export default class Abfl_DataTableWithPagination extends LightningElement {

    @api columns = [];
    @api tableData;
    @api key;
    @api pageSize; //No.of records to be displayed per page

    isRenderDatatable = true;

    recordsToDisplay = []; //Records to be displayed on the page

    totalNoOfRecordsInDatatable = 0;
    emptyTable = false;
    totalPages; //Total no.of pages
    pageNumber = 1; //Page number

    connectedCallback() {
        this.totalNoOfRecordsInDatatable = this.tableData?.length;
        if(this.totalNoOfRecordsInDatatable==0){
            this.emptyTable=true;
        }
        if (this.totalNoOfRecordsInDatatable) {
            this.paginationHelper();
        }
    }

    @api
    refreshTable(messageData){
        this.tableData = JSON.parse(JSON.stringify(messageData));
        this.totalNoOfRecordsInDatatable = this.tableData?.length;
        if(this.totalNoOfRecordsInDatatable==0){
            this.emptyTable=true;
        }
        if (this.totalNoOfRecordsInDatatable) {
            this.emptyTable=false;
            this.paginationHelper();
        }
    }

    get notEmptyTable(){
        return !this.emptyTable && this.totalPages>1;
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

        for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if (i === this.totalNoOfRecordsInDatatable) {
                break;
            }
            this.recordsToDisplay.push(this.tableData[i]);
        }
    }

    callRowAction(event){
        const custEvent = new CustomEvent(
            'rowaction', {
                detail: event.detail.row
        });
        this.dispatchEvent(custEvent);                    
    }
    get divBlock(){
        return this.columns?.length==1?'width:25%':'';
    }
    get divClass(){
        return this.changeView?'slds-modal__container':'';
    }
    get secClass(){
        return this.changeView?'slds-modal slds-fade-in-open slds-modal_medium slds-modal_large':'';
    }
    get headClass(){
        return this.changeView?'slds-modal__header':'slds-hide';
    }
    get bodyClass(){
        return this.changeView?'slds-modal__content slds-p-around_medium':'';
    }
    get backClass(){
        return this.changeView?'slds-backdrop slds-backdrop_open':'';
    }
    changeView=false;
    @api
    changeViewFn(){
        this.changeView=this.changeView==true?false:true;
        console.log('***changeView:'+this.changeView);
    }

    closeModal(){
    	this.changeViewFn();
    }
}