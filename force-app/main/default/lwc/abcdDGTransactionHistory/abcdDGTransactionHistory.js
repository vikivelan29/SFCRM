// childComponent.js
import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getTrasanctionDetails from '@salesforce/apex/ABCD_DGTransactionHistoryController.getTransactions';

export default class abcdDGTransactionHistory extends LightningElement {
    @api mobileNumber;
    @track customerID;  
    @track selectedOption = 'last5'; 
    @track fromDate = '';
    @track toDate = '';
    @track showDateFields = false;
    @track isModalOpen = false;
    @track transactionDetails = [];
    showTransactionTable = false;
    @track currentPage = 1;
    @track pageSize = 5;
    @api clientid;
    @api emailId;
    @track isLoading = false; 
    

    get options() {
        return [
            { label: 'Last 5 transactions', value: 'last5' },
            { label: 'Custom Filter', value: 'custom' }
        ];
    }
    
    handleMobileChange(event){
        this.mobileNumber = event.target.value;
    }

    handleOptionChange(event) {
        this.selectedOption = event.detail.value;
        this.showDateFields = this.selectedOption === 'custom';
        if (!this.showDateFields) {
            this.fromDate = '';
            this.toDate = '';
        }
    }
    
    handleDateChange(event) {
        const field = event.target.name;
        this[field] = event.target.value;
        this.validateDates();
    }
    
    validateDates() {
        const today = new Date().toISOString().split('T')[0];
        if (this.fromDate && this.fromDate > today) {
            this.showToast('Error', 'From Date cannot be greater than today.', 'error');
            this.fromDate = '';
        }
        if (this.toDate && this.toDate < this.fromDate) {
            this.showToast('Error', 'To Date cannot be earlier than From Date.', 'error');
            this.toDate = '';
        }
    }
    
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    
    get isButtonVisible() {
        return this.selectedOption === 'last5' || (this.fromDate && this.toDate);
    }
    
    handleClear() {
        this.selectedOption = 'last5';
        this.showDateFields = false;
        this.fromDate = '';
        this.toDate = '';
        this.transactionDetails = [];
        this.showTransactionTable = false;
        this.currentPage = 1;
    }

    @api openModal(recordId) {
        if (recordId) {
            this.recordId = recordId;
            this.isModalOpen = true;
        }
    }
    
    closeModal() {
        this.isModalOpen = false;
    }

    async getTransaction(){
        try {
                this.isLoading = true;
                const result = await getTrasanctionDetails({
                    mobileNumber: this.mobileNumber,
                    customerID : this.clientid,
                    emailID : this.emailId,
                    startDate: this.selectedOption === 'last5' ? null : this.fromDate,
                    toDate: this.selectedOption === 'last5' ? null : this.toDate
                });
                if (result.isSuccess) {
                    debugger
                    this.showTransactionTable = true;
                    console.log('Fetched Transactions:', JSON.stringify(result.dgTransactionDetails));
                    let transactions = result.dgTransactionDetails.map(txn => ({
                        transactionType: txn.transactionType,
                        amount: txn.amount,
                        unit: txn.unit,
                        transactionDate: txn.transactionDate,
                        transactionStatus: txn.transactionStatus
                    }));
                    this.transactionDetails = transactions;
                    this.isLoading = false;
                    this.currentPage = 1;
                } else {
                    this.showToast('Error', result.errorMessage || 'Error fetching transactions', 'error');
                    this.isLoading = false;
                }
            
        } catch (error) {
            this.showToast('Error', error.body ? error.body.message : error.message, 'error');
            this.isLoading = false;
        }

    }

    get transactionColumns() {
        return [
            { label: 'Transaction Type', fieldName: 'transactionType', type: 'text', cellAttributes: { alignment: 'right' }, minWidth: 150 },
            { label: 'Amount', fieldName: 'amount', type: 'currency', cellAttributes: { alignment: 'right' }, minWidth: 150 },
            { label: 'Units', fieldName: 'unit', type: 'number', cellAttributes: { alignment: 'right' }, minWidth: 150 },
            { 
                label: 'Date of Transaction', 
                fieldName: 'transactionDate', 
                type: 'date', 
                typeAttributes: { 
                    year: "numeric", 
                    month: "2-digit", 
                    day: "2-digit", 
                    timeZone: "UTC"
                }, 
                minWidth: 150 
            },
            { label: 'Transaction Status', fieldName: 'transactionStatus', type: 'text', wrapText: true, minWidth: 150 }
        ];
    }

    get totalPages() {
        return Math.ceil(this.transactionDetails.length / this.pageSize);
    }

    get paginatedTransactions() {
        const start = (this.currentPage - 1) * this.pageSize;
        return this.transactionDetails.slice(start, start + this.pageSize);
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
        }
    }

    handlePrevPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
        }
    }

    get bDisablePrevious() {
        return this.currentPage == 1;
    }
    get bDisableNext() {
        return this.currentPage == this.totalPages;
    }
}