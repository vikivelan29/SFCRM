import { api, LightningElement } from 'lwc';
import fetchDigitalErrors from '@salesforce/apex/ABAMC_DisplayDigitalErrorsController.fetchDigitalErrors';
import { reduceErrors } from 'c/asf_ldsUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import TIME_ZONE from '@salesforce/i18n/timeZone';
import MyModal from 'c/asf_simpleModal';

const columns = [
    { 
        label: 'Updated Date', 
        fieldName: 'updatedDatetime', 
        type: 'date', 
        initialWidth: 200,
        sortable: true,
        typeAttributes: {
            year: "2-digit",
            month: "short",
            day: "2-digit",
            hour: "2-digit",
            minute: "2-digit",
            timeZone: TIME_ZONE
        }
    },
    { label: 'Event Type', fieldName: 'eventType', initialWidth: 100, sortable: true },
    { label: 'Message', fieldName: 'messageText', initialWidth: 550, sortable: true },
    { 
        label: 'View', 
        fieldName: 'id', 
        type: 'button-icon', 
        initialWidth: 80,
        typeAttributes: {
            label: { fieldName: 'View' },
            name: 'id',
            iconName: 'action:preview'
        },
    }
];

export default class Abamc_displayDigitalErrors extends LightningElement {
    data = [];
    columns = columns;
    defaultSortDirection = 'desc';
    sortDirection = 'desc';
    sortedBy;
    @api recordId;
    loading = true;
    displayTable = true;
    userMessage;

    // Pagination variables
    currentPage = 1;
    recordsPerPage = 10;
    totalRecords = 0;
    totalPages = 0;
    paginatedData = [];

    connectedCallback() {
        console.log('connectedCallback');
        this.fetchData();
        this.loading = false;
    }

    async fetchData() {
        console.log('fetchData', this.recordId);
        if (this.recordId) {
            let wrap = await fetchDigitalErrors({ input: this.recordId }).catch((error) => {
                console.error(error);
                this.showError('error', 'Oops! Something went wrong', error);
            });

            if (wrap && wrap.isSuccess) {
                let response = JSON.parse(wrap.responseBody);
                if (response.length == 0) {
                    this.displayTable = false;
                    this.userMessage = 'No data found';
                }

                this.data = response.map((item) => {
                    return {
                        'id': item._id,
                        'updatedDatetime': item._metadata.lastUpdated,
                        'eventType': item.eventType,
                        'messageText': item.messageText
                    };
                });
                this.totalRecords = this.data.length;
                this.totalPages = Math.ceil(this.totalRecords / this.recordsPerPage);
                this.updatePaginatedData();
                this.sortedBy = 'updatedDatetime';
                this.loading = false;
            } else {
                console.error(wrap.errorMessage);
                this.showError('error', 'Oops! Something went wrong', wrap.errorMessage);
            }
        }
    }

    viewRecord(event) {
        console.log(event.detail.action.name);
        console.log(event.detail.row.id);
        let selectedId = event.detail.row.id;
        let selectedRow = this.data.find(item => {
            return item.id == selectedId;
        });
        console.log('selectedRow', selectedRow);
        let currentDateVal = new Date(selectedRow.updatedDatetime);
        let formattingOptions = {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            timeZone: 'IST',
            hour12: true,
            hour: '2-digit',
            minute: '2-digit'
        };
        let currentDateLocale = currentDateVal.toLocaleString('en-IN', formattingOptions);
        MyModal.open({
            content: selectedRow.messageText,
            header: 'Digital Error Details',
            label: currentDateLocale + ' / ' + selectedRow.eventType,
            footeraction: 'Okay'
        }).then((result) => {
            console.log(result);
        }).catch(error => {
            console.error(error);
        });
    }

    refreshData() {
        this.loading = true;
        this.fetchData();
    }

    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                return primer(x[field]);
            }
            : function (x) {
                return x[field];
            };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.data];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.updatePaginatedData();
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    // Pagination methods
    updatePaginatedData() {
        const startIndex = (this.currentPage - 1) * this.recordsPerPage;
        const endIndex = startIndex + this.recordsPerPage;
        this.paginatedData = this.data.slice(startIndex, endIndex);
    }

    handlePrevPage() {
        if (this.currentPage > 1) {
            this.currentPage -= 1;
            this.updatePaginatedData();
        }
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage += 1;
            this.updatePaginatedData();
        }
    }

    handleFirstPage() {
        this.currentPage = 1;
        this.updatePaginatedData();
    }

    handleLastPage() {
        this.currentPage = this.totalPages;
        this.updatePaginatedData();
    }

    get isPrevDisabled() {
        return this.currentPage === 1;
    }

    get isNextDisabled() {
        return this.currentPage === this.totalPages;
    }

    get pageInfo() {
        return `Showing ${this.currentPage} of ${this.totalPages} pages(s)`;
    }

    // Utility method for error handling
    showError(variant, title, error) {
        let errMsg = reduceErrors(error);
        const event = new ShowToastEvent({
            variant: variant,
            title: title,
            message: Array.isArray(errMsg) ? errMsg[0] : errMsg
        });
        this.dispatchEvent(event);
    }

    showSuccessMessage(variant, title, message) {
        const event = new ShowToastEvent({
            variant: variant,
            title: title,
            message: message
        });
        this.dispatchEvent(event);
    }
}