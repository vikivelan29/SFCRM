import { LightningElement,track,api,wire } from 'lwc';
import GetViewPrintDetails from '@salesforce/apex/ABHI_ViewPrintandDispatchDetails.GetViewPrintDetails';
import { getRecord } from 'lightning/uiRecordApi';

export default class Abhi_ViewPrintandDispatchDetails extends LightningElement {


    @api recordId;
    @track isLoading = false;
    @track errorMessages = '';
    @track displayError = false;
    @track showData;
    @track tableData = [];
    @track pageSize = 10; // Number of records per page
    showRecords = false;
    @track currentPage = 1;
    @track totalPages = 0;
    @track totalNoOfRecordsInDatatable = 0;
    //@track totalPages;
    //@track pageNumber = 1;
    @track recordsToDisplay = [];
    policyNumber;


    


    get bDisableFirst() {
        return this.currentPage === 1;
    }

    get bDisableLast() {
        return this.currentPage === this.totalPages;
    }

    @wire(getRecord, { recordId: '$recordId'})
    record;

    get paginatedTableData() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        return this.tableData.slice(start, end);
    }

    connectedCallback() {
        console.log('Component connected with recordId:', this.recordId);
        if (this.recordId) {
            this.loadData();
        } else {
            console.error('No recordId available');
        }

        //this.loadData();
    }

    loadData() {
        this.isLoading = true;
        GetViewPrintDetails({ assetId: this.recordId })
            .then(result => {
                
                console.log('Full Result:', JSON.stringify(result, null, 2));
                this.isLoading = false;
                if (result && result.response) {
                    const responseCode = result.response.responseCode;
                    const messages = result.response.messages || [];
                    const messageDescription = messages.length > 0 ? messages[0].messageDescription : null;
                    this.ApiFailure = messageDescription;
                    if (result && result.response && result.response.responseCode === '200') {
                    console.log('result.statusCode', result.response.responseCode);
                    const printDetails = result.vendorPrintDispatchDetails;
                    if (printDetails && printDetails.basicdetailAttribute && Array.isArray(printDetails.basicdetailAttribute)) {
                        this.processAttributes(printDetails.basicdetailAttribute);
                    } else {
                        this.errorMessages = messageDescription;
                        this.displayError = true;
                        this.showRecords = false;
                    }
                } else {
                    this.errorMessages = messageDescription;
                    this.displayError = true;
                    this.showRecords = false;
                }
            } else {
                // If result structure is unexpected
                this.errorMessages = 'Invalid response';
                this.displayError = true;
                this.showRecords = false;
            }
            })
            .catch(error => {
                this.isLoading = false;
                this.displayError = true;
                if (error.body!= null) {
                    this.errorMessages = error.body.message;
                } else if(this.ApiFailure){
                    this.errorMessages = this.ApiFailure;
                }
                else{
                    this.errorMessages = 'An unknown error occured, please contact your system admin'
                }
                console.error('error in getdetails>>>', error);            
            });
    }

    processAttributes(attributes) {
        if (!attributes || !Array.isArray(attributes)) {
            console.error('No valid attributes provided');
            this.tableData = [];
            this.showTable = false;
            return;
        }
        console.log('Attributes:', attributes);

        // Define the list of attributes you want to display
    const desiredAttributes = [
        'Go Green',
        'Communication Trigger Date',
        'Communication Mode',
        'Recipient email/Mobile No',
        'Communication Delivery Status',
        'Communication Delivery Date',
        'Communication_Name',
        'Dispatch Date',
        'AWB No',
        'Courier Name'
    ];

    // Filter the attributes to include only those in the desiredAttributes list
    const filteredAttributes = attributes.filter(attr => desiredAttributes.includes(attr.name));

// Map the attributes to tableData directly
        this.tableData = filteredAttributes.map(attr => ({
    attributeCode: attr.name || 'Unnamed Attribute',
    attributeValue: attr.value || 'N/A'
    }));
    this.totalNoOfRecordsInDatatable = this.tableData.length;
    this.updatePagination();
    this.showRecords = this.tableData.length > 0;

    }

    updatePagination() {
        this.totalPages = Math.ceil(this.totalNoOfRecordsInDatatable / this.pageSize);
        this.currentPage = Math.min(Math.max(this.currentPage, 1), this.totalPages);
        console.log('pagination--',this.currentPage, this.pageSize,this.totalPages,this.recordsToDisplay);
    }
        

    handleRefresh(){
        this.isLoading=true;
        this.showData=false;
        this.loadData();
    }

    firstPage() {
        this.currentPage = 1;
        this.updatePagination();
    }

    previousPage() {
        if (this.currentPage > 1) {
            this.currentPage -= 1;
            this.updatePagination();
        }
    }

    nextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage += 1;
            this.updatePagination();
        }
    }

    lastPage() {
        this.currentPage = this.totalPages;
        this.updatePagination();
    }
    get pageNumber() {
        return this.currentPage;
    }

}